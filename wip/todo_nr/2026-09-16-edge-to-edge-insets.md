# Seven screens draw their last list item under the system navigation bar

- **Noted:** 2026-09-16 — while reading the Play Console's "affichage de bord à bord" recommended action
- **Theme:** edge-to-edge
- **Area:** app
- **Blocks release:** no

The Console's advice itself does not apply: `enableEdgeToEdge()` is an AndroidX Kotlin/Java
call, `MainActivity.kt` is a bare `FlutterActivity`, and `values{,-night}/styles.xml` are the
stock Flutter themes with no `windowOptOutEdgeToEdgeEnforcement` and no
`statusBarColor`/`navigationBarColor` override. With `targetSdk` 36 the app is already
edge-to-edge and cannot opt out. Nothing to enable, and the AndroidX call must not be added.

What is real is the inset handling behind it. `lib/` has no `SystemChrome` or
`SystemUiOverlayStyle` call at all and three `SafeArea` for ten screens — one of them added
after this exact bug, `lib/screens/game_analysis_screen.dart:326`: *"The footer used to be
drawn behind the system gesture bar."* It was fixed case by case, never in principle.

`BoxScrollView` inserts `MediaQuery.padding` on the main axis **only when `padding` is
null**. Every root scrollable below passes an explicit one, so that compensation is lost and
the last row cannot be scrolled clear of the navigation bar:

| File | Line | Padding |
|---|---|---|
| `lib/screens/about_screen.dart` | 22 | `EdgeInsets.all(24)` |
| `lib/screens/create_game_screen.dart` | 199 | `EdgeInsets.all(16)` |
| `lib/screens/game_analysis_screen.dart` | 438 | `EdgeInsets.all(16)` |
| `lib/screens/game_types_screen.dart` | 42 | `EdgeInsets.all(8)` |
| `lib/screens/player_stats_screen.dart` | 82 | `EdgeInsets.all(8)` |
| `lib/screens/players_screen.dart` | 60 | `EdgeInsets.all(8)` |
| `lib/screens/ranking_screen.dart` | 67 | `EdgeInsets.all(8)` |

`lib/screens/settings_screen.dart:117` passes none and is therefore correct — by accident,
not by decision. `lib/screens/home_screen.dart:86` gives the drawer `EdgeInsets.zero`, which
likely puts the `DrawerHeader` under the status bar. The two `FloatingActionButton.extended`
are fine: `Scaffold` lifts them itself.

Severity depends on the navigation mode and was **not** measured on hardware: a gesture pill
is thin and translucent, a 3-button bar is ~48 dp and hides a whole row.

**Fix:** measure first on the Pixel 9 Pro XL in both navigation modes (`flutter-device-test`),
then add `MediaQuery.of(context).padding.bottom` to the bottom of each root scrollable's
padding rather than wrapping seven more `SafeArea`s — reproducing what Flutter already does
when the padding is left null. Check the drawer header while there.
