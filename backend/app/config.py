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
