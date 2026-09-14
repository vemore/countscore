# Nothing independent reviews a pull request before it is merged and deployed

- **Noted:** 2026-09-14 — while reviewing the two weeks of work since 2026-09-09
- **Theme:** merge-safety
- **Area:** tooling
- **Blocks release:** no

`ship-parallel` §3 says to the orchestrator "you are the only reviewer": one agent writes the
pull request, another instance of the same model reads its diff, squash-merges it and deploys
it to production. Since 2026-09-14 no human is in that loop. Group sharing (#21, +6.9 k lines,
64 files), device revocation (#32) and the fixes to what leaves the device (#23, the player
names sent to the LLM) were merged and deployed on the day they were opened — #21 was followed
the same day by six fix pull requests (#22–#27), a crash and security findings among them.

**Fix:** a review gate on the sensitive paths only, so the loop stays fast elsewhere. When a
pull request touches `backend/app/routes/`, `backend/app/services/{ws_ticket,trusted_proxy,notify}.py`,
`lib/services/sync/`, `lib/services/backend_client.dart`, or any of `privacy_policy.md` / `PLAY_STORE_DATA_SAFETY.md` /
`AndroidManifest.xml`: either require the user's approval (`gh pr review --approve` by a human,
a required reviewer on those paths through `CODEOWNERS`), or at least run `/code-review high`
from a fresh agent that did not write it, and block the merge on its findings. Record the
path list in `.llmwiki/ParallelDelivery.md` and apply it in `ship-parallel` §3.
