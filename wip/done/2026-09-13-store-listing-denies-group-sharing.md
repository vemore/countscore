# The store listing text denies group sharing

**Status:** done (2026-09-15) — closed by fix/store-listing-1-1-0. Both locales rewritten from `privacy_policy.md`: a Group sharing paragraph, a "Your own server" section saying both network features reach only the server the user enters, no "our server" or "no cloud sync" (en-US 2781, fr-FR 3431 characters).

- **Noted:** 2026-09-13 — while rewriting the `release-android` skill
- **Theme:** store-listing
- **Area:** docs
- **Blocks release:** yes — the listing contradicts the Data Safety declaration

`store_listing/{en-US,fr-FR}/full_description.txt` describe the pre-sync app: line 21 calls
the ZapZap analysis "the one feature that uses the internet" and sends scores "to our
server"; line 36 says "No accounts, no cloud sync". Group sharing stores game data on the
server the user configures, and the app ships no server of ours.

**Fix:** rewrite both locales from `privacy_policy.md` (≤ 4000 characters), and add a
"Group sharing" paragraph to the features list.
