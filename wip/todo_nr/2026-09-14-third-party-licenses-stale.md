# THIRD_PARTY_LICENSES.md lists a 2025 dependency set

- **Noted:** 2026-09-14 — while adding `url_launcher` for the AI commentary report control
- **Theme:** store-listing
- **Area:** docs
- **Blocks release:** no

`THIRD_PARTY_LICENSES.md` names ten direct dependencies with 2025 constraints
(`flex_color_picker ^3.5.1`, `intl ^0.19.0`, `file_picker ^8.1.6`, `flutter_lints ^5.0.0`)
while `pubspec.yaml` has moved on, and it omits `http`, `flutter_markdown_plus`, `drift`,
`drift_flutter`, `flutter_secure_storage`, `web_socket_channel` and `crypto`. It is listed as a
compliance document in `.llmwiki/Release.md`. `feat/ai-commentary-report` added only the
`url_launcher` entry it introduced. No rule in `CLAUDE.md` names this file when a dependency
changes, which is how it drifted.

**Fix:** regenerate the direct-dependency list from `pubspec.yaml` (licenses from each
package's `LICENSE` in the pub cache), and add the file to the README table in `CLAUDE.md`'s
"dependency added" row, or generate it with a script checked in CI.

**Decided (2026-09-18, refinement):** generate it with a script, and check it in CI.

**Acceptance:**
- A script regenerates `THIRD_PARTY_LICENSES.md` from the direct dependencies of `pubspec.yaml` and each package's `LICENSE` in the pub cache.
- CI fails when the committed file differs from the generated one.
- The regenerated file lists every direct dependency of `pubspec.yaml`.
