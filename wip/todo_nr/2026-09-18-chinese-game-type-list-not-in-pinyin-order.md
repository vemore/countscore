# A Chinese game-type list is sorted by code point, not by pinyin

- **Noted:** 2026-09-18 — while closing `2026-09-16-game-type-list-sorts-on-the-untranslated-name.md` in feat/play-again-and-type-order
- **Theme:** game-types
- **Area:** app
- **Blocks release:** no

Game-type lists are now ordered by their displayed name through `collateNames`
(`lib/utils/game_type_name.dart`), a hand-written approximation of the Unicode Collation
Algorithm: neither the Dart SDK nor `intl` ships a collator. It folds Latin accents, case,
kana and `ё`, but leaves Han characters in code-point order. In `zh`, where twelve of the
22 built-in names are Han (`其他`, `总统`, `桥牌`, `拉米`, `快艇骰子`…), the order therefore
looks arbitrary to a reader who expects pinyin order. `ja` is affected the same way for
`大富豪`, which only matters once more kanji names exist.

**Fix:** either a pinyin reading per built-in name (a sort key next to each `gameTypeName*`
value — ARB keys must exist in all ten files, so one that equals the name everywhere but
`zh`; custom names stay in code-point order), or a real collator. Check first what a collator such as `intl4x` costs in
APK and PWA size and whether it runs on the web build; feat/play-again-and-type-order chose
not to add ICU data for a list of about twenty names.

**Acceptance:**
- In `zh`, the game-types screen lists the built-in types in pinyin order of their displayed names.
- `test/utils/game_type_name_test.dart` covers `zh`.
- The APK and PWA size change is stated in the pull request.
