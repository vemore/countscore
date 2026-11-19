# A backend deploy starts the new code before it migrates the schema

- **Noted:** 2026-09-25 — comparing the NAS deploy with standard deployment practice
- **Theme:** deploy-safety
- **Area:** backend
- **Blocks release:** no

`backend/scripts/deploy_nas.sh:86` runs `docker compose pull && docker compose up -d`, and
only then takes the pre-migration dump (`:98-112`) and runs `alembic upgrade head` inside the
already-replaced `api` container (`:117`). Between the two, the new code serves the old
schema; if the upgrade fails, it keeps serving it, and the old image is gone from the
container. The pre-migration dump is also taken while the new code is already writing.

Standard practice is the reverse order: dump, migrate from a one-off container, then swap
the app — and keep each revision backward compatible with the code still running
(expand/contract: add first, drop in a later release).

**Fix:** in `deploy_nas.sh`, after `pull`: read `alembic current`/`heads` with
`docker compose run --rm api alembic …`, take the dump, run
`docker compose run --rm api alembic upgrade head`, and only then `docker compose up -d`.
A failed dump or upgrade stops before the swap, leaving the old container serving. Write the
expand/contract rule into the `db-migration` skill and `.llmwiki/Deployment.md`.

**State of the art** (web search, 2026-09-26): the expand/contract pattern is the standard
answer — add new structure first (expand), deploy code that tolerates both old and new
schema, then remove the old structure later (contract) — always migrating before the new
code serves traffic, and keeping each revision backward compatible with the release still
running. The fix here matches the order (migrate in a one-off container, then swap) but
folds expand and contract into the same single-service deploy rather than separate releases,
the accepted simplification for one backend with a single deployed version rather than a
rolling multi-instance rollout.
Sources: [Reliable Penguin, expand/contract in practice](https://blogs.reliablepenguin.com/2025/11/16/database-migrations-without-drama-expand-contract-in-practice),
[Tim Wellhausen, Expand and Contract](https://www.tim-wellhausen.de/papers/ExpandAndContract/ExpandAndContract.html).

**Acceptance:**
- In `deploy_nas.sh`, `alembic upgrade head` runs before any `docker compose up -d`.
- A deploy whose upgrade fails leaves the previous `api` container running (checked by
  forcing a failing revision against a local compose stack).
- The `db-migration` skill states that a revision must not break the previous release's code.
