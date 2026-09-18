# Nothing checks that the published privacy page matches privacy_policy.md

- **Noted:** 2026-09-18 — while regenerating the page for docs/privacy-permission
- **Theme:** docs
- **Area:** docs, CI
- **Blocks release:** no

#75 and #77 edited `privacy_policy.md` (rules text a user writes for a game type; the preset
identifier and thresholds a shared game type carries) without running
`scripts/build_privacy_page.py`, so `docs/privacy-policy.html` — the page Play links to — went
two days without those details, and neither change added a Version History entry.
docs/privacy-permission published them under v2.8. No hook and no CI job compares the two
files; `docs/README.md` relies on the author remembering.

**Fix:** a CI step (in the job `scope` runs when `privacy_policy.md` or
`docs/privacy-policy.html` changes) that runs `scripts/build_privacy_page.py` and fails on
`git diff --exit-code docs/privacy-policy.html`. Pin or record the pandoc version so the
output is reproducible. Consider also failing when `privacy_policy.md` changes without its
`**Last Updated**` line changing.

**Acceptance:**
- A pull request that edits `privacy_policy.md` without regenerating the page is red.
- The pandoc version is pinned in CI and recorded in `docs/README.md`.
- A pull request that edits `privacy_policy.md` without changing its `**Last Updated**` line is red.
