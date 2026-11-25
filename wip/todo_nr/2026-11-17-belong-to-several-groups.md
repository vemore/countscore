# A device can belong to one group only

- **Noted:** 2026-11-17 — requested by the user
- **Theme:** groups-v2
- **Area:** app
- **Blocks release:** no

`GroupProvider` holds a single `_membership` and a single `_deviceToken`
(`lib/providers/group_provider.dart`), saved as one pair by `SyncCredentials`
(`lib/services/sync/sync_credentials.dart`). Joining another group means leaving the first.
`.llmwiki/KnownLimits.md` records it as a deliberate v1 limit. Someone who plays with family
and with friends cannot keep both.

**Analysis (2026-11-25).** The backend needs nothing: a device row, and its token, is already
per group, and `/groups/me` resolves the group from the token. Most of `SyncStore` already takes
a `groupId`, and `group_links` is keyed by group. What assumes one group:
1. `outbox` has no `group_id`: a player or game type linked into two groups yields **one**
   outbox row, the first group's push consumes it, the second never gets the edit. Same for
   `sync_inbox`.
2. `SyncStore.join` runs `DELETE FROM sync_state`; `membership()` reads `LIMIT 1`.
3. `SyncStore.leave` empties `outbox`, `group_links`, `entity_versions`, `sync_inbox`,
   `sync_state` whole, not the group's rows.
4. `SyncCredentials` has two fixed keys.
5. `GroupProvider`: one membership, token, stream, timers, status, owner, label.
6. UI: create-game switch, `play_again`, shared-game analysis, Settings → Group, devices sheet,
   the QR dialog that *replaces* the configuration.

**Decisions (user, 2026-11-25):**
1. A game belongs to **one** group at most, for good (the server already refuses an existing
   uuid of another group).
2. A player is **one person** across groups: one local row, linked into each group by name, as
   pulls already do. Two different "Alice" in two groups become one person on this device.
3. A **local** edit of a player or game type goes to every group it is linked in. An edit
   **pulled** from one group is applied locally and **not relayed** to the others; the next
   local edit carries it. No relay means no ping-pong between two devices in both groups.
4. **One server** for every group: the URL stays in `BackendProvider`. Changing it leaves every
   group (asked first); a QR of another server keeps today's "replace" flow.
5. Creating a game: a selector *Local / group A / group B*, defaulting to the last group used.
6. The games list: the cloud icon is **replaced** by a badge with the group's name.
7. Configuration QR on the same server: "join this group too?", leaving nothing; a group already
   joined changes nothing.
8. **One nickname** for all groups, held on the device; a rename is sent to every membership.
9. At most **5 groups**. Client-side only: the server cannot tell two device rows are one install.
10. Sync status per group in Settings, the worst of them wherever one status is shown.

**Plan — one pull request each, in this order:**
- `wip/todo_nr/2026-09-26-a-sync-pass-running-across-a-group-switch-reports-unauthorized.md`
  (prerequisite);
- `wip/todo_nr/2026-11-25-sync-server-adversarial-api-tests.md` (in parallel with the above:
  the server is shared, and hardened before it serves several groups per install);
- `wip/todo_nr/2026-11-25-multi-group-storage.md`;
- `wip/todo_nr/2026-11-25-multi-group-sync-sessions.md`;
- `wip/todo_nr/2026-11-25-multi-group-ui.md`.

This entry closes with the last of them.

**Acceptance:**
- One device joins two groups; a game shared into each syncs to the other members of that
  group only (integration test through a real backend).
- Leaving one group leaves the other's games and sync intact.
- An install upgraded with one group keeps it, with no re-join.
