"""Provider-agnostic contract for LLM text generation.

A provider takes a system prompt + a user message and returns generated text. The
prompt content is supplied by the caller and stays identical across providers — only
the wire format (Llama-3 markers vs OpenAI chat messages) differs per implementation.
"""

from __future__ import annotations

from dataclasses import dataclass
from typing import Protocol, runtime_checkable

# Shared generation parameters — kept identical across providers so the comparison
# between Bedrock / Gemini / Mistral is fair. The budget is generous (8192) because
# Gemini 2.5 models spend a large share of it on internal "thinking" tokens before
# the visible answer (4096 still truncated mid-sentence in practice). Bedrock/Mistral
# stop well before this cap, so their output is unchanged.
DEFAULT_MAX_TOKENS = 8192
DEFAULT_TEMPERATURE = 0.4
DEFAULT_TOP_P = 0.9


class LLMRateLimitedError(RuntimeError):
    """The provider refused the call on quota or rate grounds (HTTP 429, throttling).

    Distinct from any other upstream failure because it is not a defect: the call is
    well formed, the account simply has no capacity left right now. The route maps it to
    503 + Retry-After instead of a bare 502. See .llmwiki/Api.md.
    """


@dataclass(slots=True)
class LLMResult:
    content: str
    model: str
    tokens_in: int
    tokens_out: int


@runtime_checkable
class LLMProvider(Protocol):
    """Common interface every provider implements."""

    @property
    def available(self) -> bool:
        """True when credentials are configured and the provider can be called."""
        ...

    @property
    def model(self) -> str:
        """The model identifier this provider will call.

        Exposed so `/health` can report the *resolved* model without spending a
        request: `available` only proves a key is set, never that the account may
        call the model behind it. See .llmwiki/LlmProviders.md.
        """
        ...

    async def generate(
        self,
        system_prompt: str,
        user_message: str,
        *,
        max_tokens: int = DEFAULT_MAX_TOKENS,
        temperature: float = DEFAULT_TEMPERATURE,
        top_p: float = DEFAULT_TOP_P,
    ) -> LLMResult: ...
