# GroupProvider keeps two first-group getters for one sync test

- **Noted:** 2026-11-25 — while removing the single-group compatibility layer (`feat/multi-group-ui`)
- **Theme:** multi-group-ui
- **Area:** app
- **Blocks release:** no

`feat/multi-group-ui` moved every screen to `GroupProvider.memberships` and
`session(groupId)` and removed the compatibility layer that read "the first group joined"
(`groupName`, `deviceId`, `isOwner`, `deviceLabel`, `canReachGroup`, the owner and comment
actions). Two getters stay, `groupId` and `shareToken` (`lib/providers/group_provider.dart`,
`@visibleForTesting`): `test/sync/sync_reconcile_test.dart` reads them (lines 266–267), and
`test/sync/` belonged to a parallel pull request (`fix/restored-device-own-deltas`) at the time.
`test/providers/group_provider_join_test.dart`, `group_provider_generation_test.dart` and
`test/widgets/*` read them too, where `memberships.single` would say the same.

**Fix:** read `group.memberships.single.groupId` / `.shareToken` in those tests, then delete
the two getters. No behaviour changes.

**Acceptance:**
- `grep -rn "group\.groupId\b\|group\.shareToken\b" test` finds nothing that reads the provider's.
- `GroupProvider` has no getter that names one group without a group id.
