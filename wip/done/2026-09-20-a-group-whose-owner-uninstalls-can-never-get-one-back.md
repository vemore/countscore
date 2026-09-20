# A group whose owner uninstalls the app can never get an owner back

**Status:** done (2026-09-20) — closed by feat/group-owner-claim. Shape 2, the deliberate claim: `POST /groups/me/owner/claim` takes the role once the owner has been unseen for `GROUP_OWNER_DORMANT_DAYS` (30, `backend/app/config.py`), 409 while it has been seen; `GET /groups/me/devices` reports `dormant` per device, and the app offers *Claim ownership* on the owner's row. A group with a single live device owns itself, healed on read, and creating a group now says in one line that the role lives on this device. No migration: `devices.last_seen_at` has existed since `0001_initial`.

- **Noted:** 2026-09-20 — reported by the user, read out of `backend/app/routes/groups.py`
- **Theme:** groups-v2
- **Area:** backend
- **Blocks release:** no — but it is the one group failure with no way out, and it leaves a share token nobody can rotate

`Group.owner_device_id` (`backend/app/models/group.py`) is set once, by the device that creates
the group, and moves only on two deliberate acts: *Make owner*
(`PUT /groups/me/owner`) and the owner **leaving**, which hands the role to
`_earliest_live_device` (`backend/app/routes/groups.py:285`). An uninstall is neither: no
request is sent, the `Device` row stays un-revoked, and `_require_owner`
(`groups.py:72`) answers 403 to every other member for ever.

Reinstalling does not help. The device token lives in `flutter_secure_storage` and goes with
the app; the same person rejoining with the share token gets a **new** `Device` row
([[Sync]], "Joining"), not the old one.

What the group loses: revoking a device, *New code* — so the share token that leaked or that an
ex-member still holds can never be rotated — and the monthly budget (`groups.py:199`). Comment
style and language stay open to every member, and sync keeps working.

**Fix — three shapes, to be chosen.** `Device.last_seen_at` already exists, which is what makes
the first two possible with no schema change:

1. **Dormant-owner succession, automatic.** When a group is loaded under its row lock and the
   owner has not been seen for more than `GROUP_OWNER_DORMANT_DAYS` (30?), hand the role to the
   earliest-joined device seen inside that window. Nothing to explain, nothing to store; the
   cost is that a member who is merely on holiday can lose the role.
2. **Dormant-owner claim, deliberate** (*recommended*). Same condition, but it takes an act:
   `POST /groups/me/owner/claim` succeeds only while the owner is dormant, 409 otherwise, and
   Settings → Group → Devices shows *Claim ownership* to a member when the list reports the
   owner dormant. The group decides rather than the clock, and the owner's own reinstall is
   just one more device that may claim it.
3. **A recovery code handed out at creation.** One-time secret shown when the group is created,
   `POST /groups/me/owner/recover` takes the role back. It is the only shape that survives an
   uninstall *immediately* — and the only one that adds a secret the user must keep and an
   attacker may phish. Weakest fit for an app whose other secrets never leave the device.

Two small things belong with whichever is chosen: a group with a **single** live device should
own itself (heal on read — the degenerate case costs nothing), and creating a group should say
in one line that the role lives on this device and can be handed over.

**Acceptance:**
- A group whose owner row has been dormant past the threshold ends up with a live owner, and the new owner can rotate the share token.
- A member cannot take the role while the owner has been seen recently (409, tested).
- A group with exactly one live device reports that device as owner.
- `backend/tests/test_groups.py` covers the dormant, the recent and the single-device cases.

**Decided (2026-09-20, the user):** shape **2, the deliberate claim**. So: a backend change —
`POST /groups/me/owner/claim`, 409 while the owner has been seen recently, the dormancy window
in settings as `GROUP_OWNER_DORMANT_DAYS` — plus the *Claim ownership* action in Settings →
Group → Devices, shown to a member once the device list reports the owner dormant. The two
small things above ship with it: a single-device group owns itself, and creating a group says
the role lives on this device.

The window is **30 days** unless the user says otherwise — long enough that a holiday does not
open a claim, short enough that a group is not stuck for a season. It is a setting, so it costs
nothing to revisit.
