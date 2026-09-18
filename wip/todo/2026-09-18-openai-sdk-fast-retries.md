# The OpenAI SDK's own retries only delay a capacity error by three seconds

- **Noted:** 2026-09-18 — while fixing the upstream-503 mapping (fix/llm-upstream-unavailable)
- **Theme:** backend-hardening
- **Area:** backend
- **Blocks release:** no

`OpenAICompatProvider` (`backend/app/services/llm/openai_compat.py`) builds `AsyncOpenAI`
without `max_retries`, so the SDK default of 2 applies. On 2026-09-16 those retries fired at
+0.4 s and +0.9 s against Gemini's 503 "high demand": three attempts inside three seconds
land in the same capacity dip, and the retry budget buys nothing but a later error.
`BedrockProvider` already sets `retries={"max_attempts": 0}`, so the two paths disagree.

It was decided on 2026-09-18 that the Regenerate button is the retry for this route (no
backoff, [[Api]]); the SDK retries were out of that pull request's scope.

**Fix:** pass `max_retries=0` to `AsyncOpenAI`, matching Bedrock, and say so in
[[LlmProviders]] next to "no retries". Check that `backend/scripts/compare_providers.py` does not
rely on the SDK retry.

**Acceptance:**
- `OpenAICompatProvider(...)._client.max_retries == 0`, pinned by a test.
- A 503 from the provider makes exactly one upstream call before the route answers 503.
