# CountScore LLM Wiki — Index

Load this file first. Then read only the pages your task touches.

## Conventions

- `[[Name]]` resolves to `.llmwiki/Name.md`. Links are liberal — a dangling link marks a
  page worth writing, not an error.
- Facts carry their source path (`backend/app/config.py:44`). Values are verbatim: if the
  code says `8192`, write `8192`, never "about 8k".
- Every page ends with `## Decisions & History` — the *why* behind the facts, not a
  restatement of them. Add to it whenever a decision is taken or reversed.
- A fact that turns out to be wrong gets a status block directly under it rather than a
  silent rewrite:
  `> **Status: Outdated** (YYYY-MM-DD) — what changed, and what now holds.`
- When you change a durable fact, update the page **and** its `Updated:` date.
- Do not paste code into pages. Point at the file and the line.

## Overview

| Page | Summary | Updated |
|---|---|---|
| [[Architecture]] | The three evolution axes, target topology, milestone status | 2026-09-19 |
| [[KnownLimits]] | What is deliberately deferred, and what is simply missing | 2026-09-19 |

## Mobile (Flutter)

| Page | Summary | Updated |
|---|---|---|
| [[MobileApp]] | `lib/` layout, providers, screens (the game-type editor among them), widgets, services (the review prompt), `utils/`, the dynamic-icon constraint | 2026-09-20 |
| [[DataLayer]] | Drift owns runtime CRUD; sqflite survives as a bootstrap migrator | 2026-09-20 |
| [[SchemaV10]] | Schema v18: the twelve tables, `rules`/`rules_slug` (21 rulesets, keyed on `builtin_key`), `builtin_key` and its live-unique index, what `isDefault` does and does not mean, sync bookkeeping and capture triggers, tombstones, the migration chain, the v17 dedupe of keyless built-in copies and the v18 replay that restores a wiped slug | 2026-09-20 |
| [[I18n]] | 10 languages × 409 keys, French template, English fallback; built-in game-type names are localized and sorted by a per-name key (pinyin in zh); the key *and* value checks; long-form rules are assets, not ARB; store locales differ | 2026-09-20 |
| [[Web]] | PWA specifics: sqlite3.wasm, IndexedDB (not OPFS) and the flush that makes it survive a reload, committed binaries and the check that gates them, `kIsWeb` guards, the wake lock and sharing under the CSP, base href, the self-hosted CanvasKit and fallback fonts (no Google request), the service worker (offline after one visit, a reload offered after a deploy), the GitHub Pages workflow and its CORS consequences | 2026-09-19 |

## Backend (FastAPI)

| Page | Summary | Updated |
|---|---|---|
| [[Backend]] | Stack, module layout, settings, device-token auth | 2026-09-14 |
| [[Api]] | Every endpoint, its auth requirement and its failure modes | 2026-09-20 |
| [[Sync]] | Delta-log + row-level LWW, the Flutter client (triggers, push/pull, conflicts), the group owner on screen, WebSocket | 2026-09-20 |
| [[LlmProviders]] | The analysis prompt — nine voices, ten languages, the game-type registry — the pluggable provider factory, the separate Claude path, the report control | 2026-09-19 |

## Operations

| Page | Summary | Updated |
|---|---|---|
| [[Deployment]] | Synology NAS, Web Station TLS, `deploy_nas.sh`, `deploy_web.sh`, the Pages copy of the PWA, environment | 2026-09-20 |
| [[Hooks]] | What Claude Code refuses mechanically, why each rule left CLAUDE.md, recovering from a stale branch | 2026-09-19 |
| [[Documentation]] | Which documents a change implicates: wiki, README table, the three privacy documents, why a share sheet is not a data flow; the CLAUDE.md budget | 2026-09-19 |
| [[ParallelDelivery]] | Protection on main, worktrees, local cleanup, why one PR per theme and serial squash merges (`wip/` format: `wip/README.md`), the refinement pass that feeds `wip/todo/` | 2026-09-18 |
| [[Security]] | Defended surfaces (the group owner among them), and the security debt that is knowingly open | 2026-09-20 |
| [[Testing]] | Unit, Drift, migration, e2e web and device; backend pytest, release tooling; CI jobs and how `scope` picks them, `alembic check`, dependency audit, the `web/` binary gate, the privacy page check and the monthly lock refresh | 2026-09-20 |
| [[Release]] | Play Store signing state, publishing through the Play API, target API, 2026 Play policy constraints, release cadence and pruning pass | 2026-09-20 |
| [[StoreListing]] | The 10 store locales, the keyword per market, category and tags, the generated assets (icon and teal feature graphic) and the per-locale composed screenshots, Play's text limits, and the 2026-09-16 acquisition baseline | 2026-09-20 |

## Procedures live in skills, not here

These pages describe *what is*. For *how to do*, use the skills in `.claude/skills/`:
`i18n-add-string`, `db-migration`, `release-android`, `backend-deploy`, `web-deploy`,
`flutter-device-test`, `ship-parallel`.
