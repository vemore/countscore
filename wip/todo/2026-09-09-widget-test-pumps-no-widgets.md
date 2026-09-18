# `test/widget_test.dart` pumps no widgets

- **Noted:** 2026-09-09 — surfaced during the LLM-wiki migration
- **Theme:** test-tooling
- **Area:** app
- **Blocks release:** no

Its 8 tests are model serialisation; the name implies widget coverage that exists nowhere in
the repo. Rename it, or give it real widget tests.

**Changed (2026-09-18, refinement):** real widget tests now exist (`test/screens/`,
`test/widgets/`). What is left is the name: `test/widget_test.dart` holds only model tests.

**Fix:** rename it after what it tests (e.g. `test/models_test.dart`).

**Acceptance:**
- `test/widget_test.dart` no longer exists; its model tests live in a file named after what they test.
- The same number of tests passes.
- No document refers to the old name.
