# Group settings in the app — for 1.2

- **Noted:** 2026-09-13 — out of scope for the sync client, decided with the user; the device list and revoke half shipped 2026-09-14
- **Theme:** groups-v2
- **Area:** app
- **Blocks release:** no

The app does not use `GET/PATCH /groups/me` (comment style, language, LLM budget),
`GET /groups/me/usage`, or the group-scoped comments. Per-field LWW (`field_versions`,
`.llmwiki/Sync.md`) belongs to the same "v2 of groups" conversation, and so does an owner
role: today any member can remove any other (`.llmwiki/Security.md`), which the user wants
revisited before group sharing is opened to the public.
