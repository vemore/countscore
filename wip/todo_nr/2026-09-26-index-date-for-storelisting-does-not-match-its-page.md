# `INDEX.md`'s row for `[[StoreListing]]` disagrees with the page's own `Updated:` line

- **Noted:** 2026-09-26 — running `scripts/wiki_lint.sh` on the real wiki while building it
- **Theme:** docs
- **Area:** docs
- **Blocks release:** no

`.llmwiki/INDEX.md`'s row for `[[StoreListing]]` says `2026-09-20`; `.llmwiki/StoreListing.md`'s
own `> Updated:` line says `2026-09-24`. A change since 2026-09-20 updated the page and forgot
the index row, which the ingest rule in `INDEX.md` ("Changing a fact is an ingest") says should
never happen. `scripts/wiki_lint.sh` now catches exactly this drift; this is its first real
finding.

**Fix:** set the `INDEX.md` row's date to `2026-09-24`, or to whatever `StoreListing.md`'s
`Updated:` line says by the time this is picked up — check which one is actually current
against the page's own history first.

**Acceptance:**
- `scripts/wiki_lint.sh` reports no date mismatch for `[[StoreListing]]`.
