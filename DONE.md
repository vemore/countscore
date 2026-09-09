# DONE

Closed items, newest first. Moved out of `TODO.md` when they were finished, so that file
holds only open work. Nothing here is deleted — the reasoning behind a decision stays
readable after the fact.

---

## `ThemeProvider` never persists

**Status:** done (2026-09-09) — closed by `ccc3640`, *fix: persist the selected theme
across restarts*. Surfaced during the LLM-wiki migration.

`lib/providers/theme_provider.dart` held `ThemeMode` in memory only, so the app reset to
`ThemeMode.system` on every restart. It now stores `ThemeMode.name` under the `themeMode`
key, and `main()` reads it before `runApp` rather than loading async in the constructor
the way `SettingsProvider` does — that pattern would have shown a light flash on every
cold start for a dark-mode user. The unused `toggleTheme()` and `isDarkMode` went with it.

---

## Backend security debt

**Status:** done (2026-09-09) — closed by `c14ff9c`, *feat(backend): harden the API, and
make ruff and mypy green*, recorded in `ef57989`. Surfaced during the LLM-wiki migration.

All five catalogued items are closed, plus four found while reading the code:
WebSocket ticket handshake, IP rate limit on group create/join, `share_token`
out of `GET /groups/me`, value bounds on `/sync/push`, security headers; and
the driver error leaked in sync rejections, the `--workers 2` default in the
Dockerfile, the `Content-Length` bypass of the body cap, and the one
string-built SQL statement in `notify.py`.

Details and the reasoning: `.llmwiki/Security.md`. What remains open is listed
there too — the unauthenticated `/comments` endpoints, the O(N) argon2 scan,
and the absence of an owner role on `Device`.

---

## Backend lint debt and type checking

**Status:** done (2026-09-09) — closed by `c14ff9c`, *feat(backend): harden the API, and
make ruff and mypy green*. Surfaced during the LLM-wiki migration.

`ruff check .` in `backend/` is clean, and `mypy` is now configured
(`[tool.mypy]` in `backend/pyproject.toml`) and clean over the 36 source files.
The SQLModel query expressions were rewritten with `sqlmodel.col()` rather than
having the error codes silenced, so the checker still reads those lines.

`openai` is unpinned from `>=2,<3` to `>=3,<4` (3.10.0). The only breaking
change in 3.0 was httpx2 as the default client, which `openai_compat.py` never
touched — and `anthropic` 1.4 was already on httpx2, so the tree converged.

Note: `ruff format` has still **never** been run on `backend/` — that stays open in
`TODO.md`.
