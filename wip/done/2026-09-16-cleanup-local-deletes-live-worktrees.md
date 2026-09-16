# `cleanup_local.sh --apply` deletes a worktree another agent is still setting up

**Status:** done (2026-09-16) — closed by `fix/cleanup-local-live-worktrees`. Both proposals
were implemented, because they cover different windows: `worktree_setup.sh` now writes a
`.countscore-setup-in-progress` marker (gitignored) and clears it only on success, and
`cleanup_local.sh` keeps any worktree carrying one, or modified in the last
`CLEANUP_IDLE_MINUTES` (default 30) minutes — both keeping the worktree's **branch** too,
which is what let the incident delete `chore/flutter-deps` itself. Three self-test cases.

- **Noted:** 2026-09-16 — the `chore/flutter-deps` worktree vanished mid-`worktree_setup.sh`
- **Theme:** dependencies
- **Area:** tooling
- **Blocks release:** no

`scripts/worktree_setup.sh ../countscore-flutter-deps` was running its `dart run build_runner
build` when the directory disappeared underneath it:

```
PathNotFoundException: Cannot open file, path =
  '/home/vemore/workspace/countscore-flutter-deps/.dart_tool/build/entrypoint/build.dart.aot.deps'
Bad state: Generating AOT kernel dill failed!
```

The worktree *and* the `chore/flutter-deps` branch were both gone. The cause is
`scripts/cleanup_local.sh --apply`, run from another session in this repository (two locked
agent worktrees were live under `.claude/worktrees/`). Its own header names the failure
mode — *"Never run it while agents are still working: a freshly created branch with no commit
yet, in a clean worktree, is indistinguishable from an abandoned one"* — and
`.llmwiki/ParallelDelivery.md` says to run it "once no agent is working", but nothing
enforces either. `git status --porcelain` ignores `.dart_tool/`, `*.g.dart` and everything
else `worktree_setup.sh` produces, so a worktree in the middle of a five-minute setup reads
as perfectly clean.

The work was not lost — the branch had no commit yet, which is precisely why it was deleted —
but it cost a full re-setup, and the same sequence a few minutes later would have taken
uncommitted edits with it.

**Fix:** make "no agent is working" something the script can see rather than something the
operator has to remember. Cheapest version: refuse to remove a worktree whose directory was
modified in the last N minutes (`find "$path" -newermt '-30 minutes'`), which covers the
setup window without needing to know about agents. Better: have `worktree_setup.sh` drop a
`.countscore-setup-in-progress` marker and clear it on success, and have `cleanup_local.sh`
keep any worktree carrying one — an explicit handshake between the two scripts that already
own the two ends of this.

Either way `cleanup_local.sh` should print *why* it kept something, as it already does, and
the dry run should stay the default it is.
