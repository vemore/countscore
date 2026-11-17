# Merges on main are not deployed to production

- **Noted:** 2026-11-17 — the ship-parallel session that merged them ran without `backend/scripts/deploy.env` (no route to the NAS)
- **Theme:** deploy-safety
- **Area:** backend | web
- **Blocks release:** yes — the app's sync pushes `max_rounds`, which an undeployed server drops; the Android release must wait for the backend

| Squash sha | Pull request | Needs |
|---|---|---|
| `29ad3cf` | #269 feat: a game type can end after a maximum number of rounds; Chouineurs is built in | **backend with Alembic** `0007_game_type_max_rounds`, then **PWA** |

**Fix:** from a session that can reach the NAS, deploy `origin/main` — backend first
(`backend-deploy` skill, `alembic upgrade head` included), then the PWA (`web-deploy`). One
deploy covers every sha listed. Smoke-test: `/health`; the PWA loads; in the game-type
editor, set "Nombre de manches maximum" on a type, play to the limit and see the end screen
and the "Tour n/N" header; Chouineurs is listed among the built-in types.

**Acceptance:**
- `alembic current` on the NAS prints `0007_game_type_max_rounds`.
- `/health` is OK and the PWA served is built from a commit at or after `29ad3cf`.
- The smoke test above passes; close this entry naming the deployed sha.
