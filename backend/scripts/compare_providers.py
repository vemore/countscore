#!/usr/bin/env python
"""Compare the game analysis across LLM providers, personas and languages on a real game.

Reads a JSON payload (the shape the app POSTs to /comments/game-analysis), builds the
prompt once per style, then runs each selected provider with the SAME prompt and
parameters. Writes one Markdown file per provider and style and prints a side-by-side
recap.

This is the only way to judge what no unit test can: that the answer really does fit on a
page, that it does not rebuild the score table, and that it reads well in a language whose
persona block is written in English.

Usage:
    python scripts/compare_providers.py --payload scripts/sample_payload.json
    python scripts/compare_providers.py --payload game.json --providers bedrock,gemini
    python scripts/compare_providers.py --payload scripts/sample_payload_skyjo.json \
        --styles bard,coach --language ja
"""

from __future__ import annotations

import argparse
import asyncio
import json
import time
from dataclasses import dataclass
from pathlib import Path

from app.services.analysis import PERSONA_KEYS, build_analysis_prompt
from app.services.llm import get_llm_provider
from app.services.llm.base import DEFAULT_MAX_TOKENS
from app.services.llm.factory import _PROVIDERS


@dataclass
class Outcome:
    provider: str
    style: str = ""
    model: str = ""
    tokens_in: int = 0
    tokens_out: int = 0
    elapsed_s: float = 0.0
    status: str = ""
    content: str = ""


async def _run_one(
    name: str, style: str, system_prompt: str, user_message: str, max_tokens: int
) -> Outcome:
    out = Outcome(provider=name, style=style)
    try:
        provider = get_llm_provider(name)
    except ValueError as e:
        out.status = f"unknown ({e})"
        return out
    if not provider.available:
        out.status = "unavailable (API key missing)"
        return out

    start = time.monotonic()
    try:
        result = await provider.generate(system_prompt, user_message, max_tokens=max_tokens)
    except Exception as e:
        out.elapsed_s = time.monotonic() - start
        out.status = f"error: {type(e).__name__}: {e}"
        return out

    out.elapsed_s = time.monotonic() - start
    out.model = result.model
    out.tokens_in = result.tokens_in
    out.tokens_out = result.tokens_out
    out.content = result.content
    out.status = "ok"
    return out


async def _main(args: argparse.Namespace) -> int:
    payload = json.loads(Path(args.payload).read_text(encoding="utf-8"))

    names = (
        [p.strip() for p in args.providers.split(",") if p.strip()]
        if args.providers
        else list(_PROVIDERS)
    )
    styles = (
        [s.strip() for s in args.styles.split(",") if s.strip()]
        if args.styles
        else [payload.get("style") or PERSONA_KEYS[0]]
    )
    if args.language:
        payload["language"] = args.language
    # The schema fills this in for a request that omits it — an app older than the
    # multilingual analysis — so a raw JSON file has to opt into the same default, or the
    # script would silently compare a different prompt from the one the route builds.
    payload.setdefault("language", "fr")

    jobs = []
    for style in styles:
        system_prompt, user_message = build_analysis_prompt(payload | {"style": style})
        jobs += [_run_one(n, style, system_prompt, user_message, args.max_tokens) for n in names]
    outcomes = await asyncio.gather(*jobs)

    out_dir = Path(args.out_dir)
    out_dir.mkdir(parents=True, exist_ok=True)
    for o in outcomes:
        if o.status == "ok":
            header = (
                f"<!-- provider={o.provider} style={o.style} model={o.model} "
                f"tokens_in={o.tokens_in} tokens_out={o.tokens_out} "
                f"elapsed={o.elapsed_s:.1f}s -->\n\n"
            )
            (out_dir / f"analysis_{o.style}_{o.provider}.md").write_text(
                header + o.content, encoding="utf-8"
            )

    # Side-by-side recap.
    print(f"\nGame: {payload.get('game', {}).get('name', '?')}")
    print(f"Output dir: {out_dir.resolve()}\n")
    print(
        f"{'provider':<10} {'style':<12} {'model':<32} {'tok_in':>7} {'tok_out':>8} "
        f"{'words':>6} {'secs':>6}  status"
    )
    print("-" * 110)
    for o in outcomes:
        # The contract asks for 250-350 words; the count is the quickest way to see it.
        words = len(o.content.split())
        print(
            f"{o.provider:<10} {o.style:<12} {o.model[:32]:<32} {o.tokens_in:>7} "
            f"{o.tokens_out:>8} {words:>6} {o.elapsed_s:>6.1f}  {o.status}"
        )
    print()

    ok = [o for o in outcomes if o.status == "ok"]
    return 0 if ok else 1


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--payload", required=True, help="Path to the game JSON payload")
    parser.add_argument(
        "--providers",
        default="",
        help="Comma-separated providers (default: bedrock,gemini,mistral)",
    )
    parser.add_argument(
        "--styles",
        default="",
        help=f"Comma-separated personas (default: the payload's, or {PERSONA_KEYS[0]}). "
        f"One of: {', '.join(PERSONA_KEYS)}",
    )
    parser.add_argument("--language", default="", help="Output language tag, e.g. ja or pt-BR")
    parser.add_argument("--out-dir", default="out", help="Directory for per-provider .md files")
    parser.add_argument("--max-tokens", type=int, default=DEFAULT_MAX_TOKENS)
    return asyncio.run(_main(parser.parse_args()))


if __name__ == "__main__":
    raise SystemExit(main())
