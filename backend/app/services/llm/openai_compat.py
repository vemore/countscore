"""Generic provider for any OpenAI-compatible Chat Completions endpoint.

Used for both Gemini (https://generativelanguage.googleapis.com/v1beta/openai/) and
Mistral (https://api.mistral.ai/v1): only base_url, api_key and model differ. We send
only the common params (temperature, top_p, max_tokens) — Mistral rejects unknown
fields and `max_completion_tokens` with HTTP 422.
"""

from __future__ import annotations

import openai
from openai import AsyncOpenAI

from .base import (
    DEFAULT_MAX_TOKENS,
    DEFAULT_TEMPERATURE,
    DEFAULT_TOP_P,
    LLM_TIMEOUT_SECONDS,
    LLMRateLimitedError,
    LLMResult,
)


class OpenAICompatProvider:
    def __init__(self, *, label: str, base_url: str, api_key: str | None, model: str) -> None:
        self.label = label
        self.model = model
        # max_retries=0, like Bedrock's max_attempts 0: the SDK's two retries fire within
        # a second and land in the same capacity dip. The Regenerate button is the retry.
        self._client = (
            AsyncOpenAI(
                api_key=api_key,
                base_url=base_url,
                timeout=LLM_TIMEOUT_SECONDS,
                max_retries=0,
            )
            if api_key
            else None
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
        except openai.RateLimitError as e:
            raise LLMRateLimitedError(f"{self.label} API rate-limited: {e}") from e
        except openai.InternalServerError as e:
            # A 5xx from the provider — Gemini's free tier answers 503 UNAVAILABLE "high
            # demand, try again later". Same family as a 429: no capacity right now, the
            # call itself is fine. See .llmwiki/Api.md.
            raise LLMRateLimitedError(f"{self.label} API unavailable: {e}") from e
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
