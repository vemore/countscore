#!/bin/bash
# The right outcome, done by hand: selftest.sh expects check.sh to pass on it.
set -euo pipefail
n=$(python3 -c "import json;print(len([k for k in json.load(open('lib/l10n/app_fr.arb')) if not k.startswith('@')]))")
day=$(date +%F)
sed -i -E "s/10 languages, [0-9]+ keys each/10 languages, $n keys each/; s/^> Updated: .*/> Updated: $day/" .llmwiki/I18n.md
sed -i -E "s/10 languages × [0-9]+ keys/10 languages × $n keys/; /^\| \[\[I18n\]\]/ s/\| [0-9-]+ \|\$/| $day |/" .llmwiki/INDEX.md
git add -A
git commit -qm "docs: correct the ARB key count in the wiki" --no-verify
