# Every backend deploy may upgrade Postgres without anyone deciding it

- **Noted:** 2026-09-25 — comparing the NAS deploy with standard deployment practice
- **Theme:** dependencies
- **Area:** backend
- **Blocks release:** no

`backend/docker-compose.prod.yml:9` runs `postgres:17-alpine`, a moving tag, and
`deploy_nas.sh:86` runs `docker compose pull` for the whole stack. Each deploy therefore
pulls whatever 17.x and Alpine release the tag points at that day, and recreates the `db`
container — a database upgrade folded into an unrelated app deploy, with no changelog read.
`.github/dependabot.yml` has no `docker` ecosystem, so nothing proposes these bumps as pull
requests either. (`Dockerfile.backup` already pins `postgres:17-alpine3.23`.)

**Fix:** pin the `db` image to a minor and Alpine release (e.g. `postgres:17.x-alpine3.23`,
optionally with its digest), limit `pull` to the images the deploy built
(`docker compose pull api db-backup`), and add the `docker` ecosystem for `backend/` to
`dependabot.yml` so upgrades arrive as reviewed pull requests. Keep the backup image's
`pg_dump` major equal to the server's.

**Acceptance:**
- `docker-compose.prod.yml` names no floating Postgres tag.
- `dependabot.yml` covers the backend Dockerfiles and compose file.
