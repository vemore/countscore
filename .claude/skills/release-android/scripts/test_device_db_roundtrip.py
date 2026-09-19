"""Tests for device_db_roundtrip.sh — no device: `adb` is a fake that serves a directory.

    uv run --no-project --with pytest pytest .claude/skills/release-android/scripts/
"""

from __future__ import annotations

import os
import shutil
import sqlite3
import subprocess
import textwrap
from pathlib import Path

import pytest

SCRIPT = Path(__file__).resolve().parent / "device_db_roundtrip.sh"

# The fake adb: get-state, run-as ... true|ls|cat, am force-stop|broadcast, exec-out, push.
# $FAKE_DATA is the app's data dir, $FAKE_SDCARD stands in for /sdcard, $FAKE_DEBUGGABLE=0
# makes run-as fail the way it does on a store install. Every call is logged to $FAKE_LOG.
FAKE_ADB = textwrap.dedent(
    """\
    #!/usr/bin/env bash
    set -eu
    echo "$ANDROID_SERIAL $*" >>"$FAKE_LOG"
    case "$1" in
      get-state) echo device ;;
      push) mkdir -p "$FAKE_SDCARD/Download"; cp "$2" "$FAKE_SDCARD/${3#/sdcard/}" ;;
      shell|exec-out)
        shift
        if [ "$1" = run-as ]; then
          [ "${FAKE_DEBUGGABLE:-1}" = 1 ] || { echo "run-as: package not debuggable" >&2; exit 1; }
          shift 2
          case "$1" in
            true) ;;
            ls) ls "$FAKE_DATA/$2" ;;
            cat) cat "$FAKE_DATA/$2" ;;
          esac
        fi ;;
    esac
    """
)


@pytest.fixture
def device(tmp_path: Path) -> dict[str, str]:
    bin_dir = tmp_path / "bin"
    bin_dir.mkdir()
    adb = bin_dir / "adb"
    adb.write_text(FAKE_ADB)
    adb.chmod(0o755)
    (tmp_path / "data" / "databases").mkdir(parents=True)
    env = dict(os.environ)
    env.pop("ANDROID_SERIAL", None)
    env.update(
        ADB=str(adb),
        FAKE_DATA=str(tmp_path / "data"),
        FAKE_SDCARD=str(tmp_path / "sdcard"),
        FAKE_LOG=str(tmp_path / "adb.log"),
    )
    return env


def run(env: dict[str, str], *args: str) -> subprocess.CompletedProcess[str]:
    return subprocess.run(
        [str(SCRIPT), *args], env=env, capture_output=True, text=True, check=False
    )


def write_wal_database(databases: Path, version: int) -> None:
    """A WAL-mode countscore.db whose rows live only in the uncheckpointed -wal, as a killed
    app leaves it: the files are copied while the writer still holds them open."""
    live = databases.parent / "live"
    live.mkdir()
    conn = sqlite3.connect(live / "countscore.db")
    conn.execute("PRAGMA journal_mode=WAL")
    conn.execute("PRAGMA wal_autocheckpoint=0")
    conn.execute("CREATE TABLE games (id INTEGER PRIMARY KEY, name TEXT)")
    conn.executemany("INSERT INTO games (name) VALUES (?)", [("a",), ("b",), ("c",)])
    conn.execute(f"PRAGMA user_version={version}")
    conn.commit()
    for name in ("countscore.db", "countscore.db-wal"):
        shutil.copy(live / name, databases / name)
    conn.close()


def test_refuses_without_a_serial(device: dict[str, str]) -> None:
    result = run(device, "pull")
    assert result.returncode != 0
    assert "ANDROID_SERIAL" in result.stderr
    assert not Path(device["FAKE_LOG"]).exists()


def test_pull_folds_the_wal_into_one_file(device: dict[str, str], tmp_path: Path) -> None:
    write_wal_database(Path(device["FAKE_DATA"]) / "databases", version=12)
    out = tmp_path / "out" / "countscore.db"

    result = run(device, "-s", "pixel:5555", "pull", str(out))

    assert result.returncode == 0, result.stderr
    assert "pulled databases/countscore.db-wal" in result.stdout
    assert "user_version=12" in result.stdout
    assert "games=3" in result.stdout
    assert sorted(p.name for p in out.parent.iterdir()) == ["countscore.db"]
    conn = sqlite3.connect(out)
    assert conn.execute("SELECT COUNT(*) FROM games").fetchone()[0] == 3
    assert conn.execute("PRAGMA journal_mode").fetchone()[0] == "delete"
    conn.close()
    log = Path(device["FAKE_LOG"]).read_text()
    assert all(line.startswith("pixel:5555 ") for line in log.splitlines())
    assert "shell am force-stop com.vemore.countscore" in log


def test_pull_refuses_a_non_debuggable_install(device: dict[str, str], tmp_path: Path) -> None:
    device["FAKE_DEBUGGABLE"] = "0"
    result = run(device, "-s", "pixel", "pull", str(tmp_path / "x.db"))
    assert result.returncode != 0
    assert "not debuggable" in result.stderr
    assert not (tmp_path / "x.db").exists()


def test_pull_refuses_a_missing_database(device: dict[str, str], tmp_path: Path) -> None:
    result = run(device, "-s", "pixel", "pull", str(tmp_path / "x.db"))
    assert result.returncode != 0
    assert "no databases/countscore.db" in result.stderr


def test_push_lands_in_downloads(device: dict[str, str], tmp_path: Path) -> None:
    db = tmp_path / "countscore.db"
    sqlite3.connect(db).execute("CREATE TABLE t (x)").connection.close()
    device["ANDROID_SERIAL"] = "pixel"

    result = run(device, "push", str(db))

    assert result.returncode == 0, result.stderr
    pushed = Path(device["FAKE_SDCARD"]) / "Download" / "countscore-upgrade-test.db"
    assert pushed.read_bytes() == db.read_bytes()


def test_push_refuses_a_file_that_is_not_sqlite(device: dict[str, str], tmp_path: Path) -> None:
    junk = tmp_path / "junk.db"
    junk.write_text("not a database")
    result = run(device, "-s", "pixel", "push", str(junk))
    assert result.returncode != 0
    assert "not an SQLite database" in result.stderr
    assert not (Path(device["FAKE_SDCARD"]) / "Download").exists()
