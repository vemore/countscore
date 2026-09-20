# The store's `04_podium` screenshot shows a standings screen that no longer exists

- **Noted:** 2026-09-20 — while merging the two standings screens (`refactor/standings-screen`)
- **Theme:** store-listing
- **Area:** android
- **Blocks release:** no

The ten composed `04_podium` screenshots published with 1.3.0 ([[StoreListing]]) show the old
`GameEndScreen`: a podium with the list under it starting at place 4. Since 2026-09-20 the
standings list every player under the podium, the first place on the primary container, and
the screen's title is *Results* rather than the game's name. The published picture and the
app no longer match.

**Fix:** retake `04_podium` in the ten locales with the existing tooling
(`release-android`, the `adb`-driven session described in [[StoreListing]]) and publish with
`play_publish.py listing --graphics`. Worth batching with the rest of the visual-refresh
wave rather than doing alone — other screens in the set may move too.

**Acceptance:**
- `04_podium` in the ten locales shows the list starting at place 1.
- `--check` exits 0 and the set is published with the next release.
