"""Generic provider for any OpenAI-compatible Chat Completions endpoint.

Used for both Gemini (https://generativelanguage.googleapis.com/v1beta/openai/) and
Mistral (https://api.mistral.ai/v1): only base_url, api_key and model differ. We send
only the common params (temperature, top_p, max_tokens) — Mistral rejects unknown
fields and `max_completion_tokens` with HTTP 422.
"""
from __future__ import annotations

import openai
from openai import AsyncOpenAI

from .base import DEFAULT_MAX_TOKENS, DEFAULT_TEMPERATURE, DEFAULT_TOP_P, LLMResult


class OpenAICompatProvider:
    def __init__(self, *, label: str, base_url: str, api_key: str | None, model: str) -> None:
        self.label = label
        self.model = model
        self._client = (
            AsyncOpenAI(api_key=api_key, base_url=base_url) if api_key else None
        )

    @property
    def available(self) -> bool:
        return self._client is not None

    async def generate(
        self,
        system_prompt: str,
        user_message: str,
        *,
        max_tokens: int = DEFAULT_MAX_TOKENS,
        temperature: float = DEFAULT_TEMPERATURE,
        top_p: float = DEFAULT_TOP_P,
    ) -> LLMResult:
        if self._client is None:
            raise RuntimeError(f"{self.label} provider not configured (API key missing)")
        try:
            resp = await self._client.chat.completions.create(
                model=self.model,
                messages=[
                    {"role": "system", "content": system_prompt},
                    {"role": "user", "content": user_message},
                ],
                temperature=temperature,
                top_p=top_p,
                max_tokens=max_tokens,
            )
        except openai.OpenAIError as e:
            raise RuntimeError(f"{self.label} API call failed: {type(e).__name__}: {e}") from e

        content = (resp.choices[0].message.content or "").strip()
        usage = resp.usage
        return LLMResult(
            content=content,
            model=resp.model or self.model,
            tokens_in=getattr(usage, "prompt_tokens", 0) or 0,
            tokens_out=getattr(usage, "completion_tokens", 0) or 0,
        )
