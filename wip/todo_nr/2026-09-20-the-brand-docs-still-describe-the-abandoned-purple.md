# The brand documents still describe the abandoned purple identity

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

**Fix:** delete both guides rather than rewrite them. `ICON_DESIGN_GUIDE.md` is 613 lines of
generic advice — where to find Figma, how to export a PNG — wrapped around a concept list
that was never used; the palette's real home is `app_theme.dart`, and the icon's constraints
belong in `.llmwiki/Release.md` beside the regeneration command. Redraw the feature graphic
in the brand teal (`store_listing/FEATURE_GRAPHIC_TEMPLATES.md` Template 1, Pillow), and
reword the `app_theme.dart` comment so it does not depend on the icon depicting a podium.

**Acceptance:**
- `grep -rn 673AB7 store_listing/` returns nothing but the game-type default in `lib/`.
- The feature graphic published for every locale is teal.
- `.llmwiki/StoreListing.md` no longer points at the deleted guides, and its `Updated:` moves.
