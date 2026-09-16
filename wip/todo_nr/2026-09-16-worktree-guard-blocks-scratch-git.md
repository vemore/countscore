# A worktree-isolated agent cannot run a git command in a throwaway repository

- **Noted:** 2026-09-16 — testing the push step of `.github/workflows/deps.yml`
- **Theme:** hooks
- **Area:** tooling
- **Blocks release:** no

The guard that keeps a worktree-isolated agent's git operations inside its own worktree
judges the Bash command line. A command that creates a scratch repository under the
session scratchpad and commits in it — nothing to do with this checkout — is refused twice
over, first as

> `git push ... HEAD:main` would update main directly

(the project's own `guard-bash.sh`, on a bare repository that is not `origin`), then as

> this command names git in a form too complex to verify that it stays inside the worktree

which no rewriting of the command fixes, because the objection is to the shape of the line
and not to the paths in it. Both refusals are correct about the command line and wrong
about what the command does.

It matters because the only way to test the shell half of a GitHub Actions step locally is
to run it against *something* — and a new workflow cannot be dispatched before it is on
`main` either (`.llmwiki/Testing.md`), so there is no CI dry run to fall back on. The step
was eventually covered by extracting it to a file and running it with a `git` stub on
`PATH`, which touches no repository at all; that took two refusals to arrive at.

**Fix:** record the working recipe rather than loosen the guard — a short paragraph in
`.llmwiki/Hooks.md` under what the hooks do not cover: *to exercise a script that calls
git, extract it to a file and put a stub named `git` first on `PATH`; do not try to build
a scratch repository from the command line*. If that proves to be needed often, the
alternative is a `scripts/` helper that owns the stub, so the recipe is a command and not a
paragraph. Loosening either guard is not proposed: both refused exactly what they promise
to refuse.
