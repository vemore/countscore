# The store listing exists in 2 languages while the app ships in 10

**Status:** done (2026-09-16) — closed by docs/store-listing-aso. `store_listing/` now holds
ten locales: `ar`, `de-DE`, `es-ES`, `hi-IN`, `ja-JP`, `pt-BR`, `ru-RU` and `zh-CN` were added
next to `en-US` and `fr-FR`, each with its own `title.txt` (head keyword first),
`short_description.txt` and `full_description.txt`, and no release notes. Every file was
checked with `wc -m` against 30 / 80 / 4000. The mapping between Play locales and app ARB
codes is documented in `.llmwiki/StoreListing.md`, `store_listing/README.md` and
`.llmwiki/I18n.md`.

- **Noted:** 2026-09-16 — while auditing store discoverability against `lib/l10n/`
- **Theme:** store-listing
- **Area:** docs
- **Blocks release:** no

`store_listing/` held only `en-US/` and `fr-FR/`. The app is fully translated into 10
languages (`lib/l10n/app_{ar,de,en,es,fr,hi,ja,pt,ru,zh}.arb`, 235 keys each, `.llmwiki/I18n.md`),
so a German, Spanish, Brazilian, Russian, Japanese, Chinese, Arabic or Hindi user searching
their own head term — `Punktezähler`, `contador de puntos`, `contador de pontos`,
`счётчик очков`, `スコア記録`, `计分器`, `عداد النقاط`, `स्कोर काउंटर` — cannot match a listing
that only exists in English and French. Play indexes the listing per locale, and the app's own
translations do not feed that index: 8 markets were not indexed at all.

**Fix:** add `store_listing/{ar,de-DE,es-ES,hi-IN,ja-JP,pt-BR,ru-RU,zh-CN}/` with
`title.txt`, `short_description.txt` and `full_description.txt`, translating the *keyword*
rather than the sentence — each market's head term opens its title. Check every title ≤ 30
and every short description ≤ 80 with `wc -m`, not `wc -c`: UTF-8 multi-byte text makes the
byte count lie. Release notes deliberately stay bilingual (`play_publish.py` publishes the
en-US/fr-FR notes with the release).
