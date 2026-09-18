# A group has no owner: any member can revoke any other

- **Noted:** 2026-09-18 — split out of `2026-09-13-group-settings-in-app` during refinement
- **Theme:** groups-v2
- **Area:** backend
- **Blocks release:** no — groups are shared within a household today

`.llmwiki/Security.md` § "Every device in a group is equal": there is no owner role on
`Device`, so any member can rotate the share token or revoke a sibling device, and since
2026-09-14 Settings → Group → Devices puts that on screen. It fits the household model, not a
public one. **Decided with the user (2026-09-18): the owner role is a prerequisite for opening
group sharing to the public.**

**Fix:** an owner (the device that created the group) on the server; only the owner may
revoke a device or rotate the share token; ownership can be handed over. The app hides the
revoke action from other members. Alembic migration assigns the owner of existing groups.

**Acceptance:**
- A non-owner's revoke or rotate is refused by the server (test).
- Existing groups get an owner from the migration.
- `.llmwiki/Security.md` no longer lists the lateral privilege as open.
