#!/usr/bin/env python
"""Compare the ZapZap caustic analysis across LLM providers on one real game.

Reads a JSON payload (same shape the mobile app POSTs to /comments/zapzap-analysis),
builds the user message once, then runs each selected provider with the SAME system
prompt and parameters. Writes one Markdown file per provider and prints a side-by-side
recap so you can judge the French stylistic quality on a real case.

Usage:
    python scripts/compare_providers.py --payload scripts/sample_payload.json
    python scripts/compare_providers.py --payload game.json --providers bedrock,gemini,mistral
"""
from __future__ import annotations

import argparse
import asyncio
import json
import time
from dataclasses import dataclass
from pathlib import Path

from app.services.llm import get_llm_provider
from app.services.llm.base import DEFAULT_MAX_TOKENS
from app.services.llm.factory import _PROVIDERS
from app.services.zapzap_prompt import ZAPZAP_SYSTEM_PROMPT, build_zapzap_user_message


@dataclass
class Outcome:
    provider: str
    model: str = ""
    tokens_in: int = 0
    tokens_out: int = 0
    elapsed_s: float = 0.0
    status: str = ""
    content: str = ""


async def _run_one(name: str, system_prompt: str, user_message: str, max_tokens: int) -> Outcome:
    out = Outcome(provider=name)
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
    user_message = build_zapzap_user_message(payload)

    names = (
        [p.strip() for p in args.providers.split(",") if p.strip()]
        if args.providers
        else list(_PROVIDERS)
    )

    outcomes = await asyncio.gather(
        *(_run_one(n, ZAPZAP_SYSTEM_PROMPT, user_message, args.max_tokens) for n in names)
    )

    out_dir = Path(args.out_dir)
    out_dir.mkdir(parents=True, exist_ok=True)
    for o in outcomes:
        if o.status == "ok":
            header = (
                f"<!-- provider={o.provider} model={o.model} "
                f"tokens_in={o.tokens_in} tokens_out={o.tokens_out} "
                f"elapsed={o.elapsed_s:.1f}s -->\n\n"
            )
            (out_dir / f"zapzap_{o.provider}.md").write_text(header + o.content, encoding="utf-8")

    # Side-by-side recap.
    print(f"\nGame: {payload.get('game', {}).get('name', '?')}")
    print(f"Output dir: {out_dir.resolve()}\n")
    print(f"{'provider':<10} {'model':<32} {'tok_in':>7} {'tok_out':>8} {'secs':>6}  status")
    print("-" * 90)
    for o in outcomes:
        print(
            f"{o.provider:<10} {o.model[:32]:<32} {o.tokens_in:>7} {o.tokens_out:>8} "
            f"{o.elapsed_s:>6.1f}  {o.status}"
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
    parser.add_argument("--out-dir", default="out", help="Directory for per-provider .md files")
    parser.add_argument("--max-tokens", type=int, default=DEFAULT_MAX_TOKENS)
    return asyncio.run(_main(parser.parse_args()))


if __name__ == "__main__":
    raise SystemExit(main())
