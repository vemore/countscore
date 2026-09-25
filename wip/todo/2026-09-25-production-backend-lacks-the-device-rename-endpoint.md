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

**Fix:** deploy the backend (`backend-deploy`, no Alembic revision since #214) and the PWA
(`web-deploy`) from current `main`. Then find out why the `ship-parallel` run that merged #214
and #215 stopped before its deploy step, and make that step impossible to skip silently —
for instance, have the merge step print "merged, not deployed" until a deploy of that sha is
recorded.

**Acceptance:**
- `PATCH /groups/devices/me` on production answers 401 without a token, not 404.
- Renaming the Pixel's nickname from Settings succeeds, and the new name appears in
  Settings → Groupe → Appareils on another device.
- The production PWA serves the build of the deployed sha.
