# The keypad and the home hero show one-letter avatars, and the keypad's Save label wraps

**Status:** done (2026-09-19) — closed by fix/player-avatars-colours-keypad. The keypad chips always draw two letters, `PlayerAvatarStack` (the home hero and game list) defaults to two, and the hero rings its avatars in its text colour so a cyan disc no longer vanishes into the teal card; the tall key's label is a `FitWordsText` that shrinks rather than breaking a word; the digit grid is laid out in `Directionality(ltr)`. Tests: `test/widgets/score_keypad_sheet_test.dart`, `test/screens/home_screen_resume_test.dart`.

- **Noted:** 2026-09-19 — full test pass of the production PWA (fresh Chromium profiles, Playwright, fr-FR at 412 × 860)
- **Theme:** visual-refresh
- **Area:** app
- **Blocks release:** no

The board uses two-letter avatars (`lib/widgets/player_avatars.dart`), so Lionel is "Li" and
Laurent is "La". Other screens draw one letter:
- **The keypad sheet's player chips** show "L Lionel", "L Laurent"
  ([capture](../assets/2026-09-19-keypad-and-home-avatars-disagree-with-the-board/one-letter-chips.png)).
- **The home Resume hero** shows "L L T V". On a 1400 px window its "V" avatar also had no
  colour disc.

On the keypad itself:
- **"Enregistrer" wraps to "Enregist / rer"** when a single past cell is edited, because the
  tall button is too narrow for the French label ([capture](../assets/2026-09-19-keypad-and-home-avatars-disagree-with-the-board/save-label-wraps.png)).
  Other long languages will do the same.
- **In Arabic the digit grid is mirrored**: 3 2 1 from left to right
  ([capture](../assets/2026-09-19-keypad-and-home-avatars-disagree-with-the-board/arabic-keypad-mirrored.png)). Phone and calculator keypads keep 1 2 3
  left to right in RTL locales.

**Fix:** use `player_avatars.dart` for the keypad chips and the hero. Give the tall button
room (a `FittedBox` or a shorter label). Wrap the digit grid in `Directionality(ltr)`.

**Acceptance:**
- A widget test: the keypad chips and the hero show the same two-letter initials as the board.
- A widget test in `fr`: the edit-mode button's label is on one line.
- A widget test in `ar`: the first row of the digit grid reads 1 2 3 from left to right.
