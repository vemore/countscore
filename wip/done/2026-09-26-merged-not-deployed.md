# Merges from the 2026-09-26 QR loop are on main but not deployed

**Status:** done (2026-09-26) — deployed `febe420` (PWA build `1503a0f43f54da1f`), which covers `5fe1f03` (#236) and `febe420` (#237, merged from the local session after the Pixel run found and fixed a restored activity replaying its launch link). `a07daed…` was published at `30a81e4` first for #236 alone. Smoke tests in production: `/health` ok; #236's QR sheet in the PWA starts from the app's own address and *Copy link* turns into *Link copied*; #237's `#/join?s=…&g=SMOKEZ9Q7` opened cold shows the replace dialog, the address bar is back to `/app/` before the dialog, Cancel leaves the settings untouched. The backend access-log check could not run as written: HTTP access logs are off by design (`uvicorn.access` at WARNING, `.llmwiki/Deployment.md`). Instead, the page's Resource Timing showed 16 same-origin requests, none carrying the code or the server; only the navigation entry holds the fragment, which a browser never sends.

- **Noted:** 2026-09-26 — ship-parallel run on the QR configuration share, from a cloud session with no route to the NAS and no `backend/scripts/deploy.env`
- **Theme:** deploy-safety
- **Area:** web
- **Blocks release:** yes — production would run older code than the release, and the QR links the app shares would open a PWA that cannot read them

The session that merged these could not deploy (`ship-parallel` §4). Each squash sha and what
it needs:

- `5fe1f03` — [vemore/countscore#236](https://github.com/vemore/countscore/pull/236), the
  configuration QR sheet and the replace dialog: **PWA** (no backend change, no Alembic).

**Fix:** from a local session, deploy `origin/main` with `web-deploy` (no backend deploy is
needed for the shas above; recheck `git diff --name-only <sha>^ <sha> -- backend` for any sha
added later). One deploy covers every sha listed. Then smoke-test each pull request's path:

- #236: the PWA loads; Settings → Server → *Share by QR code* asks for the web app address,
  then shows a QR whose link is `<web app address>/#/join?s=…&g=…`; *Copy link* turns into
  *Link copied*.

Not listed on purpose: [vemore/countscore#237](https://github.com/vemore/countscore/pull/237)
(the `countscore://join` deep link and the PWA `#/join` route), green but left open for the
user to merge from the local session after the device run: open `countscore://join?s=…&g=…`
cold and warm (`adb shell am start -a android.intent.action.VIEW -d '…'`), try the
`intent://` hand-over from Chrome with and without the app, and check that the dialog
reappearing after the system recreates the activity still needs confirmation. Once it is
merged, add its sha above (PWA), and after the deploy check the backend access log shows only
`GET <PWA_BASE_PATH>/` for a scanned link, with no `/join` and no invite code.

Close this entry naming the deployed sha.

**Acceptance:**
- `web-deploy` has published `origin/main` at or after every sha listed, and `/health` answers.
- Each listed pull request's smoke test above passes in production.
