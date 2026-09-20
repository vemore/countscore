# The About screen credits an artist who did not draw the current icon

**Status:** done (2026-09-20) — closed by fix/about-credits. The Credits `Card` and the
`_buildCredit` helper are gone from `about_screen.dart`, which now ends on the *Rate
CountScore* row; `credits`, `appIconCredit` and `artistName` are removed from all ten ARB
files with their `@` blocks in the French template, `artistName` left `SAME_AS_ENGLISH_OK`,
and `.llmwiki/I18n.md` and `INDEX.md` read 409 keys. `about_screen_test.dart` asserts the
heading, the handle and the copyright icon are absent. The old handle survives nowhere in
the repository outside this entry and that assertion.

- **Noted:** 2026-09-20 — while reviewing the About screen after the icon change
- **Theme:** visual-refresh
- **Area:** app
- **Blocks release:** no

`lib/screens/about_screen.dart:132-157` draws a whole `Card` whose only content is one
credit line, `_buildCredit(l10n.appIconCredit, l10n.artistName)`, and `artistName` is
`"efendi.sign"` (`lib/l10n/app_en.arb:252` and the nine other locales). That was the author
of the old stock-clipart podium icon.

The icon changed on 2026-09-20 (#195): the app now ships an ensemble the owner generated
himself with ChatGPT and Fable, transcribed to SVG and hardened here —
`design/icon/source-from-chatgpt.svg` is the original and `design/icon/chosen*.svg` the
shipped sources (`.llmwiki/Release.md` §Icons). The credit names the wrong person, on the
one screen whose job is to be accurate about the app.

The user's instruction is to drop the section rather than re-attribute it: « La section
"Crédits" dans A propos n'est plus utile car l'icone n'est plus celle de efendi.sign mais
une que j'ai générée moi même avec chatgpt et fable. »

**Fix:** remove the *Credits* `Card` and the now-unused `_buildCredit` helper from
`about_screen.dart`, minding the `SizedBox(height: 24)` that separated it so the screen does
not end on a dangling gap; remove the keys `credits`, `appIconCredit` and `artistName` from
all ten ARB files plus the `@` blocks in the French template, drop the `artistName` entry
from `SAME_AS_ENGLISH_OK` in `.claude/hooks/arb_keys.py`, regenerate; update the key count in
`.llmwiki/I18n.md`. Sweep the repository for the old handle elsewhere. Do not replace the
section with a different credit — the icon's provenance belongs in the repository, where
`.llmwiki/Release.md` §Icons already records it, not in the UI.

**Acceptance:**
1. `grep -rni efendi .` matches nothing outside `wip/`.
2. `python3 .claude/hooks/arb_keys.py` passes, and `--unused` does not list the three keys.
3. `test/screens/about_screen_test.dart` asserts the Credits heading and the handle are gone.
4. `flutter analyze` and `flutter test` are green.
