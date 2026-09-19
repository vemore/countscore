# A Chinese game-type list is sorted by code point, not by pinyin

**Status:** done (2026-09-19) — closed by fix/i18n-zh-pinyin-and-unused-keys. Each `gameTypeName*` has a `gameTypeName*SortKey` sibling in all ten ARB files — the name everywhere, its numbered pinyin in `zh` — read by `builtinGameTypeSortKey` in `sortGameTypesByDisplayName`; custom names keep code-point order, no dependency added. `test/utils/game_type_name_test.dart` pins the `zh` order.

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

**Decided (2026-09-18, refinement 3):** a pinyin sort key per built-in name, no collator
library. An ARB key next to each `gameTypeName*` value, equal to the name in every locale but
`zh`; custom names stay in code-point order.

**Acceptance:**
- In `zh`, the game-types screen lists the built-in types in pinyin order of their displayed names.
- `test/utils/game_type_name_test.dart` covers `zh`.
- The sort keys exist in all ten ARB files, and no new dependency is added.
