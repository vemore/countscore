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

**Open question:** Split this umbrella entry into the settings/usage screen, per-field LWW and the owner role? Since #76 the voice is chosen for each analysis, and the group style is only a fallback: are the group comment style and language still wanted? Is the owner role a prerequisite for public group sharing? (The routes are `GET /groups/me`, `PATCH /groups/me/settings` and `GET /groups/me/usage`.)
