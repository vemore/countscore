# Seven screens draw their last list item under the system navigation bar

**Status:** done (2026-09-16) — closed by fix/bottom-inset-scrollables. `lib/utils/insets.dart`
adds `MediaQuery.paddingOf(context).bottom` to the padding of the eight root scrollables that
lose the `BoxScrollView` compensation, which reproduces exactly what Flutter does when
`padding` is null. Three corrections to the table above, established while fixing it:

- **`game_analysis_screen.dart:438` does not have the bug.** It is a
  `SingleChildScrollView` — which never gets the `BoxScrollView` compensation in the first
  place — and it is already inside the `SafeArea(top: false)` added at l. 328 for this exact
  symptom. It was left alone.
- **`home_screen.dart:334` does have it** and the table did not list it: the game list is a
  root `ListView.builder` with `EdgeInsets.all(8)`, the same defect. It is fixed.
- **`about_screen.dart` passes no `padding` argument at all** (l. 22 is the
  `SingleChildScrollView`); its padding is the child `Padding` at l. 29-30, which is where
  the inset now lands.

The drawer (`home_screen.dart:86`) was only given the bottom inset: `DrawerHeader` adds the
status-bar height to its own padding (`drawer_header.dart:84-90`), so `EdgeInsets.zero` at the
top is correct and the header was never under the status bar.

The measurement on the Pixel asked for above was **not** run, and the fix did not need it: it
established severity, not the correction. `test/utils/insets_test.dart` pins the behaviour
instead — a `MediaQuery` with a 48 dp bottom padding, the resolved `EdgeInsets`, and a
`ListView` whose `maxScrollExtent` is 48 dp short without the helper and exact with it;
`test/screens/about_screen_test.dart` checks the resolved padding on a real screen. Worth a
look on hardware in three-button mode next time the phone is in hand, but nothing is pending.

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
