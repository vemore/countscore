# Spanish and Portuguese labels wrap mid-word on the statistics and keypad screens

- **Noted:** 2026-09-19 — while retaking the store screenshots (`feat/store-screenshots-retake`)
- **Theme:** i18n
- **Area:** app
- **Blocks release:** no

On the Pixel 9 Pro XL at its default resolution (1008×2244, 360 dpi), seen in
`store_listing/es-ES/raw/` and `store_listing/pt-BR/raw/`:

- `08_statistics`: the leaderboard's column header « PARTIDAS » wraps as « PARTIDA / S » in
  both locales — the games column is sized for the English « GAMES ».
- `07_score_entry`: the keypad's tall next key reads « Siguiente / : Sofia » in `es-ES` —
  the line breaks before the colon, which is then the first character of the second line.

**Fix:** let the header column take its label's width (or shrink the label to fit), and
break the next key's label after the colon — or drop the colon and put the name on its own
line, the way `fr-FR` (« Suivant / Sofia ») already reads. Check `de-DE` and `ru-RU`, whose
labels are as long.

**Acceptance:**
- No label on those two screens breaks inside a word or before punctuation in any of the ten
  locales.
