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
guard "ruff format is allowed (rule lifted)"        0 'ruff format .'
guard "ruff format through uv is allowed"           0 'uv run ruff format .'
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
guard "a squash merge"                              0 'gh pr merge 12 --squash --delete-branch'
guard "a squash merge, short flags"                 0 'gh pr merge 12 -sd'
guard "--admin bypasses the protection"             2 'gh pr merge 12 --squash --admin'
guard "a merge with no method prompts"              2 'gh pr merge 12'
guard "a rebase merge"                              2 'gh pr merge 12 --rebase'
guard "the words inside an echo (merge)"            0 'echo "gh pr merge 12 --admin"'
guard "pushing a branch"                            0 'git push -u origin feat/x'
guard "a force-push"                                2 'git push --force origin feat/x'
guard "a force-push, bundled short flag"            2 'git push -fu origin feat/x'
guard "a force-with-lease is still a force-push"    2 'git push --force-with-lease origin feat/x'
guard "a +refspec is a force-push"                  2 'git push origin +feat/x'
guard "pushing main by name"                        2 'git push origin main'
guard "pushing HEAD onto main"                      2 'git push origin HEAD:main'
guard "the words inside an echo (push)"             0 'echo "git push --force origin main"'

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
commit_field "the commit runs where cd left it" /tmp '.commit.cwd'  'cd /tmp && git commit -m x'
commit_field "git -C moves the commit"      "$(dirname "$ROOT")/wt" '.commit.cwd' 'git -C ../wt commit -m x'

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

echo "== ARB values ================================================"
# A key can be present in all ten files and still hold the literal English string.
# Own sandbox: the block above deliberately breaks app_de.arb and app_es.arb.
VALDIR="$SANDBOX/arbval"
mkdir -p "$VALDIR/lib/l10n"
cp "$ROOT/l10n.yaml" "$VALDIR/"
cp "$ROOT"/lib/l10n/*.arb "$VALDIR/lib/l10n/"
CLAUDE_PROJECT_DIR="$VALDIR" python3 "$HOOKS/arb_keys.py" --values >/dev/null 2>&1
report "ten files translated, not merely present" 0 "$?"

# description, expected exit, locale, mode, then `key=value` pairs written verbatim
# into BOTH that locale and app_en.arb -- a key absent from English is never compared,
# so writing it on one side alone would pass for the wrong reason.
arb_value_case() {
    local desc="$1" expected="$2" locale="$3" mode="$4"; shift 4
    cp "$ROOT/lib/l10n/app_$locale.arb" "$VALDIR/lib/l10n/app_$locale.arb"
    cp "$ROOT/lib/l10n/app_en.arb" "$VALDIR/lib/l10n/app_en.arb"
    python3 - "$VALDIR/lib/l10n/app_$locale.arb" "$VALDIR/lib/l10n/app_en.arb" "$@" <<'PY'
import json, sys
paths, pairs = sys.argv[1:3], [a.split("=", 1) for a in sys.argv[3:]]
for path in paths:
    data = json.load(open(path, encoding="utf-8"))
    data.update(dict(pairs))
    json.dump(data, open(path, "w", encoding="utf-8"), ensure_ascii=False)
PY
    CLAUDE_PROJECT_DIR="$VALDIR" python3 "$HOOKS/arb_keys.py" "$mode" >/dev/null 2>&1
    report "$desc" "$expected" "$?"
    cp "$ROOT/lib/l10n/app_$locale.arb" "$VALDIR/lib/l10n/app_$locale.arb"
    cp "$ROOT/lib/l10n/app_en.arb" "$VALDIR/lib/l10n/app_en.arb"
}

arb_value_case "a value left in English"     1 ja --values 'continuePlay=Continue Playing'
arb_value_case "an exempted key (appTitle)"  0 ja --values 'appTitle=CountScore'
arb_value_case "an exemption is per locale"  1 ru --values 'ok=OK'
arb_value_case "the gameTypeName* prefix"    0 ja --values 'gameTypeNameYahtzee=Yahtzee'
arb_value_case "any other new key"           1 ja --values 'someNewLabel=Yahtzee'
arb_value_case "--keys ignores values"       0 ja --keys   'continuePlay=Continue Playing'

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

# A worktree on its own branch, while the checkout the session was launched from
# sits on main: the commit must be judged on the worktree's branch.
git -C "$WORK" switch -q main
TREE="$SANDBOX/tree"
git -C "$WORK" worktree add -q -b feat/in-tree "$TREE" origin/main 2>/dev/null
out=$(payload "git commit -m x" "$TREE" | CLAUDE_PROJECT_DIR="$WORK" "$HOOKS/guard-bash.sh" 2>/dev/null)
report "a commit inside a worktree, launch checkout on main" 0 "$?"
out=$(payload "cd $TREE && git commit -m x" "$WORK" | CLAUDE_PROJECT_DIR="$WORK" "$HOOKS/guard-bash.sh" 2>/dev/null)
report "cd into a worktree, then commit" 0 "$?"
out=$(payload "git -C $TREE commit -m x" "$WORK" | CLAUDE_PROJECT_DIR="$WORK" "$HOOKS/guard-bash.sh" 2>/dev/null)
report "git -C a worktree commit" 0 "$?"
out=$(payload "git commit -m x" "$WORK" | CLAUDE_PROJECT_DIR="$TREE" "$HOOKS/guard-bash.sh" 2>/dev/null)
report "the launch checkout on main is still refused" 2 "$?"
out=$(payload "git push" "$WORK" | CLAUDE_PROJECT_DIR="$WORK" "$HOOKS/guard-bash.sh" 2>/dev/null)
report "a bare push from main" 2 "$?"
out=$(payload "git push" "$TREE" | CLAUDE_PROJECT_DIR="$WORK" "$HOOKS/guard-bash.sh" 2>/dev/null)
report "a bare push from a worktree branch" 0 "$?"

# Work tracking: one file per entry under wip/, never a shared TODO.md/DONE.md again.
mkdir -p "$TREE/wip/done"
echo "# old" > "$TREE/wip/done/ARCHIVE-2026-09.md"
git -C "$TREE" add wip
git -C "$TREE" -c user.email=t@t -c user.name=t commit -qm "archive" >/dev/null 2>&1
echo "- [ ] x" > "$TREE/TODO.md"
git -C "$TREE" add TODO.md
out=$(payload "git commit -m x" "$TREE" | CLAUDE_PROJECT_DIR="$WORK" "$HOOKS/guard-bash.sh" 2>/dev/null)
report "a TODO.md brought back next to wip/" 2 "$?"
git -C "$TREE" rm -q --cached TODO.md && rm "$TREE/TODO.md"
echo "# edited" >> "$TREE/wip/done/ARCHIVE-2026-09.md"
git -C "$TREE" add wip
out=$(payload "git commit -m x" "$TREE" | CLAUDE_PROJECT_DIR="$WORK" "$HOOKS/guard-bash.sh" 2>/dev/null)
report "editing the frozen archive" 2 "$?"
git -C "$TREE" checkout -q HEAD -- wip
echo "# entry" > "$TREE/wip/done/2026-09-14-entry.md"
git -C "$TREE" add wip
out=$(payload "git commit -m x" "$TREE" | CLAUDE_PROJECT_DIR="$WORK" "$HOOKS/guard-bash.sh" 2>/dev/null)
report "a new wip/done entry" 0 "$?"
git -C "$TREE" reset -q HEAD~1 && rm -rf "$TREE/wip"

# Secrets: a Google service-account key is refused by content, whatever its name.
printf '{\n  "type": "service_account",\n  "project_id": "fake",\n  "private_key": "not-a-key"\n}\n' > "$TREE/play.json"
git -C "$TREE" add play.json
out=$(payload "git commit -m x" "$TREE" | CLAUDE_PROJECT_DIR="$WORK" "$HOOKS/guard-bash.sh" 2>/dev/null)
report "a staged service-account key" 2 "$?"
git -C "$TREE" rm -q --cached play.json && rm "$TREE/play.json"
echo '{"type": "config", "name": "service_account"}' > "$TREE/settings.json"
git -C "$TREE" add settings.json
out=$(payload "git commit -m x" "$TREE" | CLAUDE_PROJECT_DIR="$WORK" "$HOOKS/guard-bash.sh" 2>/dev/null)
report "an ordinary JSON file" 0 "$?"
git -C "$TREE" rm -q --cached settings.json && rm "$TREE/settings.json"
echo "storeFile=/x" > "$TREE/key.properties"
git -C "$TREE" add -f key.properties
out=$(payload "git commit -m x" "$TREE" | CLAUDE_PROJECT_DIR="$WORK" "$HOOKS/guard-bash.sh" 2>/dev/null)
report "a staged key.properties" 2 "$?"
git -C "$TREE" rm -q --cached key.properties && rm "$TREE/key.properties"

# Gates: which paths select them, and a missing tool named with its setup command.
tree_commit() {  # description, expected exit, [text the refusal must contain]
    local err rc
    err=$(payload "git commit -m x" "$TREE" | CLAUDE_PROJECT_DIR="$WORK" "$HOOKS/guard-bash.sh" 2>&1 >/dev/null)
    rc=$?
    [ -n "${3:-}" ] && [[ "$err" != *"$3"* ]] && rc="$rc without '$3'"
    report "$1" "$2" "$rc"
}
mkdir -p "$WORK/backend"
echo "x = 1" > "$WORK/backend/app.py"
git -C "$WORK" add backend && git -C "$WORK" commit -qm "backend on main"
git -C "$WORK" push -q origin main 2>/dev/null
git -C "$TREE" fetch -q origin 2>/dev/null
git -C "$TREE" merge -q --no-ff --no-commit origin/main >/dev/null 2>&1
tree_commit "a merge bringing in backend files runs no backend gate" 0
echo "x = 2" > "$TREE/backend/app.py" && git -C "$TREE" add backend
tree_commit "a merge resolution in backend/ without tools" 2 "uv sync --locked --extra dev"
git -C "$TREE" merge --abort
mkdir -p "$TREE/backend/.venv/bin"
printf '#!/bin/sh\nexit 0\n' > "$TREE/backend/.venv/bin/ruff"
cp "$TREE/backend/.venv/bin/ruff" "$TREE/backend/.venv/bin/mypy"
chmod +x "$TREE/backend/.venv/bin/"*
echo "y = 1" > "$TREE/backend/new.py" && git -C "$TREE" add backend/new.py
tree_commit "a backend change with its tools installed" 0
git -C "$TREE" rm -q --cached backend/new.py && rm -rf "$TREE/backend"
mkdir -p "$TREE/lib" && echo "void main() {}" > "$TREE/lib/a.dart" && git -C "$TREE" add lib
tree_commit "an app change in a tree never set up" 2 "commit again"
git -C "$TREE" rm -q --cached lib/a.dart && rm -rf "$TREE/lib"

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

# A stubbed `gh` makes every state testable offline, including in CI. The real one
# only ever answered "open or nothing", which is how a merged pull request came to
# block a turn forever.
STUB="$SANDBOX/stub"
mkdir -p "$STUB"
stub_gh() {  # pr-list line, pr-checks lines
    cat > "$STUB/gh" <<STUBEOF
#!/bin/bash
case "\$1 \$2" in
    "auth status") exit 0 ;;
    "pr list")     printf '%s' '$1'; [ -n '$1' ] && echo ;;
    "pr checks")   printf '%b' '${2:-}' ;;
esac
exit 0
STUBEOF
    chmod +x "$STUB/gh"
}

stopped() {  # description, expected, [stop_hook_active]
    local out got
    out=$(printf '{"hook_event_name":"Stop","stop_hook_active":%s}' "${3:-false}" \
          | PATH="$STUB:$PATH" CLAUDE_PROJECT_DIR="$WORK" "$HOOKS/require-pull-request.sh" 2>/dev/null)
    case "$out" in
        "")          got=silent ;;
        *'"block"'*) got=block ;;
        *)           got="unexpected: $out" ;;
    esac
    report "$1" "$2" "$got"
}

stub_gh ""
stopped "commits with no pull request" block
stopped "already asked, do not loop" silent true

stub_gh "5 MERGED https://example.invalid/5"
stopped "the pull request was merged" silent

stub_gh "5 CLOSED https://example.invalid/5"
stopped "the pull request was closed unmerged" block

stub_gh "5 OPEN https://example.invalid/5" "App\tpass\t2m\thttps://example.invalid/j1\n"
stopped "an open pull request whose checks pass" silent

stub_gh "5 OPEN https://example.invalid/5" "App\tfail\t2m\thttps://example.invalid/j1\n"
stopped "an open pull request with a failing check" block

stub_gh "5 OPEN https://example.invalid/5" "App\tpending\t0\thttps://example.invalid/j1\n"
stopped "checks still running are not a failure" silent

git -C "$WORK" config branch.feat/quiet.noPullRequest true
stub_gh ""
stopped "a branch deliberately not published" silent
git -C "$WORK" config --unset branch.feat/quiet.noPullRequest

# A subagent in a worktree: its payload cwd is the worktree, CLAUDE_PROJECT_DIR is not.
git -C "$TREE" commit -q --allow-empty -m "agent work"
git -C "$WORK" switch -q main
stub_gh ""
out=$(printf '{"hook_event_name":"SubagentStop","stop_hook_active":false,"cwd":"%s"}' "$TREE" \
      | PATH="$STUB:$PATH" CLAUDE_PROJECT_DIR="$WORK" "$HOOKS/require-pull-request.sh" 2>/dev/null)
case "$out" in *'"block"'*) got=block ;; "") got=silent ;; *) got="unexpected: $out" ;; esac
report "a subagent's worktree commits with no pull request" block "$got"

echo "== local cleanup ============================================="
# scripts/cleanup_local.sh deletes branches and worktrees, so every reason to keep one
# is exercised here, with a stubbed gh answering per branch.
CREMOTE="$SANDBOX/cleanup-remote.git"
CWORK="$SANDBOX/cleanup-work"
git init -q --bare "$CREMOTE"
git clone -q "$CREMOTE" "$CWORK" 2>/dev/null
git -C "$CWORK" config user.email t@t
git -C "$CWORK" config user.name t
git -C "$CWORK" commit -q --allow-empty -m base
git -C "$CWORK" branch -M main
# The setup marker is gitignored in the real repository, so a worktree carrying one is
# clean by `git status` -- reproduce that here, or the marker guard is never reached and
# the worktree is kept for the wrong reason.
echo "/.countscore-setup-in-progress" > "$CWORK/.gitignore"
git -C "$CWORK" add .gitignore
git -C "$CWORK" commit -q -m "ignore the setup marker"
git -C "$CWORK" push -q -u origin main 2>/dev/null

cbranch() {  # name -- a branch with one commit of its own
    git -C "$CWORK" switch -qc "$1" origin/main
    git -C "$CWORK" commit -q --allow-empty -m "$1"
    git -C "$CWORK" switch -q main
}
git -C "$CWORK" branch worktree-agent1 origin/main          # Agent tool's placeholder
cbranch feat/merged
cbranch feat/merged-extra
cbranch feat/open
cbranch feat/nopr
git -C "$CWORK" worktree add -q "$SANDBOX/wt-merged" -b feat/wt-merged origin/main 2>/dev/null
git -C "$SANDBOX/wt-merged" commit -q --allow-empty -m wt
git -C "$CWORK" worktree add -q "$SANDBOX/wt-dirty" -b feat/wt-dirty origin/main 2>/dev/null
git -C "$SANDBOX/wt-dirty" commit -q --allow-empty -m wt
touch "$SANDBOX/wt-dirty/unsaved.txt"
# A worktree scripts/worktree_setup.sh is still building: clean, on a merged branch, and
# saved only by its marker -- the first run below has the modification-time guard off.
git -C "$CWORK" worktree add -q "$SANDBOX/wt-setup" -b feat/wt-setup origin/main 2>/dev/null
git -C "$SANDBOX/wt-setup" commit -q --allow-empty -m wt
echo "pid 1 started now branch feat/wt-setup" > "$SANDBOX/wt-setup/.countscore-setup-in-progress"

CSTUB="$SANDBOX/cleanup-stub"
mkdir -p "$CSTUB"
cat > "$CSTUB/gh" <<'STUBEOF'
#!/bin/bash
args="$*"
head=""; [[ "$args" =~ --head\ ([^ ]+) ]] && head="${BASH_REMATCH[1]}"
case "$1 $2" in
    "auth status") exit 0 ;;
    "pr list")
        case "$args" in
            *"--state merged"*)
                case "$head" in
                    feat/merged|feat/merged-extra|feat/wt-merged|feat/wt-dirty) echo "cafe 7" ;;
                    feat/wt-setup|feat/wt-recent) echo "cafe 7" ;;
                esac ;;
            *) [ "$head" = feat/open ] && echo "#8 OPEN" ;;
        esac ;;
    "api "*)
        case "$args" in
            *"...$(git -C "$CLEANUP_WORK" rev-parse feat/merged-extra)"*) echo diverged ;;
            *compare*) echo behind ;;
        esac ;;
esac
exit 0
STUBEOF
chmod +x "$CSTUB/gh"

# These worktrees are seconds old, so the modification-time guard would keep every one of
# them: the assertions below only mean anything with the window closed.
(cd "$CWORK" && PATH="$CSTUB:$PATH" CLEANUP_WORK="$CWORK" CLEANUP_IDLE_MINUTES=0 \
    "$ROOT/scripts/cleanup_local.sh" --apply >/dev/null 2>&1)
has_branch() { git -C "$CWORK" rev-parse --verify -q "refs/heads/$1" >/dev/null && echo kept || echo removed; }
report "cleanup: Agent placeholder branch with no commit"      removed "$(has_branch worktree-agent1)"
report "cleanup: merged pull request, tip included"            removed "$(has_branch feat/merged)"
report "cleanup: merged, but local commits beyond the head"    kept    "$(has_branch feat/merged-extra)"
report "cleanup: open pull request"                            kept    "$(has_branch feat/open)"
report "cleanup: no pull request at all"                       kept    "$(has_branch feat/nopr)"
report "cleanup: clean worktree on a merged branch"            removed "$([ -d "$SANDBOX/wt-merged" ] && echo kept || echo removed)"
report "cleanup: its branch too"                               removed "$(has_branch feat/wt-merged)"
report "cleanup: worktree with unsaved work"                   kept    "$([ -d "$SANDBOX/wt-dirty" ] && echo kept || echo removed)"
report "cleanup: the branch of that worktree"                  kept    "$(has_branch feat/wt-dirty)"
report "cleanup: main"                                         kept    "$(has_branch main)"

# Second run, at the default window: a worktree an agent is still working in, with nothing
# committed and nothing uncommitted either, is only visible through its modification times.
git -C "$CWORK" worktree add -q "$SANDBOX/wt-recent" -b feat/wt-recent origin/main 2>/dev/null
git -C "$SANDBOX/wt-recent" commit -q --allow-empty -m wt
(cd "$CWORK" && PATH="$CSTUB:$PATH" CLEANUP_WORK="$CWORK" \
    "$ROOT/scripts/cleanup_local.sh" --apply >/dev/null 2>&1)
report "cleanup: worktree in setup (marker)"                   kept    "$([ -d "$SANDBOX/wt-setup" ] && echo kept || echo removed)"
report "cleanup: the branch of a worktree in setup"            kept    "$(has_branch feat/wt-setup)"
report "cleanup: recently modified worktree"                   kept    "$([ -d "$SANDBOX/wt-recent" ] && echo kept || echo removed)"

echo "== worktree secrets =========================================="
# scripts/worktree_setup.sh links the main checkout's untracked secrets into a worktree only
# when asked: an implementing agent's worktree must reach neither the deployment target nor
# the keystore passwords. --no-app --no-backend keeps it to the linking step.
SMAIN="$SANDBOX/secrets-main"
git init -q "$SMAIN"
git -C "$SMAIN" config user.email t@t
git -C "$SMAIN" config user.name t
mkdir -p "$SMAIN/backend/scripts" "$SMAIN/android"
touch "$SMAIN/backend/scripts/.keep" "$SMAIN/android/.keep"
printf '/.countscore-setup-in-progress\n/backend/scripts/deploy.env\n/android/key.properties\n' > "$SMAIN/.gitignore"
git -C "$SMAIN" add -A && git -C "$SMAIN" commit -q -m base
echo "NAS_SSH=x" > "$SMAIN/backend/scripts/deploy.env"
echo "storePassword=x" > "$SMAIN/android/key.properties"
secrets_n=0
secrets_case() {  # description, expected "<deploy.env> <key.properties>", [flag...]
    local desc="$1" want="$2" wt
    shift 2
    secrets_n=$((secrets_n + 1))
    wt="$SANDBOX/secrets-wt-$secrets_n"
    git -C "$SMAIN" worktree add -q --detach "$wt" 2>/dev/null
    "$ROOT/scripts/worktree_setup.sh" --no-app --no-backend "$@" "$wt" >/dev/null 2>&1
    report "$desc" "$want" "$([ -L "$wt/backend/scripts/deploy.env" ] && echo linked || echo absent) $([ -L "$wt/android/key.properties" ] && echo linked || echo absent)"
}
secrets_case "setup: no flag links neither secret"         "absent absent"
secrets_case "setup: --deploy links deploy.env only"       "linked absent" --deploy
secrets_case "setup: --release links key.properties only"  "absent linked" --release
secrets_case "setup: both flags link both"                 "linked linked" --deploy --release

echo "== scheduled runs ============================================"
# scripts/check_scheduled_runs.sh asks GitHub whether the two `schedule:`-only workflows
# are still firing. Every answer it has to tell apart is exercised here against a stubbed
# `gh`, so the cases run offline and in CI -- and so that "silent" is proven to mean
# "nothing is wrong", never "the check quietly gave up".
SCHED="$SANDBOX/sched"
SSTUB="$SANDBOX/sched-stub"
mkdir -p "$SCHED/scripts" "$SCHED/.github/workflows" "$SSTUB"
cp "$ROOT/scripts/check_scheduled_runs.sh" "$SCHED/scripts/"
printf 'on:\n  schedule:\n    - cron: "17 6 * * 1"\n' > "$SCHED/.github/workflows/ci.yml"
printf 'on:\n  schedule:\n    - cron: "23 5 4 * *"\n' > "$SCHED/.github/workflows/deps.yml"
git init -q "$SCHED"
git -C "$SCHED" add -A >/dev/null 2>&1
git -C "$SCHED" -c user.email=t@t -c user.name=t commit -qm "workflows" >/dev/null 2>&1
git -C "$SCHED" branch -M main
git -C "$SCHED" remote add origin https://github.com/example/does-not-exist.git
git -C "$SCHED" update-ref refs/remotes/origin/main refs/heads/main

sched_stub() {  # workflows listing (%b), ci run date, deps run date, [auth exit]
    local wf="$1" ci="$2" deps="$3" auth="${4:-0}"
    cat > "$SSTUB/gh" <<STUBEOF
#!/bin/bash
[ "\$1 \$2" = "auth status" ] && exit $auth
case "\$1" in
    api) printf '%b\n' '$wf' ;;
    run) case "\$*" in
             *ci.yml*)   [ -n '$ci' ]   && echo '$ci' ;;
             *deps.yml*) [ -n '$deps' ] && echo '$deps' ;;
         esac ;;
esac
exit 0
STUBEOF
    chmod +x "$SSTUB/gh"
}

sched_check() {  # description, expected exit, [text it must name], [text it must not name]
    local out rc
    out=$(cd "$SCHED" && PATH="$SSTUB:$PATH" ./scripts/check_scheduled_runs.sh 2>/dev/null)
    rc=$?
    if [ -n "${3:-}" ]; then
        case "$out" in *"$3"*) ;; *) rc="$rc without '$3'" ;; esac
    fi
    if [ -n "${4:-}" ]; then
        case "$out" in *"$4"*) rc="$rc, wrongly naming '$4'" ;; esac
    fi
    # A silent exit 0 is the whole point: anything printed on the happy path is a failure.
    [ -z "${3:-}" ] && [ -n "$out" ] && rc="$rc but said: $(printf '%s' "$out" | head -1)"
    report "$1" "$2" "$rc"
}

ACTIVE='.github/workflows/ci.yml\tactive\n.github/workflows/deps.yml\tactive'
OFF='.github/workflows/ci.yml\tdisabled_inactivity\n.github/workflows/deps.yml\tactive'
ago() { date -u -d "$1 days ago" +%Y-%m-%dT%H:%M:%SZ; }

sched_stub "$ACTIVE" "$(ago 2)" "$(ago 20)"
sched_check "both crons fired within their own period"   0
sched_stub "$ACTIVE" "$(ago 40)" "$(ago 20)"
sched_check "a weekly workflow silent for 40 days"       1 "ci.yml" "deps.yml"
# The per-workflow threshold is the point: one 10-day window would cry wolf at the
# monthly workflow every month, and a single 40-day one would miss three weeks of ci.yml.
sched_stub "$ACTIVE" "$(ago 12)" "$(ago 35)"
sched_check "35 days is normal for a monthly workflow"   1 "ci.yml" "deps.yml"
sched_stub "$OFF" "$(ago 2)" "$(ago 20)"
sched_check "GitHub reports the workflow disabled"       1 "gh workflow enable ci.yml"
sched_stub "$ACTIVE" "" ""
sched_check "a cron that landed today has yet to fire"   0
sched_stub "$ACTIVE" "$(ago 2)" "$(ago 20)" 1
sched_check "gh cannot answer: silent, and says so"      3
git -C "$SCHED" remote set-url origin "$SANDBOX/not-a-forge.git"
sched_check "the origin is not GitHub"                   3
git -C "$SCHED" remote set-url origin https://github.com/example/does-not-exist.git

# Wired into SessionStart, at most once a day -- and the day is only banked when GitHub
# actually answered, or a session started on a train would silence the check until tomorrow.
STAMP="$SCHED/.countscore-scheduled-check"
session_start() {  # -> stdout of the hook, run inside $SCHED
    printf '{"hook_event_name":"SessionStart","cwd":"%s"}' "$SCHED" \
        | PATH="$SSTUB:$PATH" CLAUDE_PROJECT_DIR="$SCHED" "$HOOKS/session-start.sh" 2>/dev/null
}
sched_stub "$ACTIVE" "$(ago 40)" "$(ago 20)"
rm -f "$STAMP"
out=$(session_start)
case "$out" in *ci.yml*) got=reported ;; *) got=silent ;; esac
report "the session opener reports a dead cron" reported "$got"
report "and stamps the day"                     stamped  "$([ -s "$STAMP" ] && echo stamped || echo "no stamp")"
out=$(session_start)
case "$out" in *ci.yml*) got=reported ;; *) got=silent ;; esac
report "the next session of the same day is quiet" silent "$got"
rm -f "$STAMP"
sched_stub "$ACTIVE" "$(ago 40)" "$(ago 20)" 1
session_start >/dev/null
report "an unanswered check banks no day" "no stamp" "$([ -s "$STAMP" ] && echo stamped || echo "no stamp")"

echo "== wiring ===================================================="
for script in "$HOOKS"/*.sh "$HOOKS"/*.py; do
    [ -x "$script" ] && pass=$((pass + 1)) || { fail=$((fail + 1)); echo "  FAIL  $script is not executable"; }
done
python3 -m json.tool "$ROOT/.claude/settings.json" >/dev/null 2>&1
report "settings.json is valid JSON" 0 "$?"

echo
echo "$pass passed, $fail failed"
[ "$fail" -eq 0 ]
