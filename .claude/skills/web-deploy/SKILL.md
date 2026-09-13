---
name: web-deploy
description: Build and publish the CountScore PWA (Flutter web), which the backend container serves under PWA_BASE_PATH on its own host — base href read from the NAS .env, leak and binary checks, tar-over-ssh upload, rename swap, rollback. Use when shipping the web app, changing its sub-path, rolling back a bad web release, or diagnosing a PWA that loads blank, 404s its assets or hits a CSP error in production. Triggers: "deploy the PWA", "déployer la PWA", "publish the web app", "deploy_web", "base-href", "PWA_BASE_PATH", "web rollback".
---

# Deploying the CountScore PWA

The PWA is served **by the backend's `api` container**, under `PWA_BASE_PATH` (e.g.
`/countscore`) on the backend's own host. Web Station is not involved beyond the portal
that already proxies that host to the container. Same origin as the API: no `CORS_ORIGINS`
entry, no mixed content.

The target is the backend's: `NAS_SSH`, `NAS_DEPLOY_DIR` and `PUBLIC_URL` come from the
untracked `backend/scripts/deploy.env`. **Never commit a real host, path or URL** into the
script, this skill, the wiki or the README — placeholders only.

Facts: `.llmwiki/Deployment.md` (topology, decisions), `.llmwiki/Api.md` (route behaviour),
`.llmwiki/Security.md` (CSP). Web rules: `.claude/rules/web.md`. Backend procedure:
`backend-deploy`.

## How the pieces fit

| Piece | Where | Role |
|---|---|---|
| `PWA_BASE_PATH` | NAS `$NAS_DEPLOY_DIR/.env` — **its only home** | The container mounts the PWA there; `deploy_web.sh` reads it over ssh for `--base-href` |
| `pwa/current` | `$NAS_DEPLOY_DIR/pwa/` on the NAS | The live build. `pwa/` is bind-mounted read-only at `/srv/pwa` |
| `_mount_pwa` / `_PWA_CSP` | `backend/app/main.py` | Static mount + the CSP and `Cache-Control: no-cache` for those paths |
| `scripts/deploy_web.sh` | repo | Build, check, upload to `pwa/current.new`, rename swap, keep `pwa/current.prev` |

## 1. One-time setup

1. **Deploy a backend that has the PWA mount** (`docker-compose.prod.yml` with the `./pwa`
   volume, an image with `_mount_pwa`) — the `backend-deploy` skill. `deploy_nas.sh` creates
   `pwa/` as the SSH user; if it ever gets created by Docker instead, it is root-owned and
   the upload fails with a permission error.
2. **Set the sub-path in the NAS `.env`**, following *Changing one variable in place* in
   `backend-deploy` (read first, then append, then `docker compose up -d`):

   ```bash
   source backend/scripts/deploy.env
   ssh "$NAS_SSH" "grep -n PWA_BASE_PATH $NAS_DEPLOY_DIR/.env" || echo "not set"
   echo 'PWA_BASE_PATH=/countscore' | ssh "$NAS_SSH" "cat >> $NAS_DEPLOY_DIR/.env"
   ```

   Leading slash, no trailing slash. A value the backend refuses (malformed, or whose first
   segment is an API route such as `/groups` or `/health`) stops the container from
   starting — check `/health` right after.

## 2. Pre-flight

```bash
flutter analyze
flutter test
scripts/deploy_web.sh --dry-run    # reads PWA_BASE_PATH, builds, checks, prints remote commands
```

If `web/drift_worker.js` or `web/sqlite3.wasm` changed since the last release, run the web
e2e first (`.llmwiki/Testing.md`) — their failures only surface at runtime.

## 3. Deploy

```bash
scripts/deploy_web.sh
```

Outward-facing: it replaces what users load. **Confirm with the user before running it.**
No container restart is needed — the backend reads the folder on every request.

## 4. Verify

```bash
source backend/scripts/deploy.env
BASE=/countscore   # the PWA_BASE_PATH you set
curl -sI "$PUBLIC_URL$BASE/" | grep -i -e '^HTTP' -e content-security-policy   # 200 + wasm-unsafe-eval
curl -sI "$PUBLIC_URL$BASE/sqlite3.wasm" | grep -i content-type               # application/wasm
curl -s  "$PUBLIC_URL/health"                                                 # API unaffected
```

Then open `$PUBLIC_URL$BASE/` in a browser: home screen renders, no CSP or wasm error in the
console, and a game created before a reload is still there after it.

Symptoms and causes:

- **404 on `$BASE/`** — `PWA_BASE_PATH` not set in the container (`docker compose up -d`
  after editing `.env`), or no build in `pwa/current` yet.
- **Blank page, assets 404** — the build's base href differs from the served path. Cannot
  happen through the script (it reads the same value); a hand-built upload can do it.
- **CSP violation in the console** — Flutter started loading something `_PWA_CSP` does not
  allow (a new CDN host after an SDK upgrade, typically). Fix the policy in
  `backend/app/main.py` with a test, not by loosening `default-src`.
- **An old version keeps loading** — Flutter's service worker; a second reload picks up the
  new release. Responses carry `Cache-Control: no-cache`, so HTTP caching is not the cause.

## 5. Rollback

```bash
scripts/deploy_web.sh --rollback
```

Swaps `pwa/current.prev` back; the release it replaces becomes `.prev`, so running it twice
returns to where you started. One release of history only — to go further back, check out
the commit and deploy it. A backend rollback (`deploy_nas.sh --rollback`) does not touch the
PWA folder, but an image older than the PWA mount stops serving it.

## Checklist

- [ ] `flutter analyze` and `flutter test` green
- [ ] `--dry-run` passes: base path read from the NAS, no `.md` in the build, both binaries present
- [ ] Web e2e run if either web binary changed
- [ ] User confirmed before the real deploy
- [ ] `$BASE/` answers 200 with the PWA CSP, `sqlite3.wasm` as `application/wasm`, `/health` still ok
- [ ] Data survives a reload on the deployed URL
- [ ] No host, path or URL of the real deployment added to a tracked file
