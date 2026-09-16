# The `android` CI job runs on every Dart change, and it is the slowest job by far

- **Noted:** 2026-09-16 — adding the `scope` job to `.github/workflows/ci.yml`
- **Theme:** ci-scope
- **Area:** tooling
- **Blocks release:** no

`scripts/ci_scope.sh` puts `android` in the Dart rule, so `lib/`, `test/`, `pubspec.*`,
`l10n.yaml` and `analysis_options.yaml` all trigger it. At 4 min 17 it is the critical path
of the whole workflow (`backend` 2 min 36, `app` 3 min 30, `sync` 2 min 16, `image` 21 s), so
a `lib/`-only pull request — the commonest kind for code — still waits ~4 min 45 after the
change, marginally *worse* than the 4 min 30 it waited before, because `scope` is a
serialised hop in front of it.

The job's stated purpose (`.llmwiki/Testing.md`, 2026-09-09) is a **fresh-clone build proof**:
that the Flutter tool injects the gitignored `gradlew` and `gradle-wrapper.jar`, that the
pinned SDK packages resolve, and that the release manifest declares `INTERNET`. None of that
depends on `lib/`. What *does* is the AOT compile — a failure that `flutter analyze` and
`flutter test` did not already catch — and that is close to unheard of for pure Dart.

**Fix:** decide, with evidence, whether `android` belongs in the Dart rule. Check the job's
history first (`gh run list --workflow=ci.yml --json ...`, or the Actions tab) for a run where
`android` went red while `app` stayed green on a Dart-only change; if there is none, narrow
the rule to `android/*`, `pubspec.*` and the `.github/`/`scripts/` catch-all, and keep the
fresh-clone proof honest by leaving it on every push to `main` and on the weekly run — which
already force every flag true. Do not do this without also saying so in
`.llmwiki/Testing.md`: the 2026-09-09 decision exists because of a "nobody built it" bug.
