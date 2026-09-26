# The frozen-archive hook refuses a rename that leaves a dead link inside it

- **Noted:** 2026-09-26 — renaming `SchemaV10` to `Schema` in `feat/wiki-lint`
- **Theme:** hooks
- **Area:** tooling
- **Blocks release:** no

`.claude/hooks/guard-bash.sh` refuses any commit that touches `wip/done/ARCHIVE-2026-09.md`
(`.llmwiki/Hooks.md`: "editing `wip/done/ARCHIVE-*.md`"), unconditionally, once the file
exists in `HEAD`. Renaming `.llmwiki/SchemaV10.md` to `.llmwiki/Schema.md`
(`wip/done/2026-09-26-the-wiki-has-no-lint-script.md`) needed to update every reference —
`git grep -l SchemaV10` named the archive among them, at line 348: `([[SchemaV10]])`. The
hook refused, so that link stays exactly as broken as it will ever be:
`.llmwiki/SchemaV10.md` does not exist, and never will again. The rule is right to protect
the archive from rewrites of its own content; it was not written with the case of a page it
merely *links to* being renamed out from under it.

**Fix:** narrow the refusal so a change touching only a `[[WikiLink]]` — the exact rename
`sed` this pull request ran, nothing else in the diff — is let through, while any other edit
to the archive still refuses. Simplest version: the hook already has the staged diff; check
that every changed line differs from the old only in `[[OldName]]` → `[[NewName]]` tokens
before refusing.

**Open question:** is a permanently dead `[[SchemaV10]]` link inside frozen history actually
a problem worth a hook exception, or is "kept verbatim" supposed to mean exactly this —
history is read as of when it was written, broken links included? If the latter, this entry
should close as dropped instead, and `.llmwiki/Hooks.md` gets a line saying so.
