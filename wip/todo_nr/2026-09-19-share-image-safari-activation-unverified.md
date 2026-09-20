# Sharing the result's picture is unverified in Safari, whose user-activation window may be shorter

- **Noted:** 2026-09-19 — while adding the picture to the shared result (feat/share-result-image)
- **Theme:** growth
- **Area:** web
- **Blocks release:** no

`ShareResultButton` (`lib/widgets/share_result_button.dart`) now draws the standings' PNG
(`renderWidgetToPng`, about 200 ms in desktop Chromium) before it calls `navigator.share`.
The Web Share API needs the tap's transient user activation; Chromium and Firefox keep it
5 s, and the Chromium probe shared about 270 ms after the tap ([[Web]]). Safari on iOS — the
one PWA browser that shares files widely besides Android Chrome — was not measured. If its
window is shorter, or if the draw is slower on a phone, `navigator.share` rejects with
`NotAllowedError`, the retry without the image rejects too, and share_plus falls back to a
`mailto:`.

**Decided (2026-09-20, refinement):** there is no iOS device to measure on, so the entry
stops depending on a measurement. Measuring first was the better order only while an iPhone
was assumed to be available; without one the entry could never be closed as written. Draw the
card **up front** instead — the defensive fix the measurement would have led to anyway if the
window turned out to be short, and it is correct on every browser rather than only on the one
that was going to be tested.

**Fix:** render the PNG when the standings screen opens and keep the bytes, so the tap calls
`navigator.share` immediately and spends none of the transient user activation on drawing.
`ShareResultButton` (`lib/widgets/share_result_button.dart:133`) has no `initState` today and
draws inside `_share`; the bytes move to state, with the tap falling back to drawing inline if
they are not ready yet (a share tapped before the first frame settles must still work). Nothing
about the Web Share call itself changes.

**Acceptance:**
- A widget test proves the PNG is rendered before any tap — `renderImage` is called once on
  first build, and the tap handler does not call it again.
- The tap still shares text and image when the pre-render has not finished (the inline draw
  remains as the fallback, covered by a test).
- The share path is unchanged on Android and in desktop Chromium: the existing
  `share_result_button` tests pass untouched.
