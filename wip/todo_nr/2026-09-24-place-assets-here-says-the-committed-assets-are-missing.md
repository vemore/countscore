# `store_listing/assets/PLACE_ASSETS_HERE.md` says the committed assets are still to be made

- **Noted:** 2026-09-24 — while cutting `ASSET_REQUIREMENTS.md` down (docs/readme-and-asset-requirements)
- **Theme:** docs
- **Area:** docs
- **Blocks release:** no

`store_listing/assets/PLACE_ASSETS_HERE.md` opens with "Place your created visual assets in
this directory", its *Current Status* lists `icon_512.png` and `feature_graphic.png` as
unchecked, and it ends "Once you've created the assets, place them in this directory and
remove this file". Both files are committed and **generated** (`scripts/generate_icons.py`,
`scripts/generate_feature_graphic.py`), and must never be placed by hand. Its specifications
also repeat, a third time, what `store_listing/ASSET_REQUIREMENTS.md` and
`.llmwiki/StoreListing.md` state.

**Fix:** delete the file, as it asks; `store_listing/README.md` and
`.llmwiki/StoreListing.md` already say what `assets/` holds and which script writes each file.

**Acceptance:**
- `store_listing/assets/PLACE_ASSETS_HERE.md` does not exist.
- `grep -rn PLACE_ASSETS_HERE .` finds no reference outside `wip/`.
