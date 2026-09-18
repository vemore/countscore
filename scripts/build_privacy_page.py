#!/usr/bin/env python3
"""Render privacy_policy.md to docs/privacy-policy.html, the page Play links to.

The Play Console Data Safety form carries a permanent privacy-policy URL, and a policy
served there that does not match what the app does is a policy violation. Generating the
page instead of hand-writing it is what keeps the two the same document: edit
`privacy_policy.md`, run this, commit both.

    python3 scripts/build_privacy_page.py
    python3 scripts/build_privacy_page.py --check [--base REF]

`--check` writes nothing: it renders the page and fails, printing the diff, when it differs
from the committed `docs/privacy-policy.html`. With `--base REF` it also fails when
`privacy_policy.md` differs from its REF version without its `**Last Updated**` line
changing. CI runs both in the `backend` job, against the parent commit.

Requires `pandoc` on PATH, at PANDOC_VERSION below — the one CI installs: another version can
render the same Markdown differently, and `--check` would report a stale page that is not.
The output is standalone on purpose — no CDN, no external font, no script — so the page
keeps working whatever GitHub Pages does and whatever a reviewer's network blocks.
"""

from __future__ import annotations

import argparse
import difflib
import re
import shutil
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
SOURCE = ROOT / "privacy_policy.md"
OUTPUT = ROOT / "docs" / "privacy-policy.html"

# The pandoc CI installs (.github/workflows/ci.yml, `backend` job), recorded in
# docs/README.md. Move all three together, and regenerate the page in the same commit.
PANDOC_VERSION = "3.6.4"

LAST_UPDATED = re.compile(r"^\*\*Last Updated\*\*")

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


def pandoc_version() -> str | None:
    """The version of the pandoc on PATH, or None when there is none."""
    if shutil.which("pandoc") is None:
        return None
    out = subprocess.run(["pandoc", "--version"], capture_output=True, text=True, check=True)
    return out.stdout.splitlines()[0].split()[-1]


def render(source: Path = SOURCE) -> str:
    """The whole page for `source`, exactly as it is written to OUTPUT."""
    body = subprocess.run(
        ["pandoc", "--from", "gfm", "--to", "html", "--no-highlight", str(source)],
        capture_output=True,
        text=True,
        check=True,
    ).stdout.strip()
    return TEMPLATE.format(body=body)


def stale_diff(committed: str, rendered: str) -> list[str]:
    """Unified diff from the committed page to the rendered one; empty when they match."""
    return list(
        difflib.unified_diff(
            committed.splitlines(keepends=True),
            rendered.splitlines(keepends=True),
            "docs/privacy-policy.html (committed)",
            "docs/privacy-policy.html (rendered from privacy_policy.md)",
        )
    )


def last_updated_lines(text: str) -> list[str]:
    return [line for line in text.splitlines() if LAST_UPDATED.match(line)]


def last_updated_missing(old: str | None, new: str) -> bool:
    """True when the policy changed but its **Last Updated** line did not.

    `old` is None when the policy did not exist at the base: a new file needs no bump.
    """
    if old is None or old == new:
        return False
    return last_updated_lines(old) == last_updated_lines(new)


def policy_at(ref: str) -> str | None:
    """privacy_policy.md at `ref`, or None when it does not exist there."""
    # A bad ref must fail loudly, never read as "no policy there, nothing to check".
    verified = subprocess.run(
        ["git", "-C", str(ROOT), "rev-parse", "--verify", "--quiet", f"{ref}^{{commit}}"],
        stdout=subprocess.DEVNULL,
        check=False,
    )
    if verified.returncode != 0:
        raise SystemExit(f"error: --base {ref} is not a commit in this repository")
    shown = subprocess.run(
        ["git", "-C", str(ROOT), "show", f"{ref}:privacy_policy.md"],
        capture_output=True,
        text=True,
        check=False,
    )
    return shown.stdout if shown.returncode == 0 else None


def check(base: str | None) -> int:
    failed = False
    have = pandoc_version()
    if have != PANDOC_VERSION:
        print(
            f"warning: pandoc {have} is on PATH, the page is pinned to {PANDOC_VERSION} — "
            "a difference below may be the version, not the policy",
            file=sys.stderr,
        )

    diff = stale_diff(OUTPUT.read_text(encoding="utf-8"), render())
    if diff:
        failed = True
        sys.stdout.writelines(diff)
        print(
            "error: docs/privacy-policy.html is stale against privacy_policy.md — "
            "run `python3 scripts/build_privacy_page.py` and commit both",
            file=sys.stderr,
        )
    else:
        print("docs/privacy-policy.html matches privacy_policy.md")

    if base is not None:
        if last_updated_missing(policy_at(base), SOURCE.read_text(encoding="utf-8")):
            failed = True
            print(
                f"error: privacy_policy.md changed since {base} but its **Last Updated** line "
                "did not — date the change and add a Version History entry",
                file=sys.stderr,
            )
        else:
            print(f"privacy_policy.md is unchanged since {base}, or its **Last Updated** moved")
    return 1 if failed else 0


def main() -> int:
    parser = argparse.ArgumentParser(description="Render privacy_policy.md to the Play page.")
    parser.add_argument(
        "--check", action="store_true", help="write nothing; fail if the committed page is stale"
    )
    parser.add_argument(
        "--base",
        metavar="REF",
        help="with --check, also fail if privacy_policy.md changed since REF "
        "without its **Last Updated** line changing",
    )
    args = parser.parse_args()
    if args.base is not None and not args.check:
        parser.error("--base needs --check")

    if shutil.which("pandoc") is None:
        print("pandoc is not on PATH — install it, or render the page by hand.", file=sys.stderr)
        return 1
    if args.check:
        return check(args.base)

    OUTPUT.parent.mkdir(exist_ok=True)
    OUTPUT.write_text(render(), encoding="utf-8")
    print(f"wrote {OUTPUT.relative_to(ROOT)} ({OUTPUT.stat().st_size} B)")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
