# The screenshot composer's tests run nowhere but on a laptop

**Status:** dropped (2026-09-19) — merged into [[2026-09-18-store-screenshots-show-french-ui-everywhere]] by chore/refine-2026-09-19.

- **Noted:** 2026-09-18 — while writing `scripts/compose_screenshots.py` (`feat/composed-screenshots`)
- **Theme:** test-tooling
- **Area:** tooling
- **Blocks release:** no

`scripts/test_compose_screenshots.py` checks that the composer writes 1080×1920 opaque RGB,
that `--check` catches a missing or raw set, and that every committed
`store_listing/<locale>/screenshots/phone/*.png` is compliant. No CI job collects it: the
`backend` job runs pytest on `.claude/skills/release-android/scripts/` only, with no Pillow.
`.github/workflows/` was out of bounds for that pull request (another one was editing it).

**Fix:** in `.github/workflows/ci.yml`'s `backend` job, next to the `play_publish.py tests`
step, add `uv run --no-project --with pytest --with pillow pytest -v
scripts/test_compose_screenshots.py`. `store_listing/*` is ruled out by `scripts/ci_scope.sh`,
so a caption-only change would not run it — decide whether `store_listing/*/screenshots/*`
should select `backend`. Update `.llmwiki/Testing.md` (the "local only" gap).

**Acceptance:**
- A pull request that commits a 1080×2400 PNG under `store_listing/fr-FR/screenshots/phone/`
  goes red in CI.
