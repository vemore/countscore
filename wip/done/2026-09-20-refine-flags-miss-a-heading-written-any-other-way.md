# `wip.sh refine` reads three sections by their exact punctuation, so a heading written any other way is invisible

**Status:** done (2026-09-24) — closed by fix/wip-refine-heading-flags. `wip.sh` has a `section` helper, one `grep -qiE` per section: a `##`+ heading or a bold run-in, the colon inside the bold, after it or absent, an optional `(part a)` qualifier, any case; English and French names (Acceptance/Acceptation/Critères d'acceptation, Fix/Proposed fix/Fix proposé/Correctif, Open question(s)/Question ouverte). Accented letters are alternations, since `[eé]` fails in a C locale. `scripts/hooks_selftest.sh` § wip refine flags pins six cases. `refine all` before and after differs on one entry only: `2026-09-23-server-and-group-config-cannot-be-shared-by-qr-code` loses `no-fix`, its `**Fix (part a):**` now counting.

- **Noted:** 2026-09-20 — during the refinement pass, on the one entry that blocks the release
- **Theme:** hooks
- **Area:** tooling
- **Blocks release:** no

`scripts/wip.sh refine` decides three of its flags with a literal grep each:

```sh
grep -q '^\*\*Acceptance:\*\*' "$path" || flags="$flags no-acceptance"
grep -q '^\*\*Fix:\*\*'        "$path" || flags="$flags no-fix"
grep -q '^\*\*Open question:\*\*' "$path" && flags="$flags open-question"
```

`wip/README.md` § An entry shows exactly those three spellings, so the greps match the
template. They match nothing else. An entry long enough to want real headings — `##
Acceptance` instead of a bold run-in, or `**Fix proposé**` in a French entry — is reported as
having neither a fix nor acceptance criteria, and its open question is not reported at all.

**Observed, on the entry that blocks the release.**
`2026-09-20-wiped-rules-slug-is-never-restored` uses `## Acceptance`, `**Fix proposé**` and
`## Open question`. `refine all` flagged it `no-acceptance no-fix` although it has five
acceptance criteria and a two-part fix, and stayed **silent about its open question** — a
question the release fix turned out to need answering. The pass that exists to surface
exactly that missed it, and it was found by reading the file instead. The headings were
normalised inline in the same pull request, so today the flags are right about that one file;
nothing stops the next long entry from doing the same.

The two failure directions are not equally costly. A false `no-acceptance` is noise: the pass
reads the entry and sees the criteria. A missed `open-question` is silence — the pass has no
other way to notice a question waiting on the user, and silence is indistinguishable from
"nothing to ask".

**Fix:** match the section, not its punctuation — for each of the three, accept a `##`
heading and a bold run-in, with or without the colon, and case-insensitively; a French
`Fix`/`Correctif` heading counts too, since entries are written in both languages. One
`grep -qiE` per section replaces one `grep -q`, so the change is three lines and no new
concept. Then re-run `refine all` and confirm the flag set changes on no entry but the ones
that genuinely spell a heading differently.

Not proposed: refusing a non-template heading. The entries are prose, the template is a guide
to writing one rather than a schema, and `wip.sh check` already refuses what must be exact
(the header fields, the `Status:` line in `done/`).

**Acceptance:**
- An entry using `## Acceptance`, `## Open question` and `**Fix proposé**` is flagged exactly
  as the same entry using the three template spellings.
- `refine all` reports `open-question` for every open entry that has one, in either language.
- Re-running `refine all` before and after the change differs only on entries whose headings
  are spelled outside the template.
