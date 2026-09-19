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

**Fix:** measure on an iPhone (the PWA, a finished game, Share). If the share is refused,
draw the card when the screen opens and keep the bytes, so the tap shares at once.

**Acceptance:**
- On iOS Safari, Share on the end screen opens the system sheet with the PNG and the text.
