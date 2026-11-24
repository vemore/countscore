# A local edit can push back a player's old name over a rename another device made

- **Noted:** 2026-11-24 — independent review of vemore/countscore#286
- **Theme:** sync
- **Area:** app
- **Blocks release:** no — needs a rename onto a name this device already uses for someone else

`_applyPlayer` (`lib/services/sync/sync_store.dart`) keeps the local name when a pulled
rename would clash with another local player (the local unique name index counts tombstoned
rows too). The device then holds the old name under the group's identity, and its next
captured change to that player (a colour edit, and since #286 a delete, which now sends the
player's last name) pushes the old name with a fresh lamport: the group's rename is undone
on the server and on every device.

Scenario: B renames the shared "Thibaut" to "Tibo"; A has its own unrelated "Tibo", so A
keeps "Thibaut"; A deletes the player (or changes its colour); everyone is back to "Thibaut".

**Fix:** remember that a pulled name was refused locally (a column, or the pulled name kept
in `entity_versions`), and push the group's name rather than the local one for that row;
or omit `name` from the payload when the local name differs because of a clash.

**Acceptance:**
- B renames a shared player onto a name A uses for someone else; A then edits or deletes
  that player; B still shows the new name.
