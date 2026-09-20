# The dice roller's count chips wrap five and one

- **Noted:** 2026-09-19 — smoke-testing #167 (feat/dice-roller) on the production PWA at 1600 px
- **Theme:** growth
- **Area:** app
- **Blocks release:** no

`lib/widgets/dice_roller_dialog.dart` lays the six "how many dice" `ChoiceChip`s in a centred
`Wrap` inside an `AlertDialog`. At the dialog's default width the sixth chip wraps alone onto
a second line (1 2 3 4 5 / 6), which reads as an afterthought.

**Fix:** make the six fit one row — compact chips (`visualDensity`, smaller padding), or a
`SegmentedButton<int>` — or give the dialog the width it needs.

**Acceptance:**
- The six count choices sit on one line in the dialog on a 412 dp phone and on the PWA at 1600 px (widget test at 412 dp).
