# deploy_web.sh refuses any markdown in the build, including declared assets

**Status:** done (2026-09-16) — closed by fix/web-md-gate. The scan now skips
`build/web/assets/assets/`, which is what `pubspec.yaml` declares, and still covers
everything a stray note can reach.

- **Noted:** 2026-09-16 — while deploying `feat/game-rules` (#77) under `ship-parallel`
- **Theme:** tooling
- **Area:** tooling
- **Blocks release:** no — it blocked a deploy, not the release

`scripts/deploy_web.sh:92` ran `find build/web -iname '*.md'` and refused to publish on any
hit. The guard exists for a real incident: `web/CLAUDE.md` reached a public URL until
2026-09-13, and everything under `web/` is published verbatim.

But it scanned the whole build, including `build/web/assets/`, where Flutter copies what
`pubspec.yaml` declares. #77 ships the game rules as ten Markdown assets
(`assets/rules/rules_<locale>.md` — see `.llmwiki/I18n.md` for why long-form localised text
is an asset and not an ARB key), so the backend deploy succeeded and the PWA deploy was
refused with all ten files listed as leaks.

The two cases are genuinely different. A note reaches the build because someone left it in
`web/` or at the root; a declared asset is there because `pubspec.yaml` says so and
publishing it is the whole point. Excluding the declared asset tree keeps the guard aimed at
the first and stops it firing on the second.

**Fix:** `find build/web -iname '*.md' -not -path 'build/web/assets/assets/*'`, with the
reason in a comment above it. Narrowed rather than removed — `web/CLAUDE.md` would still be
caught today.
