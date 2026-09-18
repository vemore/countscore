"""Application configuration via pydantic-settings."""

from __future__ import annotations

import re
from functools import lru_cache

from pydantic import field_validator
from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    model_config = SettingsConfigDict(env_file=".env", env_file_encoding="utf-8", extra="ignore")

    database_url: str = "postgresql+asyncpg://countscore:countscore@localhost:5432/countscore"

    anthropic_api_key: str | None = None
    comment_model: str = "claude-haiku-4-5"
    default_budget_cents: int = 100
    # Ceiling on what the group owner may set through PATCH /groups/me/settings. The budget is
    # spent on the operator's key, so the operator owns the ceiling; unset, it is the
    # default budget — an owner may lower it but not raise it.
    max_budget_cents: int | None = None
    comment_memory_size: int = 5

    # LLM provider for the ZapZap analysis endpoint: bedrock | gemini | mistral
    llm_provider: str = "bedrock"

    # AWS Bedrock
    aws_region: str = "us-east-1"
    aws_access_key_id: str | None = None
    aws_secret_access_key: str | None = None
    aws_session_token: str | None = None
    bedrock_model_id: str = "us.meta.llama3-3-70b-instruct-v1:0"

    # Google Gemini (OpenAI-compatible endpoint)
    gemini_api_key: str | None = None
    gemini_model: str = "gemini-2.5-flash"
    gemini_base_url: str = "https://generativelanguage.googleapis.com/v1beta/openai/"

    # Mistral (OpenAI-compatible endpoint)
    mistral_api_key: str | None = None
    mistral_model: str = "mistral-medium-latest"
    mistral_base_url: str = "https://api.mistral.ai/v1"

    cors_origins: str = "http://localhost:3000"

    log_level: str = "INFO"

    # Rate limit thresholds (per authenticated device) — see .llmwiki/LlmProviders.md
    rl_per_minute: int = 6
    rl_per_hour: int = 30
    rl_per_day: int = 100

    # Per-IP rate limit for the unauthenticated LLM endpoints (cost-abuse guard).
    ip_rl_per_minute: int = 5
    ip_rl_per_hour: int = 30

    # Per-IP rate limit for group create/join. Counted in its own bucket so that group
    # spam cannot eat the LLM quota above. Also caps share_token guessing on /join.
    group_rl_per_minute: int = 3
    group_rl_per_hour: int = 10

    # Per-IP cap on *failed* device-token checks. A token names its device, so a failure
    # costs one argon2 verify; this bounds how many a single address can make us run.
    auth_fail_rl_per_minute: int = 10
    auth_fail_rl_per_hour: int = 60

    # Per-device cap on /sync/push. Each call can carry 500 deltas and 256 KiB, all of it
    # written to change_log and served to every member, so a member must not be able to
    # push without bound. The app sends batches of 100, so 60 a minute still lets a first
    # share of a long history through in a few minutes.
    sync_push_rl_per_minute: int = 60
    sync_push_rl_per_hour: int = 1200

    # Concurrent /sync/stream connections one device may hold. Several tabs of the PWA
    # share a device, so more than one; a cap, so one member cannot hold hundreds.
    max_streams_per_device: int = 3

    # Reverse-proxy addresses whose X-Real-IP / X-Forwarded-Proto are believed, CSV. Empty
    # (dev, tests): no header is believed. See app/services/trusted_proxy.py.
    trusted_proxy_ips: str = ""

    # Send Strict-Transport-Security. Off by default: local development is plain http
    # and an HSTS header there pins the browser to https for a year.
    hsts_enabled: bool = False

    # Serve /docs, /redoc and /openapi.json. Off by default: in production they map the
    # whole API for anyone, under a CSP that has to allow 'unsafe-inline' for Swagger.
    expose_docs: bool = False

    # Max accepted request body size (bytes); larger requests are rejected with 413.
    max_body_bytes: int = 262144  # 256 KiB

    # The PWA build, served by this app under a sub-path of its own host — same origin as
    # the API, so it needs no CORS entry. Off while pwa_base_path is empty. pwa_dir is a
    # path inside the container; production bind-mounts the NAS folder there.
    pwa_base_path: str = ""
    pwa_dir: str = "/srv/pwa/current"

    @field_validator("pwa_base_path")
    @classmethod
    def _check_pwa_base_path(cls, v: str) -> str:
        # Flutter's --base-href is this value plus a trailing slash, so it must be a
        # plain path: leading slash, no trailing slash, no dot-only segments.
        if v and not re.fullmatch(r"(/[A-Za-z0-9_-][A-Za-z0-9._-]*)+", v):
            raise ValueError(
                f"PWA_BASE_PATH must look like /countscore (leading slash, no trailing "
                f"slash): {v!r}"
            )
        return v

    @field_validator("max_budget_cents", mode="before")
    @classmethod
    def _empty_budget_ceiling_is_unset(cls, v: object) -> object:
        # docker-compose.prod.yml passes ${MAX_BUDGET_CENTS:-}, an empty string when unset.
        return None if v == "" else v

    @field_validator("cors_origins")
    @classmethod
    def _reject_cors_wildcard(cls, v: str) -> str:
        if "*" in v:
            raise ValueError("CORS wildcard '*' is not allowed; list explicit origins")
        return v

    @property
    def effective_max_budget_cents(self) -> int:
        return self.default_budget_cents if self.max_budget_cents is None else self.max_budget_cents

    @property
    def trusted_proxy_ips_list(self) -> list[str]:
        return [ip.strip() for ip in self.trusted_proxy_ips.split(",") if ip.strip()]

    @property
    def cors_origins_list(self) -> list[str]:
        return [o.strip() for o in self.cors_origins.split(",") if o.strip()]


@lru_cache
def get_settings() -> Settings:
    return Settings()
