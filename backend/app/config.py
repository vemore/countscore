"""Application configuration via pydantic-settings."""
from __future__ import annotations

from functools import lru_cache

from pydantic import field_validator
from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    model_config = SettingsConfigDict(env_file=".env", env_file_encoding="utf-8", extra="ignore")

    database_url: str = "postgresql+asyncpg://countscore:countscore@localhost:5432/countscore"

    anthropic_api_key: str | None = None
    comment_model: str = "claude-haiku-4-5"
    default_budget_cents: int = 100
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
    gemini_model: str = "gemini-2.5-pro"
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

    # Send Strict-Transport-Security. Off by default: local development is plain http
    # and an HSTS header there pins the browser to https for a year.
    hsts_enabled: bool = False

    # Max accepted request body size (bytes); larger requests are rejected with 413.
    max_body_bytes: int = 262144  # 256 KiB

    @field_validator("cors_origins")
    @classmethod
    def _reject_cors_wildcard(cls, v: str) -> str:
        if "*" in v:
            raise ValueError("CORS wildcard '*' is not allowed; list explicit origins")
        return v

    @property
    def cors_origins_list(self) -> list[str]:
        return [o.strip() for o in self.cors_origins.split(",") if o.strip()]


@lru_cache
def get_settings() -> Settings:
    return Settings()
