# PLAY_STORE_DATA_SAFETY.md declares Device IDs and then says it collects none

**Status:** done (2026-09-16) — closed by docs/store-listing-aso, **document only**. The
Console declaration was not touched. `PLAY_STORE_DATA_SAFETY.md` now carries a dated
correction block, its Quick Summary explains why *Device or other IDs* is declared, the
copy-paste block says "no hardware or advertising identifier" instead of "no device
identifiers", the checklist points at the current policy version (v2.5) rather than v2.3, and
§Q4's "v2.4" was corrected. `PUBLISHING.md` §3 says three data types. The store descriptions
in all ten locales now explain the three entries of the public card instead of contradicting
them.

- **Noted:** 2026-09-16 — while checking the listing copy against the declaration
- **Theme:** store-listing
- **Area:** docs
- **Blocks release:** no

`PLAY_STORE_DATA_SAFETY.md` §*Data Types to Declare* declares **three** types, the third
being *Device or other IDs* (the per-installation group device id and token). Two blocks of
the same file contradict it:

- §*Data Safety Summary for Copy-Paste*: "Collects no device identifiers and requires no
  account" — the copy-paste block is the text meant to be pasted into the Console;
- §*Do NOT declare* / *Quick Summary*, which never mention the third type either, and the
  *Completion Checklist*, which asks for a privacy policy serving the **v2.3** text while
  §Q4 of the same file says v2.4 — `privacy_policy.md` is at v2.5.

`PUBLISHING.md` §3 *Data safety* repeats the same omission: it says "Two data types".

The public Data Safety card therefore advertises sharing of *Personal info / App activity /
Device or other IDs* with third parties while the store description says "no tracking", with
nothing in either document explaining why both are true.

**Fix:** correct the *document*, never the declaration — a Play answer is not softened to make
the card read better. Say three data types everywhere in `PLAY_STORE_DATA_SAFETY.md` and
`PUBLISHING.md`, fix the policy version in the checklist, and have the store descriptions
explain the card instead of contradicting it (the identifier is a random per-installation
token, it exists only after the user joins a group, and it is not linked to an identity and
not used for tracking). If it is ever concluded that a Console checkbox should change, that is
a separate change: it also moves `README.md` Privacy, `privacy_policy.md` and the manifest
(`.llmwiki/Documentation.md`).
