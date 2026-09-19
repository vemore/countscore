# The Chinese rules call trick-taking games "communication card games"

- **Noted:** 2026-09-19 — reviewing the long-tail translations in feat/game-rules-twelve
- **Theme:** i18n
- **Area:** app
- **Blocks release:** no

`assets/rules/rules_zh.md` opens Belote, Tarot and Bridge (lines 175, 208 and 246 on
2026-09-19) with 沟通牌类游戏, "communication card game". That is a mistranslation of
"trick-taking game": the usual Chinese term is 吃墩游戏 / 吃墩类纸牌游戏, and the rest of the
file already uses 墩 for a trick. The Wizard ruleset added on 2026-09-19 uses 吃墩类纸牌游戏.
The first nine rulesets of the other locales were not reviewed as a whole either.

**Fix:** replace 沟通牌类游戏 with 吃墩类纸牌游戏 in the three sections (`rules_zh.md:175,208,246`).
The native-speaker review of `ar`, `hi`, `ja`, `ru` and `zh` it used to ask for is left out
(2026-09-19, refinement): it depends on an outside reviewer and has no end, so it does not fit a pull request.

**Acceptance:**
- `grep 沟通 assets/rules/rules_zh.md` finds nothing.
