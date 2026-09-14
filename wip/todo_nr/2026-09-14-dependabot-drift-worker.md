# A Dependabot drift bump leaves `web/drift_worker.js` behind, and CI stays green

- **Noted:** 2026-09-14 — merging Dependabot #43 (drift 2.34.4 → 2.35.0)
- **Theme:** dependencies
- **Area:** tooling
- **Blocks release:** no

`.github/dependabot.yml` groups `drift` with the other pub minor/patch updates. Dependabot
edits `pubspec.yaml` and `pubspec.lock` only, but `.claude/rules/web.md` requires
`web/drift_worker.js` to be copied from the same drift version, then the web e2e run. #43
arrived with all five checks green and the 2.34.4 worker still tracked: nothing in CI
compares the two, and the e2e suite is not in CI. It was completed by hand on the
Dependabot branch (worker copied from `~/.pub-cache/hosted/pub.dev/drift-2.35.0/`, web e2e
run locally with a Chrome for Testing 153 driver fetched by hand — see
`2026-09-13-chromedriver-script.md`).

**Fix:** a CI step in the `app` job, after `flutter pub get`:
`cmp web/drift_worker.js "$PUB_CACHE/hosted/pub.dev/drift-$(drift version from pubspec.lock)/drift_worker.js"`,
failing with the copy command in its message. Optionally list `drift` in its own Dependabot
group so its pull request is recognisable.
