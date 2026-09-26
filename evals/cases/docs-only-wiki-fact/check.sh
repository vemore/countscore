#!/bin/bash
# check.sh <worktree> [<base>]: see evals/lib.sh
. "$(dirname "$0")/../../lib.sh"
ev_init "$@"

n=$(python3 -c "import json,sys;print(len([k for k in json.load(open(sys.argv[1])) if not k.startswith('@')]))" "$WT/lib/l10n/app_fr.arb")
day=$(work_date)

assert "I18n.md states the real count ($n keys)" grep -q "10 languages, $n keys each" "$WT/.llmwiki/I18n.md"
assert "INDEX.md row states the real count" grep -q "10 languages × $n keys" "$WT/.llmwiki/INDEX.md"
assert "I18n.md Updated: is the day of the change ($day)" grep -q "^> Updated: $day" "$WT/.llmwiki/I18n.md"
assert "INDEX.md row for I18n is dated $day" grep -Eq "^\| \[\[I18n\]\] \|.*\| $day \|\$" "$WT/.llmwiki/INDEX.md"
assert "README.md untouched" g diff --quiet "$BASE" -- README.md
assert_only_paths "only the wiki (and wip/) changed" '\.llmwiki/' 'wip/'
assert_committed
ev_done
