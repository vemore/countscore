# The quality gates are written out in three places

- **Noted:** 2026-09-18 — comparing the project's SDLC with "Your SDLC is your context
  engineering" (Daniel Kravets, LeadDev, 2026-08-10)
- **Theme:** hooks
- **Area:** tooling
- **Blocks release:** no

`ruff check`, `ruff format --check`, `mypy` and `flutter analyze` are each spelled out in
`.claude/hooks/guard-bash.sh:258-269` (commit gate), `.github/workflows/ci.yml:199-206` and
`:444-445` (CI), and `backend/CLAUDE.md:34-38` (what an agent runs by hand). *(Line numbers
refreshed 2026-09-20; the `ci.yml` ranges in particular had drifted a long way — 162-175 is
now the privacy-page tests and 286-290 the backup sidecar. The substance is unchanged, which
is itself the point: three copies drift independently.)* Adding or
changing a gate means three edits that nothing keeps in step, and an agent cannot run "what CI
will run" as one command. The article's answer is one verification interface (`make ci`,
`make test`, …) that agents, CI and humans all call.

**Fix:** a `scripts/check.sh {fast|app|backend|all}` — `fast` being what the commit hook runs,
`all` what CI runs — called by `guard-bash.sh` and by `ci.yml`, and named in `CLAUDE.md`
§ Commands and `backend/CLAUDE.md` in place of the lists. Keep the hook's missing-tool
refusals (they belong to the hook, not to the checks). Cover it in
`scripts/hooks_selftest.sh`. The net change should remove lines, not add them.

**Acceptance:**
- `scripts/check.sh fast|app|backend|all` exists, and `guard-bash.sh` and `ci.yml` call it instead of calling ruff, mypy or `flutter analyze` themselves.
- `hooks_selftest.sh` passes, and the missing-tool refusals still fire.
- Outside `check.sh`, the diff removes more lines than it adds.
