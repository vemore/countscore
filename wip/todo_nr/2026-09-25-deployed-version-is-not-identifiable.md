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

**Acceptance:**
- `grep latest backend/docker-compose.prod.yml` finds nothing.
- `curl $PUBLIC_URL/health` reports the short sha `deploy_nas.sh` just built.
- `deploy_nas.sh --rollback` with no sha returns to the previous deploy, for both images.
