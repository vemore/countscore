# No screen adapts to a tablet, foldable or the web PWA on a desktop

- **Noted:** 2026-09-16 — while establishing what tablet store screenshots would need
- **Theme:** large-screen
- **Area:** app
- **Blocks release:** no

`grep -rl "LayoutBuilder\|MediaQuery.of(context).size" lib/` returns **nothing**: not one of
the ten screens in `lib/screens/` branches on the available width. Every layout is a phone
layout stretched, which on a 10-inch tablet or on the PWA in a desktop browser
(`.llmwiki/Web.md` — the same code serves it) means a single column of cards across 1 600
logical pixels, and a score grid that wastes the width where it is most useful: a scoring
table is exactly the content that gets *better* with room.

Play grades large-screen quality separately and surfaces it in the Console; the store also
shows tablet screenshots only if tablet screenshots exist, and
`store_listing/assets/screenshots/` has a `phone/` directory only. So this is a prerequisite
for the tablet half of `2026-09-16-screenshots-are-raw-captures.md`, not an independent nicety.

**Fix:** one breakpoint, applied where it pays first — the game board and the home list:
below ~600 dp keep today's layout, above it use a two-pane or multi-column arrangement.
`flutter-device-test` can drive the check on hardware, and `-d chrome` at a desktop window
size covers the PWA. Then capture the tablet screenshot set.
