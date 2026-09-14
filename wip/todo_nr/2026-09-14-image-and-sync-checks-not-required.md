# The image and two-device sync checks do not block a merge

- **Noted:** 2026-09-14 — while reviewing the two weeks of work since 2026-09-09
- **Theme:** merge-safety
- **Area:** tooling
- **Blocks release:** no

The protection on `main` requires three checks (`Backend — ruff, mypy, pytest`,
`App — codegen, analyze, test, web build`, `Android debug APK — fresh-clone build proof`).
`Backend image — build, non-root, locked` (#31) and `Sync — two devices against a real
backend` (#29) run in CI but are not required, so `gh pr merge` goes through while they are
red or still running — and the merge is followed by a deploy of that very image. The sync test
is the only automated proof that group sharing works end to end.

**Fix:** add both to `required_status_checks.contexts` (`gh api -X PATCH
repos/{owner}/{repo}/branches/main/protection/required_status_checks`). Neither job has a
path filter in `.github/workflows/ci.yml` today; keep it that way, since a filtered required
job leaves a doc-only pull request waiting forever. Update the protection table in `.llmwiki/ParallelDelivery.md`.
