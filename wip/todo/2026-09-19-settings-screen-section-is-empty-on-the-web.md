# On the PWA, Settings ends on a "Screen" heading with nothing under it

- **Noted:** 2026-09-19 — reported by the user ("I cannot reach the bottom of Settings"), reproduced on the local PWA
- **Theme:** web
- **Area:** app
- **Blocks release:** no

Reported as "the bottom of Settings cannot be reached, the screen settings are
inaccessible on the PWA". Reproduced at 412 px: the page does scroll, but the last thing on it
is the **"Screen" heading with nothing below it** ([capture](../assets/2026-09-19-settings-screen-section-is-empty-on-the-web/today.png)). That
reads as a page cut short.

The cause is `lib/screens/settings_screen.dart:262-289`: the heading is drawn on every
platform, but its only setting, "Keep screen awake", is wrapped in `if (!kIsWeb)`, and so is
the Backup section after it. On the web the section exists without its content.

`wakelock_plus` (^1.8.0, `pubspec.yaml:45`) ships a web implementation
(`wakelock_plus_web_plugin.dart`), so there is no evident reason to hide the setting from the
PWA. A phone on a games table is exactly where the screen should stay on.

**Fix:** offer "Keep screen awake" on the web too, after checking that `wakelock_plus` enables
the lock in a browser under the PWA's CSP (`.claude/rules/web.md`). If it cannot, hide the
"Screen" heading on the web together with its content. Either way, no section heading may be
drawn without at least one row under it.

**Acceptance:**
- A widget test with `kIsWeb` forced (or a web e2e run) finds no "Screen" heading without the
  "Keep screen awake" switch under it.
- On the PWA, turning the switch on keeps a Chrome tab awake past the system timeout, or, if
  that fails, the heading is gone and the pull request says why.
- The last row of Settings is fully visible above the bottom inset at 412 × 860 in the PWA.
