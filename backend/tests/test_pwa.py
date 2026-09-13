"""Tests for serving the PWA build under PWA_BASE_PATH."""

from __future__ import annotations

from collections.abc import AsyncIterator, Callable
from pathlib import Path

import pytest
import pytest_asyncio
from httpx import ASGITransport, AsyncClient
from pydantic import ValidationError

from app.config import Settings, get_settings
from app.main import create_app

BASE = "/countscore"
JSON_CSP = "default-src 'none'; frame-ancestors 'none'"


@pytest.fixture
def build_dir(tmp_path: Path) -> Path:
    """A minimal stand-in for build/web, inside a parent like the NAS pwa/ folder."""
    d = tmp_path / "pwa" / "current"
    d.mkdir(parents=True)
    (d / "index.html").write_text('<!DOCTYPE html><base href="/countscore/">')
    (d / "sqlite3.wasm").write_bytes(b"\x00asm\x01\x00\x00\x00")
    (d / "drift_worker.js").write_text("// worker")
    return d


@pytest.fixture
def pwa_settings(monkeypatch) -> Callable[[str, Path], None]:
    def _apply(base_path: str, directory: Path) -> None:
        monkeypatch.setenv("PWA_BASE_PATH", base_path)
        monkeypatch.setenv("PWA_DIR", str(directory))
        get_settings.cache_clear()

    yield _apply
    get_settings.cache_clear()


@pytest_asyncio.fixture
async def pwa_client(pwa_settings, build_dir) -> AsyncIterator[AsyncClient]:
    pwa_settings(BASE, build_dir)
    app = create_app()
    async with AsyncClient(transport=ASGITransport(app=app), base_url="http://test") as ac:
        yield ac


async def test_pwa_is_not_served_by_default(client):
    r = await client.get(f"{BASE}/")

    assert r.status_code == 404


async def test_index_is_served_with_the_pwa_csp(pwa_client):
    r = await pwa_client.get(f"{BASE}/")

    assert r.status_code == 200
    assert r.headers["content-type"].startswith("text/html")
    csp = r.headers["Content-Security-Policy"]
    assert "'wasm-unsafe-eval'" in csp
    assert "https://www.gstatic.com" in csp
    assert "frame-ancestors 'none'" in csp
    assert r.headers["Cache-Control"] == "no-cache"
    assert r.headers["X-Content-Type-Options"] == "nosniff"


async def test_base_path_without_slash_redirects(pwa_client):
    r = await pwa_client.get(BASE)

    assert r.status_code in (307, 308)
    assert r.headers["location"].endswith(f"{BASE}/")


async def test_wasm_is_served_as_application_wasm(pwa_client):
    """nosniff is on, so a wrong MIME type would make the browser refuse the module."""
    r = await pwa_client.get(f"{BASE}/sqlite3.wasm")

    assert r.status_code == 200
    assert r.headers["content-type"] == "application/wasm"


async def test_api_keeps_its_json_csp(pwa_client):
    r = await pwa_client.get("/health")

    assert r.status_code == 200
    assert r.headers["Content-Security-Policy"] == JSON_CSP
    assert "Cache-Control" not in r.headers


async def test_a_lookalike_prefix_is_not_the_pwa(pwa_client):
    r = await pwa_client.get(f"{BASE}-evil/")

    assert r.status_code == 404
    assert r.headers["Content-Security-Policy"] == JSON_CSP


async def test_path_traversal_stays_inside_the_build(pwa_client, build_dir):
    (build_dir.parent / "secret.txt").write_text("nope")

    r = await pwa_client.get(f"{BASE}/..%2Fsecret.txt")

    assert r.status_code == 404


async def test_writes_are_refused(pwa_client):
    r = await pwa_client.post(f"{BASE}/index.html", content=b"x")

    assert r.status_code == 405


async def test_missing_build_is_404_and_appears_without_restart(pwa_settings, tmp_path):
    """The app starts before the first deploy, and deploy_web.sh swaps the folder in."""
    directory = tmp_path / "pwa" / "current"
    pwa_settings(BASE, directory)
    app = create_app()

    async with AsyncClient(transport=ASGITransport(app=app), base_url="http://test") as ac:
        before = await ac.get(f"{BASE}/")
        directory.mkdir(parents=True)
        (directory / "index.html").write_text("<!DOCTYPE html>")
        after = await ac.get(f"{BASE}/")

    assert before.status_code == 404
    assert after.status_code == 200


@pytest.mark.parametrize("value", ["/sync/app", "/groups", "/health", "/docs"])
def test_base_path_shadowing_an_api_route_is_refused(pwa_settings, build_dir, value):
    pwa_settings(value, build_dir)

    with pytest.raises(RuntimeError, match="collides"):
        create_app()


@pytest.mark.parametrize("value", ["countscore", "/countscore/", "/", "/..", "/a b"])
def test_malformed_base_path_is_rejected(value):
    with pytest.raises(ValidationError):
        Settings(pwa_base_path=value)


@pytest.mark.parametrize("value", ["", "/countscore", "/apps/count-score_2"])
def test_wellformed_base_path_is_accepted(value):
    assert Settings(pwa_base_path=value).pwa_base_path == value
