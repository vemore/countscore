# A member's configuration QR can carry an invite code the owner has since rotated

- **Noted:** 2026-09-26 — independent review of [vemore/countscore#236](https://github.com/vemore/countscore/pull/236) (finding 4)
- **Theme:** groups-v2
- **Area:** app
- **Blocks release:** no

The configuration QR (`lib/widgets/config_share_sheet.dart`) carries the invite code this
device stored when it joined. Only the owner learns a new one: the owner's rotate and revoke
return it, but the group view every member reads leaves it out on purpose (`GroupPayload`,
`backend/app/schemas/groups.py`: "no share_token"). So after the owner rotates the code, or
revokes a lost phone (which rotates it), every member's QR and the invite code Settings → Group
shows are dead. A device that scans one gets "unknown or replaced invite code" from the join;
since #236 nothing is lost (the join runs first), but the share fails with no hint why.

This was already true of the invite code and its copy button; the QR makes it easier to spread.

**Fix:** on a member's device (not the owner), say on the QR sheet and next to the invite code
that the owner may have replaced it, and point to the owner for a fresh one. The owner's
device, which does learn rotations, needs no change. Alternative to weigh: a member's QR
carries the server only.

**Acceptance:**
- On a member device the QR sheet and the invite code show the "may be out of date" note; on the owner's device they do not (widget test).
- A join refused with 404 from a scanned QR names the stale-code cause in its message (widget test).
