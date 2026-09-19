# The PWA's fallback-font cache is never pruned

- **Noted:** 2026-09-19 — while writing feat/pwa-offline-service-worker
- **Theme:** web
- **Area:** web
- **Blocks release:** no

`web/service_worker.js` keeps the engine's fallback fonts in `countscore-fonts`, a cache shared
by every build because the font paths are versioned (`notosanssc/v37/…`). Build caches are
deleted on activation; this one never is. A Flutter upgrade that moves a family to a new
version (`v37` → `v38`) leaves the old slices in every browser that used them — a few hundred
KB per language, forever, counted against the origin's storage quota.

**Fix:** have `scripts/build_web.sh` inject the font paths the build names (the list it
already reads from `main.dart.js`, 725 paths, ~60 KB — or a digest of the list plus the
list in a separate `fallback-fonts/index.json`), and delete the `countscore-fonts` entries
outside it on activation.

**Acceptance:**
- After an update whose build names a different set of font paths, `countscore-fonts` holds no path the new build does not name.
- A font still named by the new build survives the update (no re-download).
