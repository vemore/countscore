#!/usr/bin/env python3
"""Check the ARB files against the template (keys) and against English (values).

Ten ARB files must hold the same 238 keys: a key missing from one language is a
silent English fallback for those users. The template is app_fr.arb, not the
English file -- it is read from l10n.yaml so the two cannot drift.

Metadata is excluded by filtering keys that start with "@", which also drops
"@@locale" for free. Key ORDER differs between files, so this compares sets and
never sequences.

Counting keys is not enough. A key can be present in all ten files and still hold
the literal English string in five of them -- that is exactly how the whole
game-over cluster stayed English in ar, hi, ja, ru and zh until 2026-09-16
(wip/done/2026-09-16-game-over-strings-untranslated.md). So the value check
compares every non-English locale against app_en.arb, minus the matches that are
legitimate (see SAME_AS_ENGLISH_OK).

Modes: --keys or --values runs that check alone; with neither, both run. The
PostToolUse reporter (check-arb-sync.sh) runs both and never blocks; guard-bash.sh
runs them separately at commit time so its refusal can say which one failed.

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

# The runtime fallback locale, hardcoded here as it is in main.dart: an unsupported
# locale resolves to English, so English is what an untranslated value looks like.
FALLBACK_LOCALE = "en"

ALL_LOCALES = "*"

# Keys whose value is legitimately identical to English, measured across all 238
# keys x 10 locales on 2026-09-16. Without this list the value check cries wolf on
# every brand name, loanword and word that is simply spelt the same.
#
# EXTENDING THIS LIST IS THE ESCAPE HATCH. When a genuine translation happens to
# equal the English string, add it here rather than distorting the translation. A
# key maps either to ALL_LOCALES or to the set of locales where the match is
# deliberate; a key ending in "*" exempts every key with that prefix.
SAME_AS_ENGLISH_OK = {
    "appTitle": ALL_LOCALES,        # "CountScore" -- the product name
    "artistName": ALL_LOCALES,      # "efendi.sign" -- a person's handle
    "backendUrlHint": ALL_LOCALES,  # an example URL
    "gameTypeName*": ALL_LOCALES,   # Yahtzee, Qwirkle, Uno, Skyjo, Rummikub, Farkle,
                                    # Bridge, Tarot, Canasta, Wizard, Scrabble, ZapZap --
                                    # proper nouns that most locales keep as they are
    "keypadZeroZapZap": ALL_LOCALES,  # "0 ZapZap" -- a digit and the game's name
    "gameRulesInApp": {"de"},        # "In CountScore" is the German for it too
    "ok": {"fr", "de", "pt", "ja"},  # "OK" is the loanword in all four
    "version": {"fr", "de"},         # "Version {version}"
    "confirmation": {"fr"},          # "Confirmation"
    "lowestScoreExample": {"fr"},    # "Ex: Golf, Hearts" -- two game names
    "color": {"es"},                 # "Color:"
    "system": {"de"},                # "System"
    "rate": {"de"},                  # "Rate"
    "serverSection": {"de"},         # "Server"
    "backup": {"pt"},                # "Backup"
    "newGameNameLabel": {"de"},      # "Name" -- the German word is the same
}

_EXEMPT_PREFIXES = {k[:-1]: v for k, v in SAME_AS_ENGLISH_OK.items() if k.endswith("*")}


def is_exempt(key, locale):
    """True when key holding the English string in locale is deliberate.

    A "prefix*" entry covers the camelCase family under that prefix, never the
    bare prefix itself: "gameTypeName*" exempts gameTypeNameYahtzee and its
    twenty-one siblings, but NOT gameTypeName, which is the form label "Game
    type name" and has to stay translated like any other. Hence the requirement
    that what follows the prefix start with a capital.
    """
    candidates = [SAME_AS_ENGLISH_OK.get(key)]
    candidates += [
        v
        for prefix, v in _EXEMPT_PREFIXES.items()
        if key.startswith(prefix) and key[len(prefix) :][:1].isupper()
    ]
    return any(c == ALL_LOCALES or (c is not None and locale in c) for c in candidates)


def messages(path):
    with path.open(encoding="utf-8") as handle:
        return {k: v for k, v in json.load(handle).items() if not k.startswith("@")}


def check_keys(directory, template_name, reference, loaded):
    """Report keys present in the template but not in a locale, and vice versa."""
    missing, extra, in_sync = {}, {}, 0
    for locale, values in sorted(loaded.items()):
        if f"app_{locale}.arb" == template_name:
            continue
        keys = set(values)
        if keys - reference:
            extra[locale] = sorted(keys - reference)
        if reference - keys:
            missing[locale] = sorted(reference - keys)
        if keys == reference:
            in_sync += 1

    lines = []
    if missing:
        keys_missing = sorted({k for keys in missing.values() for k in keys})
        shown = ", ".join(keys_missing[:3]) + (" ..." if len(keys_missing) > 3 else "")
        total = len(list(directory.glob("app_*.arb")))
        lines.append(
            f"l10n: {len(keys_missing)} key(s) from {template_name} not yet in "
            f"{', '.join(sorted(missing))} ({in_sync + 1}/{total} in sync) -- {shown}"
        )
    for locale, keys in sorted(extra.items()):
        lines.append(f"l10n: {locale} has key(s) absent from {template_name}: {', '.join(keys)}")
    return lines


def check_values(loaded):
    """Report values still identical to English, outside the exemption list."""
    english = loaded.get(FALLBACK_LOCALE)
    if english is None:
        return []

    untranslated = {}
    for locale, values in sorted(loaded.items()):
        if locale == FALLBACK_LOCALE:
            continue
        for key, value in english.items():
            if values.get(key) == value and not is_exempt(key, locale):
                untranslated.setdefault(key, []).append(locale)

    if not untranslated:
        return []
    shown = ", ".join(sorted(untranslated)[:3]) + (" ..." if len(untranslated) > 3 else "")
    locales = sorted({loc for locs in untranslated.values() for loc in locs})
    return [
        f"l10n: {len(untranslated)} key(s) still hold the English string in "
        f"{', '.join(locales)} -- {shown}"
    ]


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--focus", help="file just edited; invalid JSON in it is an error")
    mode = parser.add_mutually_exclusive_group()
    mode.add_argument("--keys", action="store_true", help="only compare key sets")
    mode.add_argument("--values", action="store_true", help="only compare values against English")
    args = parser.parse_args()
    want_keys = args.keys or not args.values
    want_values = args.values or not args.keys

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
        reference = set(messages(template))
    except (OSError, json.JSONDecodeError) as error:
        print(f"l10n: {template_name} is unreadable -- {error}", file=sys.stderr)
        return 2 if args.focus and pathlib.Path(args.focus).name == template_name else 3

    loaded, broken = {}, []
    for path in sorted(directory.glob("app_*.arb")):
        try:
            loaded[path.stem.replace("app_", "")] = messages(path)
        except (OSError, json.JSONDecodeError) as error:
            broken.append(f"{path.name}: {error}")

    if broken:
        for line in broken:
            print(f"l10n: invalid JSON in {line}", file=sys.stderr)
        focus_name = pathlib.Path(args.focus).name if args.focus else None
        if focus_name and any(line.startswith(focus_name + ":") for line in broken):
            return 2
        return 1

    lines = []
    if want_keys:
        lines += check_keys(directory, template_name, reference, loaded)
    if want_values:
        lines += check_values(loaded)

    for line in lines:
        print(line)
    return 1 if lines else 0


if __name__ == "__main__":
    sys.exit(main())
