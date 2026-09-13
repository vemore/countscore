#!/usr/bin/env python3
"""Shared command parser for the CountScore Claude Code hooks.

Reads a PreToolUse hook payload (JSON) on stdin and prints a JSON verdict on
stdout:

    {"parse_ok": bool,
     "blocks":   [{"rule": str, "message": str}, ...],
     "commit":   null | {"all": bool, "amend": bool, "pathspecs": [str, ...]}}

Why a parser and not a grep: splitting a command on "&&" and ";" and then
matching substrings misfires on every quoting case -- `git commit -m "flutter
build apk"`, `echo "..."`, and above all a heredoc body that documents a
forbidden command. The refusals and the `git commit` detection need the same
tokenizer; duplicated across two scripts, they would drift apart silently.

Failure policy: an unparseable command yields no blocks (fail open -- a guard
that refuses every command it cannot read is worse than the risk it covers) but
parse_ok=false, which the caller treats as "assume a commit" (fail closed -- a
skipped gate is a silent regression, a spurious gate costs seconds).
"""

import json
import os
import posixpath
import re
import shlex
import sys

PROJECT_DIR = os.environ.get("CLAUDE_PROJECT_DIR", os.getcwd())

WEB_BINARIES = ("web/sqlite3.wasm", "web/drift_worker.js")
WEB_BINARY_NAMES = ("sqlite3.wasm", "drift_worker.js")

BUILD_TARGETS = {
    "apk", "appbundle", "aab", "bundle", "web",
    "ios", "ipa", "macos", "linux", "windows",
}

# Shell keywords and command prefixes that may sit in front of the real command.
HEAD_NOISE = {
    "if", "then", "else", "elif", "fi", "do", "done", "while", "until", "for",
    "!", "time", "env", "sudo", "nohup", "command", "exec", "{", "}",
}

OPERATORS = {"&&", "||", ";", ";;", "|", "|&", "&", "(", ")", "\n"}
REDIRECTS = {">", ">>", "<", "<<", "2>", "2>>", "&>", ">&", "<<<"}

# `git` options that sit before the subcommand.
GIT_GLOBAL_WITH_ARG = {"-C", "-c", "--git-dir", "--work-tree", "--namespace",
                       "--exec-path", "--super-prefix"}
GIT_GLOBAL_FLAG = {"-p", "-P", "--paginate", "--no-pager", "--bare", "--no-replace-objects",
                   "--literal-pathspecs", "--glob-pathspecs", "--noglob-pathspecs",
                   "--icase-pathspecs", "--no-optional-locks"}

# `git commit` options that consume the next token.
COMMIT_OPT_WITH_ARG = {"-m", "-F", "-C", "-c", "-t", "-S", "-u", "--message", "--file",
                       "--reuse-message", "--reedit-message", "--template", "--author",
                       "--date", "--cleanup", "--fixup", "--squash", "--gpg-sign",
                       "--untracked-files", "--pathspec-from-file", "--trailer"}
COMMIT_SHORT_WITH_ARG = set("mFCctSu")


def strip_heredocs(text):
    """Drop heredoc bodies, keeping every other line.

    Without this, writing a document that quotes `flutter build apk` through a
    heredoc trips the guard against the very file that documents it.
    """
    out = []
    lines = text.split("\n")
    i = 0
    while i < len(lines):
        line = lines[i]
        out.append(line)
        starts = re.findall(r"<<-?\s*([\"']?)([A-Za-z_][A-Za-z0-9_]*)\1", line)
        i += 1
        for _quote, delim in starts:
            while i < len(lines):
                candidate = lines[i].strip() if line.count("<<-") else lines[i].rstrip()
                i += 1
                if candidate == delim:
                    break
    return "\n".join(out)


def _lex(text):
    lexer = shlex.shlex(text, posix=True, punctuation_chars=True)
    lexer.whitespace_split = True
    return list(lexer)


def tokenize(text):
    """Return (tokens, ok). Newlines become explicit command separators."""
    tokens = []
    try:
        for line in text.split("\n"):
            tokens.extend(_lex(line))
            tokens.append(";")
        return tokens, True
    except ValueError:
        pass
    # A quoted construct spanning several lines -- the idiomatic
    # `git commit -m "$(cat <<'EOF' ... EOF)"` -- only parses as a whole.
    try:
        return _lex(text), True
    except ValueError:
        return [], False


def segments(tokens):
    """Split a token stream into commands, dropping operators and redirections."""
    result, current, skip_next = [], [], False
    for token in tokens:
        if skip_next:
            skip_next = False
            continue
        if token in OPERATORS:
            if current:
                result.append(current)
            current = []
            continue
        if token in REDIRECTS:
            skip_next = True
            continue
        current.append(token)
    if current:
        result.append(current)
    return [normalize_head(s) for s in result if s]


def normalize_head(tokens):
    """Drop shell keywords, `sudo`-style prefixes and leading VAR=value pairs."""
    index = 0
    while index < len(tokens):
        token = tokens[index]
        if token in HEAD_NOISE or re.match(r"^[A-Za-z_][A-Za-z0-9_]*=", token):
            index += 1
            continue
        break
    return tokens[index:]


def base(token):
    return posixpath.basename(token)


def is_option(token):
    return token.startswith("-") and token != "-"


def operands(tokens):
    """Non-option arguments of a segment, honouring the `--` terminator."""
    result, after_dashdash = [], False
    for token in tokens[1:]:
        if after_dashdash:
            result.append(token)
        elif token == "--":
            after_dashdash = True
        elif not is_option(token):
            result.append(token)
    return result


def relpath(token, cwd):
    """Path relative to the project root, or None when outside the project."""
    absolute = posixpath.normpath(posixpath.join(cwd, token))
    root = posixpath.normpath(PROJECT_DIR)
    if absolute == root:
        return "."
    if not absolute.startswith(root + "/"):
        return None
    return absolute[len(root) + 1:]


# --------------------------------------------------------------------------- rules

def check_flutter_build(tokens):
    if not tokens or base(tokens[0]) != "flutter":
        return None
    rest = [t for t in tokens[1:] if not is_option(t)]
    if not rest or rest[0] != "build":
        return None
    if len(rest) < 2 or rest[1] not in BUILD_TARGETS:
        return None  # `flutter build` alone, or `flutter build --help`: no artifact
    if "-h" in tokens or "--help" in tokens:
        return None
    if "--no-tree-shake-icons" in tokens:
        return None
    return {
        "rule": "no-tree-shake-icons",
        "message": (
            "Refused: `flutter build {target}` without --no-tree-shake-icons.\n"
            "CountScore builds its game-type icons from IconData codepoints stored in the "
            "database, so Flutter's icon tree-shaker cannot see those references and the "
            "build fails. The flag is mandatory on every target (apk, appbundle, ios, web); "
            "it costs about 200 KB.\n"
            "Re-run the same command with --no-tree-shake-icons added."
        ).format(target=rest[1]),
    }


def check_stacked_pr(tokens):
    """A pull request whose base is not `main` merges into that base, not into main."""
    if not tokens or base(tokens[0]) != "gh":
        return None
    words = [t for t in tokens[1:] if not is_option(t)]
    if words[:2] != ["pr", "create"]:
        return None
    target = None
    for index, token in enumerate(tokens):
        if token == "--base" and index + 1 < len(tokens):
            target = tokens[index + 1]
        elif token.startswith("--base="):
            target = token.split("=", 1)[1]
    if target is None or target == "main":
        return None  # no --base means the repository default, which is main
    return {
        "rule": "stacked-pr",
        "message": (
            "Refused: `gh pr create --base {target}` stacks this pull request on another "
            "branch.\n"
            "A stacked pull request merges into its base, not into main. If the base is "
            "merged first -- and it usually is, since it is reviewed first -- the child "
            "merges into a branch whose content already reached main under different "
            "hashes, and its own work silently never arrives. That happened on 2026-09-09 "
            "and cost a fourth pull request to repair.\n"
            "Do one of these instead: wait for the other branch to merge, then rebase onto "
            "main and target main; or put both changes in one pull request.\n"
            "If stacking really is what you want, say so to the user and let them decide, "
            "then unlock it with `git config countscore.allowStackedPr true`."
        ).format(target=target),
    }


def check_web_binaries(tokens, cwd):
    if not tokens:
        return None
    head = base(tokens[0])
    args = None
    if head in {"rm", "mv", "unlink", "shred"}:
        args = operands(tokens)
    elif head == "git":
        subcommand, rest = git_subcommand(tokens)
        if subcommand == "rm":
            args = operands(["git"] + rest)
    if not args:
        return None
    for token in args:
        rel = relpath(token, cwd)
        if rel is None:
            continue  # outside the project: not ours to protect
        if rel in WEB_BINARIES:
            return web_refusal(token)
        if any(target == rel or target.startswith(rel.rstrip("/") + "/") for target in WEB_BINARIES):
            return web_refusal(token)
        if base(rel) in WEB_BINARY_NAMES and not rel.startswith("build/"):
            return web_refusal(token)
    return None


def web_refusal(token):
    return {
        "rule": "web-binaries",
        "message": (
            "Refused: this would remove or move `{token}`.\n"
            "web/sqlite3.wasm (744 KB) and web/drift_worker.js (351 KB) are tracked in git on "
            "purpose, so a fresh clone can run the PWA without fetching binaries. .gitignore "
            "carries a comment saying so, and .llmwiki/Web.md explains where each comes from.\n"
            "Copies under build/ are build output and may be deleted freely."
        ).format(token=token),
    }


def git_subcommand(tokens):
    """Return (subcommand, tokens after it) for a `git ...` segment."""
    index = 1
    while index < len(tokens):
        token = tokens[index]
        if token in GIT_GLOBAL_WITH_ARG:
            index += 2
            continue
        if token in GIT_GLOBAL_FLAG or "=" in token and token.startswith("--"):
            index += 1
            continue
        if is_option(token):
            index += 1
            continue
        return token, tokens[index + 1:]
    return None, []


def parse_commit(tokens):
    """Return commit info for a `git commit` segment, or None."""
    if not tokens or base(tokens[0]) != "git":
        return None
    subcommand, rest = git_subcommand(tokens)
    if subcommand != "commit":
        return None
    if "--dry-run" in rest or "-h" in rest or "--help" in rest:
        return None

    info = {"all": False, "amend": False, "pathspecs": []}
    index, after_dashdash = 0, False
    while index < len(rest):
        token = rest[index]
        if after_dashdash:
            info["pathspecs"].append(token)
            index += 1
            continue
        if token == "--":
            after_dashdash = True
        elif token in {"--all", "--amend"}:
            info[token[2:]] = True
        elif token.startswith("--"):
            if "=" not in token and token in COMMIT_OPT_WITH_ARG:
                index += 1
        elif token.startswith("-") and token != "-":
            letters = token[1:]
            if "a" in letters:
                info["all"] = True
            if letters and letters[-1] in COMMIT_SHORT_WITH_ARG:
                index += 1
        else:
            info["pathspecs"].append(token)
        index += 1
    return info


def main():
    try:
        payload = json.load(sys.stdin)
    except (json.JSONDecodeError, ValueError):
        payload = {}
    command = (payload.get("tool_input") or {}).get("command") or ""
    cwd = payload.get("cwd") or PROJECT_DIR

    tokens, ok = tokenize(strip_heredocs(command))
    verdict = {"parse_ok": ok, "blocks": [], "commit": None}
    if not ok:
        # Fail closed on the commit question only: a regex is enough to decide
        # whether the gates should run, and running them spuriously is cheap.
        if re.search(r"\bgit\b[^\n]*\bcommit\b", command) and "--dry-run" not in command:
            verdict["commit"] = {"all": True, "amend": True, "pathspecs": []}
        print(json.dumps(verdict))
        return

    notional_cwd = posixpath.normpath(cwd)
    for tokens_of_segment in segments(tokens):
        if not tokens_of_segment:
            continue
        if base(tokens_of_segment[0]) == "cd":
            args = operands(tokens_of_segment)
            if args and args[0] != "-":
                notional_cwd = posixpath.normpath(posixpath.join(notional_cwd, args[0]))
            else:
                notional_cwd = posixpath.normpath(cwd)
            continue
        for finding in (
            check_flutter_build(tokens_of_segment),
            check_stacked_pr(tokens_of_segment),
            check_web_binaries(tokens_of_segment, notional_cwd),
        ):
            if finding:
                verdict["blocks"].append(finding)
        commit = parse_commit(tokens_of_segment)
        if commit:
            verdict["commit"] = commit
    print(json.dumps(verdict))


if __name__ == "__main__":
    main()
