# Play Store Asset Requirements for CountScore

Complete specifications and guidelines for creating Google Play Store visual assets.

**Last Updated**: September 16, 2026
**Target**: Google Play Store listing for CountScore v1.1.0 and later

> The icon, the feature graphic and eight phone screenshots are **committed and published**
> (`assets/`), so the "what you need to create" framing below applies only to what is still
> missing: compliant screenshots and a tablet set. See
> `wip/todo/2026-09-16-screenshots-are-raw-captures.md` and
> `.llmwiki/StoreListing.md`.

---

## Table of Contents

1. [Asset Checklist](#asset-checklist)
2. [App Icon (512×512)](#app-icon-512512)
3. [Feature Graphic (1024×500)](#feature-graphic-1024500)
4. [Screenshots](#screenshots)
5. [Design Tips](#design-tips)
6. [Tools and Resources](#tools-and-resources)

---

## Asset Checklist

**Required Assets** (MUST have before submission):
- [ ] App Icon: 512×512px PNG with alpha
- [ ] Feature Graphic: 1024×500px JPEG or PNG (no alpha)
- [ ] Phone Screenshots: Minimum 2, recommended 4-8

**Optional Assets** (Good to have):
- [ ] Tablet Screenshots: 1-8 screenshots (7-10 inch tablets)
- [ ] Promotional Video: YouTube URL (30-120 seconds)

**Status Tracking**:
- Assets location: `store_listing/assets/`
- Naming convention: `icon_512.png`, `feature_graphic.png`, `screenshot_1.png`, etc.

---

## App Icon (512×512)

### Technical Specifications

**Dimensions**: 512 × 512 pixels (exact)
**Format**: 32-bit PNG with alpha channel
**File Size**: Maximum 1024 KB (1 MB)
**Color Space**: sRGB
**File Name**: `icon_512.png`

### Design Requirements

**Shape**:
- ✅ Full square (512×512)
- ❌ No rounded corners (Google Play handles masking)
- ❌ No drop shadows extending beyond square
- ✅ Design should work when masked to circle or squircle

**Content Rules**:
- ❌ No text claiming ranking (e.g., "#1 App", "Best")
- ❌ No pricing information ("Free", "$0.99")
- ❌ No device frames or UI mockups
- ✅ Simple, recognizable icon design
- ✅ Works well at small sizes (48×48px)

**Transparency**:
- ✅ Alpha channel allowed for non-rectangular designs
- ⚠️ Background transparency will show as white on some devices
- 💡 Tip: Design works on both light and dark backgrounds

### Design Guidelines for CountScore

**Theme**: Score tracking, games, counting

**Color Palette**:
- Primary: Material Design colors (consider blue, green, or purple)
- Consider using app's theme colors for consistency
- Ensure good contrast for visibility

**Icon Concepts** (choose one):
1. **Scorecard Design**:
   - Simple scorecard/clipboard graphic
   - Numbers or tally marks
   - Clean, minimal style

2. **Game Elements**:
   - Dice, cards, or board game pieces
   - Abstract representation
   - Recognizable at small size

3. **Counter/Tracker**:
   - Circular counter or gauge
   - Numbers prominently displayed
   - Modern, clean look

4. **Typography-Based**:
   - "CS" monogram
   - Numbers (like "01" or "123")
   - Bold, readable font

**What to Avoid**:
- Overly complex designs
- Text that's too small to read
- Too many elements
- Dated or skeuomorphic styles

### Current Icon

Your current icon is located at:
```
android/app/src/main/res/mipmap-xxxhdpi/ic_launcher.png (192×192)
```

**Action Required**: Create high-resolution 512×512 version for Play Store.

### Export Settings

**Figma/Sketch/Adobe XD**:
```
Size: 512×512px
Format: PNG
DPI: 72 (web standard)
Color: RGB
Alpha: Yes
```

**Photoshop**:
```
File > Export > Export As
Format: PNG-24
Width: 512px, Height: 512px
Transparency: Checked
```

---

## Feature Graphic (1024×500)

### Technical Specifications

**Dimensions**: 1024 × 500 pixels (exact, 2.048:1 ratio)
**Format**: JPEG or 24-bit PNG
**Alpha Channel**: ❌ NOT allowed (must be opaque)
**File Size**: No strict limit, keep under 1 MB recommended
**File Name**: `feature_graphic.png` or `feature_graphic.jpg`

### Design Requirements

**Shape & Masking**:
- ✅ Full rectangle 1024×500
- ❌ No rounded corners (Play Store may apply)
- ⚠️ Keep important content away from edges (safe zone: 924×400 center)

**Content Rules**:
- ✅ Showcase app purpose or key features
- ✅ High-quality professional design
- ❌ No misleading images
- ❌ No screenshots with visible bugs
- ❌ No text claiming rankings or awards
- ✅ Consistent branding with app icon

### Design Ideas for CountScore

**Layout Options**:

**Option 1: App Name + Screenshot**
```
[App Icon]  CountScore - Score Tracker
            [Screenshot of main UI]
```

**Option 2: Feature Highlights**
```
Background: Gradient or solid color
Content:
- CountScore logo/icon (left)
- "Track Scores for Any Game" tagline
- 3 small feature icons with labels:
  • Multiple Games • Player Stats • Offline
```

**Option 3: Mockup Style**
```
Phone mockup showing app in use
Tagline: "Simple Score Tracking for Game Night"
Clean background (solid color or subtle gradient)
```

**Option 4: Typography Focus**
```
Large "CountScore" text
Tagline: "Never Lose Track Again"
Small icons representing game types
Minimal, clean design
```

### Content Suggestions

**Headline Options**:
- "CountScore – Track Every Point"
- "Simple Score Tracking for Any Game"
- "Your Game Night Score Keeper"
- "Never Forget the Score Again"

**Tagline Options**:
- "No Ads • No Tracking • Open Source"
- "Multiple Games • Unlimited Players"
- "Works Offline • Privacy Focused"

**Visual Elements**:
- App icon
- Phone mockup with screenshot
- Feature icons (dice, scoreboard, players)
- Game-related imagery (cards, board games)

### Color Schemes

**Option 1: Vibrant**
- Background: Gradient (purple to blue)
- Text: White
- Accent: Yellow or green

**Option 2: Clean Professional**
- Background: White or light gray
- Text: Dark blue or black
- Accent: Brand color

**Option 3: Dark Mode**
- Background: Dark blue or charcoal
- Text: White
- Accent: Bright accent color

### Safe Zones

Keep critical content within safe zone to avoid cropping:

```
Total:  1024 × 500
Safe:   924 × 400 (50px padding on all sides)
```

**What to keep in safe zone**:
- App name/logo
- Important text
- Key visual elements
- Call-to-action

**Can extend to edges**:
- Background colors/gradients
- Decorative elements
- Non-critical imagery

---

## Screenshots

### Technical Specifications

**Quantity**:
- Minimum: 2 screenshots
- Recommended: 4-8 screenshots
- Maximum: 8 screenshots per device type

**Dimensions**:
- Minimum width or height: 320px
- Maximum width or height: 3840px
- **Aspect ratio: no wider than 16:9 (1.778)** in either orientation — i.e. the long side is
  at most 1.778× the short side

> **Status: Corrected** (2026-09-16) — this line read "Max dimension ≤ 2× min dimension"
> (2:1). That is the *old* Play limit; the current requirement is 16:9. The difference is not
> academic here: the committed captures are 1080×2400, ratio **2.222**, which fails both.

**Recommended Resolution**:
- **Phone (portrait)**: 1080 × 1920px (9:16 ratio) — the target to compose to
- **Phone (landscape)**: 1920 × 1080px (16:9 ratio)
- **Tablet (portrait)**: 1536 × 2048px (3:4 ratio)

A modern phone screen is taller than 16:9 (a Pixel 9 Pro XL captures 1080×2400), so a raw
`adb` capture is **never** a valid screenshot on its own. It has to be composed into a
1080×1920 frame — which is what a caption band above the screen is for.

**Format**: JPEG or 24-bit PNG
**Alpha**: not allowed — the image must be fully opaque, 24-bit RGB.

> **Status: Composed per locale** (2026-09-18) — the eight PNGs in
> `assets/screenshots/phone/` are still raw `8-bit/color RGBA` captures, but they are now only
> the input of `scripts/compose_screenshots.py`, which writes the 1080×1920 opaque RGB set of
> each locale to `<locale>/screenshots/phone/`. `--check` verifies every locale has one. Until
> a locale has its set, `play_publish.py` falls back to the raw captures for it — `fr-FR` has
> its set; the nine others follow once the French captions are validated
> (`wip/todo/2026-09-16-screenshots-are-raw-captures.md`).

**File Size**: Maximum 8 MB per screenshot

### Screenshot Strategy

**First 2-3 screenshots are CRITICAL** (most users only see these):

1. **Main Screen** - Show core functionality
2. **Key Feature** - Highlight best feature
3. **User Benefit** - Show value proposition

**Full 8-screenshot strategy**:

1. **Main Game Screen** - Active score tracking
2. **Player Management** - Add/manage players
3. **Game History** - Past games and stats
4. **Game Types** - Multiple game support
5. **Customization** - Colors and settings
6. **Easy Score Entry** - Simple interface
7. **Game Board View** - Visual appeal
8. **Settings/About** - App info (optional)

### Content Guidelines

**DO**:
- ✅ Show realistic, authentic UI
- ✅ Use real-looking data (not lorem ipsum)
- ✅ Highlight key features
- ✅ Show actual app screens
- ✅ Keep UI clean and bug-free
- ✅ Use high-resolution captures

**DON'T**:
- ❌ Use mockups or fake UI
- ❌ Show bugs or errors
- ❌ Include developer tools
- ❌ Show placeholder text
- ❌ Use low-quality captures

### Screenshot Enhancement

**Optional Enhancements** (not required but effective):

**1. Text Overlays** (subtle, not covering UI):
```
Screenshot 1: "Track Scores for Any Game"
Screenshot 2: "Manage Multiple Players"
Screenshot 3: "View Complete History"
```

**2. Device Frames**:
- Add phone frame around screenshot
- Makes screenshots more attractive
- Tool: Device Art Generator (Android)

**3. Background**:
- Solid color background
- Gradient background
- Keeps focus on app

**Keep it simple** - The app UI should be the star, not the decoration.

### Capturing Screenshots

**Method 1: Android Emulator**
```bash
# Start emulator
flutter run

# Use emulator controls to capture screenshot
# Or press Cmd+S (Mac) / Ctrl+S (Windows)
```

**Method 2: Physical Device**
```bash
# Connect device via ADB
adb devices

# Take screenshot
adb shell screencap -p > screenshot.png

# Or use device's screenshot function
# Power + Volume Down (most Android devices)
```

**Method 3: Android Studio**
```
# In Android Studio
# Logcat panel > Camera icon > Capture screenshot
```

### Screenshot Checklist

Before uploading:
- [ ] Resolution meets requirements (min 320px, max 3840px)
- [ ] Aspect ratio no wider than 16:9 (a raw phone capture is not)
- [ ] File format is JPEG or PNG
- [ ] File size under 8 MB
- [ ] No alpha channel (fully opaque)
- [ ] UI looks clean and professional
- [ ] Data looks realistic
- [ ] No bugs or errors visible
- [ ] First 2-3 screenshots are strongest
- [ ] Screenshots tell a story/show value

---

## Design Tips

### General Guidelines

**1. Consistency**
- All assets should share visual language
- Use same color palette across icon, feature graphic, screenshots
- Maintain brand identity

**2. Simplicity**
- Less is more - avoid clutter
- Focus on key message
- Make it easy to understand at a glance

**3. Quality**
- Use high-resolution assets
- Avoid compression artifacts
- Test on multiple screen sizes

**4. Authenticity**
- Show real app functionality
- Don't promise features that don't exist
- Use actual screenshots, not mockups

### Typography

**Font Choices**:
- Modern, readable sans-serif fonts
- Google Fonts recommendations:
  - Roboto (Android standard)
  - Open Sans
  - Lato
  - Montserrat

**Size Guidelines**:
- Feature Graphic headline: 60-100px
- Feature Graphic tagline: 30-50px
- Screenshot overlays: 40-60px

**Legibility**:
- High contrast (text vs background)
- Avoid thin fonts
- Test readability at small sizes

### Color Psychology

**Blue**: Trust, reliability, professionalism
- Good for: Productivity apps, utilities

**Green**: Growth, harmony, health
- Good for: Health, finance, education

**Purple**: Creativity, wisdom, quality
- Good for: Creative apps, premium tools

**Red/Orange**: Energy, excitement, urgency
- Good for: Games, social apps, alerts

**For CountScore**: Consider blue (trust), green (positive), or purple (quality)

---

## Tools and Resources

### Design Tools

**Professional (Paid)**:
- **Adobe Photoshop** ($20.99/month)
- **Adobe Illustrator** ($20.99/month)
- **Sketch** (Mac only, $99/year)
- **Affinity Designer** (one-time $69.99)

**Free Tools**:
- **Figma** (Free tier available) - **Recommended**
  - https://figma.com
  - Browser-based, collaborative
  - Templates available

- **GIMP** (Free, open source)
  - https://www.gimp.org
  - Photoshop alternative

- **Inkscape** (Free, open source)
  - https://inkscape.org
  - Vector graphics editor

- **Canva** (Free tier)
  - https://canva.com
  - Easy for non-designers
  - Templates available

### Icon Generators

**Android Asset Studio**
- https://romannurik.github.io/AndroidAssetStudio/
- Generate all icon sizes
- Free, browser-based

**App Icon Generator**
- https://appicon.co/
- Generate icons for multiple platforms

### Screenshot Tools

**Device Frame Generator**
- https://mockuphone.com/
- Add device frames to screenshots

**Screenshot Beautifier**
- https://screenshots.pro/
- Add backgrounds and frames

**Screely**
- https://screely.com/
- Add backgrounds to screenshots

### Color Tools

**Material Design Color Tool**
- https://material.io/resources/color/
- Generate color palettes
- Check contrast

**Coolors**
- https://coolors.co/
- Color palette generator

**Adobe Color**
- https://color.adobe.com/
- Professional color schemes

### Inspiration

**Google Play Store**
- Browse top apps in Tools category
- See what works well

**Dribbble**
- https://dribbble.com/
- Search "app icon" or "app store assets"

**Behance**
- https://behance.net/
- Professional design portfolios

---

## File Organization

**Recommended structure**:
```
store_listing/
├── assets/
│   ├── icon_512.png (512×512, <1MB)
│   ├── feature_graphic.png (1024×500)
│   ├── screenshots/
│   │   ├── phone/
│   │   │   ├── 01_main_screen.png
│   │   │   ├── 02_player_management.png
│   │   │   ├── 03_game_history.png
│   │   │   └── 04_game_types.png
│   │   └── tablet/ (optional)
│   │       ├── 01_main_screen_tablet.png
│   │       └── ...
│   └── source_files/ (optional, for future edits)
│       ├── icon.fig or .psd
│       └── feature_graphic.fig or .psd
└── ASSET_REQUIREMENTS.md (this file)
```

---

## Quality Checklist

Before submitting to Play Store:

### Icon
- [ ] 512×512 pixels exactly
- [ ] 32-bit PNG with alpha
- [ ] File size under 1 MB
- [ ] Works on light and dark backgrounds
- [ ] Recognizable at small sizes (48×48)
- [ ] No text that's too small
- [ ] Professional, polished appearance

### Feature Graphic
- [ ] 1024×500 pixels exactly
- [ ] JPEG or 24-bit PNG (no alpha)
- [ ] Important content in safe zone (924×400)
- [ ] High quality, no artifacts
- [ ] Represents app accurately
- [ ] Professional, attractive design
- [ ] Consistent with app icon

### Screenshots
- [ ] Minimum 2 screenshots provided
- [ ] Recommended 4-8 screenshots
- [ ] Resolution meets requirements
- [ ] Aspect ratio no wider than 16:9 (a raw phone capture is not)
- [ ] File size under 8 MB each
- [ ] No alpha channel
- [ ] Shows real app UI
- [ ] Clean, bug-free screens
- [ ] First 2-3 are strongest
- [ ] Tell a coherent story

---

## Next Steps

1. **Design Phase** (3-5 days):
   - Sketch concepts
   - Choose colors and fonts
   - Create drafts

2. **Creation Phase** (2-4 days):
   - Design 512×512 icon
   - Create 1024×500 feature graphic
   - Capture and enhance screenshots

3. **Review Phase** (1 day):
   - Check all requirements
   - Test on different backgrounds
   - Get feedback from others

4. **Upload Phase**:
   - Upload to Play Console
   - Preview in store listing
   - Make adjustments if needed

---

## Support

Need help with asset creation?

- **Design Questions**: Refer to Material Design guidelines
- **Technical Issues**: Check Play Console Help Center
- **Outsourcing**: Consider hiring designer on Fiverr, 99designs, or Upwork

**Estimated Cost** (if outsourcing):
- Icon only: $20-100
- Feature graphic: $30-100
- Complete asset package: $100-300

---

**Good luck with your asset creation!** 🎨

Remember: Great assets can significantly improve your app's conversion rate on the Play Store.
