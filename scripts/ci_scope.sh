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
        # Documentation and store assets. Checked 2026-09-16: no Dart test and no
        # pytest reads a .md, .llmwiki/, wip/, docs/ or store_listing/ file --
        # test_play_publish.py builds its own store_listing/ fixture under
        # tmp_path. A case glob's `*` crosses `/`, so `*.md` is `**/*.md`:
        # backend/README.md and .claude/skills/*/SKILL.md are documentation, and
        # nothing outside this line is.
        *.md|.llmwiki/*|wip/*|docs/*|store_listing/*|LICENSE) ;;

        # The server: its own suite, the image built from it, and the sync job,
        # which runs that very server against two Flutter devices.
        backend/*) backend=true; image=true; sync=true ;;

        # The Gradle project, the manifest, the launcher icons: only the APK
        # build reads them. `flutter analyze`, `flutter test` and `build web` do not.
        android/*) android=true ;;

        # The web shell -- index.html, manifest.json, sqlite3.wasm,
        # drift_worker.js. Only `flutter build web` consumes it.
        web/*) app=true ;;

        # Dart, its dependencies, its analysis and l10n configuration. `android`
        # is in this list on purpose: that job is the fresh-clone build proof,
        # and an AOT-only failure is exactly what it exists to catch. `app` also
        # covers scripts/hooks_selftest.sh, which reads l10n.yaml and lib/l10n/*.arb.
        lib/*|test/*|integration_test/*|test_driver/*|pubspec.yaml|pubspec.lock|l10n.yaml|analysis_options.yaml)
            app=true; android=true; sync=true ;;

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
