# `.llmwiki/MobileApp.md` counts files, and the counts rot without anyone noticing

- **Noted:** 2026-09-16 — while adding `lib/utils/` for the bottom-inset fix
- **Theme:** docs
- **Area:** docs
- **Blocks release:** no

The page opened with "49 Dart files under `lib/`". The real number on `main` before that
change was **60** tracked `.dart` files (`git ls-files lib | grep -c '\.dart$'`), so the
figure had been wrong by eleven for an unknown number of pull requests. It was corrected to
61 in `fix/bottom-inset-scrollables`, but the same page carries a second count that is still
false and that the change did not touch:

> ``lib/widgets/` holds exactly one component: `player_picker_dialog.dart` (291 l.).`

`lib/widgets/` has **three**: `player_picker_dialog.dart`, `group_devices_sheet.dart` and
`group_settings_section.dart`. The per-screen line counts in the same section are of the same
family: they are true only on the day they are written.

A count of files is a fact no reader ever needs and no change ever remembers to update; it is
the one kind of fact the wiki's "verify against the source" rule cannot save, because nothing
points at a source line.

**Fix:** drop the bare counts from `.llmwiki/MobileApp.md` — the `lib/` file total, the
`lib/widgets/` "exactly one", and the `(N l.)` sizes next to each screen and provider — and
name what each directory *holds* instead. Keep the counts that carry meaning and are pinned
by code (the 10 supported locales, the 6 providers wired in `main.dart`). Check the other
pages for the same pattern while there ([[I18n]]'s key count is pinned by
`.claude/hooks/arb_keys.py`, so it is fine).
