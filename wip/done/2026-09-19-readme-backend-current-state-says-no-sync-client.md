# README says the Flutter client for groups and sync has not been written

**Status:** done (2026-09-24) — closed by docs/readme-and-asset-requirements. The README Backend paragraph now says the app is a client of `/comments/*`, `/groups/*` and `/sync/*` once a server is configured, and of none of them without one.

- **Noted:** 2026-09-19 — while updating README.md for feat/group-comment-analysis
- **Theme:** docs
- **Area:** docs
- **Blocks release:** no

`README.md`, section *Backend*, paragraph "**Current state, stated plainly:**" still says the
server side of groups and sync is implemented "but **the Flutter client for it has not been
written yet**. The app is therefore local-only today, and the single live app↔backend call is
the game analysis". The same README's *Features* and *Privacy* sections describe group sharing
as shipped (Settings → Group, `lib/providers/group_provider.dart`, `lib/services/sync/`), and
since 2026-09-19 a shared game's analysis goes through the group endpoint too. A newcomer
reading the Backend section gets the opposite of the truth.

**Fix:** rewrite the paragraph to what holds — the app is a client of every surface in the
table (groups, sync push/pull/stream, the comment endpoints) once a server is configured —
or drop it, since the Features section already says it.

**Acceptance:**
- `grep -n "has not been written yet" README.md` finds nothing.
- The Backend section names no app↔backend call as the only one.
