# The release device pass assumes a Pixel: three things fail on a Xiaomi (MIUI)

- **Noted:** 2026-11-19 — the 1.7.0 device pass on a Xiaomi M2007J3SG, Android 11
- **Theme:** test-tooling
- **Area:** tooling
- **Blocks release:** no

1. **`device_db_roundtrip.sh` hardcodes `PKG="com.vemore.countscore"`** (line 22), but the
   debuggable install holding the old database is `com.vemore.countscore.dev`; `pull` then says
   the package is not debuggable. The pass had to pull by hand with `run-as` on the `.dev`
   package.
2. **MIUI refuses `adb install`** with `INSTALL_FAILED_USER_RESTRICTED` until "Install via USB"
   is allowed in the developer options (it asks for a Mi account). The skill does not say so.
3. **The system file picker cannot be driven by `adb input tap`** on this device: a tap on a
   file or folder row does nothing, only the drawer and the search field answer, and a file
   pushed by `adb` is listed with "0 octet(s)". So Settings → Import and → Export need the
   user's hand on the phone.

**Fix:** a `PKG`/`-p` option for `device_db_roundtrip.sh`; a "MIUI" note in the
`release-android` §5 and `flutter-device-test` skills (Install via USB; do the picker by hand,
or `adb shell am start` an `ACTION_VIEW` on the file); say that the release pass can only be
claimed for what was driven.

**Acceptance:**
- `device_db_roundtrip.sh -p com.vemore.countscore.dev pull` produces a database (test with the
  fake `adb`).
- Both skills mention `INSTALL_FAILED_USER_RESTRICTED` and the picker limit.
