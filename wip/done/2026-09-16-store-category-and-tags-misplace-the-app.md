# The Console tags put CountScore next to Windy and Uber, not next to score counters

- **Noted:** 2026-09-16 — while auditing store discoverability in the Play Console
- **Theme:** store-listing
- **Area:** docs
- **Blocks release:** no

Declared in the Console on 2026-09-16: app type **App**, category **Tools**, tags **Tools,
Productivity**. Play uses the tags to build the "similar apps" group, and the public listing
shows the result: the *More apps to try* block offers **Windy, Google Cloud, ChatGPT, Uber,
Microsoft Launcher, Gemini Notebook** — not one score counter, not one board-game app. Every
impression the app could earn from being shown beside a competitor is lost.

Checked in the Console tag picker: **there is no board-game or score tag at all**. The only
relevant tag available is **Entertainment**.

The category itself is fine: the 500 K+ leader "Compteur : comptez tout" (napps) is also in
Tools, and CountScore is not a game, so switching to the Games category would be a
misclassification — Play ranks a mislabelled app badly and reviewers notice.

**Fix (Play Console, manual — `play_publish.py` handles neither the category nor the tags):**
Store presence → Store settings → drop **Productivity**, add **Entertainment**, keep the
category **Tools**. Then re-check the *More apps to try* block a few days later and record
what it became in `.llmwiki/StoreListing.md`.

**Status:** done (2026-09-16) — closed by docs/store-listing-live. In the Console, *Productivity*
was removed and *Entertainment* added; the category stays *Tools*. Tags are now
`Entertainment, Tools`. The *More apps to try* block still has to be re-checked in a few days and
the result recorded in `.llmwiki/StoreListing.md`.
