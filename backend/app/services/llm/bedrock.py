"""AWS Bedrock provider (Llama-3 via boto3).

Credentials live in backend env vars (never in the mobile APK). The sync boto3 call is
wrapped with asyncio.to_thread so it fits the async provider contract.
"""
from __future__ import annotations

import asyncio
import json
from typing import Any

import boto3
from botocore.config import Config as BotoConfig
from botocore.exceptions import ClientError

from app.config import get_settings

from .base import (
    DEFAULT_MAX_TOKENS,
    DEFAULT_TEMPERATURE,
    DEFAULT_TOP_P,
    LLMRateLimitedError,
    LLMResult,
)

# Bedrock error codes that mean "no capacity right now", not "bad request".
_THROTTLING_CODES = frozenset({"ThrottlingException", "ServiceQuotaExceededException"})


class BedrockProvider:
    """Sync boto3 bedrock-runtime client wrapped for async usage."""

    def __init__(self) -> None:
        settings = get_settings()
        self.region = settings.aws_region
        self.model_id = settings.bedrock_model_id
        self._client = None
        if settings.aws_access_key_id and settings.aws_secret_access_key:
            self._client = boto3.client(
                "bedrock-runtime",
                region_name=settings.aws_region,
                aws_access_key_id=settings.aws_access_key_id,
                aws_secret_access_key=settings.aws_secret_access_key,
                aws_session_token=settings.aws_session_token,
                config=BotoConfig(read_timeout=90, retries={"max_attempts": 0}),
            )

    @property
    def available(self) -> bool:
        return self._client is not None

    @property
    def model(self) -> str:
        # `model_id` is kept as the attribute name because it is boto3's own
        # parameter (`modelId=`); `model` is the name the LLMProvider contract uses.
        return self.model_id

    def _invoke_sync(
        self,
        system_prompt: str,
        user_message: str,
        max_tokens: int,
        temperature: float,
        top_p: float,
    ) -> dict[str, Any]:
        # Llama-3 chat format: a single completion-style prompt with role markers.
        prompt = (
            "<|begin_of_text|><|start_header_id|>system<|end_header_id|>\n\n"
            f"{system_prompt}<|eot_id|>"
            "<|start_header_id|>user<|end_header_id|>\n\n"
            f"{user_message}<|eot_id|>"
            "<|start_header_id|>assistant<|end_header_id|>\n\n"
        )
        body = json.dumps(
            {
                "prompt": prompt,
                "max_gen_len": max_tokens,
                "temperature": temperature,
                "top_p": top_p,
            }
        )
        response = self._client.invoke_model(  # type: ignore[union-attr]
            modelId=self.model_id,
            contentType="application/json",
            accept="application/json",
            body=body,
        )
        return json.loads(response["body"].read())

    async def generate(
        self,
        system_prompt: str,
        user_message: str,
        *,
        max_tokens: int = DEFAULT_MAX_TOKENS,
        temperature: float = DEFAULT_TEMPERATURE,
        top_p: float = DEFAULT_TOP_P,
    ) -> LLMResult:
        if self._client is None:
            raise RuntimeError(
                "Bedrock provider not configured "
                "(AWS_ACCESS_KEY_ID / AWS_SECRET_ACCESS_KEY missing)"
            )
        try:
            payload = await asyncio.to_thread(
                self._invoke_sync, system_prompt, user_message, max_tokens, temperature, top_p
            )
        except ClientError as e:
            if e.response.get("Error", {}).get("Code") in _THROTTLING_CODES:
                raise LLMRateLimitedError(f"Bedrock API rate-limited: {e}") from e
            raise
        content = (payload.get("generation") or "").strip()
        return LLMResult(
            content=content,
            model=self.model_id,
            tokens_in=int(payload.get("prompt_token_count") or 0),
            tokens_out=int(payload.get("generation_token_count") or 0),
        )
