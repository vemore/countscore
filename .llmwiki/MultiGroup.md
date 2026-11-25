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
Drift. The user's decisions are in `wip/done/2026-11-17-belong-to-several-groups.md`.

- **At most `GroupProvider.maxGroups` (5)** (`GroupActionError.tooManyGroups`,
  `groupErrorTooManyGroups`): the server cannot tell two device rows are one install. At five,
  a create, and a join whose code matches none of the invite codes this device holds, are
  refused before any request. A join with a held code goes to the server, since only its
  answer names the group: the group already joined takes the new registration; a new one
  (the code moved to another group) is refused then, its registration revoked and nothing
  kept. A group's rotated code that this device does not hold yet is refused at five.
- **Create and join add a membership**; the same group joined again takes the new
  registration and revokes the old one. **The configuration QR on the same server adds one
  too** ("join this group too?", decision 7): `completeJoin` adopts it beside the others
  (refused at five), keeps a group already joined, and leaves every group only for another
  server (decision 4). The three paths are [[ConfigShare]], *The replace dialog*.
- **A game's group** is the game's `group_id`: its analysis (`gameAnalysis(groupId, …)`),
  `analysesThroughGroup`, and its rematch (`play_again.dart`, shared with the source's group
  while this device is in it) go to that group's session. Sharing names the group
  (`shareGame(gameId, groupId)`).
- **Where a game goes** (decision 5): the create screen shows nothing in no group, today's
  *Share with the group* switch (on) in one, and in several a chip per group beside *This
  device only* (`create_group_<groupId>`, `create_group_local`), starting on the group the last
  game was created in (`LastGameGroup`, SharedPreferences `lastGameGroupId`; a game created
  local leaves it; a group since left falls back on the first joined). The board's *Share
  with the group* names the one group, or asks which of several with none preselected
  (`showShareGroupDialog`): sharing cannot be undone.
- **A shared game shows its group** (decision 6): `GroupBadge`, a small rounded label with the
  group's name (tooltip `gameSharedWith`), on the game cards, the Resume card and the board's
  title, where a cloud icon was. A group this device does not know by name shows the cloud
  icon.
- **Settings → Groups** (`group_settings_section.dart`) is a list: one card per group
  (`group_card_<groupId>`, unfolded when it is the only one) with its own status, waiting and
  refused counts, invite code, *Sync now*, QR, *Devices* (`GroupDevicesSheet(groupId)`, the
  owner actions included), *Comments and usage* (`GroupSettingsScreen(groupId)`), the owner's
  *Rotate* and its own *Leave* (`leaveGroup`, that group's pending count); one nickname row
  above the list (decision 8); *Create* and *Join* replaced by `groupsMaxReached` at
  `maxGroups` (`GroupProvider.canJoinMore`).
- **One status where one is shown**: `GroupProvider.status` is the worst of every group's
  (`SyncStatus.worse`: off < idle < syncing < offline < error < unauthorized),
  `pendingChanges` and `rejectedChanges` the sums, `lastSyncAt` the oldest. Per group:
  `session(groupId).status`, which is what Settings → Groups shows on each card; no screen
  shows a single figure today.
- **Revoked or left in one group, the others sync on.** A local edit of a player or game
  type linked in several groups is queued for each (the v23 triggers); one pulled from one
  group is applied and not relayed (`sync_flags.suppress`), and reaches the others with the
  row's next local edit (decision 3).

Tests: `test/providers/group_provider_multi_group_test.dart` (mock server) and
`test/sync/sync_multi_group_backend_test.dart` (a real server: X in A and B, Y in A, Z in B;
run by the `sync` CI job beside `sync_two_devices_test.dart`). The screens:
`test/widgets/groups_list_test.dart` (the list, per-group status, leave one, five),
`test/screens/create_game_group_choice_test.dart` (0, 1 and 2 groups, the remembered
default), `test/widgets/group_badge_test.dart`, `test/widgets/replace_config_dialog_test.dart`
(group `a group link while in groups`) and `integration_test/multi_group_test.dart` (two groups
through the UI against a local backend, [[Testing]]).

The storage under it — the per-group queue, quarantine, versions and credentials, and the
reconciliation on start — is [[Sync]] (*The client*) and [[Schema]] (v23). The nickname's
rules are [[Sync]], *The nickname*.

## Decisions & History

- **The screens name their group; the single-group layer is gone (2026-11-25,
  `feat/multi-group-ui`).** Every screen reads `memberships` or `session(groupId)`;
  `groupName`, `deviceId`, `isOwner`, `deviceLabel`, `canReachGroup` and the owner and
  comment actions on the provider were removed. `groupId` and `shareToken` (the first group)
  stay, `@visibleForTesting`, for `test/sync/sync_reconcile_test.dart`, which this change
  could not edit. The create selector remembers the last *group*, not the last choice: a
  local game now and then should not turn sharing off by default, as the single-group switch
  was on by default. The board's share asks with no group preselected, where the create
  selector preselects one: a game created in the wrong group is one tap from the default the
  user sees, a share cannot be undone.
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
  `wip/done/2026-11-17-belong-to-several-groups.md`, with the plan of pull requests: the
  prerequisite generation counter, the adversarial server suite, the storage (v23), these
  sessions, then the UI.
