# The PWA's icons are still the stock Flutter logo

- **Noted:** 2026-09-20 — while auditing the app icon before proposing replacements
- **Theme:** web
- **Area:** web
- **Blocks release:** no — it is not a store-policy, security, crash or data-loss fault,
  so it lands here by `wip/README.md`'s rule; it is however visible on production today

`web/icons/Icon-192.png`, `Icon-512.png`, `Icon-maskable-192.png`, `Icon-maskable-512.png`
and `web/favicon.png` are the blue Flutter "F" from the project template. They have never
been regenerated: the browser tab, the installed PWA and the Android "add to home screen"
shortcut have never shown CountScore's own icon.

`pubspec.yaml:134-140` configures `flutter_launcher_icons` with `android: true, ios: false`.
The package does not emit web icons at all, so no step in the pipeline ever writes these five
files. `.llmwiki/Release.md:104-109` and `.claude/skills/release-android/SKILL.md:322-328`
both say "replace `store_listing/assets/icon_512.png`, then `dart run flutter_launcher_icons`"
— true for Android, silently incomplete for the web build.

`wip/done/2026-09-19-pwa-shell-still-says-flutter-template-and-offline.md` fixed the
manifest's `theme_color`, title and description but did not touch the icon files.

**Fix:** generate the five web files from the same source as the Android icons, and add the
step to the icon procedure in `.llmwiki/Release.md` so it cannot be missed again. The
maskable pair needs its own safe-zone framing (80% circle), not a copy of the flat icon.

**Acceptance:**
- `web/icons/*.png` and `web/favicon.png` show the app's icon, not the Flutter logo.
- The two `Icon-maskable-*.png` keep their whole subject inside the 80% safe circle.
- `.llmwiki/Release.md`'s icon section names the web step, and its `Updated:` date moves.
- A production smoke test shows the icon in the browser tab and in the installed PWA.
