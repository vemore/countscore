# Store Assets Directory

Place your created visual assets in this directory.

## Required Files

### App Icon
- **File**: `icon_512.png`
- **Size**: 512 × 512 pixels
- **Format**: 32-bit PNG with alpha
- **Max Size**: 1 MB

### Feature Graphic
- **File**: `feature_graphic.png` (or `.jpg`)
- **Size**: 1024 × 500 pixels
- **Format**: JPEG or 24-bit PNG (no alpha)

### Screenshots

#### Phone Screenshots (Required)
**Not here.** Each store locale has its own: raw captures in `../<locale>/raw/`
(`scripts/capture_screenshots.sh <locale>`), composed by `scripts/compose_screenshots.py` into
`../<locale>/screenshots/phone/` (1080 × 1920, opaque RGB), which is what Play gets. There is
no shared set to fall back on — see `../README.md`, "Screenshots".

#### Tablet Screenshots (Optional)
None yet. Like the phone set, a tablet set would be per locale, not placed here:
- **Quantity**: 1-8 screenshots
- **Resolution**: 1536 × 2048 pixels recommended
- **Format**: JPEG or PNG

## How to Create

See `../ASSET_REQUIREMENTS.md` for Play's image specifications; the palette is in `lib/utils/app_theme.dart`.

## Current Status

- [ ] icon_512.png
- [ ] feature_graphic.png
- [ ] Tablet screenshots (optional)

Once you've created the assets, place them in this directory and remove this file.
