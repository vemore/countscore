"""Wrapper around the Anthropic SDK.

The wrapper handles:
- Optional initialization (returns a stub if ANTHROPIC_API_KEY is missing — useful for tests)
- Cost calculation from token counts (Haiku 4.5 pricing as of 2026-05)
- Prompt caching via ``cache_control`` for the system prompt

We intentionally do NOT retry here: transient failures bubble up as 502 to the client so
they can show a user-facing retry button. Retrying silently on Anthropic 5xx can stack
costs and mask outages.
"""

from __future__ import annotations

from dataclasses import dataclass

import anthropic
from anthropic.types import TextBlock, TextBlockParam

from app.config import get_settings

# Haiku 4.5 pricing — $0.80 / Mtok input, $4.00 / Mtok output (as of 2026-05).
# We store ``cost_cents`` as integer cents in the DB. To avoid losing precision on
# sub-cent costs, we round half-up at the call boundary.
_PRICE_IN_PER_MTOK_USD = 0.80
_PRICE_OUT_PER_MTOK_USD = 4.00
_CENTS_PER_USD = 100


@dataclass(slots=True)
class CommentResult:
    content: str
    model: str
    tokens_in: int
    tokens_out: int
    cost_cents: int


def calculate_cost_cents(tokens_in: int, tokens_out: int) -> int:
    cost_usd = (tokens_in / 1_000_000) * _PRICE_IN_PER_MTOK_USD + (
        tokens_out / 1_000_000
    ) * _PRICE_OUT_PER_MTOK_USD
    cents = cost_usd * _CENTS_PER_USD
    return max(1, round(cents))  # always charge at least 1 cent for any successful call


class AnthropicClient:
    """Async wrapper. Returns None on configuration errors (caller handles 503)."""

    def __init__(self) -> None:
        settings = get_settings()
        self.model = settings.comment_model
        self._client: anthropic.AsyncAnthropic | None = None
        if settings.anthropic_api_key:
            self._client = anthropic.AsyncAnthropic(api_key=settings.anthropic_api_key)

    @property
    def available(self) -> bool:
        return self._client is not None

    async def generate_comment(
        self,
        system_blocks: list[TextBlockParam],
        user_content: str,
        max_tokens: int = 400,
    ) -> CommentResult:
        """Generate a single comment.

        Args:
            system_blocks: list of system blocks with optional cache_control markers
            user_content: the user-message body (XML-formatted game data)
            max_tokens: hard cap; for short comments 400 is plenty
        """
        if self._client is None:
            raise RuntimeError("Anthropic client not configured (ANTHROPIC_API_KEY missing)")

        message = await self._client.messages.create(
            model=self.model,
            max_tokens=max_tokens,
            system=system_blocks,  # list-form enables per-block cache_control
            messages=[{"role": "user", "content": user_content}],
        )

        # Extract text from the first text block. A response can also carry
        # thinking or tool blocks, which have no .text at all.
        content = ""
        for block in message.content:
            if isinstance(block, TextBlock):
                content = block.text
                break

        tokens_in = message.usage.input_tokens + (message.usage.cache_read_input_tokens or 0)
        tokens_out = message.usage.output_tokens

        return CommentResult(
            content=content.strip(),
            model=self.model,
            tokens_in=tokens_in,
            tokens_out=tokens_out,
            cost_cents=calculate_cost_cents(message.usage.input_tokens, tokens_out),
        )


_singleton: AnthropicClient | None = None


def get_anthropic_client() -> AnthropicClient:
    global _singleton
    if _singleton is None:
        _singleton = AnthropicClient()
    return _singleton
