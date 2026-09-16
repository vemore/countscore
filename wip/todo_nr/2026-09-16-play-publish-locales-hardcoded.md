# One hardcoded locale list serves both the listing and the release notes

- **Noted:** 2026-09-16 — preparing the ASO pass on the Play Store listing
- **Theme:** release-automation
- **Area:** tooling
- **Blocks release:** no

`LOCALES = ("en-US", "fr-FR")` in `.claude/skills/release-android/scripts/play_publish.py`
drives `read_release_notes()`, `read_listing()` and the graphics loop at once, and
`read_release_notes()` runs on every `publish`, with or without `--listing`. Widening that
constant to the app's ten languages would therefore make
`store_listing/<locale>/release_notes_v<version>.txt` mandatory in ten locales at every
release and break each publication after it.

The graphics loop has the same shape: it pushes the same eight screenshots from
`store_listing/assets/screenshots/phone/` into every locale, with no way to give one locale
its own — and the androidpublisher `Listing` resource has a `video` field the script never
sends.

**Fix:** split the two lists. `NOTES_LOCALES = ("en-US", "fr-FR")` for the release notes,
falling back to `en-US` when a file is missing; `listing_locales(root)` derived from the disk
— the subdirectories of `store_listing/` holding a `title.txt`, `assets/` excluded, sorted —
for the listing and the graphics, so that adding a language is creating a directory and there
is no file/constant double truth. Let the graphics look in `store_listing/<locale>/` first
and fall back to `assets/`, and read an optional `store_listing/<locale>/video.txt`.
