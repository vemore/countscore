# A device can belong to one group only

- **Noted:** 2026-11-17 — requested by the user
- **Theme:** groups-v2
- **Area:** app
- **Blocks release:** no

`GroupProvider` holds a single `_membership` and a single `_deviceToken`
(`lib/providers/group_provider.dart:106`, `isJoined` at `:128`), saved as one pair by
`SyncCredentials` (`lib/services/sync/sync_credentials.dart`). Joining another group means
leaving the first. `.llmwiki/KnownLimits.md` records it as a deliberate v1 limit: "the schema
supports it (`group_id` per row); the UX was not designed". Someone who plays with family and
with friends cannot keep both.

**Fix:** a design first, then the change.
- Storage: a list of memberships, each with its device token, share token and server URL;
  a migration of the existing single credential into the list.
- Sync: one push/pull and one WebSocket per membership, a game belonging to one group at most
  (`group_id`), and the "sync pass across a group switch" race
  (`wip/todo_nr/2026-09-26-a-sync-pass-running-across-a-group-switch-reports-unauthorized.md`)
  settled on the way.
- UX: Settings → Groups as a list (join, create, leave each); sharing a game asks which group;
  game cards show the group; the configuration QR stays per group.
- Backend: probably nothing, since a device token is already per group — to verify.

**Acceptance:**
- One device joins two groups; a game shared into each syncs to the other members of that
  group only.
- Leaving one group leaves the other's games and sync intact.
- An install upgraded with one group keeps it, with no re-join.

**Open question:** may a game belong to several groups, or one; may two groups live on two
different servers; is a player (a person) shared across groups or one per group.
