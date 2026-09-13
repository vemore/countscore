"""Basic smoke tests."""
from __future__ import annotations

import pytest

from app.config import get_settings
from app.services.llm import factory


@pytest.fixture(autouse=True)
def _reset_caches():
    """The factory memoises provider instances and get_settings is lru_cached.

    Without this, a provider built from an earlier test's environment leaks into the
    next one and /health reports a model nobody configured.
    """
    factory._cache.clear()
    get_settings.cache_clear()
    yield
    factory._cache.clear()
    get_settings.cache_clear()


async def test_health(client):
    r = await client.get("/health")
    assert r.status_code == 200
    body = r.json()
    assert body["status"] == "ok"
    assert "version" in body


async def test_health_reports_resolved_llm_config(client, monkeypatch):
    """The fact that was invisible during the 2026-09-09 outage.

    /health answered {"status": "ok"} for two days while every analysis 502'd on a
    model the account's tier rejected. The model id is what makes a curl conclusive.

    Every value is set explicitly, so the assertion does not depend on the code defaults.
    (backend/.env is no longer read in tests: see conftest.py.)
    """
    monkeypatch.setenv("LLM_PROVIDER", "bedrock")
    monkeypatch.setenv("BEDROCK_MODEL_ID", "us.meta.llama3-3-70b-instruct-v1:0")
    monkeypatch.setenv("AWS_ACCESS_KEY_ID", "")
    monkeypatch.setenv("AWS_SECRET_ACCESS_KEY", "")
    get_settings.cache_clear()
    factory._cache.clear()

    llm = (await client.get("/health")).json()["llm"]
    assert llm["provider"] == "bedrock"
    assert llm["model"] == "us.meta.llama3-3-70b-instruct-v1:0"
    assert llm["credentials"] is False  # no credentials -> the provider cannot be called


async def test_health_model_follows_mistral_model_env(client, monkeypatch):
    """MISTRAL_MODEL must be visible in /health, not just inside the container."""
    monkeypatch.setenv("LLM_PROVIDER", "mistral")
    monkeypatch.setenv("MISTRAL_API_KEY", "test-key")
    monkeypatch.setenv("MISTRAL_MODEL", "mistral-small-latest")
    get_settings.cache_clear()
    factory._cache.clear()

    llm = (await client.get("/health")).json()["llm"]
    assert llm["provider"] == "mistral"
    assert llm["model"] == "mistral-small-latest"
    assert llm["credentials"] is True


async def test_health_survives_an_unknown_provider(client, monkeypatch):
    """A typo in LLM_PROVIDER must not restart-loop the container."""
    monkeypatch.setenv("LLM_PROVIDER", "does-not-exist")
    get_settings.cache_clear()
    factory._cache.clear()

    r = await client.get("/health")
    assert r.status_code == 200
    assert r.json()["status"] == "ok"
    assert r.json()["llm"] == {
        "provider": "does-not-exist",
        "model": None,
        "credentials": False,
    }


async def test_health_gemini_defaults_to_flash(client, monkeypatch):
    """Without GEMINI_MODEL, the default must be a model the free tier can call.

    gemini-2.5-pro has a quota of 0 on a free-tier key, so a bare LLM_PROVIDER=gemini
    used to swap one outage for another.
    """
    monkeypatch.setenv("LLM_PROVIDER", "gemini")
    monkeypatch.setenv("GEMINI_API_KEY", "test-key")
    monkeypatch.delenv("GEMINI_MODEL", raising=False)
    get_settings.cache_clear()
    factory._cache.clear()

    llm = (await client.get("/health")).json()["llm"]
    assert llm == {"provider": "gemini", "model": "gemini-2.5-flash", "credentials": True}


def test_settings_ignore_a_local_env_file(tmp_path, monkeypatch):
    """A developer's backend/.env must not leak into the test run."""
    (tmp_path / ".env").write_text("GEMINI_MODEL=gemini-2.5-pro\n")
    monkeypatch.chdir(tmp_path)
    monkeypatch.delenv("GEMINI_MODEL", raising=False)
    get_settings.cache_clear()

    assert get_settings().gemini_model == "gemini-2.5-flash"
