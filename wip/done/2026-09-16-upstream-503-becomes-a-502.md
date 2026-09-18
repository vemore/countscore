# An upstream 503 reaches the user as "HTTP 502" instead of "try again later"

**Status:** done (2026-09-18) — closed by fix/llm-upstream-unavailable. `openai.InternalServerError` and the Bedrock `ServiceUnavailableException` / `ModelNotReadyException` codes now raise `LLMRateLimitedError`, so the route answers 503 + `Retry-After: 60`; any other `OpenAIError` stays a 502. Four route tests drive the real providers with the network call stubbed. No backoff: the Regenerate button is the retry. The SDK's own 2 fast retries are left as they are — `wip/todo_nr/2026-09-18-openai-sdk-fast-retries.md`.

- **Noted:** 2026-09-16 — the user's second analysis of the evening failed on production
- **Theme:** backend-hardening
- **Area:** backend
- **Blocks release:** no

Production logs, 2026-09-16 20:01–20:03 UTC: one analysis succeeded, the next one 94 seconds
later got three `503 Service Unavailable` from Google in three seconds —

> `503 UNAVAILABLE — This model is currently experiencing high demand. Spikes in demand are
> usually temporary. Please try again later.`

the shared free-tier capacity of `gemini-2.5-flash`. Transient: two calls a few minutes later
returned 200. Same prompt, same payload shape as the call that had just worked.

The user saw **"Échec de la génération de l'analyse (HTTP 502)"** (`analysisErrorStatus`).
They should have seen `analysisErrorUnavailable` — "momentanément indisponible, réessayez plus
tard" — which is the wording [[Api]] settled on for exactly this class of failure on
2026-09-13, after the Mistral quota outage.

**Cause:** `app/services/llm/openai_compat.py:60` maps only `openai.RateLimitError` (429) to
`LLMRateLimitedError`. Google's 503 arrives as `openai.InternalServerError`, falls through to
the generic `except openai.OpenAIError`, becomes a bare `RuntimeError`, and the route answers
**502** — the code that means "something upstream is broken". The 2026-09-13 decision covered
the 429 and stopped there; a 503 "try again later" is the same family, and says so in its own
message.

`bedrock.py` has the mirror gap: `_THROTTLING_CODES` covers `ThrottlingException` and
`ServiceQuotaExceededException`, not `ServiceUnavailableException` or `ModelNotReadyException`.

Second, smaller defect in the same event: the OpenAI SDK's own retries fired at **+0.4 s and
+0.9 s**. Three attempts inside three seconds all land in the same capacity dip, so the retry
budget buys nothing and only delays the error by three seconds.

**Fix:** map `openai.InternalServerError` — and the two Bedrock unavailability codes — to
`LLMRateLimitedError` as well, so the route answers 503 + `Retry-After` and the app words it
as temporary. A test per case, next to the existing `test_analysis_upstream_rate_limit_*`.
Then decide separately whether this path deserves a real backoff (a few seconds, once) or
whether the Regenerate button is retry enough — the analysis is user-initiated, so leaving the
retry to the user is defensible and costs no held connection.

**Acceptance:**
- An `openai.InternalServerError` (503) from the provider makes the analysis route answer 503 with `Retry-After`.
- Bedrock `ServiceUnavailableException` and `ModelNotReadyException` do the same.
- Any other `OpenAIError` still answers 502.
- One test per case, next to `test_analysis_upstream_rate_limit_returns_503_with_retry_after` (`backend/tests/test_game_analysis.py`). No backoff: retrying stays the Regenerate button's job.
