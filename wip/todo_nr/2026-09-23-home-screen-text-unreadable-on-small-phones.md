# Home screen text is unreadable on small phones

- **Noted:** 2026-09-23 — user request, seen on a small screen
- **Theme:** visual-refresh
- **Area:** app
- **Blocks release:** no

On the smallest phones still in use, iPhone 6/7/8 and SE (2nd/3rd gen) at 375×667
logical px, and the original SE at 320×568, much of the home screen text
(`lib/screens/home_screen.dart`) can't be read: truncated or shrunk labels and crowded
cards. On larger screens, such as the Pixel 9 Pro XL, the layout is right and must not
change.

**Fix:** audit the home screen at 320, 360 and 375 px wide, also at text scale 1.3. Give
it a compact layout below a width breakpoint (one `LayoutBuilder`/`MediaQuery` threshold,
next to the existing large-screen breakpoints). Options: fewer columns, shorter
secondary lines, wrapping instead of ellipsis, smaller paddings. Fonts are not shrunk below
the Material minimum. Wider screens stay the same, pixel for pixel.

**Acceptance:**
- Widget tests render the home screen at 320×568 and 375×667 (text scale 1.0 and 1.3) with no overflow error and no ellipsised primary label.
- Golden tests at 412×915 and one tablet width are unchanged by the pull request.
- Before/after screenshots at 375×667 (Chrome device emulation of the PWA) are attached to the pull request. No iOS device is needed.

**Open question:** which texts did the user find unreadable (game names, stats, dates,
the type chips)? A screenshot in `wip/assets/<slug>/` would pin the target.
