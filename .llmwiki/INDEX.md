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
| [[Architecture]] | The three evolution axes, target topology, milestone status | 2026-09-13 |
| [[KnownLimits]] | What is deliberately deferred, and what is simply missing | 2026-09-14 |

## Mobile (Flutter)

| Page | Summary | Updated |
|---|---|---|
| [[MobileApp]] | `lib/` layout, providers, screens, the dynamic-icon constraint | 2026-09-14 |
| [[DataLayer]] | Drift owns runtime CRUD; sqflite survives as a bootstrap migrator | 2026-09-13 |
| [[SchemaV10]] | Schema v11: the twelve tables, sync bookkeeping and capture triggers, tombstones, the migration chain | 2026-09-13 |
| [[I18n]] | 10 languages × 233 keys, French template, English fallback | 2026-09-14 |
| [[Web]] | PWA specifics: sqlite3.wasm, OPFS, committed binaries, `kIsWeb` guards, base href | 2026-09-14 |

## Backend (FastAPI)

| Page | Summary | Updated |
|---|---|---|
| [[Backend]] | Stack, module layout, settings, device-token auth | 2026-09-14 |
| [[Api]] | Every endpoint, its auth requirement and its failure modes | 2026-09-14 |
| [[Sync]] | Delta-log + row-level LWW, the Flutter client (triggers, push/pull, conflicts), WebSocket | 2026-09-14 |
| [[LlmProviders]] | ZapZap prompt, the pluggable provider factory, the separate Claude path, the report control | 2026-09-14 |

## Operations

| Page | Summary | Updated |
|---|---|---|
| [[Deployment]] | Synology NAS, Web Station TLS, `deploy_nas.sh`, `deploy_web.sh`, environment | 2026-09-14 |
| [[Hooks]] | What Claude Code refuses mechanically, why each rule left CLAUDE.md, recovering from a stale branch | 2026-09-14 |
| [[Documentation]] | Which documents a change implicates: wiki, README table, the three privacy documents; the CLAUDE.md budget | 2026-09-14 |
| [[ParallelDelivery]] | Protection on main, worktrees, local cleanup, why one PR per theme and serial squash merges (`wip/` format: `wip/README.md`) | 2026-09-14 |
| [[Security]] | Defended surfaces, and the security debt that is knowingly open | 2026-09-14 |
| [[Testing]] | Unit, Drift, migration, e2e web and device; backend pytest; CI jobs, `alembic check`, dependency audit | 2026-09-14 |
| [[Release]] | Play Store signing state, target API, 2026 Play policy constraints, release cadence and pruning pass | 2026-09-14 |

## Procedures live in skills, not here

These pages describe *what is*. For *how to do*, use the skills in `.claude/skills/`:
`i18n-add-string`, `db-migration`, `release-android`, `backend-deploy`, `web-deploy`,
`flutter-device-test`, `ship-parallel`.
