# Every self-hosting user deploys this image, so it is built to be safe by default:
# dependencies come from uv.lock, no compiler reaches the final image, and the
# process does not run as root.

# ---------------------------------------------------------------- builder
FROM python:3.13-slim AS builder

COPY --from=ghcr.io/astral-sh/uv:0.12.6 /uv /bin/uv

# The venv is created at the path it will have in the runtime stage: its scripts
# (uvicorn, alembic) carry an absolute shebang.
ENV UV_COMPILE_BYTECODE=1 \
    UV_LINK_MODE=copy \
    UV_PYTHON_DOWNLOADS=0 \
    UV_PROJECT_ENVIRONMENT=/app/.venv

WORKDIR /app

# Dependencies only (--no-install-project): the app is imported from /app, as
# before, and building the project itself would need the README.md that
# .dockerignore keeps out. --locked refuses a uv.lock stale against pyproject.toml;
# --no-dev leaves out pytest, ruff, mypy and testcontainers.
COPY pyproject.toml uv.lock ./
RUN --mount=type=cache,target=/root/.cache/uv \
    uv sync --locked --no-dev --no-install-project

# ---------------------------------------------------------------- runtime
FROM python:3.13-slim AS runtime

ENV PYTHONUNBUFFERED=1 \
    PYTHONDONTWRITEBYTECODE=1 \
    PATH=/app/.venv/bin:$PATH

RUN groupadd --system --gid 10001 app \
    && useradd --system --uid 10001 --gid app --home-dir /nonexistent --no-create-home \
       --shell /usr/sbin/nologin app

WORKDIR /app

# Owned by root and not writable by `app`: the service writes nothing to its own
# filesystem, so a compromised process cannot rewrite its code either.
COPY --from=builder /app/.venv /app/.venv
COPY app ./app
COPY alembic ./alembic
COPY alembic.ini ./

USER app

EXPOSE 8000

# One worker, deliberately: ip_rate_limiter and ws_ticket keep state in process memory,
# so a second worker doubles the effective rate limit and drops WS tickets. See rule 2
# in backend/CLAUDE.md before raising this.
CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8000", "--workers", "1"]
