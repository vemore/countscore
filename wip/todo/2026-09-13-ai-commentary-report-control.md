# No in-app report control for AI-generated commentary

- **Noted:** 2026-09-13 — while checking current Play policy for the release skill
- **Theme:** ai-report
- **Area:** app
- **Blocks release:** yes — Play AI-Generated Content policy

Play requires apps that generate content with AI to let users report offensive output from
inside the app. The ZapZap analysis screen shows LLM text with no such control. The
2026-07-15 announcement also puts third-party AI integrations under the User Data policy.

**Fix:** a "Report this commentary" action on the analysis screen opening a `mailto:` to the
listing contact, comment id and text prefilled — no new data flow. (A server-side
`POST /comments/{id}/report` is a new outbound flow: three privacy documents, rule in
`CLAUDE.md`.) Strings through `i18n-add-string`. Then update `.llmwiki/Release.md` (policy table).
