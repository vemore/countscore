# The PWA can hang on "Loading game types" in a browser that had another tab of it open

- **Noted:** 2026-09-19 — while screenshotting the New game screen on a local web build (feat/new-game-screen)
- **Theme:** web
- **Area:** web
- **Blocks release:** no

A release web build served on `127.0.0.1:8731`, opened in Playwright's Chromium in a browser
profile where an earlier tab of the same origin had been open (and then navigated away by
another session), stayed on "Loading game types..." in *New game*: the database calls never
returned, and four bare uncaught `Error`s were logged (the drift storage in use is
`sharedIndexedDb`). The same build in a fresh browser context worked every time. Not
reproduced deliberately; it may share its cause with
[[2026-09-18-pwa-uncaught-error-at-startup]].

**Fix:** reproduce with two tabs of the PWA on the same origin (open, close one, reload the
other), with a `--source-maps` build; if the shared IndexedDB worker is left locked, surface an
error instead of an endless loading state.

**Acceptance:** with two tabs of the PWA opened and one closed, the remaining tab still lists
the game types after a reload.
