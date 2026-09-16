# The whole game-over string cluster is English in five of the ten languages

- **Noted:** 2026-09-16 — while adding the explicit end of a game (feat/explicit-end-of-game)
- **Theme:** i18n
- **Area:** app
- **Blocks release:** no

`.llmwiki/I18n.md` says "10 languages, all fully translated", and the ARB key *counts* do
agree — every key exists in every file. But fifteen keys hold the literal English string in
`ar`, `hi`, `ja`, `ru` and `zh`, and they are not scattered: they are one block, the
game-over and game-type-condition cluster, added together and never translated.

```
playerEliminationCondition  gameOverCondition  none  overThreshold  underThreshold
firstPlayerOver  firstPlayerUnder  lastPlayerOver  lastPlayerUnder  threshold
conditionType  gameOverTitle  gameOverMessage  continuePlay  endGame
```

Measured with a value-equality check against `app_en.arb`: 18–19 keys identical to English
in each of those five files, against 4–8 in `es`, `de`, `pt` and `fr` — where the matches are
genuine (`appTitle`, `ok`, `artistName`, `backendUrlHint`). A Japanese user configuring a
game type therefore reads "First player over" and "Under threshold", and the game-over dialog
is entirely English.

`endGame` was fixed inline by the branch above, because that branch puts it on two new menus
in all ten languages; the other fourteen were left alone.

**Fix:** translate the remaining fourteen keys in the five locales (`i18n-add-string`), and
add a value-equality check to the ARB verification so "present" stops being mistaken for
"translated" — the current `check-arb-sync.sh` and the skill's one-liner both count keys
only. A handful of legitimate matches (`appTitle`, `artistName`) need an allow-list.
