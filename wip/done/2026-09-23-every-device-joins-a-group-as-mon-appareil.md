# Every device joins a group as "Mon appareil"

**Status:** done (2026-09-24) — closed by feat/group-nickname-and-rename. The join and create dialogs ask for a nickname first, empty, with OK disabled until every field is non-blank, and pass the trimmed values; `deviceLabelLabel` and `deviceLabelDefault` gave way to four `groupNickname*` keys in the ten ARB files.

- **Noted:** 2026-09-23 — user request. Production holds two active devices named "Mon appareil", and one of them requested last night's p173 analysis
- **Theme:** groups-v2
- **Area:** app
- **Blocks release:** no

Settings → Group → Join (and Create) opens a dialog: the invite code first, then
"Nom de cet appareil" (`deviceLabelLabel`), pre-filled with `deviceLabelDefault` ("Mon
appareil") (`lib/widgets/group_settings_section.dart:84-105`). OK accepts it as-is, so
everyone leaves the default, and the group's devices list, the comment authors and the
analyses' requester can no longer be told apart. The backend only requires
`min_length=1` (`backend/app/schemas/groups.py:13,18`), which the default satisfies.

**Fix:** in both the join and create dialogs:
- The name field comes **first**, the invite code (or group name) second.
- It is relabelled as a player-facing nickname, e.g. "Ton pseudo" / "Your nickname", with a
  hint saying the others will see it. The exact wording goes through `i18n-add-string`, 10
  locales.
- It starts **empty**, and OK stays disabled until it holds a non-blank value (trimmed,
  ≤ 64 chars, matching the backend).
- `deviceLabelDefault` is removed from the ARB files if nothing else uses it.
Existing devices keep their label. There is no rename endpoint today, and adding one is
out of scope (see Open question).

**Acceptance:**
- Widget test: the join dialog shows the nickname field above the invite field, empty, and OK is disabled until both are filled; a whitespace-only nickname keeps it disabled.
- Same for the create dialog (nickname, then group name).
- `joinGroup` / `createGroup` receive the trimmed nickname (widget test with a fake `GroupProvider`).
- The new label and hint exist in the ten ARB files; `deviceLabelDefault` is gone or still referenced.

**Decided (2026-09-24, refinement):** yes, through
[[2026-09-23-a-device-cannot-rename-itself-in-its-group]], promoted with this entry and shipped
in the same pull request (theme `groups-v2`).
