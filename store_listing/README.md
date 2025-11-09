# CountScore - Google Play Store Listing

This directory contains all materials for the Google Play Store listing.

## Directory Structure

```
store_listing/
├── en-US/                          # English (United States) listing
│   ├── title.txt                   # App name (50 chars max)
│   ├── short_description.txt       # Short description (80 chars max)
│   ├── full_description.txt        # Full description (4000 chars max)
│   └── release_notes_v1.0.0.txt   # Release notes for v1.0.0
├── fr-FR/                          # French (France) listing
│   ├── title.txt                   # App name (50 chars max)
│   ├── short_description.txt       # Short description (80 chars max)
│   ├── full_description.txt        # Full description (4000 chars max)
│   └── release_notes_v1.0.0.txt   # Release notes for v1.0.0
├── assets/                         # Visual assets (create these)
│   ├── icon_512.png               # App icon 512×512 (REQUIRED)
│   ├── feature_graphic.png        # Feature graphic 1024×500 (REQUIRED)
│   └── screenshots/               # Screenshots (REQUIRED)
│       ├── phone/                 # Phone screenshots (2-8 required)
│       └── tablet/                # Tablet screenshots (optional)
├── ASSET_REQUIREMENTS.md          # Complete asset specifications
└── README.md                      # This file
```

## What's Included

### Store Listing Copy ✅

All text content is ready to use in **2 languages**:

**English (en-US)** and **French (fr-FR)**:
1. **title.txt** - "CountScore - Score Tracker" / "CountScore - Suivi de Score"
2. **short_description.txt** - Engaging description (under 80 chars)
3. **full_description.txt** - 3,500+ character comprehensive description with:
   - Feature highlights
   - Use cases
   - Privacy focus
   - SEO-optimized keywords
4. **release_notes_v1.0.0.txt** - Launch announcement for v1.0.0

### Asset Specifications ✅

Complete requirements documented in `ASSET_REQUIREMENTS.md`:
- App icon specifications (512×512)
- Feature graphic specifications (1024×500)
- Screenshot requirements and strategies
- Design tips and tools
- Quality checklist

## What You Need to Create

### Required Visual Assets

Before you can publish, you need to create:

1. **App Icon** (512×512px PNG)
   - High-resolution version of your app icon
   - See: `ASSET_REQUIREMENTS.md` for specifications

2. **Feature Graphic** (1024×500px)
   - Promotional banner for Play Store
   - See: `ASSET_REQUIREMENTS.md` for design ideas

3. **Screenshots** (minimum 2, recommended 4-8)
   - Phone screenshots showing key features
   - See: `ASSET_REQUIREMENTS.md` for capture guide

Save these files in the `assets/` directory:
```
assets/
├── icon_512.png
├── feature_graphic.png
└── screenshots/
    └── phone/
        ├── 01_main_screen.png
        ├── 02_players.png
        ├── 03_history.png
        └── 04_games.png
```

## How to Use

### 1. Review Store Listing Copy

Read through the text files in `en-US/`:
- Edit if you want to personalize the content
- Replace placeholder email/GitHub URLs
- Ensure it accurately represents your app

### 2. Create Visual Assets

Follow the guide in `ASSET_REQUIREMENTS.md`:
- Design app icon (512×512)
- Create feature graphic (1024×500)
- Capture screenshots (4-8 recommended)

### 3. Upload to Play Console

In Google Play Console:

**Store Presence > Main store listing**:
1. App name: Copy from `title.txt`
2. Short description: Copy from `short_description.txt`
3. Full description: Copy from `full_description.txt`
4. App icon: Upload `assets/icon_512.png`
5. Feature graphic: Upload `assets/feature_graphic.png`
6. Phone screenshots: Upload from `assets/screenshots/phone/`

**Production > Releases**:
1. Release notes: Copy from `release_notes_v1.0.0.txt`

## Localization

### Available Languages ✅

CountScore store listing is currently available in:
- 🇺🇸 **en-US** - English (United States)
- 🇫🇷 **fr-FR** - French (France)

### Adding More Languages

To add support for additional languages, create new directories:

```
store_listing/
├── en-US/           # English (United States) ✅
├── fr-FR/           # French (France) ✅
├── es-ES/           # Spanish (Spain)
├── de-DE/           # German (Germany)
├── it-IT/           # Italian (Italy)
├── pt-BR/           # Portuguese (Brazil)
└── ...
```

Each language directory should contain:
- title.txt
- short_description.txt
- full_description.txt
- release_notes_vX.X.X.txt

Screenshots can be reused or localized as needed.

## Tips for Success

### Store Listing Copy

**DO**:
- ✅ Highlight unique features
- ✅ Focus on user benefits
- ✅ Use clear, concise language
- ✅ Include relevant keywords naturally
- ✅ Mention "free", "no ads", "privacy" (competitive advantages)

**DON'T**:
- ❌ Make false claims
- ❌ Keyword stuff
- ❌ Use all caps excessively
- ❌ Mention competitors by name

### Visual Assets

**Quality Matters**:
- Professional-looking assets increase conversion rates
- First impressions are critical
- Consistency across all assets

**Testing**:
- Preview on different device sizes
- Check readability at small sizes
- Get feedback before finalizing

## Character Limits Reference

Quick reference for Play Console text fields:

| Field | Limit | Current |
|-------|-------|---------|
| App name | 50 chars | 26 chars ✅ |
| Short description | 80 chars | 79 chars ✅ |
| Full description | 4000 chars | ~3500 chars ✅ |
| Release notes | 500 chars | ~450 chars ✅ |

## Asset Size Reference

| Asset | Dimensions | Format | Max Size |
|-------|------------|--------|----------|
| App icon | 512 × 512 | PNG (32-bit) | 1 MB |
| Feature graphic | 1024 × 500 | JPEG/PNG (24-bit) | ~1 MB |
| Screenshots | See ASSET_REQUIREMENTS.md | JPEG/PNG (24-bit) | 8 MB each |

## Maintenance

### Updating for New Versions

When releasing updates:

1. Create new release notes:
   ```
   release_notes_v1.1.0.txt
   release_notes_v1.2.0.txt
   ```

2. Update full description if features change

3. Update screenshots if UI changes significantly

### A/B Testing

Consider testing different:
- Short descriptions
- Screenshot orders
- Feature graphic designs

Google Play Console supports A/B testing for store listings.

## Resources

- **Play Console Help**: https://support.google.com/googleplay/android-developer
- **Material Design**: https://material.io/
- **App Store Optimization**: https://developer.android.com/distribute/best-practices/grow

## Checklist

Before submitting to Play Store:

**Text Content**:
- [ ] Reviewed all text files
- [ ] Replaced placeholders (email, URLs)
- [ ] Verified character limits
- [ ] Spell-checked content
- [ ] Accurate feature descriptions

**Visual Assets**:
- [ ] Created 512×512 app icon
- [ ] Created 1024×500 feature graphic
- [ ] Captured 4-8 screenshots
- [ ] All assets meet specifications
- [ ] Previewed on multiple devices

**Upload**:
- [ ] Uploaded all text to Play Console
- [ ] Uploaded all visual assets
- [ ] Previewed store listing
- [ ] Looks professional and accurate

---

**Status**: Store listing copy ✅ Ready | Visual assets ⚠️ Need creation

See `ASSET_REQUIREMENTS.md` for detailed asset creation guide.
