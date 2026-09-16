# The store listing still sells the analysis as ZapZap-only, in ten locales

- **Noted:** 2026-09-16 — while opening the AI analysis to every game type
- **Theme:** store-listing
- **Area:** docs
- **Blocks release:** no

`store_listing/*/full_description.txt` line 38 describes the feature as the « Analyse
ZapZap » / "ZapZap analysis" in all ten locales, and
`store_listing/fr-FR/release_notes_v1.1.0.txt` does the same. Since
`feat/ai-analysis-styles` the analysis covers **every** game type, comes in nine voices and
answers in the language the app is displayed in.

The copy is therefore understated rather than misleading — a reviewer cannot call it a false
claim — but it wastes the one line of the description that would sell the feature, and it
contradicts `README.md` and `privacy_policy.md`, which now describe it correctly. The
per-game keyword work of `.llmwiki/StoreListing.md` argues the same way: a listing that names
Skyjo and Belote and then offers "the ZapZap analysis" reads as if the feature were for one
game only.

Publishing the listing is its own operation — no version bump, no rebuild —
`release-android` (`play_publish.py listing`), which is why this is not part of the change
that caused it.

**Fix:** rewrite that line in the ten locales to say the analysis works for any finished
game, name two or three voices as the hook, and mention the language follows the app. Publish
with `play_publish.py listing`. While in there, check whether the release notes of the next
version should carry the same news.
