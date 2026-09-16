# `play_publish.py` times out uploading the bundle on the first try

**Status:** done (2026-09-16) — closed by chore/play-publish-listing. `build_service()` now
wraps the credentials in an `AuthorizedHttp` over `httplib2.Http(timeout=300)`, the bundle and
image uploads `.execute(num_retries=5)`, and a `TimeoutError` becomes a `PublishError` saying
nothing was committed and the command can be rerun. `google-auth-httplib2` and `httplib2` are
in the PEP 723 header.

- **Noted:** 2026-09-15 — publishing 1.1.0+4 to the internal track
- **Theme:** release-automation
- **Area:** tooling
- **Blocks release:** no

The first `publish --track internal --listing --graphics` run died with
`TimeoutError: The read operation timed out` in `httplib2` (a raw traceback, no
`PublishError`); the identical rerun a minute later uploaded the 64 MB bundle and validated.
`build_service()` in `.claude/skills/release-android/scripts/play_publish.py` builds the
client with httplib2's default socket timeout, and `MediaFileUpload` is resumable but the
script calls `.execute()` without `num_retries`. The edit left behind expires on its own.

**Fix:** pass `num_retries=` to the upload `.execute()` calls (and the edit calls), build
the client with an `AuthorizedHttp` over `httplib2.Http(timeout=300)`, and turn a timeout
into a `PublishError` saying the edit was not committed and the command can be rerun.
