"""FastAPI application entry point."""
from __future__ import annotations

import logging
from contextlib import asynccontextmanager

from fastapi import FastAPI, Request, status
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse

from app import __version__
from app.config import get_settings
from app.routes import comments, groups, sync

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
            response.headers["Strict-Transport-Security"] = (
                "max-age=31536000; includeSubDomains"
            )
        return response

    app.include_router(groups.router)
    app.include_router(sync.router)
    app.include_router(comments.router)

    @app.get("/health", tags=["meta"])
    async def health() -> dict[str, str]:
        return {"status": "ok", "version": __version__}

    return app


app = create_app()
