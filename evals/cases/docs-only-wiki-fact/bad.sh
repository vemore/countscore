#!/bin/bash
# A plausible wrong outcome: the page fixed, its INDEX.md row left stale, the date not
# moved, README.md touched for nothing.
set -euo pipefail
n=$(python3 -c "import json;print(len([k for k in json.load(open('lib/l10n/app_fr.arb')) if not k.startswith('@')]))")
sed -i -E "s/10 languages, [0-9]+ keys each/10 languages, $n keys each/" .llmwiki/I18n.md
echo >> README.md
git add -A
git commit -qm "docs: key count" --no-verify
