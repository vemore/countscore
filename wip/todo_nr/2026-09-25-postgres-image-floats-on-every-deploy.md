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

**State of the art** (web search, 2026-09-26): current practice pins a production image to
an exact minor version — ideally its digest too — rather than a floating major tag, and lets
Dependabot or Renovate propose the bump as a reviewed pull request instead of it arriving
silently on the next `pull`. The fix matches this directly — pin to a minor/Alpine release,
add the `docker` ecosystem to `dependabot.yml` — and already names the digest as the
optional stronger form the state of the art treats as most secure, so there is no departure.
Sources: [Tomoda Hinata, safely updating Docker base images with Dependabot](https://tomodahinata.com/en/blog/dependabot-docker-base-image-digest-pinning-updates-guide),
[OneUptime, pinning package versions for reproducible builds](https://oneuptime.com/blog/post/2026-02-08-how-to-pin-package-versions-in-dockerfiles-for-reproducible-builds/view).

**Acceptance:**
- `docker-compose.prod.yml` names no floating Postgres tag.
- `dependabot.yml` covers the backend Dockerfiles and compose file.
