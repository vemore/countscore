# Nothing ever refreshes the transitive half of `pubspec.lock`

- **Noted:** 2026-09-16 — reviewing what dependency updates were available
- **Theme:** dependencies
- **Area:** tooling
- **Blocks release:** no

Dependabot's `pub` ecosystem proposes updates for the dependencies *written in
`pubspec.yaml`* and nothing else. A package that only appears in `pubspec.lock` is never
bumped, and no job or procedure runs `flutter pub upgrade`.

The result, two days after Dependabot's weekly run had merged #43 clean: `flutter pub
outdated` listed **32 transitive packages** behind their resolvable version — `sqlite3`
3.5.2 → 3.6.0, `sqflite_common` 2.5.11 → 2.5.13, `analyzer` 14.3.0 → 14.4.0,
`record_use` 0.6.0 → 1.1.1, `package_config` 2.2.0 → 3.0.0 and so on. They were cleared by
hand in the same pull request as this entry, which is exactly the problem: it took someone
asking.

It is not only staleness. `sqlite3` is one of the two packages whose binary is committed
under `web/`, so drifting silently past a wasm release is how the PWA and its
`web/sqlite3.wasm` get out of step — see `2026-09-14-dependabot-drift-worker.md`.

Three packages are *not* part of this and must not be chased: `material_color_utilities`,
`cli_util` and `test_api` are pinned by the Flutter SDK, and `pub outdated` reports their
resolvable version as the current one. Only `FLUTTER_VERSION` in `ci.yml` moves them.

**Fix:** a scheduled workflow — monthly, or weekly right after Dependabot's Monday — that
runs `flutter pub upgrade`, `dart run build_runner build`, `flutter analyze`, `flutter test`
and opens a `chore:` pull request when `pubspec.lock` changed. Failing that, a step in the
pruning pass of `release-android` §3b, which at least ties it to a cadence that exists.

Whichever it is, it has to carry the `web/` binary check from
`2026-09-14-dependabot-drift-worker.md`, or it reintroduces the drift it is meant to catch.
