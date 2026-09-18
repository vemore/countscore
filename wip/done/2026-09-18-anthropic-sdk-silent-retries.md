# The comments path retries twice although its docstring says it never retries

**Status:** done (2026-09-18) — closed by fix/anthropic-no-retries. `AsyncAnthropic` now gets
`max_retries=0`; `test_anthropic_client_does_not_retry` pins it and
`test_anthropic_5xx_makes_exactly_one_upstream_call` stubs a 500 at the `httpx2` transport
and sees one call. `.llmwiki/LlmProviders.md` says so under Path 1.

- **Noted:** 2026-09-18 — while removing the OpenAI SDK retries (fix/backend-hardening)
- **Theme:** backend-hardening
- **Area:** backend
- **Blocks release:** no

`backend/app/services/anthropic_client.py` says "We intentionally do NOT retry here:
transient failures bubble up as 502 … Retrying silently on Anthropic 5xx can stack costs
and mask outages", but builds `anthropic.AsyncAnthropic(api_key=…, timeout=…)` without
`max_retries`, so the SDK default of 2 applies (`AsyncAnthropic(api_key='k').max_retries`
is `2`, anthropic SDK in `backend/uv.lock`). A 5xx or 429 from Anthropic is thus retried
twice before `/comments` answers — the behaviour the docstring rules out. The analysis path
has had no retries since fix/backend-hardening (Bedrock `max_attempts 0`,
`AsyncOpenAI(max_retries=0)`).

**Fix:** pass `max_retries=0` to `AsyncAnthropic`, and say so in `.llmwiki/LlmProviders.md`
next to the timeout line.

**Acceptance:**
- `AnthropicClient()._client.max_retries == 0` when a key is set, pinned by a test.
- A 5xx from Anthropic, stubbed at the transport, makes exactly one upstream call.
