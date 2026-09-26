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

**State of the art** (web search, 2026-09-26): CI/CD practice is "build once, promote
everywhere" — an image built once from a known commit and carried unchanged through
environments, because a mutable base image, resolved dependency or dirty working tree can
make two builds of "the same" commit differ. We depart for now: the minimal fix only guards
the tree `deploy_nas.sh` builds from (clean, `HEAD == origin/main`) rather than moving the
build into CI and pulling a stored image, because the project's local-registry decision
(not reachable from CI) rules that out until revisited — the entry already names the full
form as its "later, optional" step.
Sources: [MinimumCD, immutable artifacts](https://beyond.minimumcd.org/docs/migrate-to-cd/pipeline/immutable-artifacts/),
[OneUptime, build once, promote everywhere](https://oneuptime.com/blog/post/2026-07-28-build-once-promote-everywhere/view).

**Acceptance:**
- With a modified tracked file, `deploy_nas.sh` exits non-zero before `docker build`.
- On a branch whose `HEAD` is not `origin/main`, it exits non-zero naming the flag.
