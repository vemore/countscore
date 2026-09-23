# A device cannot rename itself in its group

- **Noted:** 2026-09-23 — user request, following [[2026-09-23-every-device-joins-a-group-as-mon-appareil]]
- **Theme:** groups-v2
- **Area:** app, backend
- **Blocks release:** no

A device's name in a group (`devices.label`) is chosen once, when the device joins or creates
the group (`backend/app/routes/groups.py:203,236`), and can't be changed afterwards. There is
no endpoint and no field in Settings → Group. The two production devices still called "Mon
appareil" could only take another name by leaving the group and joining again.

**Fix:**
- Backend: `PATCH /groups/devices/me` with `{label}` (1–64 chars, trimmed), authenticated as
  the device itself. It updates `devices.label` and nothing else, with its own rate-limit
  bucket.
- App: Settings → Group shows "Ton pseudo: <label>" with an edit action, reusing the
  nickname field and its validation from the join dialog. The devices sheet
  (`lib/widgets/group_devices_sheet.dart`) picks up the new name on the next refresh.
- Strings through `i18n-add-string` (10 locales). `.llmwiki/Api.md` updated for the new route.

**Acceptance:**
- pytest: a device renames itself, gets 422 on an empty or 65-character label, and cannot rename another device (no device id in the route).
- Widget test: editing the nickname in Settings → Group calls the client with the trimmed value and shows the new name.
- The two-device sync CI job still passes (a rename changes no synced row).
