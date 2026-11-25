# The nickname stored on the device is not read by GroupProvider

**Status:** done (2026-11-25) — closed by feat/multi-group-sync-sessions. The nickname is saved on create, join and rename, read on start (known offline), offered in the create and join dialogs, and sent to every membership; a group that missed it gets it after its next successful pass. A devices list's label is saved only when the device holds none — otherwise the device's nickname wins and is sent back (`.llmwiki/MultiGroup.md`, *Decisions & History*). `privacy_policy.md` item 6 and v2.14 say it is stored on the device.

- **Noted:** 2026-11-25 — feat/multi-group-storage (step 2 of `2026-11-17-belong-to-several-groups.md`)
- **Theme:** multi-group-sync
- **Area:** app
- **Blocks release:** no

Decision 8 of the multi-group plan: one nickname for every group, held on the device.
feat/multi-group-storage added the storage — `SyncCredentials.nickname()` and
`saveNickname()` (`lib/services/sync/sync_credentials.dart`, key `sync.nickname`, kept when a
group's pair is cleared) — but did not wire it: that PR was scoped to touch
`lib/providers/group_provider.dart` only at the storage API's call sites, while
fix/sync-generation reworked the same file. `GroupProvider.deviceLabel` is still held in memory
only, and `test/providers/group_provider_nickname_test.dart` pins "null after a restart until
the devices list answers".

**Fix:** with the per-group sessions (`2026-11-25-multi-group-sync-sessions.md`): save the
nickname on create, join, rename and when the devices list reports this device's label; read
it on start as `deviceLabel`, and offer it as the default in the join dialog of a second
group. The nickname test's "null after a restart" becomes "the stored one after a restart".
Nothing calls `saveNickname` yet, so the device stores no nickname today: the change that
does adds it to item 6 of `privacy_policy.md` ("Group membership", what stays on the device).

**Acceptance:**
- After a restart with the server unreachable, `deviceLabel` is the nickname last saved.
- Joining a second group offers that nickname, and a rename is stored once for all groups.
