# The first game's default name is a hardcoded French "Partie 1"

- **Noted:** 2026-09-19 — while redrawing the New game screen (feat/new-game-screen)
- **Theme:** i18n
- **Area:** app
- **Blocks release:** no

`lib/screens/create_game_screen.dart` (`_loadData`) prefills the name of the first game ever
created with the literal `'Partie 1'`, in every language; later games count on from the last
name (`nextGameName`, `lib/utils/play_again.dart`). A German or Japanese user starts with a
French name. `integration_test/app_test.dart` waits for the literal `Partie 1`, and
`.llmwiki/Testing.md` calls it locale-proof.

**Fix:** an ICU key such as `defaultGameName` ("Partie {number}") in the ten ARB files, used
for the first game; the e2e test then waits on the name field's key rather than its text.

**Acceptance:**
- `grep -n "'Partie 1'" lib/` finds nothing.
- A widget test in `en` shows "Game 1" as the first game's name.
