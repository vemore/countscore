# Every agent worktree gets the deployment target and the keystore passwords

- **Noted:** 2026-09-18 — comparing the project's SDLC with "Your SDLC is your context
  engineering" (Daniel Kravets, LeadDev, 2026-08-10)
- **Theme:** deploy-safety
- **Area:** tooling
- **Blocks release:** no

`scripts/worktree_setup.sh` (`LOCAL_ONLY`) symlinks `backend/scripts/deploy.env` and
`android/key.properties` into every worktree it prepares, the implementing agents' included.
Those agents never deploy and never sign (`ship-parallel` §2 rule 7): only the orchestrator's
deploy worktree (§4) and the release worktree need them. The article scopes what an agent can
reach to what its task needs. Low priority while the user is prod's sole user.

**Fix:** link nothing by default; `worktree_setup.sh --deploy` links `deploy.env`,
`--release` links `key.properties`. Update the calls in `ship-parallel` §4, `backend-deploy`,
`web-deploy` and `release-android`, and `.llmwiki/ParallelDelivery.md`.
