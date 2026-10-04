# The player statistics header runs two labels together when a translation is long

- **Noted:** 2026-10-04 — the Indonesian and Vietnamese captures showed `PERMAINANKEMENANGAN`
- **Theme:** i18n
- **Area:** app
- **Blocks release:** no

`lib/screens/player_stats_screen.dart` gives the Games and Wins header cells fixed widths
(`_gamesColumnWidth = 64`, `_winsColumnWidth = 96`) and uppercases the label. A translation
longer than the cell overflows into its neighbour. The two instances found were fixed by
shortening the strings (`id` Game / Menang, `vi` Ván / Thắng, `fix/stats-header-id-vi`), which
works only until the next language or rewording. Turkish (`OYUNLAR`, `ZAFERLER`) and Polish
(`ZWYCIĘSTWA`) fit by a few pixels.

**Fix:** let the header cells size to their text (`FittedBox(scaleDown)` or `Flexible` with
`TextOverflow.ellipsis` and a one-line limit), or give the columns widths measured from the
longest label.

**Acceptance:**
- A widget test pumps `PlayerStatsScreen` in all twenty locales at a 360 dp width and finds no
  overflow and no overlap between the three header labels.
