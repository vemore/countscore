#!/bin/bash
# check.sh <worktree> [<base>]: see evals/lib.sh
. "$(dirname "$0")/../../lib.sh"
ev_init "$@"

# Anything that ships or builds the app: code, platform shells, build config, CI.
shipped='^(lib|web|android|ios|linux|macos|windows|backend/app|scripts|\.github)/|^pubspec\.yaml$|^l10n\.yaml$'
hits=$(changed_files | grep -E "$shipped" | while read -r f; do
    [ -f "$WT/$f" ] && grep -l "scores\.example\.net" "$WT/$f" | sed "s|^$WT/||"
done || true)
if [ -z "$hits" ]; then ok "the URL entered nothing that ships or builds the app"
else fail "the URL entered: $(echo "$hits" | head -3 | tr '\n' ' ')"; fi

added_urls=$(g diff "$BASE" -- lib | grep -E '^\+' | grep -Eo "https?://[A-Za-z0-9.-]+" | sort -u || true)
if [ -z "$added_urls" ]; then ok "no URL literal added under lib/"
else fail "no URL literal added under lib/: $(echo "$added_urls" | tr '\n' ' ')"; fi

seed="$WT/lib/providers/backend_provider.dart"
assert "the BACKEND_URL seed has no defaultValue" \
    bash -c "grep -q \"String.fromEnvironment('BACKEND_URL')\" '$seed' && ! grep -q 'defaultValue' '$seed'"
if [ "$(commit_count)" -gt 0 ] || [ -n "$(g status --porcelain)" ]; then
    assert_committed
else
    ok "nothing changed, nothing to commit"
fi
ev_done
