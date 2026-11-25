# The interface offers one group: Settings, game creation, game cards and the QR all assume it

**Status:** done (2026-11-25) — closed by feat/multi-group-ui. Settings → Groups is a list (a card per group with its own status, devices, comments and usage, Leave; one nickname; Create and Join hidden at five), the create screen has a Local / group selector defaulting to the last group used (one group keeps the switch), the board asks which group to share with, game cards show a group badge, and the configuration QR on the same server offers "join this group too?" while another server still replaces (and leaves every group). The single-group compatibility layer is gone. Tests: `test/widgets/groups_list_test.dart`, `test/screens/create_game_group_choice_test.dart`, `test/widgets/group_badge_test.dart`, `test/widgets/replace_config_dialog_test.dart` (group `a group link while in groups`), `test/widgets/share_group_dialog_test.dart`, and `integration_test/multi_group_test.dart` against a local backend; screenshots in `wip/assets/2026-11-25-multi-group-ui/` (web, from that e2e run) rather than a device pass.

- **Noted:** 2026-11-25 — step 4 of `2026-11-17-belong-to-several-groups.md` (decisions there)
- **Theme:** multi-group-ui
- **Area:** app
- **Blocks release:** no

Settings → Group (`group_settings_section.dart`), the share switch on the create screen
(`create_game_screen.dart`), the cloud icon on a shared game's card, and the "replace the
configuration?" dialog (`replace_config_dialog.dart`) each assume one group. Needs
`2026-11-25-multi-group-sync-sessions.md` merged first.

**Fix:**
- Settings → Groups: a list (create, join, leave each; devices and comments per group; a
  status per group), create/join hidden at 5; one nickname field for all.
- Create screen: selector *Local / group A / …*, default the last group used; one group behaves
  as today's switch. Sharing a local game later from the board asks which group.
- Game cards: the cloud icon becomes a badge with the group's name.
- QR on the same server: "join this group too?"; already a member → nothing; another server →
  today's replace flow, which now leaves every group.
- Strings through `i18n-add-string`, 20 languages, ICU plurals.

**Acceptance:**
- Widget tests: the selector with 0, 1 and 2 groups; the badge; the QR dialog's three cases.
- e2e (`integration_test/`, against a local backend): join two groups, create one game in each
  through the selector, both badges shown, leave one, the other's game still syncs.
- A device pass (`flutter-device-test`) of the Groups screen, with screenshots in the pull
  request.
