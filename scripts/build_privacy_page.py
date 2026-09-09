#!/usr/bin/env python3
"""Render privacy_policy.md to docs/privacy-policy.html, the page Play links to.

The Play Console Data Safety form carries a permanent privacy-policy URL, and a policy
served there that does not match what the app does is a policy violation. Generating the
page instead of hand-writing it is what keeps the two the same document: edit
`privacy_policy.md`, run this, commit both.

    python3 scripts/build_privacy_page.py

Requires `pandoc` on PATH. The output is standalone on purpose — no CDN, no external font,
no script — so the page keeps working whatever GitHub Pages does and whatever a reviewer's
network blocks.
"""

from __future__ import annotations

import shutil
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
SOURCE = ROOT / "privacy_policy.md"
OUTPUT = ROOT / "docs" / "privacy-policy.html"

# Light palette on :root, dark overridden under prefers-color-scheme, so the page follows
# the reader's system setting without any script.
TEMPLATE = """<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>Privacy Policy — CountScore</title>
<meta name="description" content="How CountScore handles your information.">
<style>
:root {{
  color-scheme: light dark;
  --bg: #fbfaf8;
  --surface: #ffffff;
  --text: #1c1b1a;
  --muted: #5c5955;
  --rule: #e2ded7;
  --accent: #1f5fa9;
  --code-bg: #f1efea;
}}
@media (prefers-color-scheme: dark) {{
  :root {{
    --bg: #16181c;
    --surface: #1d2026;
    --text: #e6e4e0;
    --muted: #a2a09b;
    --rule: #32363e;
    --accent: #7fb2ec;
    --code-bg: #262a31;
  }}
}}
* {{ box-sizing: border-box; }}
body {{
  margin: 0;
  padding: 2.5rem 1.25rem 5rem;
  background: var(--bg);
  color: var(--text);
  font: 16px/1.65 -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, "Helvetica Neue", Arial, sans-serif;
}}
main {{
  max-width: 46rem;
  margin: 0 auto;
  background: var(--surface);
  border: 1px solid var(--rule);
  border-radius: 12px;
  padding: 2.5rem 2rem;
}}
h1, h2, h3 {{ line-height: 1.25; }}
h1 {{ font-size: 1.9rem; margin: 0 0 1.5rem; }}
h2 {{
  font-size: 1.3rem;
  margin: 2.5rem 0 0.75rem;
  padding-top: 1.25rem;
  border-top: 1px solid var(--rule);
}}
h3 {{ font-size: 1.05rem; margin: 1.75rem 0 0.5rem; color: var(--muted); }}
a {{ color: var(--accent); }}
code {{
  background: var(--code-bg);
  padding: 0.12em 0.35em;
  border-radius: 4px;
  font-family: ui-monospace, SFMono-Regular, Menlo, Consolas, monospace;
  font-size: 0.9em;
}}
pre {{ background: var(--code-bg); padding: 1rem; border-radius: 8px; overflow-x: auto; }}
pre code {{ background: none; padding: 0; }}
blockquote {{
  margin: 1.25rem 0;
  padding: 0.25rem 0 0.25rem 1rem;
  border-left: 3px solid var(--rule);
  color: var(--muted);
}}
ul, ol {{ padding-left: 1.35rem; }}
li {{ margin: 0.35rem 0; }}
hr {{ border: 0; border-top: 1px solid var(--rule); margin: 2.5rem 0; }}
table {{ width: 100%; border-collapse: collapse; margin: 1.25rem 0; }}
th, td {{ border: 1px solid var(--rule); padding: 0.5rem 0.65rem; text-align: left; }}
th {{ background: var(--code-bg); }}
.generated {{
  max-width: 46rem;
  margin: 1.5rem auto 0;
  color: var(--muted);
  font-size: 0.85rem;
  text-align: center;
}}
.generated a {{ color: var(--muted); }}
</style>
</head>
<body>
<main>
{body}
</main>
<p class="generated">
Generated from <a href="https://github.com/vemore/countscore/blob/main/privacy_policy.md">privacy_policy.md</a>
in the CountScore repository.
</p>
</body>
</html>
"""


def main() -> int:
    if shutil.which("pandoc") is None:
        print("pandoc is not on PATH — install it, or render the page by hand.", file=sys.stderr)
        return 1

    body = subprocess.run(
        ["pandoc", "--from", "gfm", "--to", "html", "--no-highlight", str(SOURCE)],
        capture_output=True,
        text=True,
        check=True,
    ).stdout.strip()

    OUTPUT.parent.mkdir(exist_ok=True)
    OUTPUT.write_text(TEMPLATE.format(body=body), encoding="utf-8")
    print(f"wrote {OUTPUT.relative_to(ROOT)} ({OUTPUT.stat().st_size} B)")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
