# CountScore — Google Play store listing

The committed source of truth for everything the Play Store page shows.

`.claude/skills/release-android/scripts/play_publish.py publish --listing --graphics` uploads
these files to the Console. **A field edited in the Console and not here silently reverts at
the next release.** The durable facts — which locales, which keyword per market, the
category, the acquisition baseline — are `.llmwiki/StoreListing.md`; the Console walkthrough
is `PUBLISHING.md`.

## Layout

```
store_listing/
├── <play-locale>/                  # one directory per published locale
│   ├── title.txt                   # app name, 30 characters max
│   ├── short_description.txt       # 80 characters max
│   ├── full_description.txt        # 4000 characters max
│   └── release_notes_v<x.y.z>.txt  # 500 characters max — en-US and fr-FR only
├── assets/
│   ├── icon_512.png                # 512×512, also the source of the Android launcher icons
│   ├── feature_graphic.png         # 1024×500, opaque
│   └── screenshots/phone/          # 8 captures, 01_… to 08_…
├── ASSET_REQUIREMENTS.md           # image specifications
├── ASSET_CREATION_CHECKLIST.md · COLOR_THEME_GUIDE.md
├── FEATURE_GRAPHIC_TEMPLATES.md · ICON_DESIGN_GUIDE.md · SCREENSHOT_GUIDE.md
└── README.md                       # this file
```

The ten published locales are Play's identifiers, **not** the app's:

| Play locale | App ARB | | Play locale | App ARB |
|---|---|---|---|---|
| `ar` | `app_ar.arb` | | `ja-JP` | `app_ja.arb` |
| `de-DE` | `app_de.arb` | | `pt-BR` | `app_pt.arb` |
| `en-US` | `app_en.arb` | | `ru-RU` | `app_ru.arb` |
| `es-ES` | `app_es.arb` | | `zh-CN` | `app_zh.arb` |
| `fr-FR` | `app_fr.arb` | | `hi-IN` | `app_hi.arb` |

Adding a language to `lib/l10n/` does not create the listing for it, and vice versa.

> **Not published yet.** `play_publish.py` iterates a hardcoded `LOCALES = ("en-US", "fr-FR")`
> for the text, the notes and the graphics, so the eight locales added on 2026-09-16 are
> committed but not uploaded. Widening that list (text: every directory here; notes: still the
> two) belongs to the `chore/play-publish-listing` work — `.llmwiki/StoreListing.md`.

## Limits, and how to check them

| Field | Play limit |
|---|---|
| `title.txt` | 30 characters |
| `short_description.txt` | 80 characters |
| `full_description.txt` | 4000 characters |
| `release_notes_v*.txt` | 500 characters per locale |

`play_publish.py` refuses a file over the limit, so a bad edit fails the release rather than
the review. Check locally with **`wc -m`, never `wc -c`** — every non-Latin locale here is
multi-byte and the byte count would be two to three times the real length:

```bash
for d in store_listing/*/; do
  printf '%-7s %3s %3s %5s\n' "$(basename "$d")" \
    "$(wc -m < "$d/title.txt")" \
    "$(wc -m < "$d/short_description.txt")" \
    "$(wc -m < "$d/full_description.txt")"
done
```

The files carry **no trailing newline**: the Console shows one as part of the field.

## Writing the copy

The full rules and the reasoning are in `.llmwiki/StoreListing.md`. The ones that get a
release rejected or wasted:

- **Never "our server", and never claim the app has no sync.** Group sharing and the ZapZap
  analysis are real and reach the server *the user hosts*. "100 % offline" or "no data leaves
  the device" contradicts the Data Safety declaration — the first rejection reason in
  `PUBLISHING.md`. This holds in all ten languages, not only the two you can read.
- **No backend URL, anywhere** (`CLAUDE.md`).
- **No third-party game name in `title.txt`.** Uno, Skyjo, Scrabble, Phase 10 and Yahtzee are
  trademarks and the title is where Play enforces it. In the descriptions they are used
  descriptively — "works for your games of …", never "official app".
- **No keyword stuffing.** Play's Metadata policy forbids a comma block of game names; they go
  into sentences.
- **The head keyword opens the title**, before the brand, in every locale.
- `en-US/release_notes_v1.0.0.txt` and `fr-FR/release_notes_v1.0.0.txt` describe 1.0.x, which
  had no networking at all. They are history — never publish them against a 1.1.0+ build.

## Assets

Committed and published since 2026-09-15: the icon, the feature graphic and eight phone
screenshots. Specifications are in `ASSET_REQUIREMENTS.md`; `scripts/capture_screenshots.sh`
pulls fresh captures over ADB.

Known gap: the eight screenshots are raw 1080×2400 RGBA captures, which is wider than the
16:9 Play asks for and carries an alpha channel it does not allow, with no caption and no
localization — `wip/todo_nr/2026-09-16-screenshots-are-raw-captures.md`. There is no tablet
set, because no screen has a large-screen layout yet
(`wip/todo_nr/2026-09-16-no-large-screen-layout.md`).

## Releasing a change to the listing

1. Edit the files, per locale.
2. Check the character counts with the loop above.
3. Re-read the two rules that get releases rejected: no "our server", no denial of sync.
4. Commit — the listing is published by `release-android` §8, with the release.
5. Anything the API cannot reach — the category, the store tags, the Data Safety review — is
   manual Console work, listed in `PUBLISHING.md`.
