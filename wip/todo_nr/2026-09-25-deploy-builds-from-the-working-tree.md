# A backend deploy builds whatever is in the working tree

- **Noted:** 2026-09-25 — comparing the NAS deploy with standard deployment practice
- **Theme:** deploy-safety
- **Area:** backend
- **Blocks release:** no

`backend/scripts/deploy_nas.sh:54` tags the image with `git rev-parse --short HEAD`, but
`:67` and `:70` run `docker build` on the working directory. Uncommitted edits, a branch
other than `main`, or a commit never pushed all reach production under a sha that does not
describe them. The CI `image` job builds and checks the same Dockerfile, but its image is
thrown away.

**Fix, minimal:** `deploy_nas.sh` refuses to build when `git status --porcelain` is not empty,
when `HEAD` is not `origin/main` (after a `git fetch`), unless `--allow-branch` is passed for
a deliberate hotfix test. **Later, optional:** build once in CI on merge to `main` and have the
deploy pull that image — only worth it if the image moves to a registry CI can reach, which
the decision "a local registry on the NAS" (`.llmwiki/Deployment.md`) currently rules out.

**Acceptance:**
- With a modified tracked file, `deploy_nas.sh` exits non-zero before `docker build`.
- On a branch whose `HEAD` is not `origin/main`, it exits non-zero naming the flag.
