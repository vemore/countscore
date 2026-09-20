# The brand documents still describe the abandoned purple identity

**Status:** done (2026-09-20) — closed by docs/brand-guides. `ICON_DESIGN_GUIDE.md` (612
lines) and `COLOR_THEME_GUIDE.md` (414) deleted; the purple repainted teal in
`FEATURE_GRAPHIC_TEMPLATES.md` and `ASSET_CREATION_CHECKLIST.md`, whose pointers at the two
guides are gone, as are `store_listing/README.md`'s. `store_listing/assets/feature_graphic.png`
is redrawn in the brand teal around the new cards-and-pawns icon, by the new
`scripts/generate_feature_graphic.py` (Template 1, Pillow, `--check` to verify) from committed
inputs only — no locale has an override, so all ten publish it, once the user asks for a
listing publish. `lib/utils/app_theme.dart:5` no longer sources the teal from a podium, and
the two `.llmwiki/MobileApp.md` lines that repeated that claim are corrected;
`.llmwiki/StoreListing.md` records the decision.

- **Noted:** 2026-09-20 — while auditing the app icon before proposing replacements
- **Theme:** docs
- **Area:** docs
- **Blocks release:** no

`store_listing/ICON_DESIGN_GUIDE.md` (613 lines) and `store_listing/COLOR_THEME_GUIDE.md`,
both dated 9 November 2025, specify Deep Purple `#673AB7` as the brand colour and propose six
purple icon concepts. The app moved to teal on 2026-09-18
(`wip/done/2026-09-18-app-theme-is-default-deep-purple.md`): `lib/utils/app_theme.dart:9-15`
is `#0E8F88` / `#5ED8CF` / gold `#F2B705`. Neither guide was updated, so a reader following
them produces the wrong colours.

`store_listing/assets/feature_graphic.png` is still purple too, and is what every locale
without its own override publishes on the Play Store.

A related line will go stale with the next icon change: `lib/utils/app_theme.dart:5` says the
teal is "taken from the icon's podium". If the podium goes, that sentence stops being true.

**Wider than first written (2026-09-20, refinement).** `grep -rn 673AB7 store_listing/ lib/`
returns **45** hits, and two of the files carrying them are not named above:
`store_listing/FEATURE_GRAPHIC_TEMPLATES.md` (11) and
`store_listing/ASSET_CREATION_CHECKLIST.md` (3), beside `ICON_DESIGN_GUIDE.md` (18) and
`COLOR_THEME_GUIDE.md` (15). `lib/` has the single expected hit, the game-type default at
`lib/models/game_type.dart:317`. Two more pointers survive the deletion too:
`store_listing/README.md:27-28` and `ASSET_CREATION_CHECKLIST.md:27` both send the reader to
the guides. So the acceptance criterion below was already wider than the fix — the fix is
widened to match rather than the criterion narrowed, because a purple hex left in a template
is the same trap as a purple hex left in a guide.

**Fix:** delete both guides rather than rewrite them; repaint the purple out of
`FEATURE_GRAPHIC_TEMPLATES.md` and `ASSET_CREATION_CHECKLIST.md`, and drop the pointers to the
deleted guides from `store_listing/README.md` and `ASSET_CREATION_CHECKLIST.md`. `ICON_DESIGN_GUIDE.md` is 613 lines of
generic advice — where to find Figma, how to export a PNG — wrapped around a concept list
that was never used; the palette's real home is `app_theme.dart`, and the icon's constraints
belong in `.llmwiki/Release.md` beside the regeneration command. Redraw the feature graphic
in the brand teal (`store_listing/FEATURE_GRAPHIC_TEMPLATES.md` Template 1, Pillow), and
reword the `app_theme.dart` comment so it does not depend on the icon depicting a podium.

**Acceptance:**
- `grep -rn 673AB7 store_listing/` returns nothing, and `lib/`'s only hit stays the
  game-type default at `lib/models/game_type.dart:317`.
- No file points at the two deleted guides (`grep -rn "ICON_DESIGN_GUIDE\|COLOR_THEME_GUIDE"`
  returns nothing outside `wip/`).
- The feature graphic published for every locale is teal.
- `.llmwiki/StoreListing.md` no longer points at the deleted guides, and its `Updated:` moves.
