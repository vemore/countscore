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
- **One owner per fact.** A fact lives on one page; other pages link to it, never restate it.
- **Changing a fact is an ingest.** `grep -rn` the old value across `.llmwiki/` and fix every
  page it falsifies, in the same change, each with its `Updated:` date and its row below.
- **Answers compound.** A synthesis the next task would otherwise rebuild — a root cause, a
  comparison, a measured figure — goes into the page that owns the topic in the same pull
  request, not only into the chat or the pull request body.
- Two pages that disagree and cannot be settled now: `> **Status: Contradicted** (YYYY-MM-DD)
  — see [[Other]]` on both, and a `wip/` entry.
- **Budgets:** a row below is one line of 25 words at most; a page stays under 400 lines —
  past it, split by sub-topic and leave a pointer. The lint pass: [[Documentation]].
- Do not paste code into pages. Point at the file and the line.

## Overview

| Page | Summary | Updated |
|---|---|---|
| [[Architecture]] | The three evolution axes, target topology, milestone status | 2026-09-19 |
| [[KnownLimits]] | What is deliberately deferred, and what is simply missing | 2026-09-19 |

## Mobile (Flutter)

| Page | Summary | Updated |
|---|---|---|
| [[MobileApp]] | `lib/` layout, providers, screens, widgets, services and `utils/`, the dynamic-icon constraint | 2026-09-26 |
| [[DataLayer]] | Drift owns runtime CRUD; sqflite survives as a bootstrap migrator | 2026-09-26 |
| [[Schema]] | Schema v21: the twelve tables, `builtin_key` and its unique index, sync bookkeeping and triggers, tombstones, the migration chain and its repair steps | 2026-09-26 |
| [[ConfigShare]] | The configuration QR: the `#/join` link and its parser, the PWA base, the replace dialog, what opens a link (PWA route, Android deep link) | 2026-09-26 |
| [[I18n]] | 10 languages × 451 keys, French template, English fallback, localized built-in names and their sort key, the ARB checks, rules as assets | 2026-09-26 |
| [[Web]] | PWA: sqlite3.wasm on IndexedDB and its flush, committed binaries, `kIsWeb` guards, the CSP, self-hosted fonts, the service worker, GitHub Pages | 2026-09-26 |

## Backend (FastAPI)

| Page | Summary | Updated |
|---|---|---|
| [[Backend]] | Stack, module layout, settings, device-token auth | 2026-09-14 |
| [[Api]] | Every endpoint, its auth requirement and its failure modes | 2026-09-25 |
| [[Sync]] | Delta-log + row-level LWW, the Flutter client (triggers, push/pull, conflicts), the group owner on screen, WebSocket | 2026-09-26 |
| [[LlmProviders]] | The analysis prompt — nine voices, ten languages, the game-type registry — the pluggable provider factory, the separate Claude path, the report control | 2026-09-19 |

## Operations

| Page | Summary | Updated |
|---|---|---|
| [[Deployment]] | Synology NAS, Web Station TLS, `deploy_nas.sh`, `deploy_web.sh`, the Pages copy of the PWA, environment | 2026-09-24 |
| [[AgentEvals]] | `evals/run.sh`: past tasks replayed with `claude -p` in throwaway worktrees, script-checked; when to run them, skill-creator cases per skill | 2026-09-26 |
| [[Hooks]] | What Claude Code refuses mechanically, why each rule left CLAUDE.md, recovering from a stale branch | 2026-09-19 |
| [[Documentation]] | Which documents a change implicates (wiki, README, the three privacy documents), the wiki lint pass, the CLAUDE.md budget | 2026-09-26 |
| [[ParallelDelivery]] | Protection on main, worktrees, cleanup, one PR per theme, serial squash merges, refinement, lanes A–D, model routing, the reviewer, "merged, not deployed", metrics | 2026-09-26 |
| [[Security]] | Defended surfaces (the group owner among them), and the security debt that is knowingly open | 2026-09-26 |
| [[Testing]] | Unit, Drift, migration, e2e web and device, backend pytest; CI jobs and `scope`, and the extra gates (alembic, audit, binaries, privacy page) | 2026-09-26 |
| [[Release]] | Play signing, publishing through the Play API, target API, 2026 policy constraints, cadence, the pruning pass | 2026-09-26 |
| [[StoreListing]] | The 10 store locales and their keywords, category and tags, generated icon, feature graphic and screenshots, text limits, acquisition baseline | 2026-09-20 |

## Procedures live in skills, not here

These pages describe *what is*. For *how to do*, use the skills in `.claude/skills/`:
`i18n-add-string`, `db-migration`, `release-android`, `backend-deploy`, `web-deploy`,
`flutter-device-test`, `ship-parallel`, `wip-refine`.
