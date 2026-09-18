# `flutter-device-test` Modes 1b and 3 pass a flag `flutter run` rejects

- **Noted:** 2026-09-18 — while fixing the skill's device address and debug/profile guidance (chore/test-tooling-housekeeping)
- **Theme:** test-tooling
- **Area:** tooling
- **Blocks release:** no

`.claude/skills/flutter-device-test/SKILL.md` says in Mode 1 that `--no-tree-shake-icons` "is a
`flutter build` flag only — `flutter run` rejects it with exit 64". Yet Mode 1b runs
`flutter run -d $DEV --profile --no-tree-shake-icons` and Mode 3 runs
`flutter run -d $DEV --profile --no-tree-shake-icons --trace-startup`. One of the two claims
is wrong; if the note is right, both modes fail at the first command.

**Fix:** check `flutter run --no-tree-shake-icons` against the installed Flutter, then either
drop the flag from Modes 1b and 3 or correct the Mode 1 note.

**Acceptance:**
- The skill's Mode 1 note and its Mode 1b / Mode 3 commands agree about `--no-tree-shake-icons`.
- The Mode 1b and Mode 3 `flutter run` commands start without a usage error.
- The `flutter test integration_test` commands (`SKILL.md:205,207`) no longer pass the flag either: `flutter test -h` does not list it.
