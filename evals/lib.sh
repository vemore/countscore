# Shared helpers for the eval check scripts. Sourced, never run.
#
# A check script is called as  check.sh <worktree> [<base>]  and judges what changed in
# <worktree> since <base>: the commits in <base>..HEAD, plus anything left uncommitted or
# untracked. It prints one line per assertion and exits 0 when every assertion holds, 1
# otherwise. It never writes to the worktree and never touches the network, so it can be
# rerun as often as needed against the same tree.
#
# <base> defaults to the newest commit whose subject starts with "eval fixture:" (what
# evals/run.sh and evals/selftest.sh commit before the agent starts), else to the merge
# base with origin/main.

set -uo pipefail

ev_init() {
    WT="${1:?usage: check.sh <worktree> [<base>]}"
    WT="$(cd "$WT" && pwd)" || exit 2
    if [ -n "${2:-}" ]; then
        BASE="$2"
    else
        BASE="$(git -C "$WT" log --format=%H --grep='^eval fixture:' -n 1 HEAD)"
        [ -n "$BASE" ] || BASE="$(git -C "$WT" merge-base origin/main HEAD)"
    fi
    BASE="$(git -C "$WT" rev-parse --verify --quiet "$BASE^{commit}")" \
        || { echo "check: base $2 is not a commit in $WT" >&2; exit 2; }
    EV_FAILS=0
    EV_CHECKS=0
}

ok()   { EV_CHECKS=$((EV_CHECKS + 1)); echo "  ok   $*"; }
fail() { EV_CHECKS=$((EV_CHECKS + 1)); EV_FAILS=$((EV_FAILS + 1)); echo "  FAIL $*"; }

# assert <description> <command...> — ok when the command succeeds.
assert() {
    local what="$1"; shift
    if "$@" >/dev/null 2>&1; then ok "$what"; else fail "$what"; fi
}

# assert_not <description> <command...> — ok when the command fails.
assert_not() {
    local what="$1"; shift
    if "$@" >/dev/null 2>&1; then fail "$what"; else ok "$what"; fi
}

g() { git -C "$WT" "$@"; }

# Every path that differs from BASE: committed, staged, unstaged or untracked.
changed_files() {
    { g diff --name-only "$BASE" HEAD; g diff --name-only HEAD; g ls-files --others --exclude-standard; } \
        | sed '/^$/d' | sort -u
}

# Paths added since BASE (committed or untracked). A rename counts as an addition of the
# new path.
added_files() {
    { g diff --name-only --no-renames --diff-filter=A "$BASE" HEAD; g ls-files --others --exclude-standard; } \
        | sed '/^$/d' | sort -u
}

commit_count() { g rev-list --count "$BASE..HEAD"; }

# The day the work was done: the newest commit's date, or today when nothing is committed.
# Using the commit date keeps a check deterministic when it is rerun on a later day.
work_date() {
    if [ "$(commit_count)" -gt 0 ]; then g log -1 --format=%cs HEAD; else date +%F; fi
}

# The standard ending of any task in this project: committed, nothing left behind, and a
# conventional subject on every commit.
assert_committed() {
    if [ "$(commit_count)" -gt 0 ]; then ok "work is committed ($(commit_count) commit(s))"
    else fail "work is committed (no commit after the base)"; fi
    if [ -z "$(g status --porcelain)" ]; then ok "working tree clean"
    else fail "working tree clean: $(g status --porcelain | head -3 | tr '\n' ' ')"; fi
    local bad
    bad="$(g log --format=%s "$BASE..HEAD" | grep -Ev '^(feat|fix|refactor|docs|chore)(\([^)]*\))?!?: ' || true)"
    if [ -z "$bad" ]; then ok "conventional commit subjects"
    else fail "conventional commit subjects: $(echo "$bad" | head -1)"; fi
}

# Every changed path matches one of the given extended regexes.
assert_only_paths() {
    local what="$1"; shift
    local re; re="$(IFS='|'; echo "$*")"
    local stray; stray="$(changed_files | grep -Ev "^($re)" || true)"
    if [ -z "$stray" ]; then ok "$what"
    else fail "$what: $(echo "$stray" | head -3 | tr '\n' ' ')"; fi
}

ev_done() {
    if [ "$EV_FAILS" -eq 0 ]; then echo "  => pass ($EV_CHECKS checks)"; exit 0; fi
    echo "  => fail ($EV_FAILS of $EV_CHECKS checks)"; exit 1
}
