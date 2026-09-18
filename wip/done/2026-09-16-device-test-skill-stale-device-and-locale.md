# `flutter-device-test` sends you to the wrong address, the wrong locale syntax and a build without `run-as`

**Status:** done (2026-09-18) — closed by chore/test-tooling-housekeeping. `flutter-device-test` has no hardcoded address: a *Find the device* step runs `adb devices`, then asks the user for `<ip>:<port>` from Settings → Wireless debugging, never scanning the LAN. Mode 1 runs `--debug` and says `run-as` needs a debuggable build; `--profile` is left in Modes 1b and 3 only.

- **Noted:** 2026-09-16 — running the skill to test everything since tag 1.1.0+4
- **Theme:** test-tooling
- **Area:** tooling
- **Blocks release:** no

Three things in `.claude/skills/flutter-device-test/SKILL.md` cost a detour in one session:

- **The ADB address is hardcoded and stale.** `192.168.1.199:44249` gave *No route to host*;
  the phone was at another IP and another port. `adb mdns services` returned an empty list
  (WSL2 does not see the phone's mDNS), so nothing in the skill recovers the address — the
  user had to read it off the phone. The port changes on every reboot of wireless debugging.
- **The per-app locale command is wrong on Android 16.** `cmd locale set-app-locales <pkg>
  --locales=de` throws `IllegalArgumentException: Unknown option: --locales=de`; the option
  takes a space: `--locales de`, and `--locales ""` resets. **Fixed inline** in the same
  change that filed this entry.
- **Mode 1 says `--profile`, and profile kills half the cheatsheet.** A profile APK is not
  debuggable, so every `run-as` command the skill lists — pulling `databases/countscore.db`,
  reading `shared_prefs` — fails against it. Seeding `SharedPreferences` to reach the review
  prompt's seven-day guard is only possible on a debug build.

**Fix:** the two remaining ones. Replace the hardcoded address with a discovery step
(`adb devices` first, then ask the user for `<ip>:<port>` from Settings → Wireless debugging —
do not scan the LAN), and say in Mode 1 that functional work uses `--debug` because `run-as`
needs it, `--profile` being for Mode 1b and Mode 3 only.

**Acceptance:**
- No hardcoded IP:port remains in `flutter-device-test`: the setup runs `adb devices`, then asks the user for the wireless-debugging address.
- Mode 1 uses `--debug` and says why `run-as` needs it.
- `--profile` appears only in Modes 1b and 3.
