# Production runs `:latest`, and nothing tells which commit it is

- **Noted:** 2026-09-25 — comparing the NAS deploy with standard deployment practice
- **Theme:** deploy-safety
- **Area:** backend
- **Blocks release:** no

- `backend/docker-compose.prod.yml:25` and `:86` run `…/countscore:latest` and
  `…/countscore-backup:latest`. `deploy_nas.sh` pushes a sha tag too, but the stack never
  references it.
- `/health` reports `version` from `backend/app/__init__.py:3`, a constant `"0.1.0"`, so it
  cannot say which build answered.
- `--rollback` (`deploy_nas.sh:49`) rewrites the NAS `compose.yaml` with `sed`; nothing
  records which tag ran before, so a rollback needs the sha found by hand, and the
  `db-backup` image is never rolled back.

Standard practice: immutable tags (or digests) only, the running version recorded, and the
build identity reported by the service.

**Fix:** compose reads `image: …/countscore:${IMAGE_TAG:?}` (same for the backup image);
`deploy_nas.sh` writes `IMAGE_TAG=<sha>` into the NAS `.env` and keeps the previous value as
`PREVIOUS_IMAGE_TAG`; `--rollback` with no argument swaps back to it. The Dockerfile takes a
`GIT_SHA` build arg into an env var that `/health` reports next to `version`. Stop pushing
`:latest`, or keep it only for the dev compose file.

**State of the art** (web search, 2026-09-26): production images should carry immutable
tags — ideally pinned further by digest — never `:latest`, since a mutable tag only means
"the last thing pushed"; a running build should trace back to its commit, commonly a git-sha
tag reported by the service itself. The fix matches this — sha tag read back at `/health`,
`:latest` retired from the prod compose file — and departs only by tagging on the sha rather
than also pinning the pulled digest, acceptable here because the registry is local and
single-writer, unlike a shared public registry where a tag can be silently reassigned.
Sources: [Docker blog, tags and labels](https://www.docker.com/blog/docker-best-practices-using-tags-and-labels-to-manage-docker-image-sprawl/),
[Smartinary, why you should use immutable Docker tags](https://www.smartinary.com/blog/why-you-should-use-immutable-docker-tags/).

**Acceptance:**
- `grep latest backend/docker-compose.prod.yml` finds nothing.
- `curl $PUBLIC_URL/health` reports the short sha `deploy_nas.sh` just built.
- `deploy_nas.sh --rollback` with no sha returns to the previous deploy, for both images.
