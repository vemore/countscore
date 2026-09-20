# StoreListing

> Scope: what the Play Store page says, in which languages, with which keywords, and the
> assets behind it. The Console walkthrough is `PUBLISHING.md`; the publishing mechanism is
> [[Release]] and the `release-android` skill.
> Related: [[Release]] · [[I18n]] · [[Documentation]] · [[KnownLimits]]
> Updated: 2026-09-20

## Facts

### Where it lives

`store_listing/<play-locale>/` holds three committed text files per locale — `title.txt`,
`short_description.txt`, `full_description.txt` — plus the release notes
`release_notes_v<x.y.z>.txt` for the locales that have them. `play_publish.py publish
--listing` uploads the text and `--graphics` the images, both to every locale directory it
finds, so **the files are the source of truth**: a field edited in the Console and not in the
file silently reverts at the next release.

`store_listing/assets/` has the 512×512 icon `icon_512.png` — a *generated* file, written
by `scripts/generate_icons.py` from the vector source in `design/icon/`, never edited by
hand; it is also a Flutter asset (`pubspec.yaml`), which is how the home and About screens
show it, and the input `flutter_launcher_icons` uses for the legacy square mipmap
([[Release]] §Icons) — plus the 1024×500
`feature_graphic.png` (Template 1 of `store_listing/FEATURE_GRAPHIC_TEMPLATES.md`: icon, name,
tagline and the scoring grid in a phone frame, drawn with Pillow) — every locale's, unless
`<locale>/feature_graphic.png` exists. It holds **no screenshots**: the old shared raw set
(`assets/screenshots/phone/`, French, purple, pre-refresh) was deleted on 2026-09-19, and each
locale has its own `raw/` set. `scripts/capture_screenshots.sh <locale>` switches CountScore alone to a
store locale's language (`adb shell cmd locale set-app-locales com.vemore.countscore --locales
<locale>`, Android 13+; `--reset` puts it back on the phone's language) and writes that
locale's own set to `store_listing/<locale>/raw/`. Per-app language works on the Pixel with no
`android:localeConfig` in the manifest (checked 2026-09-19 on `ja-JP`): the phone stays
French. Requirements: `store_listing/ASSET_REQUIREMENTS.md`.

**The demo data.** Store images show no real person's data. `test/demo_db_test.dart` writes a
fictional database — `DEMO_DB_OUT=/tmp/countscore_demo.db flutter test
test/demo_db_test.dart` — built as an Android install builds its own file (sqflite chain, then
the Drift repositories): six invented first names (Emma, Léo, Sofia, Noah, Maya, Hugo), ten
games under city names across ZapZap, Tarot, Skyjo, Belote, Yahtzee and a custom *Kubb* type,
one in progress (*Annecy*, round 6, Emma leading), every player with the five finished games
the statistics ranking needs. It goes on the phone through **Settings → Import** (push it to
`/sdcard/Download/`, pick it). Game and player names stay the same in every locale.

### Screenshots: raw captures in, one composed set per locale out

The raw captures are 1008×2244 (the Pixel 9 Pro XL at its default resolution, every `raw/`
set) RGBA — ratio 2.22 and an alpha channel, both refused by
Play — so they are **input only**. `scripts/compose_screenshots.py` (Pillow, PEP 723, `uv run
--script`) takes a locale's own `raw/` set and nothing else — no shared fallback, so one carousel
never shows another locale's UI language; a captioned locale without `raw/` is refused
(`ComposeError`, exit 2), in compose and in `--check` — crops the status and navigation
bars (`SYSTEM_BARS`, measured per capture size: 110/132 px at 1080×2400 — the deleted shared
set's size, kept for a 1080p phone — 110/108 px at 1008×2244 — the navigation bar is 48 dp, so it follows the density; any other size is
refused rather than cropped by guess), scales the screen under a caption band on a
gradient from the app's teal (`BRAND = #0E8F88`, `kBrandSeedLight` in
`lib/utils/app_theme.dart`, which a test compares) to 70 % of it, and writes **1080×1920 opaque
RGB** PNGs to `store_listing/<locale>/screenshots/phone/`, under the capture's own file name.
That is the only directory `play_publish.py graphics_files()` takes a locale's screenshots
from — it refuses a locale without it rather than upload anything else — so `listing
--graphics` publishes the composed set with no change to the publisher. The directory holds exactly the
composed set: compose deletes a PNG there with no raw capture of that name, and `--check`
reports one — which is how a stray capture committed there turns CI red ([[Testing]]).

- The captions are `store_listing/<locale>/screenshot_captions.txt`, one `<capture stem>:
  <caption>` line per capture; the script refuses a missing or an unknown stem, and a caption
  that does not fit two lines at 48 px. French uses a no-break space before `?` and `:`.
- A locale is a directory holding `title.txt`, the rule `play_publish.py` uses. One with no
  captions file is skipped with a warning — **and `play_publish.py` then falls back to the raw
  captures for it**, which `--check` reports as a missing set.
- Fonts: Roboto Bold from the Flutter SDK's `material_fonts` cache for the Latin and Cyrillic
  locales; Noto Sans CJK (face 0, Japanese, for `ja-JP`; face 2, Simplified Chinese, for
  `zh-CN`), Noto Sans Devanagari and Noto Sans Arabic from `fonts-noto-cjk` / `fonts-noto-core`.
  `ar` and `hi-IN` refuse to compose without a Pillow built with libraqm: unshaped, both
  scripts render as disconnected, misordered letters. `--font` overrides.
- A line breaks after a clause (`,` `?` `:` `—` and their Arabic and CJK forms) when one
  fits, else at the most even split. `ja-JP` and `zh-CN` have no spaces to wrap on, so their
  captions force the break with `|`.
- **All ten locales are retaken and composed** (2026-09-19) and `--check` exits 0: each
  locale's own UI, the teal theme, on the demo data, eight distinct screens — home, players,
  New game with the seat order, the end-of-game **podium** (`04_podium`, which replaced a
  `04_game_history` that was the home screen again), the board in progress with its leader,
  the custom type being edited, the keypad sheet open, the statistics leaderboard. The French
  captions were validated by the user — with #3 changed to name no game, see the decision
  below — and the nine others are translated from them; the `04_podium` caption was written
  with the retake. **Retaken again for 1.3.0** (2026-09-19, second pass) on a profile build of
  `main` at 038a76a: the avatars are two letters with the contrast-picked initial (#152), the
  home card, keypad and podium as 1.3.0 draws them. Published with the 1.3.0 release
  (`play_publish.py listing --graphics`).
- The retake was driven over `adb` (`uiautomator dump` to find each control by the demo's
  player and game names, which no locale translates), one session for the ten locales, with
  the status-bar demo mode on (`sysui_demo_allowed`, `am broadcast -a
  com.android.systemui.demo`) — the bar is cropped anyway. A profile APK (`flutter build apk
  --profile`) has no debug banner and needs no release keystore — but it is signed with the
  debug key, so the Play-installed app must be **uninstalled** first (its data goes: ask), and
  reinstalled from Play afterwards. The demo database goes in through Settings → Import.
  In `ar` the screens mirror but the **keypad does not**: tap its keys at their LTR positions.

### Promo video

`store_listing/<locale>/video.txt` holds the Listing `video` field, a YouTube URL, which
`play_publish.py listing` sends when the file exists (absent: the field is not sent, and Play
keeps what it has). All ten locales point at the same **unlisted** video,
`https://www.youtube.com/watch?v=WnYxasc4dV0` (24 s, English narration and UI, embedding
allowed), rendered by the `/brag` plugin into the ignored `brag-output/`: the teal board
lanes, the keypad with its "0 ZapZap" key, the end-screen podium and the analysis voices,
rebuilt in HTML from the widgets rather than captured.

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
- **No third-party game name in the screenshot captions** either (the user's call, 2026-09-18):
  artwork reads as endorsement where a sentence of the description reads as description.
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
| Phone screenshots | 2–8, ratio ≤ 16:9, opaque 24-bit, ≤ 8 MB | `compose_screenshots.py --check` (size and mode); `play_publish.py` refuses a ninth |
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

- **One English promo video for every locale (2026-09-19).** The user's call: a video in a
  language the visitor may not read still shows the app working, which ten empty slots do
  not. Unlisted, because the listing is its only audience. A localized cut replaces the URL in
  the locale's `video.txt` alone.
- **Screenshots are composed, per locale, from one set of raw captures (2026-09-18).** Play
  refuses the raw Pixel captures (2.22 ratio, alpha), and a carousel of bare UI says nothing
  at thumbnail size, where the decision to tap is made. 1080×1920 was decided at the
  2026-09-18 refinement: exactly 16:9, the widest ratio Play accepts for a phone. The captions
  are per locale because the listing is — ten markets, ten languages — while the captures stay
  shared: re-capturing the UI in ten languages costs a device session per locale for a screen
  the caption already explains.

  > **Status: Outdated** (2026-09-19) — reversed at refinement 4: a `ja-JP` visitor reading a
  > Japanese caption above « Liste des joueurs » sees an app that is not in their language,
  > though it is. The captures are per locale now (`store_listing/<locale>/raw/`); the shared
  > set, left as a fallback until every locale was retaken, was deleted at refinement 6
  > (2026-09-19) — its stems no longer matched the captions, so the fallback would have
  > composed a new locale from French purple captures under the wrong names. Claude drafts the French captions from the listing copy, the
  user validates them, the other locales are translated from them.
- **No game brand names in the store images (2026-09-18).** The draft caption for the game
  types screen named three third-party games; the user replaced it with « Vos jeux préférés,
  prêts à compter ». Brand names stay in the description, where they are framed as
  descriptive use, and out of the artwork, where they read as endorsement. Closed
  `wip/done/2026-09-16-screenshots-are-raw-captures.md`.
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
