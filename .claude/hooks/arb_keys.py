#!/usr/bin/env python3
"""Compare the message-key sets of the ARB files against the template.

Ten ARB files must hold the same 165 keys: a key missing from one language is a
silent English fallback for those users. The template is app_fr.arb, not the
English file -- it is read from l10n.yaml so the two cannot drift.

Metadata is excluded by filtering keys that start with "@", which also drops
"@@locale" for free. Key ORDER differs between files, so this compares sets and
never sequences.

Exit codes: 0 in sync, 1 divergent, 2 invalid JSON in the file named by --focus,
3 the l10n setup could not be read.
"""

import argparse
import json
import os
import pathlib
import re
import sys

ROOT = pathlib.Path(os.environ.get("CLAUDE_PROJECT_DIR", os.getcwd()))


def message_keys(path):
    with path.open(encoding="utf-8") as handle:
        return {k for k in json.load(handle) if not k.startswith("@")}


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--focus", help="file just edited; invalid JSON in it is an error")
    args = parser.parse_args()

    try:
        config = (ROOT / "l10n.yaml").read_text(encoding="utf-8")
        arb_dir = re.search(r"^arb-dir:\s*(\S+)", config, re.M).group(1)
        template_name = re.search(r"^template-arb-file:\s*(\S+)", config, re.M).group(1)
    except (OSError, AttributeError):
        print("l10n: could not read arb-dir/template-arb-file from l10n.yaml", file=sys.stderr)
        return 3

    directory = ROOT / arb_dir
    template = directory / template_name
    try:
        reference = message_keys(template)
    except (OSError, json.JSONDecodeError) as error:
        print(f"l10n: {template_name} is unreadable -- {error}", file=sys.stderr)
        return 2 if args.focus and pathlib.Path(args.focus).name == template_name else 3

    missing, extra, broken, in_sync = {}, {}, [], 0
    for path in sorted(directory.glob("app_*.arb")):
        if path.name == template_name:
            continue
        try:
            keys = message_keys(path)
        except (OSError, json.JSONDecodeError) as error:
            broken.append(f"{path.name}: {error}")
            continue
        locale = path.stem.replace("app_", "")
        if keys - reference:
            extra[locale] = sorted(keys - reference)
        if reference - keys:
            missing[locale] = sorted(reference - keys)
        if keys == reference:
            in_sync += 1

    if broken:
        for line in broken:
            print(f"l10n: invalid JSON in {line}", file=sys.stderr)
        focus_name = pathlib.Path(args.focus).name if args.focus else None
        if focus_name and any(line.startswith(focus_name + ":") for line in broken):
            return 2
        return 1

    if not missing and not extra:
        return 0

    total = len(list(directory.glob("app_*.arb")))
    if missing:
        keys_missing = sorted({k for keys in missing.values() for k in keys})
        shown = ", ".join(keys_missing[:3]) + (" ..." if len(keys_missing) > 3 else "")
        print(
            f"l10n: {len(keys_missing)} key(s) from {template_name} not yet in "
            f"{', '.join(sorted(missing))} ({in_sync + 1}/{total} in sync) -- {shown}"
        )
    for locale, keys in sorted(extra.items()):
        print(f"l10n: {locale} has key(s) absent from {template_name}: {', '.join(keys)}")
    return 1


if __name__ == "__main__":
    sys.exit(main())
