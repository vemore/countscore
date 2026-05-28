"""Tests for the LLM provider abstraction: factory selection + OpenAI-compat client."""
from __future__ import annotations

from types import SimpleNamespace
from unittest.mock import AsyncMock

import openai
import pytest

from app.config import get_settings
from app.services.llm import (
    BedrockProvider,
    OpenAICompatProvider,
    factory,
    get_llm_provider,
)


@pytest.fixture(autouse=True)
def _reset_caches():
    factory._cache.clear()
    get_settings.cache_clear()
    yield
    factory._cache.clear()
    get_settings.cache_clear()


# --- Factory selection ---------------------------------------------------------


def test_factory_returns_bedrock():
    assert isinstance(get_llm_provider("bedrock"), BedrockProvider)


def test_factory_returns_gemini_from_env(monkeypatch):
    monkeypatch.setenv("LLM_PROVIDER", "gemini")
    monkeypatch.setenv("GEMINI_API_KEY", "test-key")
    get_settings.cache_clear()

    provider = get_llm_provider()
    assert isinstance(provider, OpenAICompatProvider)
    assert provider.label == "gemini"
    assert provider.model == "gemini-2.5-pro"
    assert provider.available is True


def test_factory_returns_mistral_from_env(monkeypatch):
    monkeypatch.setenv("LLM_PROVIDER", "mistral")
    monkeypatch.setenv("MISTRAL_API_KEY", "test-key")
    get_settings.cache_clear()

    provider = get_llm_provider()
    assert isinstance(provider, OpenAICompatProvider)
    assert provider.label == "mistral"
    assert provider.available is True


def test_factory_unknown_provider_raises():
    with pytest.raises(ValueError, match="unknown LLM provider"):
        get_llm_provider("does-not-exist")


# --- OpenAICompatProvider ------------------------------------------------------


def test_openai_compat_unavailable_without_key():
    p = OpenAICompatProvider(label="gemini", base_url="http://x", api_key=None, model="m")
    assert p.available is False


async def test_openai_compat_unavailable_generate_raises():
    p = OpenAICompatProvider(label="gemini", base_url="http://x", api_key=None, model="m")
    with pytest.raises(RuntimeError, match="not configured"):
        await p.generate("sys", "user")


async def test_openai_compat_generate_builds_messages_and_parses():
    p = OpenAICompatProvider(
        label="mistral", base_url="http://x", api_key="k", model="mistral-large-latest"
    )
    fake_response = SimpleNamespace(
        choices=[SimpleNamespace(message=SimpleNamespace(content="  Verdict acide.  "))],
        model="mistral-large-2412",
        usage=SimpleNamespace(prompt_tokens=120, completion_tokens=80),
    )
    create = AsyncMock(return_value=fake_response)
    p._client = SimpleNamespace(chat=SimpleNamespace(completions=SimpleNamespace(create=create)))

    result = await p.generate("SYSTEM", "USER", max_tokens=1024, temperature=0.4, top_p=0.9)

    assert result.content == "Verdict acide."
    assert result.model == "mistral-large-2412"
    assert result.tokens_in == 120
    assert result.tokens_out == 80

    kwargs = create.call_args.kwargs
    assert kwargs["model"] == "mistral-large-latest"
    assert kwargs["messages"] == [
        {"role": "system", "content": "SYSTEM"},
        {"role": "user", "content": "USER"},
    ]
    assert kwargs["max_tokens"] == 1024
    assert kwargs["temperature"] == 0.4
    assert kwargs["top_p"] == 0.9
    # Must not leak params Mistral rejects.
    assert "max_completion_tokens" not in kwargs


async def test_openai_compat_wraps_api_error():
    p = OpenAICompatProvider(label="gemini", base_url="http://x", api_key="k", model="m")
    create = AsyncMock(side_effect=openai.OpenAIError("quota exceeded"))
    p._client = SimpleNamespace(chat=SimpleNamespace(completions=SimpleNamespace(create=create)))

    with pytest.raises(RuntimeError, match="gemini API call failed"):
        await p.generate("sys", "user")
