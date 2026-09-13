---
name: web-deploy
description: Build and publish the CountScore PWA (Flutter web) to a Synology Web Station folder served under a sub-path — base href, leak and binary checks, tar-over-ssh upload, atomic swap, rollback. Use when shipping the web app, changing where it is served, rolling back a bad web release, or diagnosing a PWA that loads blank or 404s its assets in production. Triggers: "deploy the PWA", "déployer la PWA", "publish the web app", "deploy_web", "base-href", "web rollback", "Web Station web app".
---

# Deploying the CountScore PWA

Target: the folder, sub-path and SSH alias named in `scripts/deploy_web.env` — untracked,
because it is one person's infrastructure and this repository is public. Copy
`scripts/deploy_web.env.example` if it is missing. **Never commit a real host, path or URL**
into the script, this skill, the wiki or the README: they carry placeholders only.

Web-specific rules (the tracked binaries, `DriftWebOptions`, `kIsWeb`) are in
`.claude/rules/web.md`; the facts are in `.llmwiki/Web.md` and `.llmwiki/Deployment.md`.
The backend is a separate deploy — see the `backend-deploy` skill.

## What the script does

`scripts/deploy_web.sh`:

1. Validates `WEB_NAS_DIR` (plain absolute path, ≥ 2 levels) and `WEB_BASE_HREF`
   (leading and trailing `/`).
2. `flutter build web --release --no-tree-shake-icons --base-href=$WEB_BASE_HREF` — no
   `BACKEND_URL`, the backend is a user setting.
3. Refuses to publish if `build/web` holds any `.md` file, or lacks `index.html`,
   `main.dart.js`, `sqlite3.wasm` or `drift_worker.js`.
4. Streams `build/web` as a tarball over ssh (scp is blocked on the NAS) into
   `$WEB_NAS_DIR.new`, makes it world-readable, then swaps: current → `.prev`, `.new` →
   current. One previous release is kept.

## 1. One-time setup

- `scripts/deploy_web.env` filled in from the example.
- The SSH user behind `NAS_SSH` can create and rename directories in the **parent** of
  `WEB_NAS_DIR` (the swap renames the folder itself, not only its contents).
- Web Station serves `WEB_NAS_DIR` at `WEB_BASE_HREF`, over the existing TLS certificate.
  **The sub-path and the folder must agree**: a build whose base href differs from the
  path it is served at loads `index.html` and then 404s every asset — a blank page.
  The DSM steps are not scripted; record them in `.llmwiki/Deployment.md` the first time
  they are done rather than rediscovering them.

## 2. Pre-flight

```bash
flutter analyze
flutter test
scripts/deploy_web.sh --dry-run    # builds, runs the checks, prints the remote commands
```

If `web/drift_worker.js` or `web/sqlite3.wasm` changed since the last release, run the web
e2e first (`.llmwiki/Testing.md`) — their failures only surface at runtime.

## 3. Deploy

```bash
scripts/deploy_web.sh
```

This is outward-facing: it replaces what users load. Confirm with the user before running it.

## 4. Verify

```bash
source scripts/deploy_web.env
curl -sI "$WEB_PUBLIC_URL"                  # 200
curl -sI "${WEB_PUBLIC_URL}sqlite3.wasm" | grep -i content-type   # application/wasm
curl -sI "${WEB_PUBLIC_URL}drift_worker.js" # 200
```

Then open the URL in a browser: the home screen renders, the console shows no drift or wasm
error, and a game created before a reload is still there after it. A blank page with
asset 404s is a base-href/sub-path mismatch; a crash at startup with assets loading fine
points at `connection_web.dart` (see `.claude/rules/web.md`).

Things that look like a failed deploy and are not:

- **An old version keeps loading.** Flutter's service worker serves the cached release;
  a second reload, or closing the installed PWA, picks up the new one.
- **The ZapZap analysis fails in the browser only.** The backend's `CORS_ORIGINS` must list
  the PWA's **origin** (scheme + host + port, no path). A PWA on the API's own host is
  same-origin and needs nothing. An `https` PWA cannot call an `http` backend at all.

## 5. Rollback

```bash
scripts/deploy_web.sh --rollback
```

Swaps `.prev` back in; the release it replaces becomes `.prev`, so running it twice returns
to where you started. There is no history beyond one release — to go further back, check
out the commit and deploy it.

## Checklist

- [ ] `flutter analyze` and `flutter test` green
- [ ] `--dry-run` passes: no `.md` in the build, both binaries present
- [ ] Web e2e run if either web binary changed
- [ ] User confirmed before the real deploy
- [ ] `sqlite3.wasm` served as `application/wasm`
- [ ] Data survives a reload on the deployed URL
- [ ] No host, path or URL of the real deployment added to a tracked file
