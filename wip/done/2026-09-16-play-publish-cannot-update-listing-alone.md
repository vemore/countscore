# The store listing cannot be published without rebuilding an App Bundle

**Status:** done (2026-09-16) — closed by chore/play-publish-listing. `play_publish.py` has a
`listing [--graphics] [--commit]` subcommand that touches neither `pubspec.yaml`,
`verify_aab.sh`, `bundles().upload()` nor `tracks().update()`, and says in its output that a
listing has no `userFraction`. Documented in `release-android` SKILL.md §8a; tests cover the
validate-only path, the commit path and the absence of any bundle or track call.

- **Noted:** 2026-09-16 — preparing the ASO pass on the Play Store listing
- **Theme:** release-automation
- **Area:** tooling
- **Blocks release:** no

`cmd_publish()` in `.claude/skills/release-android/scripts/play_publish.py` always calls
`read_version()`, then `edits.bundles().upload(...)` and `edits.tracks().update(...)`;
`main()` runs `verify_aab(root, aab)` before it even builds the client. `--listing` and
`--graphics` are options grafted onto a bundle publication, never a mode of their own.

So rewriting the title or the descriptions means bumping `version:` in `pubspec.yaml` and
rebuilding a signed AAB — while `PUBLISHING.md` §2 and
`.claude/skills/release-android/references/play-console-handoff.md` (rule 2, "never edit the
store listing or its graphics: those go through the API") forbid doing it by hand in the
Console. ASO work has nowhere to go.

**Fix:** a `listing [--graphics] [--commit]` subcommand next to `status` and `publish`:
open an edit, `edits.listings().update()` per locale, optionally `images().deleteall()` plus
re-upload, `edits.validate()`, and `commit()` only with `--commit` — no `read_version()`, no
`verify_aab()`, no bundle, no track. Its output must say that a listing has no
`userFraction`, so `--commit` is live for everyone at once with no staged rollout.
