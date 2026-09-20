# The dice roller's count chips wrap five and one

**Status:** done (2026-09-20) — closed by fix/dice-count-chips. The cause was not the
dialog's width: `AlertDialog` sizes its column with `IntrinsicWidth`, and `RenderWrap`'s
intrinsic width sums its children while ignoring its own `spacing`, so the `Wrap` was handed
6 × 48.1 = 288.6 dp when the run needs 318.6 dp — it wrapped 5 / 1 at *every* width, 1600 px
included. The six chips are now a `Row` with explicit `SizedBox(width: 6)` spacers (which
`IntrinsicWidth` does count), `visualDensity: VisualDensity.compact`, inside a
`FittedBox(fit: BoxFit.scaleDown)` that absorbs a large text scale or a 320 dp screen; the
dialog takes `insetPadding` 16 dp horizontal so the row fits unscaled on a 412 dp phone.
Measured: one row at 412 dp, at 1600 px, at 320 dp and at text scale 2.0. The tray of rolled
dice below is a separate `Wrap` and still lays six as 5 / 1 —
`wip/todo_nr/2026-09-20-dice-tray-wraps-five-and-one-at-six-dice.md`.

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
