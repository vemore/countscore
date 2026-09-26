#!/bin/bash
# Plant a stale ARB key count in I18n.md and its INDEX.md row: the real count minus 18.
# Run from the root of the throwaway worktree, before the fixture commit.
set -euo pipefail
n=$(python3 -c "import json;print(len([k for k in json.load(open('lib/l10n/app_fr.arb')) if not k.startswith('@')]))")
stale=$((n - 18))
sed -i -E "s/10 languages, [0-9]+ keys each/10 languages, $stale keys each/" .llmwiki/I18n.md
sed -i -E "s/10 languages × [0-9]+ keys/10 languages × $stale keys/" .llmwiki/INDEX.md
grep -q "$stale keys each" .llmwiki/I18n.md
grep -q "× $stale keys" .llmwiki/INDEX.md
