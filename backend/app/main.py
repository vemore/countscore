"""FastAPI application entry point."""

from __future__ import annotations

import logging
from contextlib import asynccontextmanager

from fastapi import FastAPI, Request, status
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse
from pydantic import BaseModel

from app import __version__
from app.config import get_settings
from app.routes import comments, groups, sync
from app.services.llm import get_llm_provider

logger = logging.getLogger(__name__)

# Swagger loads its bundle from a CDN, so the JSON-only CSP below would blank it out.
_DOCS_PATHS = frozenset({"/docs", "/redoc", "/openapi.json"})
_BODY_METHODS = frozenset({"POST", "PUT", "PATCH"})


@asynccontextmanager
async def lifespan(app: FastAPI):
    settings = get_settings()
    logging.basicConfig(
        level=settings.log_level,
        format="%(asctime)s %(levelname)s [%(name)s] %(message)s",
    )
    logging.getLogger("uvicorn.access").setLevel(logging.WARNING)
    yield


class LlmHealth(BaseModel):
    """The ZapZap provider as the running process resolved it."""

    provider: str
    model: str | None = None
    # Named for what it actually proves: a key is present. It is NOT a promise the
    # model can be called — the 2026-09-09 outage ran for two days with this true.
    credentials: bool = False


class HealthResponse(BaseModel):
    status: str = "ok"
    version: str = __version__
    llm: LlmHealth


def _llm_health() -> LlmHealth:
    """Resolve the provider's configuration without calling it.

    An unknown LLM_PROVIDER makes the factory raise ValueError; that must not take
    /health down with it, so it is reported as an unresolvable model instead.
    """
    name = get_settings().llm_provider
    try:
        provider = get_llm_provider()
    except ValueError:
        logger.warning("unknown LLM_PROVIDER %r", name)
        return LlmHealth(provider=name)
    return LlmHealth(provider=name, model=provider.model, credentials=provider.available)


def create_app() -> FastAPI:
    settings = get_settings()
    app = FastAPI(
        title="CountScore Backend",
        version=__version__,
        lifespan=lifespan,
    )

    app.add_middleware(
        CORSMiddleware,
        allow_origins=settings.cors_origins_list,
        allow_credentials=False,
        allow_methods=["GET", "POST", "PATCH", "DELETE"],
        allow_headers=["Authorization", "Content-Type"],
    )

    max_body_bytes = settings.max_body_bytes
    hsts_enabled = settings.hsts_enabled

    @app.middleware("http")
    async def limit_body_size(request: Request, call_next):
        cl = request.headers.get("content-length")
        if cl is None:
            # No Content-Length means a chunked body, whose size we cannot check up
            # front — the cap would be trivially bypassable. This API only ever takes
            # small JSON documents, so requiring the header costs nothing.
            if request.method in _BODY_METHODS:
                return JSONResponse(
                    {"detail": "Content-Length required"},
                    status_code=status.HTTP_411_LENGTH_REQUIRED,
                )
        elif cl.isdigit() and int(cl) > max_body_bytes:
            return JSONResponse(
                {"detail": "request body too large"},
                status_code=status.HTTP_413_CONTENT_TOO_LARGE,
            )
        return await call_next(request)

    @app.middleware("http")
    async def security_headers(request: Request, call_next):
        response = await call_next(request)
        response.headers["X-Content-Type-Options"] = "nosniff"
        response.headers["X-Frame-Options"] = "DENY"
        response.headers["Referrer-Policy"] = "no-referrer"
        response.headers["Cross-Origin-Opener-Policy"] = "same-origin"
        if request.url.path in _DOCS_PATHS:
            response.headers["Content-Security-Policy"] = (
                "default-src 'self'; script-src 'self' https://cdn.jsdelivr.net "
                "'unsafe-inline'; style-src 'self' https://cdn.jsdelivr.net "
                "'unsafe-inline'; img-src 'self' https://fastapi.tiangolo.com data:"
            )
        else:
            # The API answers JSON and nothing else: it needs to load nothing at all.
            response.headers["Content-Security-Policy"] = (
                "default-src 'none'; frame-ancestors 'none'"
            )
        if hsts_enabled:
            response.headers["Strict-Transport-Security"] = "max-age=31536000; includeSubDomains"
        return response

    app.include_router(groups.router)
    app.include_router(sync.router)
    app.include_router(comments.router)

    @app.get("/health", tags=["meta"])
    async def health() -> HealthResponse:
        """Liveness probe, plus the *resolved* LLM configuration.

        `status` stays "ok" even when the LLM is misconfigured: this endpoint is what
        the container healthcheck polls every 30 s, and failing it would restart-loop
        the service over a configuration mistake. The `llm` block is a diagnostic.

        It reports the model id because that is the fact that was invisible during the
        2026-09-09 outage — `credentials` only proves a key is set, never that the
        account's tier may call the model. No request is made to the provider: building
        the instance is pure local construction. The model id is not a secret; every
        successful analysis already returns it.
        """
        return HealthResponse(llm=_llm_health())

    return app


app = create_app()
