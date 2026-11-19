# Merges on main are not deployed to production

**Status:** done (2026-11-19) — deployed at `f5336f4` (a superset of `b972b60`) by the ship-parallel session. Backend: `deploy_nas.sh` (the new migrate-first script, #279) found the schema already at `0007_game_type_max_rounds` and an `api` image built on 2026-11-18, after #269 — the backend part had been deployed in the meantime, and Chouineurs is in the running container. PWA: `deploy_web.sh` published `f5336f4`; the served `service_worker.js` carries the build id of the local build, `/manifest.json` has no `orientation`, `/health` is ok. Not driven in a browser: the end screen / "Tour n/N" header and the landscape layout on a phone.

- **Noted:** 2026-11-17 — the ship-parallel session that merged them ran without `backend/scripts/deploy.env` (no route to the NAS)
- **Theme:** deploy-safety
- **Area:** backend | web
- **Blocks release:** yes — the app's sync pushes `max_rounds`, which an undeployed server drops; the Android release must wait for the backend

| Squash sha | Pull request | Needs |
|---|---|---|
| `29ad3cf` | #269 feat: a game type can end after a maximum number of rounds; Chouineurs is built in | **backend with Alembic** `0007_game_type_max_rounds`, then **PWA** |
| `ec1b255` | #273 feat: a compact landscape layout for the board, home and the statistics | **PWA** (new `web/manifest.json`, no `orientation`) |
| `b972b60` | #275 feat: in landscape the board's order switch sits in the app bar and the rows board packs more rounds | **PWA** |

**Fix:** from a session that can reach the NAS, deploy `origin/main` — backend first
(`backend-deploy` skill, `alembic upgrade head` included), then the PWA (`web-deploy`). One
deploy covers every sha listed. Smoke-test: `/health`; the PWA loads; in the game-type
editor, set "Nombre de manches maximum" on a type, play to the limit and see the end screen
and the "Tour n/N" header; Chouineurs is listed among the built-in types; on a phone held sideways, the PWA rotates and the board shows the compact landscape layout (round button in a side rail); in the one-row-per-player view the Ordre de jeu / Classement switch is in the app bar beside the game name and 7 or more rounds show.

**Acceptance:**
- `alembic current` on the NAS prints `0007_game_type_max_rounds`.
- `/health` is OK and the PWA served is built from a commit at or after `ec1b255`.
- The smoke test above passes; close this entry naming the deployed sha.
