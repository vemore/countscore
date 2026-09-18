# Deployment.md tells operators to rotate from any device, which only the owner can now do

- **Noted:** 2026-09-18 — while adding the group owner (`feat/group-owner`), which could not
  touch `.llmwiki/Deployment.md` because `fix/backend-hardening` owned it in parallel
- **Theme:** docs
- **Area:** docs
- **Blocks release:** no

`.llmwiki/Deployment.md` § *Backups* says to recover from a leaked key by rotating every
group's invite code "(Settings → Group → *New code*, or `POST /groups/me/rotate-share-token`
from one device per group)". Since `0005_group_owner` only the group's owner can rotate:
another device gets a 403, and the app no longer shows *New code* to it.

**Fix:** say "from the owner device of each group" and point at [[Api]] for the owner rule.

**Acceptance:**
- `.llmwiki/Deployment.md` names the owner device as the one that rotates.
