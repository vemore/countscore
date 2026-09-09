#!/bin/bash

# CountScore - Claude Code hooks self-test
#
# The guards decide from a parsed command line, and the interesting cases are the
# ones that look like a violation and are not (a heredoc documenting a build, a
# `git commit -m "flutter build apk"`, `rm build/web/sqlite3.wasm`) or the reverse
# (`rm -rf web/`, `git commit -am` with nothing staged). This table is the only
# way to exercise them without running a real multi-minute build.
#
# Usage: scripts/hooks_selftest.sh        (exit 0 = every case behaves)

set -uo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
HOOKS="$ROOT/.claude/hooks"
export CLAUDE_PROJECT_DIR="$ROOT"

pass=0
fail=0

report() {  # description, expected, actual
    if [ "$2" = "$3" ]; then
        pass=$((pass + 1))
    else
        fail=$((fail + 1))
        printf '  FAIL  %s\n        expected %s, got %s\n' "$1" "$2" "$3"
    fi
}

payload() {  # command, [cwd]
    python3 -c 'import json,sys; print(json.dumps({"tool_input":{"command":sys.argv[1]},"cwd":sys.argv[2],"hook_event_name":"PreToolUse","tool_name":"Bash"}))' \
        "$1" "${2:-$ROOT}"
}

guard() {  # description, expected exit, command, [cwd]
    local out
    out=$(payload "$3" "${4:-$ROOT}" | "$HOOKS/guard-bash.sh" 2>/dev/null)
    report "$1" "$2" "$?"
}

commit_field() {  # description, expected, field, command
    local got
    got=$(payload "$4" | CLAUDE_PROJECT_DIR="$ROOT" python3 "$HOOKS/parse_command.py" | jq -r "$3")
    report "$1" "$2" "$got"
}

echo "== refusals =================================================="
guard "flutter build apk without the flag"          2 'flutter build apk --release'
guard "flutter build apk with the flag"             0 'flutter build apk --release --no-tree-shake-icons'
guard "flutter build web with the flag"             0 'flutter build web --release --no-tree-shake-icons --dart-define=BACKEND_URL=https://x'
guard "flutter build --help produces no artifact"   0 'flutter build apk --help'
guard "flutter build alone prints usage"            0 'flutter build'
guard "flutter run is not a release build"          0 'flutter run -d chrome'
guard "the words inside a commit message"           0 'git commit -m "flutter build apk" --dry-run'
guard "the words inside an echo"                    0 'echo "flutter build apk"'
guard "a heredoc body that documents the command"   0 "$(printf 'cat > /tmp/x <<%sEOF%s\nflutter build apk\nrm web/sqlite3.wasm\nEOF\n' "'" "'")"
guard "ruff format rewrites files"                  2 'ruff format .'
guard "ruff format through uv"                      2 'uv run ruff format .'
guard "ruff format --check only measures"           0 'ruff format --check .'
guard "ruff format --diff only measures"            0 'ruff format --diff .'
guard "ruff check is a linter, not a formatter"     0 'ruff check .'
guard "removing a tracked web binary"               2 'rm web/sqlite3.wasm'
guard "moving a tracked web binary"                 2 'mv web/drift_worker.js /tmp/'
guard "git rm --cached untracks it"                 2 'git rm --cached web/sqlite3.wasm'
guard "removing the whole web directory"            2 'rm -rf web/'
guard "removing it from inside web/"                2 'cd web && rm sqlite3.wasm'
guard "the build output copy is disposable"         0 'rm build/web/sqlite3.wasm'
guard "a same-named file outside the project"       0 'rm -rf /tmp/web/sqlite3.wasm'
guard "wiping build/ is routine"                    0 'rm -rf build/'
guard "an unparseable command fails open"           0 'echo "unbalanced'
guard "a pull request aimed at main"                 0 'gh pr create --base main --head x --title t --body b'
guard "a pull request stacked on another branch"    2 'gh pr create --base feat/other --head x --title t'
guard "the same, written --base=x"                  2 'gh pr create --base=feat/other --title t'
guard "no --base means the repository default"      0 'gh pr create --title t --body b'
guard "reading pull requests is not creating one"   0 'gh pr list --state merged'

echo "== commit detection =========================================="
commit_field "plain commit"                    false '.commit.all'   'git commit -m x'
commit_field "commit -am stages tracked files" true  '.commit.all'   'git commit -am wip'
commit_field "--amend rewrites the last one"   true  '.commit.amend' 'git commit --amend --no-edit'
commit_field "git -C still commits"            false '.commit.all'   'git -C backend commit -m x'
commit_field "commit after add in one line"    false '.commit.all'   'git add -A && git commit -m "x"'
commit_field "a trailing pathspec"    'lib/foo.dart' '.commit.pathspecs[0]' 'git commit -m x lib/foo.dart'
commit_field "--dry-run runs no gates"          null '.commit'       'git commit --dry-run'
commit_field "git log is not a commit"          null '.commit'       'git log --grep=commit'
commit_field "git status is not a commit"       null '.commit'       'git status'
commit_field "the word in an echo"              null '.commit'       'echo "git commit"'
commit_field "unparseable assumes a commit"    true  '.commit.all'   'git commit -m "unbalanced'

echo "== .gitignore ================================================"
SANDBOX=$(mktemp -d)
trap 'rm -rf "$SANDBOX"' EXIT
git init -q "$SANDBOX"
mkdir -p "$SANDBOX/web"
touch "$SANDBOX/web/sqlite3.wasm" "$SANDBOX/web/drift_worker.js"
git -C "$SANDBOX" add -A >/dev/null 2>&1
git -C "$SANDBOX" -c user.email=t@t -c user.name=t commit -qm init >/dev/null 2>&1

ignore_case() {  # description, expected exit, .gitignore content
    printf '%s\n' "$3" > "$SANDBOX/.gitignore"
    local out
    out=$(python3 -c 'import json,sys; print(json.dumps({"tool_input":{"file_path":sys.argv[1]},"hook_event_name":"PostToolUse","tool_name":"Write"}))' "$SANDBOX/.gitignore" \
          | CLAUDE_PROJECT_DIR="$SANDBOX" "$HOOKS/guard-gitignore.sh" 2>/dev/null)
    report "$1" "$2" "$?"
}

ignore_case "an unrelated rule"                    0 'build/'
ignore_case "the explanatory comment is not a rule" 0 '# web/sqlite3.wasm is tracked on purpose'
ignore_case "the file named outright"              2 'web/sqlite3.wasm'
ignore_case "a wildcard that never names it"       2 '*.wasm'
ignore_case "the whole directory"                  2 'web/'
ignore_case "a negation is not an ignore"          0 '!web/sqlite3.wasm'

echo "== ARB key sets =============================================="
ARBDIR="$SANDBOX/arb"
mkdir -p "$ARBDIR/lib/l10n"
cp "$ROOT/l10n.yaml" "$ARBDIR/"
cp "$ROOT"/lib/l10n/*.arb "$ARBDIR/lib/l10n/"
CLAUDE_PROJECT_DIR="$ARBDIR" python3 "$HOOKS/arb_keys.py" >/dev/null 2>&1
report "ten files in sync" 0 "$?"

python3 - "$ARBDIR/lib/l10n/app_de.arb" <<'PY'
import json, sys
path = sys.argv[1]
data = json.load(open(path, encoding="utf-8"))
del data[[k for k in data if not k.startswith("@")][0]]
json.dump(data, open(path, "w", encoding="utf-8"), ensure_ascii=False)
PY
CLAUDE_PROJECT_DIR="$ARBDIR" python3 "$HOOKS/arb_keys.py" >/dev/null 2>&1
report "one language missing a key" 1 "$?"

out=$(python3 -c 'import json,sys; print(json.dumps({"tool_input":{"file_path":sys.argv[1]},"hook_event_name":"PostToolUse","tool_name":"Edit"}))' "$ARBDIR/lib/l10n/app_de.arb" \
      | CLAUDE_PROJECT_DIR="$ARBDIR" "$HOOKS/check-arb-sync.sh" 2>/dev/null)
report "divergence reports without blocking" 0 "$?"
case "$out" in *additionalContext*) report "divergence reaches the model" ok ok ;;
                              *)    report "divergence reaches the model" ok "no additionalContext" ;; esac

echo '{invalid' > "$ARBDIR/lib/l10n/app_es.arb"
python3 -c 'import json,sys; print(json.dumps({"tool_input":{"file_path":sys.argv[1]},"hook_event_name":"PostToolUse","tool_name":"Edit"}))' "$ARBDIR/lib/l10n/app_es.arb" \
    | CLAUDE_PROJECT_DIR="$ARBDIR" "$HOOKS/check-arb-sync.sh" >/dev/null 2>&1
report "invalid JSON in the edited file" 2 "$?"

echo "== branch discipline ========================================="
REMOTE="$SANDBOX/remote.git"
WORK="$SANDBOX/work"
git init -q --bare "$REMOTE"
git clone -q "$REMOTE" "$WORK" 2>/dev/null
git -C "$WORK" config user.email t@t
git -C "$WORK" config user.name t
git -C "$WORK" commit -q --allow-empty -m "base"
git -C "$WORK" branch -M main
git -C "$WORK" push -q -u origin main 2>/dev/null

branch_case() {  # description, expected exit
    local out
    out=$(payload "git commit -m x" "$WORK" | CLAUDE_PROJECT_DIR="$WORK" "$HOOKS/guard-bash.sh" 2>/dev/null)
    report "$1" "$2" "$?"
}

branch_case "committing on main" 2

git -C "$WORK" switch -qc feat/live origin/main
branch_case "a fresh branch off origin/main" 0

git -C "$WORK" commit -q --allow-empty -m "work"
git -C "$WORK" push -q -u origin feat/live 2>/dev/null
git -C "$REMOTE" branch -D feat/live >/dev/null 2>&1
git -C "$WORK" fetch -q --prune origin 2>/dev/null
branch_case "a branch whose remote was merged and deleted" 2

# A commit that also reached origin/main under a different hash -- what a merged
# branch looks like once the remote has moved on.
git -C "$WORK" switch -qc feat/picked origin/main
echo dup > "$WORK/dup.txt"
git -C "$WORK" add dup.txt
git -C "$WORK" commit -qm "add dup"
git -C "$WORK" switch -q main
git -C "$WORK" cherry-pick feat/picked >/dev/null 2>&1
# Same patch, different hash -- as a rebase-merge leaves it upstream.
git -C "$WORK" commit -q --amend -m "add dup (upstream)"
git -C "$WORK" push -q origin main 2>/dev/null
git -C "$WORK" switch -q feat/picked
branch_case "a branch replaying a commit already upstream" 2

git -C "$WORK" checkout -q --detach origin/main
branch_case "a detached HEAD" 2

echo "== pull request ==============================================="
stop_case() {  # description, expected (silent|block), [stop_hook_active]
    local out got
    out=$(printf '{"hook_event_name":"Stop","stop_hook_active":%s}' "${3:-false}" \
          | CLAUDE_PROJECT_DIR="$WORK" "$HOOKS/require-pull-request.sh" 2>/dev/null)
    case "$out" in
        "")       got=silent ;;
        *'"block"'*) got=block ;;
        *)        got="unexpected: $out" ;;
    esac
    report "$1" "$2" "$got"
}

git -C "$WORK" switch -q main
stop_case "nothing to publish from main" silent

# Stacking stays possible, per repository and on purpose.
out=$(payload "gh pr create --base feat/other --title t" "$WORK" \
      | CLAUDE_PROJECT_DIR="$WORK" "$HOOKS/guard-bash.sh" 2>/dev/null)
report "stacking is refused by default" 2 "$?"
git -C "$WORK" config countscore.allowStackedPr true
out=$(payload "gh pr create --base feat/other --title t" "$WORK" \
      | CLAUDE_PROJECT_DIR="$WORK" "$HOOKS/guard-bash.sh" 2>/dev/null)
report "stacking unlocked for this repository" 0 "$?"
git -C "$WORK" config --unset countscore.allowStackedPr

git -C "$WORK" switch -qc feat/quiet origin/main
stop_case "a branch with no commits of its own" silent

git -C "$WORK" commit -q --allow-empty -m "work in progress"
stop_case "a local-only remote is not a forge" silent

git -C "$WORK" remote set-url origin https://github.com/example/does-not-exist.git
if gh auth status >/dev/null 2>&1; then
    stop_case "commits with no pull request" block
    stop_case "already asked, do not loop" silent true
    git -C "$WORK" config branch.feat/quiet.noPullRequest true
    stop_case "a branch deliberately not published" silent
else
    echo "  skip  the three GitHub cases (gh is not authenticated here)"
fi

echo "== wiring ===================================================="
for script in "$HOOKS"/*.sh "$HOOKS"/*.py; do
    [ -x "$script" ] && pass=$((pass + 1)) || { fail=$((fail + 1)); echo "  FAIL  $script is not executable"; }
done
python3 -m json.tool "$ROOT/.claude/settings.json" >/dev/null 2>&1
report "settings.json is valid JSON" 0 "$?"

echo
echo "$pass passed, $fail failed"
[ "$fail" -eq 0 ]
