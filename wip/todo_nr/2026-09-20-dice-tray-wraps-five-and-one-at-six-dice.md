# The dice roller's tray still wraps five dice and one

- **Noted:** 2026-09-20 — while fixing the count chips (`fix/dice-count-chips`); found in the
  same dialog, filed rather than fixed because the entry it closed is about the count choices
- **Theme:** growth
- **Area:** app
- **Blocks release:** no

`lib/widgets/dice_roller_dialog.dart` shows the rolled dice in a second, separate
`Wrap` (48 dp `_Die` squares, `spacing: 8`). With six dice chosen it lays them 5 / 1 — the
same "afterthought" shape the count chips had, for the same reason: `AlertDialog` sizes its
column with `IntrinsicWidth`, and `RenderWrap`'s intrinsic width sums its children while
ignoring its own spacing, so the column is asked for 6 × 48 = 288 dp when the run needs
6 × 48 + 5 × 8 = 328 dp. Measured after `fix/dice-count-chips`, at 412 dp and at 1600 px
alike: the sixth die drops to a line of its own.

It is arguably less jarring than a lone chip — a tray of dice may legitimately wrap — so
this is a judgement call, not an obvious bug. Two ways out:

- **Same treatment as the chips:** a `Row` in a `FittedBox(fit: BoxFit.scaleDown)`, which
  reports its spacers to `IntrinsicWidth` and shrinks the dice rather than wrapping them.
  Six 48 dp dice need 328 dp; the dialog offers 380 − 48 = 332 dp at 412 dp with the
  16 dp `insetPadding` the chips introduced, so nothing would actually scale on a phone.
- **Leave it wrapping, but deliberately:** 3 / 3 reads better than 5 / 1. A `Wrap` whose
  parent width is set on purpose (e.g. `SizedBox(width: 3 * 48 + 2 * 8)` for counts above
  four) would balance the runs instead of leaving one orphan.

Decide which before writing code — the first is the smaller change, the second may look
better for five dice (3 / 2 rather than 5 alone on a wide line).

**Acceptance:**
- With six dice chosen, the tray is one row — or two balanced ones — on a 412 dp phone and
  at 1600 px, never 5 / 1.
- Covered by a widget test that asserts the laid-out geometry (the dice's `dy` values), in
  `test/widgets/dice_roller_dialog_test.dart` next to the count-chip case.
