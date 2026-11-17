# The device-test skill connects to whatever phone answers, and calls it the Pixel

- **Noted:** 2026-11-17 — taking the landscape screenshots for `feat/landscape-layout`
- **Theme:** test-tooling
- **Area:** tooling
- **Blocks release:** no

`.claude/skills/flutter-device-test/scripts/adb_connect.sh` returns the first Wi-Fi device
`adb devices` lists as `device` (step 1), without checking what it is. On 2026-11-17 it
returned `192.168.1.117:41669`, which `getprop ro.product.model` reports as `M2007J3SG`
(a Xiaomi Mi 10T Pro, 1080x2400 at 440 dpi), not the Pixel 9 Pro XL the skill describes
— and the same phone was listed twice, once by IP and once by its mDNS name. Nothing in
the skill says to check the model, so a session would have taken this phone's screenshots
as the Pixel's. The phone also carried a release build of CountScore (not debuggable), so
`flutter run` would have needed an uninstall — the user's data — before it could install a
debug build; the skill does not warn about that either. Its *Device Reference* also gives an
`adb` path (`/home/vemore/sdk/android/platform-tools/adb`) that does not exist on this
machine (`/home/vemore/Android/Sdk/platform-tools/adb`).

**Fix:** `adb_connect.sh` prints the model of the device it returns on stderr and, unless
`ADB_HOST` names one, refuses a device whose `ro.product.model` is not a Pixel 9 Pro XL
(exit 1 with what it found); the skill's preflight checks whether the installed
`com.vemore.countscore` is debuggable before any `flutter run`, and says never to uninstall
it without the user's go; the *Device Reference* drops the hardcoded `adb` path for
`command -v adb`.

**Acceptance:**
- With only a non-Pixel phone connected, `adb_connect.sh` exits 1 and names its model.
- The skill's preflight lists the debuggable check and the no-uninstall rule.
