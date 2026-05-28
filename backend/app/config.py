"""Application configuration via pydantic-settings."""
from __future__ import annotations

from functools import lru_cache

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
    mistral_model: str = "mistral-large-latest"
    mistral_base_url: str = "https://api.mistral.ai/v1"

    cors_origins: str = "http://localhost:3000"

    log_level: str = "INFO"

    # Rate limit thresholds — see ARCHITECTURE.md §7.3
    rl_per_minute: int = 6
    rl_per_hour: int = 30
    rl_per_day: int = 100

    @property
    def cors_origins_list(self) -> list[str]:
        return [o.strip() for o in self.cors_origins.split(",") if o.strip()]


@lru_cache
def get_settings() -> Settings:
    return Settings()
