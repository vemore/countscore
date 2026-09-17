# StoreListing

> Scope: what the Play Store page says, in which languages, with which keywords, and the
> assets behind it. The Console walkthrough is `PUBLISHING.md`; the publishing mechanism is
> [[Release]] and the `release-android` skill.
> Related: [[Release]] · [[I18n]] · [[Documentation]] · [[KnownLimits]]
> Updated: 2026-09-17

## Facts

### Where it lives

`store_listing/<play-locale>/` holds three committed text files per locale — `title.txt`,
`short_description.txt`, `full_description.txt` — plus the release notes
`release_notes_v<x.y.z>.txt` for the locales that have them. `play_publish.py publish
--listing` uploads the text and `--graphics` the images, both to every locale directory it
finds, so **the files are the source of truth**: a field edited in the Console and not in the
file silently reverts at the next release.

`store_listing/assets/` has the 512×512 icon `icon_512.png` (also the source
`flutter_launcher_icons` generates the Android densities from), the 1024×500
`feature_graphic.png` (Template 1 of `store_listing/FEATURE_GRAPHIC_TEMPLATES.md`: icon, name,
tagline and the scoring grid in a phone frame, drawn with Pillow), and eight phone
screenshots under `assets/screenshots/phone/`, pulled over ADB by
`scripts/capture_screenshots.sh`. Requirements: `store_listing/ASSET_REQUIREMENTS.md`.

### Published locales (10, since 2026-09-16)

`ar` · `de-DE` · `en-US` · `es-ES` · `fr-FR` · `hi-IN` · `ja-JP` · `pt-BR` · `ru-RU` · `zh-CN`.

They match the app's 10 languages ([[I18n]]) but **are not the same identifiers**: the app has
`fr`, Play wants `fr-FR`; the app has `pt`, Play wants `pt-BR`; Arabic is `ar` on both sides.
Adding a language to `lib/l10n/` does not add a store locale, and the reverse is equally true.

**Release notes stay in `en-US` and `fr-FR` only** — the 8 new locales deliberately have no
`release_notes_*.txt`.

> **Published on 2026-09-16.** `play_publish.py listing --commit` pushed the ten locales
> live in one edit (`edits.validate OK`, `committed: store listing for ar, de-DE, en-US,
> es-ES, fr-FR, hi-IN, ja-JP, pt-BR, ru-RU, zh-CN — live, no rollout`). It ran against
> `1.1.0+4`, the build already in production: **a listing is independent of the app version**,
> so no bump and no rebuild were needed. The Console header changed immediately; the public
> store page keeps serving the old title for a while, because a title change goes through
> review and the page is cached.

### Keyword targets

The head term opens the title in every market, before the brand name:

| Locale | Head term | Title |
|---|---|---|
| `fr-FR` | compteur de points | `Compteur de points: CountScore` |
| `en-US` | score keeper | `Score Keeper - CountScore` |
| `de-DE` | Punktezähler | `Punktezähler - CountScore` |
| `es-ES` | contador de puntos | `Contador de puntos: CountScore` |
| `pt-BR` | contador de pontos | `Contador de pontos: CountScore` |
| `ru-RU` | счётчик очков | `Счётчик очков - CountScore` |
| `ja-JP` | スコア記録 | `スコア記録 - CountScore` |
| `zh-CN` | 计分器 | `计分器 - CountScore 记分板` |
| `ar` | عداد النقاط | `عداد النقاط - CountScore` |
| `hi-IN` | स्कोर काउंटर | `स्कोर काउंटर - CountScore` |

The long tail is per game, and it lives in the short and full descriptions: Skyjo, Uno,
Belote, Coinche, Tarot, Rami, Président, Scrabble, Bridge, Yahtzee, Phase 10, Flip 7, Mille
Bornes, Rummikub, 6 qui prend, Qwirkle, Farkle, ZapZap, plus the market's own games (Skat and
Doppelkopf in `de-DE`, Chinchón and Mus in `es-ES`, Buraco and Truco in `pt-BR`, «Дурак» and
«Тысяча» in `ru-RU`, 大富豪 in `ja-JP`, 斗地主 in `zh-CN`, البلوت and الطرنيب in `ar`, रमी and
कैरम in `hi-IN`). Lexical variants — score keeper, score tracker, scorecard, scoreboard, point
counter, feuille de score, carnet de scores, tableau des scores — are spread through the
prose.

### Rules the copy must obey

- **Never "our server", never a denial of sync.** Group sharing and the AI analysis exist
  and reach the server *the user hosts*; "100 % offline" or "no data ever leaves the device"
  contradicts the Data Safety declaration and is the first rejection reason listed in
  `PUBLISHING.md`. Checked against `privacy_policy.md`. This applies to **all ten** languages.
- **No backend URL anywhere** (`CLAUDE.md`).
- **The analysis is named for what it does, not for one game.** `ZapZap` is one of the games
  in the long tail above; it is not the feature's name. Since `feat/ai-analysis-styles` the
  analysis covers every game type, in nine voices and ten languages, so the descriptions say
  "AI analysis" / « Analyse IA » and the equivalent in the other eight locales. Naming the
  feature after a single game reads as if it only worked there.
- **No third-party game name in `title.txt`.** Uno, Skyjo, Scrabble, Phase 10 and Yahtzee are
  trademarks; the title is where Play enforces it. Descriptive use in the descriptions is
  framed as "works for your games of …", never "official app".
- **No keyword stuffing** (Play Metadata policy): the games are named in sentences, not in a
  comma block.
- The description **explains** the Data Safety card rather than contradicting it — three data
  types, what each one actually is, and that the "device ID" is a random token the user's own
  server issues.
- `release_notes_v1.0.0.txt` describes 1.0.x, which had no networking. It is history: never
  re-publish it against a 1.1.0+ build, whose notes are `release_notes_v1.1.0.txt`.

### Play limits that apply

| Field | Limit | Enforced by |
|---|---|---|
| App name (`title.txt`) | **30** characters | `play_publish.py` refuses a longer file |
| Short description | **80** characters | idem |
| Full description | **4000** characters | idem |
| Release notes | **500** characters per locale | idem |
| Phone screenshots | 2–8, ratio ≤ 16:9, opaque 24-bit, ≤ 8 MB | nothing — checked by hand |
| Feature graphic | 1024×500, opaque | nothing |
| Icon | 512×512, ≤ 1 MB | nothing |

Count characters with `wc -m`, never `wc -c`: every non-Latin locale is multi-byte and the
byte count would be two to three times the real length.

### Category and tags

Declared in the Console: app type **App**, category **Tools**, tags **Entertainment, Tools**
(changed 2026-09-16 — *Productivity* removed, *Entertainment* added).

The tags drive the "similar apps" group. Before the change, the public listing's *More apps to
try* block offered Windy, Google Cloud, ChatGPT, Uber, Microsoft Launcher and Gemini
Notebook — no score counter. The tag picker has **no board-game or score tag at all**, checked
entry by entry: searching it for *jeu*, *score*, *loisir* or *famille* returns nothing usable,
so **Entertainment** is the whole of the available lever. The category stays **Tools**, where
the 500 K-install leader also sits; *Games* would be a false declaration, since CountScore is
not a game.

Changing either is Console-only work — `play_publish.py` handles neither
(*Grow → Store presence → Store listing settings*). **Re-check the *More apps to try* block a
few days after a tag change and record what it shows here.**

### Baseline, measured in the Console on 2026-09-16

The numbers the next listing change is judged against. 28-day window:

| Metric | Value |
|---|---|
| Store listing acquisition: impressions | **133** |
| Store listing visitors | **6** |
| Installs from the listing | **2** |
| Visitor → install conversion | **50 %** |
| Active devices (monthly) | 6 |
| Total installs, all time | ~10 |
| Ratings | **0** |
| Category / tags | Tools / Tools, Productivity (both changed the same day) |
| Store locales before this change | 2 (`en-US`, `fr-FR`) |

Read it as: conversion is not the problem, **visibility is**. Search checks the same day, FR
store:

- « compteur de points » → 30 results, **CountScore absent**; all 30 carry the keyword in
  their *title*.
- « suivi de score » → CountScore 9th, on a query with almost no volume.
- « skyjo » → more than 10 dedicated Skyjo counters; the per-game long tail is where the
  traffic is.

### Competitors (same date)

| App | Installs | Rating | Category | Notes |
|---|---|---|---|---|
| "Compteur : comptez tout" (napps) | 500 K+ | 4.9 (4 320) | Tools | No ads; the category leader, and proof that Tools is the right category |
| "Compteur de points" (R. Lebouc) | 50 K+ | 4.7 (898) | — | Keyword as the whole title |
| "Score Pad – board game tracker" | 1 K+ | 4.5 (33) | — | Title and description packed with keywords |

## Decisions & History

- **The analysis line was rewritten in all ten locales, feature-first (2026-09-17).** Line 38
  of every `full_description.txt` sold the feature as the "ZapZap analysis", which was true
  when it only ran on that one game. It has covered every game type, in nine voices and the
  app's language, since `feat/ai-analysis-styles` — so the copy was understating the feature
  rather than misleading, and it wasted the one line of the description that sells it. The
  two guarantees the line carries for Data Safety — the data goes to the *user's* server, and
  nothing leaves without a tap, with a report action — were kept verbatim in substance. The
  game named ZapZap stays in the long tail on line 9, where it belongs. `fr-FR` had 43
  characters of headroom against Play's 4 000-character limit, which is what set the length
  of the rewrite for every locale. Closed
  `wip/done/2026-09-16-listing-still-calls-the-analysis-zapzap.md`.
- **The keyword goes first in the title, ahead of the brand (2026-09-16).** The user's call.
  `CountScore - Score Tracker` ranked for nothing a person types: 133 impressions in 28 days,
  and absence from the 30 results of the query that defines the category. Every one of those
  30 competitors puts the term in the title, so the title is where Play reads it. The brand
  keeps the second half of the field because nobody searches for it yet — the day that
  changes, the order is worth revisiting, and this line is why.
- **Tools, not Games (2026-09-16).** Tempting, because the app is used at a game table. But
  CountScore is not a game, a misfiled app ranks badly inside its category and reviewers
  notice — and the 500 K-install leader of this exact niche sits in Tools. What changes is the
  *tags*, which is what actually builds the "similar apps" block.
- **Ten store locales, two locales of release notes (2026-09-16).** The app was translated
  into 10 languages while the listing existed in 2, so 8 markets could not match a search at
  all — Play indexes the listing, not the app's ARB files. Release notes were left bilingual
  on purpose: they are rewritten every release, they expire, and eight more translations per
  release buys far less than a permanent, indexed description does. `play_publish.py` sets the
  en-US/fr-FR notes on the release.
- **Keywords are translated, sentences are not (2026-09-16).** A literal translation of the
  French copy would carry French search behaviour into markets that phrase it differently.
  Each locale opens on its own head term and names the games that market plays, which is why
  the `de-DE` text mentions Skat and the `pt-BR` text Buraco.
- **No listing A/B test (2026-09-16).** Play Console offers store listing experiments, and
  they are the obvious next move — except that 6 visitors per 28 days cannot reach
  significance on any variant, ever. The honest path is to fix what is provably wrong (title,
  locales, category tags), then re-measure the same table above. A/B testing becomes a real
  option somewhere north of a few hundred visitors a week.
- **The description explains the Data Safety card instead of ignoring it (2026-09-16).** The
  public card advertises sharing of Personal info, App activity and Device or other IDs with
  third parties, while the copy said "no tracking". Both are true, and the contradiction was
  doing the damage — so the privacy section now says what those three entries are. The
  declaration itself was not touched: a Play answer is never softened to make the card read
  better (`PLAY_STORE_DATA_SAFETY.md`).
- **The listing text is committed, not typed into the Console (moved here from [[Release]],
  decided 2026-09-09).** The copy had claimed "no data collection" and "Android 5.0" for
  months because nothing in the repository owned it. Committing it per locale makes it
  reviewable, and `play_publish.py --listing` makes the repository win over the Console.
