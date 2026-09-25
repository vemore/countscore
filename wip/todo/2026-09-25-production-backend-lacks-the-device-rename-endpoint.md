# Production runs a backend from before #214: renaming a device fails with "Erreur du serveur"

- **Noted:** 2026-09-25 — testing `main` (05894ee) on the Pixel
- **Theme:** deploy-safety
- **Area:** backend
- **Blocks release:** yes — any client built from `main` shows Settings → Group → nickname
  edit, and every save fails against production

On the Pixel, Settings → Groupe → edit nickname → "Vincent-P9" → OK shows the snackbar
"Erreur du serveur". Production answers `404` to `PATCH /groups/devices/me`: the `countscore`
container was created on 2026-09-20 09:26, and the PWA folder on the NAS dates from
2026-09-22. #212 to #215 were squash-merged after that, but nothing was deployed, although
CLAUDE.md and `ship-parallel` make deploying part of every merge.

**Fix:** deploy the backend (`backend-deploy`, **with `alembic upgrade`**: #216 added revision
`0006_game_type_keypad_shortcut`, so the "no Alembic revision" of the first draft no longer
holds) and the PWA (`web-deploy`) from current `main`.

**Cause (2026-09-25, from the user):** the `ship-parallel` run that merged #212 to #216 ran in
a cloud session, which cannot reach the NAS: the deploy step could not run, and nothing said
so. Make that step impossible to skip silently — `ship-parallel` checks at planning time
whether this session can reach the deploy host, and when it cannot, the merge step reports
"merged, not deployed" and files (or updates) a `wip/todo/` entry naming the undeployed shas,
so the next local session deploys them.

**Acceptance:**
- `PATCH /groups/devices/me` on production answers 401 without a token, not 404.
- Renaming the Pixel's nickname from Settings succeeds, and the new name appears in
  Settings → Groupe → Appareils on another device.
- The production PWA serves the build of the deployed sha.
- `ship-parallel` run from a session that cannot reach the NAS ends with "merged, not
  deployed" and a `wip/todo/` entry, not with a silent success.
