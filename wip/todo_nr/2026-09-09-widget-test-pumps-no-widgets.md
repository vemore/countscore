# `test/widget_test.dart` pumps no widgets

- **Noted:** 2026-09-09 — surfaced during the LLM-wiki migration
- **Theme:** test-tooling
- **Area:** app
- **Blocks release:** no

Its 8 tests are model serialisation; the name implies widget coverage that exists nowhere in
the repo. Rename it, or give it real widget tests.
