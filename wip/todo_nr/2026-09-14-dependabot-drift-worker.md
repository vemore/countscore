# A dependency bump leaves the committed `web/` binaries behind, and CI stays green

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

## The same hole, for `web/sqlite3.wasm`

(2026-09-16) `sqlite3` is the second package with a committed binary, and it behaves the
same way — worse, it drifts without any pull request at all, because it is *transitive*:
Dependabot never proposes it (`2026-09-16-pubspec-lock-never-refreshed.md`). It had reached
3.5.2 in `pubspec.lock` against a `web/sqlite3.wasm` from an earlier release, and 3.6.0 was
out. Nothing in CI noticed, and nothing would have.

`sqlite3.wasm` does not live in the pub cache: it is a release asset,
`https://github.com/simolus3/sqlite3.dart/releases/download/sqlite3-<version>/sqlite3.wasm`.
So its check cannot be a `cmp` against `$PUB_CACHE` — it has to fetch, or compare a checksum
recorded next to the binary.

**Fix:** one CI step in the `app` job, after `flutter pub get`, covering **both** binaries
and failing with the copy command in its message:

- `web/drift_worker.js` — `cmp` against
  `$PUB_CACHE/hosted/pub.dev/drift-<version from pubspec.lock>/drift_worker.js`
- `web/sqlite3.wasm` — `cmp` against the `sqlite3-<version from pubspec.lock>` release asset,
  or against a `web/sqlite3.wasm.sha256` committed beside it and refreshed with the binary

Optionally list `drift` in its own Dependabot group so its pull request is recognisable.
Note that the check alone is not enough for the web e2e it implies: that suite is still not
in CI (`.llmwiki/Testing.md` §Gaps).
