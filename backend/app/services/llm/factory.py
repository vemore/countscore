"""Provider selection: LLM_PROVIDER env var (default bedrock) or explicit name."""

from __future__ import annotations

from app.config import get_settings

from .base import LLMProvider
from .bedrock import BedrockProvider
from .openai_compat import OpenAICompatProvider

_PROVIDERS = ("bedrock", "gemini", "mistral")

_cache: dict[str, LLMProvider] = {}


def _build(name: str) -> LLMProvider:
    settings = get_settings()
    if name == "bedrock":
        return BedrockProvider()
    if name == "gemini":
        return OpenAICompatProvider(
            label="gemini",
            base_url=settings.gemini_base_url,
            api_key=settings.gemini_api_key,
            model=settings.gemini_model,
        )
    if name == "mistral":
        return OpenAICompatProvider(
            label="mistral",
            base_url=settings.mistral_base_url,
            api_key=settings.mistral_api_key,
            model=settings.mistral_model,
        )
    raise ValueError(f"unknown LLM provider {name!r}; expected one of {', '.join(_PROVIDERS)}")


def get_llm_provider(name: str | None = None) -> LLMProvider:
    """Return the configured provider (cached). Falls back to LLM_PROVIDER env."""
    resolved = (name or get_settings().llm_provider).lower()
    if resolved not in _cache:
        _cache[resolved] = _build(resolved)
    return _cache[resolved]
