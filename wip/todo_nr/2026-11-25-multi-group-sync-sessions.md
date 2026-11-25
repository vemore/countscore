# GroupProvider runs one sync loop for one group

- **Noted:** 2026-11-25 — step 3 of `2026-11-17-belong-to-several-groups.md` (decisions there)
- **Theme:** multi-group-sync
- **Area:** app
- **Blocks release:** no

`GroupProvider` (`lib/providers/group_provider.dart`) holds one membership, token, engine,
WebSocket, poll timer, status, owner flag and label. Needs `2026-11-25-multi-group-storage.md`
merged first, and the generation counter of the "sync pass across a group switch" entry.

**Fix:** one session per membership (engine, stream, timers, status, owner, generation); a
local write wakes the sessions that have pending rows. The provider's API takes a `groupId`;
the analysis of a shared game and `play_again` use the game's group. At most 5 memberships
(`GroupActionError.tooManyGroups`). A nickname rename is sent to every membership, and one
that fails is retried at the next sync of that group.

**Acceptance** (`test/sync/`, real backend as in `sync_two_devices_test.dart`, devices X in
A+B, Y in A, Z in B):
- A game shared into A reaches Y and never Z; into B, the reverse.
- A local rename of a player linked in A and B on X reaches Y and Z.
- A rename pulled by X from A is applied on X and not pushed to B; X's next local edit of
  that player carries it (decision 3, pinned by a test).
- X leaves A: B's games, links and sync are intact; a player and a game type still linked in
  B stay.
- Revoking X in A leaves X syncing in B; joining a 6th group is refused before any request.
- A switch or a leave during an in-flight pass of the other group changes nothing in it.
