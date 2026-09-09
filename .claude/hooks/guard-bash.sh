#!/bin/bash

# CountScore - Bash command guard (Claude Code PreToolUse hook)
#
# Refuses, before it runs, a command that breaks a rule no review can be relied
# on to catch, and runs the quality gates before a commit.
#
# The rules and the reasoning behind each are in .llmwiki/Hooks.md.
#
# Exit 2 is the ONLY code that blocks a PreToolUse hook: exit 1 is treated as a
# non-blocking error and the command runs anyway. Hence `set -u` without `-e` --
# a grep that matches nothing must not kill the script and silently open the gate.

set -uo pipefail

ROOT="${CLAUDE_PROJECT_DIR:-$(git rev-parse --show-toplevel 2>/dev/null || pwd)}"
HOOKS="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

payload=$(cat)
verdict=$(printf '%s' "$payload" | CLAUDE_PROJECT_DIR="$ROOT" python3 "$HOOKS/parse_command.py" 2>/dev/null)
[ -z "$verdict" ] && exit 0   # parser unavailable: fail open, never block on our own bug

# --------------------------------------------------------------- outright refusals

blocked=$(printf '%s' "$verdict" | jq -r '.blocks[]?.message' 2>/dev/null)
if [ -n "$blocked" ]; then
    printf '%s\n' "$blocked" >&2
    exit 2
fi

printf '%s' "$verdict" | jq -e '.commit != null' >/dev/null 2>&1 || exit 0

# ------------------------------------------------------------------ commit gates

cd "$ROOT" 2>/dev/null || exit 0
git rev-parse --git-dir >/dev/null 2>&1 || exit 0

commit_all=$(printf '%s' "$verdict" | jq -r '.commit.all')
commit_amend=$(printf '%s' "$verdict" | jq -r '.commit.amend')

# Which files will this commit contain? `git commit -a` stages tracked changes
# AFTER this hook inspects the index, so --cached alone reports nothing and the
# filter below would wrongly conclude "documentation only, no gates needed".
paths=$(git diff --cached --name-only 2>/dev/null)
[ "$commit_all" = "true" ] && paths="$paths"$'\n'"$(git diff --name-only 2>/dev/null)"
if [ "$commit_amend" = "true" ] && git rev-parse --verify -q HEAD >/dev/null; then
    paths="$paths"$'\n'"$(git show --name-only --pretty=format: HEAD 2>/dev/null)"
fi
paths="$paths"$'\n'"$(printf '%s' "$verdict" | jq -r '.commit.pathspecs[]?')"
paths=$(printf '%s\n' "$paths" | grep -v '^$' | sort -u)

refuse() {
    printf '%s\n' "$1" >&2
    exit 2
}

# 1. Secrets ---------------------------------------------------------------
secrets=$(printf '%s\n' "$paths" | grep -E '(^|/)key\.properties$|\.jks$|\.keystore$|(^|/)\.env$|(^|/)\.env\.' \
          | grep -vE '\.template$|(^|/)\.env\.example$')
if [ -n "$secrets" ]; then
    refuse "Refused: this commit would add a secret to the repository.

$secrets

The keystore, key.properties and every .env file stay out of git: losing control of
the upload keystore means losing the ability to update the app on the Play Store.
They are already in .gitignore, so reaching this point took a \`git add -f\`.
Unstage them with \`git reset <path>\` and commit again. Templates
(key.properties.template, .env.example) are the committed versions."
fi

# 2. Branch ----------------------------------------------------------------
if git rev-parse --verify -q origin/main >/dev/null && git rev-parse --verify -q HEAD >/dev/null; then
    branch=$(git rev-parse --abbrev-ref HEAD)
    recipe="git fetch --prune origin && git switch -c <type>/<short-topic> origin/main
then move the work over: \`git cherry -v origin/main <old-branch>\` marks with '+' the
commits that are genuinely new, and those are the ones to cherry-pick."

    [ "$branch" = "HEAD" ] && refuse "Refused: committing on a detached HEAD.

$recipe"
    [ "$branch" = "main" ] && refuse "Refused: committing directly on main.

Work goes on a branch off origin/main, and reaches main through a pull request.

$recipe"

    track=$(git for-each-ref --format='%(upstream:track)' "refs/heads/$branch" 2>/dev/null)
    if [ "$track" = "[gone]" ]; then
        refuse "Refused: branch '$branch' tracked a remote branch that no longer exists.

Its pull request was merged and the remote deleted it. Committing here stacks new work
on top of commits that are already upstream under different hashes, and the branch has
to be untangled before anything can be pushed.

$recipe"
    fi

    ahead=$(git rev-list --count origin/main..HEAD 2>/dev/null || echo 0)
    if [ "${ahead:-0}" -gt 0 ] && [ "${ahead:-0}" -le 50 ]; then
        if git cherry origin/main HEAD 2>/dev/null | grep -q '^-'; then
            refuse "Refused: branch '$branch' replays commits that are already on origin/main.

$(git cherry -v origin/main HEAD | grep '^-' | head -5)

Either the branch was merged upstream and is stale, or a commit was cherry-picked from
main. If it is the latter and you meant it, the check cannot tell them apart -- say so
to the user and let them decide.

$recipe"
        fi
    fi
    # Note: this hook never fetches. What it knows is only as fresh as your last
    # \`git fetch --prune\`, so it errs towards letting a stale branch through.
fi

# 3. Localization ----------------------------------------------------------
if printf '%s\n' "$paths" | grep -qE '^lib/l10n/.*\.arb$'; then
    if ! arb_report=$(CLAUDE_PROJECT_DIR="$ROOT" python3 "$HOOKS/arb_keys.py" 2>&1); then
        refuse "Refused: the ARB files are not in sync.

$arb_report

Ten languages must hold the same keys -- a key missing from one is a silent English
fallback for those users. The \`i18n-add-string\` skill has the procedure."
    fi
    if command -v flutter >/dev/null 2>&1; then
        flutter gen-l10n >/dev/null 2>&1
        stale=$(git diff --name-only -- 'lib/l10n/*.dart' 2>/dev/null)
        if [ -n "$stale" ]; then
            refuse "Refused: lib/l10n/app_localizations*.dart is out of date with the ARB files.

$stale

Unlike *.g.dart these generated files are committed, so a stale one ships. They have
just been regenerated for you -- stage them into this commit and try again."
        fi
    fi
fi

# 4. The two web binaries --------------------------------------------------
if git check-ignore -q --no-index web/sqlite3.wasm 2>/dev/null || git check-ignore -q --no-index web/drift_worker.js 2>/dev/null; then
    refuse "Refused: a .gitignore rule now matches web/sqlite3.wasm or web/drift_worker.js.

Both are tracked on purpose so a fresh clone can run the PWA without fetching binaries.
Find the rule with \`git check-ignore -v --no-index web/sqlite3.wasm web/drift_worker.js\`
and remove it. See .llmwiki/Web.md."
fi

# 5. Quality gates ---------------------------------------------------------
run_gate() {  # name, then the command
    local name="$1"; shift
    local output
    if ! output=$("$@" 2>&1); then
        refuse "Refused: \`$name\` fails, so this commit is not ready.

$(printf '%s\n' "$output" | tail -40)

Fix it, then commit again. Reproduce with: $name"
    fi
}

if printf '%s\n' "$paths" | grep -qE '^(lib|test|integration_test)/|^pubspec\.(yaml|lock)$|^analysis_options\.yaml$|^l10n\.yaml$|\.arb$'; then
    if command -v flutter >/dev/null 2>&1; then
        run_gate "flutter analyze" flutter analyze
        run_gate "flutter test" flutter test
    else
        echo "note: flutter is not on PATH, the app gates were skipped" >&2
    fi
fi

if printf '%s\n' "$paths" | grep -qE '^backend/'; then
    if [ -x "$ROOT/backend/.venv/bin/ruff" ]; then
        bin="$ROOT/backend/.venv/bin"
        run_gate "ruff check ." bash -c "cd '$ROOT/backend' && '$bin/ruff' check ."
        run_gate "mypy" bash -c "cd '$ROOT/backend' && '$bin/mypy'"
        run_gate "pytest -m 'not integration'" bash -c "cd '$ROOT/backend' && '$bin/pytest' -m 'not integration' -q"
    elif command -v uv >/dev/null 2>&1; then
        run_gate "ruff check ." bash -c "cd '$ROOT/backend' && uv run ruff check ."
        run_gate "mypy" bash -c "cd '$ROOT/backend' && uv run mypy"
        run_gate "pytest -m 'not integration'" bash -c "cd '$ROOT/backend' && uv run pytest -m 'not integration' -q"
    else
        echo "note: neither backend/.venv nor uv is available, the backend gates were skipped" >&2
    fi
fi

exit 0
