# No feature graphic in `store_listing/assets/`

- **Noted:** 2026-09-13 — while listing the store assets for the Console brief
- **Theme:** store-listing
- **Area:** android
- **Blocks release:** yes — Play requires a 1024×500 feature graphic

`store_listing/assets/` has only `icon_512.png` and phone screenshots; `PUBLISHING.md` §2
names the graphic. None of the eight screenshots shows group sharing either.

**Fix:** commit `store_listing/assets/feature_graphic.png` from the brief in
`store_listing/FEATURE_GRAPHIC_TEMPLATES.md`, and add it to what
`.claude/skills/release-android/scripts/stage_handoff.sh` copies into the hand-off folder.
