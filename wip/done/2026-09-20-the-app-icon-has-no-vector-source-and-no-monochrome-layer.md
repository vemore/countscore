# The app icon has no vector source, no monochrome layer, and a white adaptive background

**Status:** dropped (2026-09-20) — merged into [[2026-09-20-the-app-icon-does-not-say-what-the-app-does]]. Three of the four acceptance criteria below are closed verbatim by that entry's work (an SVG source plus a documented regeneration command, nothing clipped under a circular mask, `.llmwiki/Release.md` matching the new procedure). The fourth is **contradicted rather than met**: it asks for a teal launcher tile, but the chosen artwork's `chosen-adaptive-bg.svg` is a single fill `#0E1716` — the ink of the ensemble. The survivor carries that criterion reworded to brand ink, so nothing here is lost.


- **Noted:** 2026-09-20 — while auditing the app icon before proposing replacements
- **Theme:** visual-refresh
- **Area:** android
- **Blocks release:** no

Three faults in how the icon is authored and wired, all independent of what it depicts:

1. **No vector source.** `store_listing/assets/icon_512.png` is the only original — a
   hand-supplied raster committed once in `75dc8f6 "Update app icon"`, with no provenance or
   attribution recorded anywhere. There is no SVG in the repository. Any change to the
   artwork means redrawing it from nothing.
2. **The adaptive foreground is the full-bleed icon.** `pubspec.yaml:139` passes the same
   512 PNG as `adaptive_icon_foreground`, and `mipmap-anydpi-v26/ic_launcher.xml` insets it
   16%. Android's circular mask therefore clips the artwork's corners, because the content
   was never laid out inside the 66% safe circle.
3. **No `monochrome` layer and a white background.** `grep -rn monochrome` over `android/`
   and `pubspec.yaml` returns nothing, so Android 13+ themed icons fall back to a shrunken
   colour icon. `android/app/src/main/res/values/colors.xml` sets
   `ic_launcher_background` to `#FFFFFF`, not the brand teal — a white tile on every launcher.

**Fix:** author the icon as SVG in two named layers (`#bg`, `#fg`) and generate the flat
icon, the adaptive foreground and the monochrome layer from it. Lay the subject inside the
66% safe circle. Set `adaptive_icon_background` to the brand teal and add
`adaptive_icon_monochrome`. The monochrome layer cannot be derived by flattening every shape
to one colour — a shape that reads through a second colour has to be knocked out or cut free
with a hairline, or it disappears into its neighbour.

**Acceptance:**
- An SVG source is committed, and a documented command regenerates every raster from it.
- No artwork is clipped under a circular mask (verified on a rendered masked icon).
- The launcher tile is brand teal, not white, and a themed icon renders legibly.
- `.llmwiki/Release.md`'s icon section matches the new procedure.

**Open question:** which candidate the icon becomes — see the five proposals of 2026-09-20.
