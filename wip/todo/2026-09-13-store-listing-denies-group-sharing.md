# The store listing text denies group sharing

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
