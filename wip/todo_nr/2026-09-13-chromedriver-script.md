# The web e2e recipe assumes a matching `chromedriver` on the PATH

- **Noted:** 2026-09-13 — while running the web e2e for the drift worker refresh
- **Theme:** test-tooling
- **Area:** tooling
- **Blocks release:** no

`.llmwiki/Testing.md` says `chromedriver --port=4444 &` with a major matching Chrome. The dev
machine has none on the PATH; `~/cft/` holds 145 while Chrome is 153. Running the suite took
a manual Chrome for Testing lookup and download.

**Fix:** `scripts/chromedriver.sh` reading `google-chrome --version`, fetching the
matching driver into a cache if absent, starting it on 4444; point `Testing.md` and
`.claude/rules/web.md` at it.

**Acceptance:**
- `scripts/chromedriver.sh` reads the major version of `google-chrome --version` and downloads the matching driver into a cache when it is missing.
- It starts the driver on port 4444.
- `.llmwiki/Testing.md` and `.claude/rules/web.md` call the script instead of a bare `chromedriver`.
