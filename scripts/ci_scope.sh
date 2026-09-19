#!/bin/bash

# CountScore - which CI jobs a change needs.
#
# Reads changed paths on stdin, one per line, and writes the five job flags on
# stdout as `name=true|false`, in the order .github/workflows/ci.yml declares
# them. No gh, no network, no repository access: the classification is a pure
# function of the path list. That is what lets scripts/ci_scope_selftest.sh pin
# it, and what lets you replay a merged pull request through it by hand.
#
# First match wins, per path, and the last rule is "everything": an unknown path
# -- a new top-level directory, a new root config, anything the table has not
# been taught -- runs the whole pipeline. Being wrong must cost a slow run,
# never an untested merge.
#
# Usage: gh api repos/o/r/pulls/7/files --paginate \
#          -q '.[] | .filename, (.previous_filename // empty)' | scripts/ci_scope.sh
#        git diff --name-only origin/main...HEAD | scripts/ci_scope.sh

set -uo pipefail

backend=false
image=false
app=false
android=false
sync=false

everything() { backend=true; image=true; app=true; android=true; sync=true; }

while IFS= read -r path; do
    [ -n "$path" ] || continue
    case "$path" in
        # The privacy policy and the page Play links to, rendered from it: the
        # `backend` job checks the page is not stale and that **Last Updated** moved
        # (scripts/build_privacy_page.py --check). Before the documentation rule,
        # which would otherwise swallow both.
        privacy_policy.md|docs/privacy-policy.html) backend=true ;;

        # Generated from pubspec.yaml and the pub cache by
        # scripts/third_party_licenses.py; the `app` job, which has the pub cache,
        # fails when it differs. Before the documentation rule, like the policy.
        THIRD_PARTY_LICENSES.md) app=true ;;

        # The store screenshots, their raw captures and captions, and the composer:
        # the `backend` job runs scripts/test_compose_screenshots.py and
        # `compose_screenshots.py --check`, which refuse a committed screenshot Play
        # would refuse or the composer did not write. Before the documentation rule,
        # which would otherwise swallow the store_listing/ ones. A glob's `*` crosses
        # `/`, so the first pattern also takes assets/screenshots/phone/.
        store_listing/*/screenshots/*|store_listing/*/raw/*|store_listing/*/screenshot_captions.txt|scripts/compose_screenshots.py|scripts/test_compose_screenshots.py)
            backend=true ;;

        # Documentation and store assets. Checked 2026-09-16: no Dart test and no
        # pytest reads a .md, .llmwiki/, wip/, docs/ or store_listing/ file --
        # test_play_publish.py builds its own store_listing/ fixture under
        # tmp_path. A case glob's `*` crosses `/`, so `*.md` is `**/*.md`:
        # backend/README.md and .claude/skills/*/SKILL.md are documentation, and
        # nothing outside this line is.
        *.md|.llmwiki/*|wip/*|docs/*|store_listing/*|LICENSE) ;;

        # The server: its own suite, the image built from it, and the sync job,
        # which runs that very server against two Flutter devices. `image` also
        # builds the db-backup sidecar (backend/Dockerfile.backup, backend/backup/)
        # and resolves both compose files, all of which sit under this rule.
        backend/*) backend=true; image=true; sync=true ;;

        # The Gradle project, the manifest, the launcher icons: only the APK
        # build reads them. `flutter analyze`, `flutter test` and `build web` do not.
        android/*) android=true ;;

        # The web shell -- index.html, manifest.json, sqlite3.wasm,
        # drift_worker.js. Only `flutter build web` consumes it.
        web/*) app=true ;;

        # The dependencies. A package can bring a Gradle plugin, Kotlin or a build
        # hook with it, which only the APK build exercises, so `android` runs.
        # `app` also runs the osv-scanner audit of pubspec.lock, so a lock-only
        # change (a Dependabot week, deps.yml's refresh) is audited before it merges.
        pubspec.yaml|pubspec.lock) app=true; android=true; sync=true ;;

        # Dart, its analysis and l10n configuration. Not `android` (2026-09-19): its
        # 416 runs to date had no red APK build on a change `app` passed that was
        # not a network flake, and pushes to main and the weekly run still build
        # the APK -- the workflow forces every flag there. `app` also covers
        # scripts/hooks_selftest.sh, which reads l10n.yaml and lib/l10n/*.arb.
        lib/*|test/*|integration_test/*|test_driver/*|l10n.yaml|analysis_options.yaml)
            app=true; sync=true ;;

        # Everything else: .github/, .claude/ outside its .md files (the hooks the
        # `app` job self-tests, the release tooling the `backend` job tests),
        # scripts/, ios/, a root config, a path nobody has classified yet.
        *) everything ;;
    esac
done

# No early exit once every flag is true: the input is small, and reading stdin to
# the end keeps the producer from taking a SIGPIPE.
printf 'backend=%s\nimage=%s\napp=%s\nandroid=%s\nsync=%s\n' \
    "$backend" "$image" "$app" "$android" "$sync"
