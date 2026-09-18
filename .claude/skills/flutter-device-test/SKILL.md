---
name: flutter-device-test
description: Run real-device Flutter tests on the user's Pixel 9 Pro XL — functional, UX, and UI validation. Use when the user wants to test a Flutter app on a real phone, evaluate UX/UI by inspecting actual screens, drive the app via adb, capture screenshots for visual review, run integration_test suites on the device, record screen for animation/jank review, or test localization/RTL on hardware. Triggers: "test sur mon pixel", "test on device", "real device test", "screenshot the app", "test UX/UI", "drive the app".
---

# Flutter Device Testing — Pixel 9 Pro XL

End-to-end workflow for testing Flutter apps on the user's physical Pixel 9 Pro XL. Covers three modes: **interactive UX/UI inspection** (LLM-driven, screenshot loop), **automated functional tests** (integration_test), and **performance/animation review** (screen record + DevTools).

## Device Reference

| Detail | Value |
|--------|-------|
| Model | Pixel 9 Pro XL |
| ADB ID | `<ip>:<port>` over Wi-Fi ADB — changes on every reboot of wireless debugging; ask the user |
| Android | 16 (API 36) |
| Screen | 1008×2244 logical px @ 360 dpi (≈2992×6656 physical, 3×) |
| `adb` path | `/home/vemore/sdk/android/platform-tools/adb` |

### Find the device

The address is never hardcoded here: the phone's IP and the wireless-debugging port both
change, and `adb mdns services` sees nothing from WSL2.

```bash
adb devices          # already connected? its id is the <ip>:<port> in the first column
```

If the Pixel is not listed (or shows `offline`), **ask the user for `<ip>:<port>`** from the
phone's Settings → Developer options → Wireless debugging ("IP address & Port"). **Never scan
the LAN for it.** Then:

```bash
adb disconnect <ip>:<port>   # only if listed as offline
adb connect <ip>:<port>
flutter devices              # confirm Flutter sees it
```

If a fresh pairing is needed, the user must approve it on the phone — ask them to do so. **Do
not** run `adb pair` blindly; it requires a 6-digit code (and a separate pairing port) only
the user can read.

For brevity below, the device id is referenced as `$DEV` — `export DEV=<ip>:<port>` once the
address is known, or substitute inline.

## Mode 1 — Interactive UX/UI Inspection (the killer loop)

This is what makes a real-device skill different from `flutter test`. The LLM drives the app via adb, captures screenshots, **reads them visually with the Read tool**, and evaluates the result. Repeat until the flow is verified.

### Setup once per session

```bash
# Functional and UX/UI work: a debug build
flutter run -d $DEV --debug
```

Use `--debug` here, not `--profile`: `run-as` — pulling `databases/countscore.db`, reading or
seeding `shared_prefs` (the cheatsheet below) — only works on a **debuggable** build, and a
profile or release APK is not one. Profile is for measuring, in Mode 1b and Mode 3.

> `--no-tree-shake-icons` is a `flutter build` flag only — `flutter run` and `flutter test` reject it with exit 64 (`Could not find an option named "--no-tree-shake-icons"`, checked on Flutter 3.47.2). Neither command tree-shakes icons, in any mode, `--profile` included, so the dynamic `IconData` from `GameType` works without the flag. No command in this skill passes it.

Run `flutter run` as a **background Bash task** so hot reload stays available. The Monitor tool can stream its stdout for compile errors.

### The screenshot → read → act loop

```bash
# 1. Capture
adb -s $DEV exec-out screencap -p > /tmp/cs_screen.png

# 2. Read it with the Read tool — do not skip this. Visual inspection is the point.
#    (Read /tmp/cs_screen.png — Claude sees the actual pixels.)

# 3. Drive the UI based on what you see
adb -s $DEV shell input tap <X> <Y>              # tap at logical coords
adb -s $DEV shell input swipe <x1> <y1> <x2> <y2> [<duration_ms>]
adb -s $DEV shell input text "hello"             # types into focused field (no spaces issue: use %s)
adb -s $DEV shell input keyevent KEYCODE_BACK    # back button — also dismisses the soft keyboard
adb -s $DEV shell input keyevent KEYCODE_ENTER

# Clear a focused TextField (works in Flutter):
adb -s $DEV shell input keyevent KEYCODE_MOVE_END
adb -s $DEV shell input keyevent KEYCODE_DEL KEYCODE_DEL KEYCODE_DEL KEYCODE_DEL  # one DEL per char

# When the soft keyboard is up, bottom-anchored buttons (FAB, "Submit") are covered.
# Always send KEYCODE_BACK to dismiss the keyboard before tapping anything in the lower half.

# 4. Repeat from step 1
```

**Coordinate system:** `wm size` returns 1008×2244 logical pixels — `input tap` uses these directly. The center of the screen is `504 1122`. Don't try to convert to physical pixels.

**Naming screenshots:** for multi-step flows, save with descriptive names (`/tmp/cs_01_home.png`, `/tmp/cs_02_create_game.png`) so you can compare before/after states.

### What to evaluate on each screenshot

When Reading a screenshot, judge it against these axes — call out concrete issues, don't just describe what you see:

- **Hierarchy & focus** — is the primary action obvious? Is anything competing visually with what should be primary?
- **Spacing & alignment** — Material 3 baseline is 8dp grid. Watch for ragged edges, inconsistent paddings, items that don't share an axis.
- **Touch targets** — every tappable thing ≥ 48×48 dp (≈ 48 logical px here, since density is 360dpi/2.5 = 144dp/inch but Flutter sizes are already in dp). Flag anything obviously small (icon buttons sized to the icon).
- **Contrast & readability** — text on its background; gray-on-gray placeholder text is a frequent miss.
- **Empty/error/loading states** — most apps only ship the happy path well. Force these and verify they aren't blank screens.
- **Localization sanity** — long German strings, RTL Arabic mirroring. Test these explicitly (Mode 1c below).
- **Safe areas** — notch, gesture bar, status bar overlap. Pixel 9 Pro XL has a center punch-hole + bottom gesture bar.
- **Theme parity** — does dark mode degrade contrast? Are any colors hardcoded white/black?

Report findings as a punch list with screenshot references, not prose paragraphs.

### Mode 1a — Screen recording for animation review

Static screenshots miss jank, easing, and transition glitches. Record short clips:

```bash
# Record up to 180s; --bit-rate 8M is plenty for review
adb -s $DEV shell screenrecord --bit-rate 8000000 --time-limit 30 /sdcard/cs_rec.mp4
adb -s $DEV pull /sdcard/cs_rec.mp4 /tmp/cs_rec.mp4
adb -s $DEV shell rm /sdcard/cs_rec.mp4
```

Claude can't read mp4 directly — extract a few frames with ffmpeg if needed:

```bash
ffmpeg -i /tmp/cs_rec.mp4 -vf fps=2 /tmp/cs_frame_%03d.png
```

Use this for: page transitions, list scroll behavior, dialog enter/exit, snackbar timing.

### Mode 1b — Performance overlay (visible jank)

```bash
flutter run -d $DEV --profile
# Then in the running session, press P to toggle the perf overlay.
# Or via service extension:
flutter screenshot -d $DEV --type=skia --observatory-uri=<vm-uri>
```

Two bars appear at the top: GPU (top) and UI (bottom). Bars touching the red line = dropped frame. Screenshot during interaction and Read it to count red spikes.

### Mode 1c — Localization on device

Real device > emulator for i18n because RTL behavior, font fallbacks (CJK, Devanagari), and system bidi all differ. Switch the device locale without touching the user's settings permanently:

```bash
# Per-app locale override (Android 13+, supported on Pixel 9 Pro XL)
adb -s $DEV shell cmd locale set-app-locales <package> --locales ar
adb -s $DEV shell cmd locale set-app-locales <package> --locales de
adb -s $DEV shell cmd locale set-app-locales <package> --locales ja
# Reset
adb -s $DEV shell cmd locale set-app-locales <package> --locales ""
```

For CountScore the package is `com.vemore.countscore` (verify with `adb -s $DEV shell cmd package list packages | grep countscore`).

Walk the full flow in each locale via Mode 1's loop — focus on:
- Text overflow (German, Russian)
- RTL mirroring of icons and layouts (Arabic) — back arrow, list chevrons must mirror
- Plural forms (test 0, 1, 2, 5 of each pluralized item)
- Date/number formatting

## Mode 2 — Automated Functional Tests (integration_test)

Use when the goal is a regression-proof check that survives across sessions, not exploratory inspection.

### One-time setup if `integration_test/` is missing

```yaml
# pubspec.yaml — under dev_dependencies
dev_dependencies:
  flutter_test:
    sdk: flutter
  integration_test:
    sdk: flutter
```

```bash
flutter pub get
mkdir -p integration_test
```

Create `integration_test/app_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:countscore/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('create game and add a score', (tester) async {
    app.main();
    await tester.pumpAndSettle();
    // ... drive widgets via tester.tap(find.byKey(...)) etc.
  });
}
```

**Add `Key`s to widgets that tests target.** Without keys, finders rely on text, which breaks under localization. Convention: `Key('home.createGameButton')`, `Key('game.addPlayerField')`.

### Run the suite on the Pixel

```bash
flutter test integration_test -d $DEV
# Single file:
flutter test integration_test/app_test.dart -d $DEV
```

### Capture screenshots from inside integration tests

```dart
final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
// In a test:
await binding.convertFlutterSurfaceToImage();
await tester.pumpAndSettle();
await binding.takeScreenshot('home_screen');
```

Screenshots end up in the test report. Pull and Read them to evaluate UX as part of the assertion.

## Mode 3 — Performance Profiling on Hardware

Emulator perf is meaningless. For real numbers:

```bash
flutter run -d $DEV --profile --trace-startup
# trace file lands in build/start_up_info.json — look at engineEnterTimestampMicros
```

For frame timing during a flow, open DevTools (URL printed by `flutter run`), go to Performance tab, record a session while driving the app via Mode 1's adb commands. Save the timeline JSON for diffing across runs.

Specific things worth checking on the Pixel 9 Pro XL:
- 120 Hz display — frame budget is 8.3 ms, not 16.6 ms. Look for sustained UI-thread work above 8 ms.
- Cold start time (`--trace-startup`) — target < 2 s for a polished feel.
- Memory: `adb -s $DEV shell dumpsys meminfo <package>` after 5 min of use, watch for leaks.

## Common adb commands — cheatsheet

```bash
# Device state
adb devices                                                       # list
adb -s $DEV shell getprop ro.product.model
adb -s $DEV shell wm size                                         # logical resolution
adb -s $DEV shell dumpsys window | grep -E 'mCurrentFocus'        # foreground activity

# App lifecycle
adb -s $DEV install -r build/app/outputs/flutter-apk/app-debug.apk
adb -s $DEV uninstall com.vemore.countscore
adb -s $DEV shell am start -n com.vemore.countscore/.MainActivity
adb -s $DEV shell am force-stop com.vemore.countscore
adb -s $DEV shell pm clear com.vemore.countscore                  # wipe app data

# Logs
adb -s $DEV logcat -c                                             # clear buffer
adb -s $DEV logcat flutter:I '*:E'                                # flutter info + errors only

# Files (e.g. pull the SQLite db) — debug build only: run-as needs a debuggable app
adb -s $DEV shell run-as com.vemore.countscore ls databases/
adb -s $DEV exec-out run-as com.vemore.countscore cat databases/countscore.db > /tmp/db.sqlite
```

## Preflight checklist before any test session

1. `adb devices` — Pixel listed? If not, ask the user for its address (see Find the device).
2. `adb -s $DEV shell dumpsys battery | grep level` — > 30%? Profile builds drain fast.
3. `adb -s $DEV shell svc power stayon true` — keep screen on while plugged/connected (resets on reboot).
4. Disable "Don't keep activities" in dev options if it's on — it breaks Flutter state restoration tests.
5. For locale tests, note the current locale and restore it at the end.

## When NOT to use this skill

- Pure logic / unit tests — use `flutter test` against `test/`, not the device.
- Widget tests that don't need real platform behavior — same, faster on the host.
- CI runs — this skill assumes the user's specific phone; CI should target an emulator matrix.
- Anything destructive on the device (factory reset, wiping user data outside the app sandbox). Stay inside `pm clear <our-package>` boundaries.
