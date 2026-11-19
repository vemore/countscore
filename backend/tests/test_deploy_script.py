"""scripts/deploy_nas.sh, run against stub ssh, docker, git and curl.

There is no NAS in CI, but what the script must guarantee is an order of commands and a
reaction to failures, which a stub can record: the schema is migrated from a one-off
container before the api is swapped, a failed dump or upgrade never reaches the swap, and an
unhealthy new image is replaced by the previous one only when no migration ran.

The stub `ssh` runs the remote command locally, in a temporary "NAS" directory, so the
script's real `sed` on compose.yaml and its `grep` on the NAS .env run too. The script is
copied out of the repository first, so a developer's untracked deploy.env is never sourced.
"""

from __future__ import annotations

import os
import shutil
import subprocess
from pathlib import Path

import pytest

BACKEND = Path(__file__).resolve().parents[1]
SCRIPT = BACKEND / "scripts" / "deploy_nas.sh"
COMPOSE = BACKEND / "docker-compose.prod.yml"

pytestmark = pytest.mark.skipif(shutil.which("bash") is None, reason="needs bash")

SSH = """#!/bin/bash
# ssh <host> <command...>: run the command here, as the NAS shell would.
shift
exec bash -c "$*"
"""

GIT = """#!/bin/bash
echo abc1234
"""

# Every call is logged. `compose` subcommands behave as the STUB_* variables say; `up`
# records which api image it started, and fails for the new one when STUB_UP_FAIL is set.
DOCKER = r"""#!/bin/bash
echo "docker $*" >> "$STUB_LOG"
case "$1" in
    inspect) echo sha256:0ld; exit 0 ;;
    compose) shift ;;
    *) exit 0 ;;
esac
api_image() { grep -o 'localhost:5050/countscore:[^ ]*' compose.yaml; }
case "$*" in
    "ps -q api") [ -n "${STUB_NO_API:-}" ] || echo 0ldc0nta1ner ;;
    "run --rm -T api alembic current")
        echo "INFO  [alembic.runtime.migration] Context impl PostgresqlImpl." >&2
        [ -z "${STUB_CURRENT:-}" ] || echo "$STUB_CURRENT" ;;
    "run --rm -T api alembic heads") echo "$STUB_HEAD (head)" ;;
    "run --rm -T api alembic upgrade head") [ -z "${STUB_UPGRADE_FAIL:-}" ] || exit 1 ;;
    "run --rm -T --entrypoint sh db-backup "*) [ -z "${STUB_DUMP_FAIL:-}" ] || exit 1 ;;
    up*)
        api_image > "$STUB_STATE/serving"
        if [ -n "${STUB_UP_FAIL:-}" ] && api_image | grep -q ':latest$'; then exit 1; fi ;;
esac
exit 0
"""

# The public /health answers for whatever image `up` last started.
CURL = """#!/bin/bash
echo "curl $*" >> "$STUB_LOG"
if [ -n "${STUB_HEALTH_FAIL:-}" ] && grep -q ':latest$' "$STUB_STATE/serving"; then
    echo "curl: (22) The requested URL returned error: 502" >&2
    exit 22
fi
printf '{"status":"ok"}'
"""

UP = "docker compose up"
UPGRADE = "docker compose run --rm -T api alembic upgrade head"
DUMP = "docker compose run --rm -T --entrypoint sh db-backup"


@pytest.fixture
def env(tmp_path: Path) -> dict[str, str]:
    bin_dir = tmp_path / "bin"
    bin_dir.mkdir()
    for name, body in (("ssh", SSH), ("git", GIT), ("docker", DOCKER), ("curl", CURL)):
        stub = bin_dir / name
        stub.write_text(body)
        stub.chmod(0o755)

    scripts = tmp_path / "backend" / "scripts"
    scripts.mkdir(parents=True)
    shutil.copy(SCRIPT, scripts / "deploy_nas.sh")
    shutil.copy(COMPOSE, tmp_path / "backend" / "docker-compose.prod.yml")

    nas = tmp_path / "nas"
    nas.mkdir()
    (nas / ".env").write_text("BACKUP_AGE_RECIPIENT=age1testrecipient\n")
    (tmp_path / "state").mkdir()
    return {
        "PATH": f"{bin_dir}:{os.environ['PATH']}",
        "HOME": str(tmp_path),
        "REGISTRY": "registry.test:5050",
        "NAS_SSH": "nas-test",
        "NAS_DEPLOY_DIR": str(nas),
        "PUBLIC_URL": "https://api.test",
        "STUB_LOG": str(tmp_path / "calls.log"),
        "STUB_STATE": str(tmp_path / "state"),
        "STUB_CURRENT": "0005_old",
        "STUB_HEAD": "0006_new",
    }


def run(env: dict[str, str], *args: str) -> subprocess.CompletedProcess:
    script = Path(env["HOME"]) / "backend" / "scripts" / "deploy_nas.sh"
    return subprocess.run(
        ["bash", str(script), *args],
        env=env,
        capture_output=True,
        text=True,
        timeout=30,
    )


def calls(env: dict[str, str]) -> list[str]:
    log = Path(env["STUB_LOG"])
    return log.read_text().splitlines() if log.exists() else []


def index(lines: list[str], prefix: str) -> int:
    return next(i for i, line in enumerate(lines) if line.startswith(prefix))


def ups(env: dict[str, str]) -> list[str]:
    return [c for c in calls(env) if c.startswith(UP)]


def api_image(env: dict[str, str]) -> str:
    compose = (Path(env["NAS_DEPLOY_DIR"]) / "compose.yaml").read_text()
    return next(w for w in compose.split() if w.startswith("localhost:5050/countscore:"))


def serving(env: dict[str, str]) -> str:
    return (Path(env["STUB_STATE"]) / "serving").read_text().strip()


def test_pending_revision_is_dumped_then_migrated_before_the_swap(env):
    result = run(env)
    assert result.returncode == 0, result.stderr
    log = calls(env)
    tag = index(log, "docker tag sha256:0ld localhost:5050/countscore:pre-deploy")
    pull = index(log, "docker compose pull")
    dump = index(log, DUMP)
    upgrade = index(log, UPGRADE)
    up = index(log, UP)
    assert tag < pull < dump < upgrade < up
    assert "curl -fsS https://api.test/health" in log[up + 1]
    assert "premigration_" in result.stdout
    assert "0005_old-to-0006_new.dump.gz.age" in result.stdout
    assert serving(env) == "localhost:5050/countscore:latest"
    # The serving container is never used for alembic or the dump any more.
    assert not [c for c in log if c.startswith("docker compose exec")]


def test_every_up_waits_for_the_healthchecks(env):
    env["STUB_UP_FAIL"] = "1"
    env["STUB_CURRENT"] = env["STUB_HEAD"]
    run(env)
    assert len(ups(env)) == 2
    assert all(c == "docker compose up -d --wait --wait-timeout 90" for c in ups(env))


def test_schema_at_head_takes_no_dump_and_runs_no_upgrade(env):
    env["STUB_CURRENT"] = env["STUB_HEAD"]
    result = run(env)
    assert result.returncode == 0, result.stderr
    log = calls(env)
    assert not [c for c in log if c.startswith((DUMP, UPGRADE))]
    assert len(ups(env)) == 1


def test_a_failed_dump_stops_before_the_upgrade_and_the_swap(env):
    env["STUB_DUMP_FAIL"] = "1"
    result = run(env)
    assert result.returncode != 0
    log = calls(env)
    assert not [c for c in log if c.startswith(UPGRADE)]
    assert ups(env) == []
    assert "previous api container is still serving" in result.stderr
    # A later `docker compose up -d` must not start the pulled :latest on the old schema.
    assert api_image(env) == "localhost:5050/countscore:pre-deploy"


def test_a_failed_upgrade_stops_before_the_swap(env):
    env["STUB_UPGRADE_FAIL"] = "1"
    result = run(env)
    assert result.returncode != 0
    assert ups(env) == []
    assert api_image(env) == "localhost:5050/countscore:pre-deploy"


def test_unhealthy_image_without_migration_is_rolled_back(env):
    env["STUB_CURRENT"] = env["STUB_HEAD"]
    env["STUB_UP_FAIL"] = "1"
    result = run(env)
    assert result.returncode != 0
    assert len(ups(env)) == 2
    assert serving(env) == "localhost:5050/countscore:pre-deploy"
    assert "the previous image is serving again" in result.stderr


def test_failing_public_health_without_migration_is_rolled_back(env):
    env["STUB_CURRENT"] = env["STUB_HEAD"]
    env["STUB_HEALTH_FAIL"] = "1"
    result = run(env)
    assert result.returncode != 0
    assert len(ups(env)) == 2
    assert serving(env) == "localhost:5050/countscore:pre-deploy"
    assert "the previous image is serving again" in result.stderr


def test_unhealthy_image_after_a_migration_is_not_rolled_back(env):
    env["STUB_HEALTH_FAIL"] = "1"
    result = run(env)
    assert result.returncode != 0
    assert len(ups(env)) == 1
    assert serving(env) == "localhost:5050/countscore:latest"
    assert "backend-deploy skill §5" in result.stderr
    assert "0005_old-to-0006_new.dump.gz.age" in result.stderr


def test_first_deploy_dumps_from_base_and_tags_nothing(env):
    env["STUB_NO_API"] = "1"
    env["STUB_CURRENT"] = ""
    result = run(env)
    assert result.returncode == 0, result.stderr
    assert "base-to-0006_new" in result.stdout
    assert not [c for c in calls(env) if c.startswith("docker tag")]


def test_no_running_api_container_means_no_rollback(env):
    env["STUB_NO_API"] = "1"
    env["STUB_CURRENT"] = env["STUB_HEAD"]
    env["STUB_UP_FAIL"] = "1"
    result = run(env)
    assert result.returncode != 0
    assert len(ups(env)) == 1
    assert "No previous api image" in result.stderr


def test_rollback_flag_retags_the_api_and_waits(env):
    shutil.copy(COMPOSE, Path(env["NAS_DEPLOY_DIR"]) / "compose.yaml")
    result = run(env, "--rollback", "1234abc")
    assert result.returncode == 0, result.stderr
    assert api_image(env) == "localhost:5050/countscore:1234abc"
    compose = (Path(env["NAS_DEPLOY_DIR"]) / "compose.yaml").read_text()
    assert "localhost:5050/countscore-backup:latest" in compose
    assert ups(env) == ["docker compose up -d --wait --wait-timeout 90"]
    assert not [c for c in calls(env) if c.startswith(("docker build", "docker push"))]


def test_rollback_flag_does_not_need_public_url(env):
    shutil.copy(COMPOSE, Path(env["NAS_DEPLOY_DIR"]) / "compose.yaml")
    del env["PUBLIC_URL"]
    assert run(env, "--rollback", "1234abc").returncode == 0


def test_a_deploy_without_public_url_stops_before_building(env):
    del env["PUBLIC_URL"]
    result = run(env)
    assert result.returncode != 0
    assert "PUBLIC_URL" in result.stderr
    assert calls(env) == []


def test_script_has_no_sleep_and_parses():
    text = SCRIPT.read_text()
    assert "sleep" not in text
    subprocess.run(["bash", "-n", str(SCRIPT)], check=True)


@pytest.mark.skipif(shutil.which("shellcheck") is None, reason="needs shellcheck")
def test_script_passes_shellcheck():
    subprocess.run(["shellcheck", "-S", "warning", str(SCRIPT)], check=True)
