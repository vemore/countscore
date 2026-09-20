# The app icon does not say what the app does

- **Noted:** 2026-09-20 — while reviewing the icon against ASO guidance the user supplied
- **Theme:** visual-refresh
- **Area:** android
- **Blocks release:** no

`store_listing/assets/icon_512.png` is stock clipart — a podium, a trophy, two stars, a
sparkle and the digits 1-2-3, in six colours with ~2 px outlines, on a transparent/white
field. At 48 px none of it survives, and against the Play Store's white results page the
icon has no edge at all. It also has no recorded provenance: one commit, `75dc8f6 "Update
app icon"`, no attribution anywhere in the repository.

**The category's own evidence.** Twelve icons read off the Play Store searches *compteur de
points cartes société* and *score keeper board games* on 2026-09-20:

| App | Rating | What its icon shows | Digits |
|---|---|---|---|
| Score points (Anthony49Dev) | 5,0 | a trophy on colour blobs | no |
| Points Scorer (Etologic) | 4,9 | "100" on a black shield | yes |
| Compteur : comptez tout (napps) | 4,8 | "+10" white on a teal tile | yes |
| Compteur de points (Romain Lebouc) | 4,8 | a white abacus on teal | no |
| Compteur de Score (Torsten Hoffmann) | 4,7 | a score table, 105 / 254 | yes |
| Score Counter – For any game (Szabolcs Árvai) | 4,7 | white cards with "+1" | yes |
| Multi Compteur (Umit YILMAZ) | 4,6 | "1 2 3" on black | yes |
| Scoreboard – Keep score (Truyendiv) | 4,6 | "5 \| 4", red against blue | yes |
| Score It (SBG Apps) | 4,6 | two orange tiles on cream | no |
| Score Counter (Martin Váňa) | 4,4 | a grid, 24 19 22 / 51 53 49 | yes |
| Scoreboard – Track Score (CensaSoft) | 4,4 | "2 \| 0", blue against red | yes |
| **CountScore (vemore)** | — | **a pale podium on white** | **no** |

Three findings follow. **Digits are the category's language** — eight of the twelve carry
them, and a digit needs no translation, which matters across ten locales. **The ground is
saturated and full-bleed** in almost all of them; CountScore is the only white one, which is
why it dissolves between its neighbours instead of standing out. **Teal is not
differentiating here**: two of the five best-rated apps on the shelf are teal, including the
direct competitor "+10".

**Sixteen candidates were drawn** and are in `../assets/2026-09-20-the-app-icon-does-not-say-what-the-app-does/`:

![All sixteen candidates](../assets/2026-09-20-the-app-icon-does-not-say-what-the-app-does/all-candidates.png)

- **C1–C5** (tally, podium, score sheet, crown, pips) carried no digits at all and each named
  an idea next to the product rather than the product. Dropped.
- **D1–D6** carried digits. **D1** (number grid) and **D3** (cards with "+1") are already the
  icons of Score Counter and Score Counter – For any game, so both are out. **D2** is the
  shelf's most copied shape and promises two players. **D4** and **D5** read as a notepad and
  a bare total.
- **D6 Classement** and **E2/E3**, the game-pieces ensemble (cards, a die, a pawn, a "+1"),
  are the shortlist.

![Shortlist at 512 px](../assets/2026-09-20-the-app-icon-does-not-say-what-the-app-does/shortlist-512.png)
![Shortlist at 48 px, current icon first](../assets/2026-09-20-the-app-icon-does-not-say-what-the-app-does/shortlist-48.png)

**Fix:** adopt one candidate and wire it through everything the icon touches. The SVGs in
`svg/` are the source: two named layers (`#bg`, `#fg`), artwork inside the 66% adaptive safe
circle, and a hand-built `-mono` layer. Adopting any of them closes most of
[[2026-09-20-the-app-icon-has-no-vector-source-and-no-monochrome-layer]] at the same time.
`tools/` holds the generators — they encode the safe-zone measurement and the monochrome
knockout, which is the part that is easy to get wrong: flattening every shape to one colour
turns the score sheet into a black slab and the tally into a scribble.

The change spans: `store_listing/assets/icon_512.png`, `dart run flutter_launcher_icons`, a
brand `adaptive_icon_background` instead of `#FFFFFF`, an `adaptive_icon_monochrome`, the
five web files of [[2026-09-20-pwa-icons-are-still-the-flutter-logo]], the two in-app uses
(`lib/screens/home_screen.dart:178`, `lib/screens/about_screen.dart:38`), the Pillow feature
graphic that insets the icon, the comment at `lib/utils/app_theme.dart:5` that says the teal
comes "from the icon's podium", and the stale guides of
[[2026-09-20-the-brand-docs-still-describe-the-abandoned-purple]].

**Acceptance:**
- The chosen artwork ships as SVG, and a documented command regenerates every raster.
- At 48 px the icon reads as score-keeping, not as a smudge — checked on a real render.
- Nothing is clipped under a circular mask, and the themed monochrome icon is legible.
- The launcher tile, the PWA icons and the in-app asset all show the same new artwork.
- `.llmwiki/Release.md`'s icon section matches the new procedure and its `Updated:` moves.

**Open question:** which candidate. The user decides; the shortlist is **E3** (the ensemble,
ink ground — says what you play *and* that points are scored, but four objects is one idea
more than the category rewards and 48 px is its floor, not its margin) and **D6** (standings
— says what makes CountScore different from a shelf of single-digit counters). Ground colour
is part of the same decision: ink separates from the shelf, teal keeps brand continuity.
