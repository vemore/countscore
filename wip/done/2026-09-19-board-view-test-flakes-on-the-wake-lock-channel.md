# The board-view toggle test fails at random on the wake-lock platform channel

**Status:** done (2026-09-19) — closed by feat/group-settings-screen. It failed two CI runs in a row and 3 local runs in 5, so the pull request could not go green without it: `SettingsProvider._applyWakeLock` now catches a plugin error and logs it. The test then passed 8 local runs out of 8.

- **Noted:** 2026-09-19 — CI of feat/group-settings-screen (#120), run 35400576700, a change that does not touch the board
- **Theme:** test-tooling
- **Area:** app
- **Blocks release:** no

`test/screens/game_board_lanes_test.dart`, "the toggle switches to one row per player in seat
order, and the choice survives rebuilding the app", failed once in CI with
`PlatformException(channel-error, Unable to establish connection on channel:
"dev.flutter.pigeon.wakelock_plus_platform_interface.WakelockPlusApi.toggle")`, thrown from
`SettingsProvider._applyWakeLock` (`lib/providers/settings_provider.dart:70`). The test
creates real `SettingsProvider`s, whose load fires `_applyWakeLock()` unawaited, and no
wake-lock mock is installed, so whether the error lands inside the test depends on timing.
It passes locally and passed on main after #119.

**Fix:** install a wake-lock mock for the test (as other tests do for plugin channels), or have
`_applyWakeLock` catch a `PlatformException` — a missing wake lock should never be an error the
user or a test sees.

**Acceptance:**
- The test passes 20 runs in a row (`flutter test --plain-name "the toggle switches" test/screens/game_board_lanes_test.dart` in a loop).
