# The phone on the table does everything except the small things the table needs

- **Noted:** 2026-09-16 — while comparing CountScore with the competing counters on the Play Store
- **Theme:** growth
- **Area:** app
- **Blocks release:** no

The category leader, "Compteur : comptez tout" (napps, 500 K+ installs, 4.9 with 4 320
ratings, Tools, no ads), wins its reviews on being the *one* utility you open at the table.
CountScore counts points and stops there: `lib/screens/` holds ten screens and none of them
offers a die, a turn timer or a way to settle who deals. Players reach for a second app, or
for a physical die that is in the other box.

Three additions, each self-contained, each keeping the app entirely local:

- **Dice roller** — pick the number and the kind of dice, roll, show the total. Directly
  serves the Yahtzee/Farkle long tail of `2026-09-16-default-game-types-miss-the-long-tail.md`.
- **Who starts?** — pick a random player among the game's players.
- **Turn timer** — a per-turn countdown with a sound, for the players who need one.

None of them touches the schema, the network or the Data Safety declaration; all of them are
reasons to keep the app installed between game nights, and words a user types into Play
search ("dé", "dice roller", "minuteur").

**Fix:** one widget each, reachable from the game board's app bar or overflow menu, every
string through `AppLocalizations` (`i18n-add-string`), no new permission. Ship them one at a
time rather than as a bundle, so a bad idea is cheap to drop.
