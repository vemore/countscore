# The invite code shows blank in Settings on the web

- **Noted:** 2026-11-25 — on the screenshots of the multi-group e2e (`feat/multi-group-ui`)
- **Theme:** web
- **Area:** web
- **Blocks release:** no

In headless Chrome (`integration_test/multi_group_test.dart`,
`wip/assets/2026-11-25-multi-group-ui/groups.png`), a group's card shows the *Invite code*
label and its explanation with an empty line between them: the code itself, a
`SelectableText` styled `fontFamily: 'monospace'` (`lib/widgets/group_settings_section.dart`,
key `group_share_token`), is not drawn. The style predates the multi-group change (the old
single-group section used the same widget). The PWA self-hosts its fonts
(`.llmwiki/Web.md`, "Self-hosted web resources") and bundles no font named `monospace`, so
the likely cause is a family the web engine cannot resolve; not checked on a real browser
window or on Android yet. *Copy the code* and the QR still carry it.

**Fix:** confirm in a headed browser; then give the code a font the build ships (the app's
own, with tabular figures), or bundle a monospace one.

**Acceptance:**
- The multi-group e2e's `groups` screenshot shows the invite code.
- A widget test finds the code's text in `group_share_token` (already true on the VM).
