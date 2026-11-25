# MultiGroup

> Scope: one device in several groups — the sessions, the limits, what one status means.
> Related: [[Sync]] · [[Schema]] · [[MobileApp]] · [[KnownLimits]]
> Updated: 2026-11-25

## Facts

`GroupProvider` (`lib/providers/group_provider.dart`) holds one `GroupSession`
(`group_session.dart`) per membership, in join order: that group's token, invite code,
WebSocket, poll and debounce timers, status, counts, owner flag, generation and what its
server calls this device. They share the one server URL (decision 4), the nickname, the
local-write listener, the lifecycle observer and the event stream. Each runs `SyncEngine`
for its own group; two groups' passes run side by side, their transactions serialised by
Drift. The user's decisions are in `wip/todo/2026-11-17-belong-to-several-groups.md`.

- **At most `GroupProvider.maxGroups` (5)** (`GroupActionError.tooManyGroups`,
  `groupErrorTooManyGroups`): the server cannot tell two device rows are one install. At five,
  a create, and a join whose code matches none of the invite codes this device holds, are
  refused before any request. A join with a held code goes to the server, since only its
  answer names the group: the group already joined takes the new registration; a new one
  (the code moved to another group) is refused then, its registration revoked and nothing
  kept. A group's rotated code that this device does not hold yet is refused at five.
- **Create and join add a membership**; the same group joined again takes the new
  registration and revokes the old one. **The configuration QR still replaces**
  (`completeJoin` leaves every group first, unless the code is a group already joined): the
  dialog says so, and the multi-group UI changes it to "join this group too?" (decision 7).
- **A game's group** is the game's `group_id`: its analysis (`gameAnalysis(groupId, …)`),
  `analysesThroughGroup`, and its rematch (`play_again.dart`, shared with the source's group
  while this device is in it) go to that group's session. Sharing names the group
  (`shareGame(gameId, groupId)`); the create switch and the board's share action still name
  the first group, as the dialogs do.
- **One status where one is shown**: `GroupProvider.status` is the worst of every group's
  (`SyncStatus.worse`: off < idle < syncing < offline < error < unauthorized),
  `pendingChanges` and `rejectedChanges` the sums, `lastSyncAt` the oldest. Per group:
  `session(groupId).status`.
- **Revoked or left in one group, the others sync on.** A local edit of a player or game
  type linked in several groups is queued for each (the v23 triggers); one pulled from one
  group is applied and not relayed (`sync_flags.suppress`), and reaches the others with the
  row's next local edit (decision 3).

Tests: `test/providers/group_provider_multi_group_test.dart` (mock server) and
`test/sync/sync_multi_group_backend_test.dart` (a real server: X in A and B, Y in A, Z in B;
run by the `sync` CI job beside `sync_two_devices_test.dart`).

The storage under it — the per-group queue, quarantine, versions and credentials, and the
reconciliation on start — is [[Sync]] (*The client*) and [[Schema]] (v23). The nickname's
rules are [[Sync]], *The nickname*.

## Decisions & History

- **One session per membership, behind a thin single-group layer (2026-11-25,
  `feat/multi-group-sync-sessions`).** A session is a `part` of the provider rather than a
  provider of its own: it needs the provider's server, nickname and event stream, and a
  `ChangeNotifier` per group would leave every screen choosing which to listen to before the
  UI exists. The screens that need *a game's* group got an explicit API (`session`,
  `gameAnalysis(groupId, …)`, `shareGame(gameId, groupId)`); the ones the next PR rewrites
  (Settings → Group, the QR dialog, the create switch, the devices sheet) read the first
  group, so this change ships nothing a user can see beyond the nickname.
- **The device's nickname wins over a group's copy (2026-11-25).** The nickname entry said
  to save the label a devices list reports. With several groups that would let a group
  that missed a rename — offline then, or the app restarted before its retry — hand the old
  name back to the device and on to the others. The device's stored nickname is the truth
  (decision 8: "held on the device"); a list's label is learnt only when none is stored, and
  a group whose copy differs gets the device's at its next successful pass.
- **The user's ten decisions (2026-11-25)** are recorded in
  `wip/todo/2026-11-17-belong-to-several-groups.md`, with the plan of pull requests: the
  prerequisite generation counter, the adversarial server suite, the storage (v23), these
  sessions, then the UI.
