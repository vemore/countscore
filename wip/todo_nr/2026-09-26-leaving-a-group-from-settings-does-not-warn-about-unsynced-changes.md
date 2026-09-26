# Leaving a group from Settings does not warn about unsynced changes

- **Noted:** 2026-09-26 — while building the configuration QR's replace dialog (feat/config-share-qr)
- **Theme:** groups-v2
- **Area:** app
- **Blocks release:** no

`GroupProvider.leave` ends in `SyncStore.leave`, which empties `outbox`
(`lib/services/sync/sync_store.dart:177`): changes this device has not pushed yet never reach
the group. The replace dialog asks a second question when changes are waiting, counted at that
moment with `GroupProvider.countPending` (`lib/widgets/replace_config_dialog.dart`), but the
two older ways out do not:

- Settings → Group → *Leave* asks `groupLeaveConfirm`, which says nothing about pending
  changes (`lib/widgets/group_settings_section.dart`, the `group_leave` button).
- Clearing the server while in a group asks `clearServerLeavesGroup`, same
  (`_clearServer` in `lib/screens/settings_screen.dart`).

Settings → Group shows `pendingChanges` too, which is only recounted at the end of a sync
pass (`syncNow`): 0 after a cold start until the first pass ends.

The rows themselves stay on the device as local games; what is lost is the group's copy.

**Fix:** both buttons read `GroupProvider.countPending` before asking and, when some remain,
say how many (`replaceConfigUnsynced` or a sibling string), as the replace dialog does.

**Acceptance:**
- *Leave* and *Clear* in Settings, with unsynced changes, show the count and change nothing on *Cancel* (widget test).
- The count shown includes a write made just before the button was pressed (widget test on a real `GroupProvider`).
