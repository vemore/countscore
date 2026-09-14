"""backup/countscore-backup.sh, the db-backup sidecar, run against stub pg_dump and age.

The script is shell, but what it must guarantee is testable without Postgres: it never
writes a dump without an age recipient, a failed pipe leaves no file behind, and the
retention sweep removes old plaintext dumps along with old encrypted ones.
"""

from __future__ import annotations

import gzip
import os
import shutil
import stat
import subprocess
import time
from pathlib import Path

import pytest

SCRIPT = Path(__file__).resolve().parents[1] / "backup" / "countscore-backup.sh"


# The image runs BusyBox ash; bash is the stand-in where BusyBox is absent. Both have
# `set -o pipefail`, which the script requires.
def _shell() -> list[str] | None:
    if busybox := shutil.which("busybox"):
        return [busybox, "sh"]
    if bash := shutil.which("bash"):
        return [bash]
    return None


SHELL = _shell()

pytestmark = pytest.mark.skipif(SHELL is None, reason="needs busybox or bash")

RECIPIENT = "age1testrecipient"

# Records that it ran, then emits a fake custom-format dump — or fails half-way through
# when PG_DUMP_FAIL is set, after writing some bytes, like a dropped connection.
PG_DUMP = """#!/bin/sh
touch "$STUB_LOG/pg_dump.ran"
printf 'PGDMP fake dump'
if [ -n "${PG_DUMP_FAIL:-}" ]; then exit 1; fi
"""

# `age -r <recipient>`: rejects anything but RECIPIENT, otherwise tags its input.
AGE = f"""#!/bin/sh
[ "$1" = "-r" ] && [ "$2" = "{RECIPIENT}" ] || {{ echo "age: bad recipient" >&2; exit 1; }}
printf 'AGE:'
cat
"""


@pytest.fixture
def env(tmp_path: Path) -> dict[str, str]:
    bin_dir = tmp_path / "bin"
    bin_dir.mkdir()
    for name, body in (("pg_dump", PG_DUMP), ("age", AGE)):
        stub = bin_dir / name
        stub.write_text(body)
        stub.chmod(0o755)
    (tmp_path / "backups").mkdir()
    (tmp_path / "log").mkdir()
    return {
        "PATH": f"{bin_dir}:{os.environ['PATH']}",
        "BACKUP_DIR": str(tmp_path / "backups"),
        "STUB_LOG": str(tmp_path / "log"),
    }


def run(env: dict[str, str], *args: str, timeout: float = 10) -> subprocess.CompletedProcess:
    assert SHELL is not None
    return subprocess.run(
        [*SHELL, str(SCRIPT), *args],
        env=env,
        capture_output=True,
        text=True,
        timeout=timeout,
    )


def files(env: dict[str, str]) -> list[str]:
    return sorted(os.listdir(env["BACKUP_DIR"]))


def test_refuses_without_recipient(env: dict[str, str]) -> None:
    result = run(env, "--once")

    assert result.returncode != 0
    assert "BACKUP_AGE_RECIPIENT is not set" in result.stderr
    assert files(env) == []
    assert not (Path(env["STUB_LOG"]) / "pg_dump.ran").exists()


def test_loop_mode_exits_at_start_without_recipient(env: dict[str, str]) -> None:
    # Must not sleep until 03:00 before noticing: the timeout would fire.
    result = run(env, timeout=5)

    assert result.returncode != 0
    assert "Refusing" in result.stderr


def test_refuses_a_recipient_age_rejects(env: dict[str, str]) -> None:
    result = run({**env, "BACKUP_AGE_RECIPIENT": "age1typo"}, "--once")

    assert result.returncode != 0
    assert files(env) == []
    assert not (Path(env["STUB_LOG"]) / "pg_dump.ran").exists()


def test_writes_an_encrypted_owner_only_dump(env: dict[str, str]) -> None:
    result = run({**env, "BACKUP_AGE_RECIPIENT": RECIPIENT}, "--once")

    assert result.returncode == 0, result.stderr
    (name,) = files(env)
    assert name.startswith("countscore_")
    assert name.endswith(".dump.gz.age")

    path = Path(env["BACKUP_DIR"]) / name
    content = path.read_bytes()
    assert content.startswith(b"AGE:")
    assert gzip.decompress(content[len(b"AGE:") :]) == b"PGDMP fake dump"
    assert stat.S_IMODE(path.stat().st_mode) == 0o600


def test_failed_pg_dump_leaves_no_file(env: dict[str, str]) -> None:
    result = run({**env, "BACKUP_AGE_RECIPIENT": RECIPIENT, "PG_DUMP_FAIL": "1"}, "--once")

    assert result.returncode != 0
    assert "FAILED" in result.stderr
    # Neither a truncated backup nor the hidden temporary file.
    assert files(env) == []


def test_retention_sweeps_old_plaintext_and_encrypted_dumps(env: dict[str, str]) -> None:
    backups = Path(env["BACKUP_DIR"])
    old = time.time() - 9 * 86400
    old_names = [
        "countscore_20260801_030000.sql.gz",
        "countscore_20260801_030000.dump.gz",
        "countscore_20260801_030000.dump.gz.age",
    ]
    kept_names = ["countscore_20260913_030000.dump.gz.age", "unrelated.sql.gz"]
    for name in old_names:
        (backups / name).write_bytes(b"x")
        os.utime(backups / name, (old, old))
    for name in kept_names:
        (backups / name).write_bytes(b"x")
    os.utime(backups / "unrelated.sql.gz", (old, old))

    result = run({**env, "BACKUP_AGE_RECIPIENT": RECIPIENT}, "--once")

    assert result.returncode == 0, result.stderr
    remaining = files(env)
    for name in old_names:
        assert name not in remaining
    for name in kept_names:
        assert name in remaining
    assert len(remaining) == len(kept_names) + 1
