# CountScore - Feature Graphic Design Templates

Complete guide with layouts and templates for creating the 1024×500 feature graphic banner.

**Last Updated**: 2026-09-20
**Target**: 1024×500px promotional banner for Google Play Store

> **What ships, and how to redraw it.** `store_listing/assets/feature_graphic.png` is
> **Template 1** in the brand teal, drawn by `scripts/generate_feature_graphic.py` (Pillow):
>
> ```bash
> uv run --script scripts/generate_feature_graphic.py           # redraw the PNG
> uv run --script scripts/generate_feature_graphic.py --check   # verify, write nothing
> ```
>
> It composes committed inputs only — the generated icon `store_listing/assets/icon_512.png`,
> the en-US capture of the fictional demo database (`en-US/raw/05_game_board.png`) and the
> bundled Nunito — so the graphic is reproducible and shows no real person's data.
>
> **The colours below are copies.** Their home is `lib/utils/app_theme.dart`:
> `kBrandSeedLight` `#0E8F88`, `kBrandSeedDark` `#5ED8CF`, `kLeaderGold` `#F2B705`; the ink
> `#0E1716` is the icon's ground and the dark theme's surface. When the theme moves, that
> file moves first and this one follows.

---

## What is a Feature Graphic?

The feature graphic is a **wide promotional banner** (1024×500px) that appears:
- At the top of your Play Store listing (on some devices)
- In Play Store search results (featured apps)
- In promotional materials and screenshots

**Purpose**: Grab attention and communicate value proposition quickly.

---

## Design Principles

### What Makes a Great Feature Graphic

**✅ Best Practices**:
1. **Clear Message**: Users should understand the app instantly
2. **Eye-Catching**: Stands out in crowded Play Store
3. **Professional**: High-quality design reflects app quality
4. **On-Brand**: Uses CountScore colors and style
5. **Simple**: Not too cluttered or busy
6. **Safe Zone Aware**: Critical content within 924×400 center

**❌ What to Avoid**:
- Too much text (hard to read)
- Cluttered design (overwhelming)
- Low-quality images (unprofessional)
- Misleading visuals (will get rejected)
- Ignoring safe zones (content gets cropped)

---

## Feature Graphic Templates

### Template 1: App Name + Screenshot Mockup

**Layout Description**:
- Left side: App icon + name + tagline
- Right side: Phone mockup showing app in use
- Background: Solid color or subtle gradient

**Visual Layout**:
```
┌─────────────────────────────────────────────────────────┐
│                                                           │
│  [Icon]  CountScore                    [Phone Mockup]   │
│          Score Tracker                 [  Screenshot  ]  │
│          No Ads • Privacy First        [    Inside    ]  │
│                                                           │
└─────────────────────────────────────────────────────────┘
     1024×500px
```

**Color Scheme**:
- Background: brand teal (#0E8F88) or a gradient of it
- Text: White (#FFFFFF)
- Mockup: natural phone colors, in an ink (#0E1716) frame
- Accent: leader gold (#F2B705) for highlights

**Use Cases**: Best for showing actual app interface clearly

**Difficulty**: Medium (need to create phone mockup)

---

### Template 2: Feature Highlights with Icons

**Layout Description**:
- Center: App name/logo
- Below: 3-4 feature highlights with icons
- Background: Colorful gradient or solid

**Visual Layout**:
```
┌─────────────────────────────────────────────────────────┐
│                    CountScore                            │
│                  Track Any Game Score                    │
│                                                           │
│   [Icon1]        [Icon2]         [Icon3]         [Icon4]│
│  Multiple      Easy Player     Complete       No Ads    │
│   Games        Management       History                  │
│                                                           │
└─────────────────────────────────────────────────────────┘
```

**Color Scheme**:
- Background: teal gradient (#189890 → #095954)
- Text: White
- Icons: the icon's own accents (gold #F2B705, vermilion #E4572E, blue #3B82F6)

**Use Cases**: Best for communicating multiple features quickly

**Difficulty**: Easy (simple icons and text)

---

### Template 3: Typography Focus

**Layout Description**:
- Large, bold headline
- Supporting tagline
- Minimal graphics (maybe app icon)
- Focus is on message, not visuals

**Visual Layout**:
```
┌─────────────────────────────────────────────────────────┐
│                                                           │
│                                                           │
│          Never Forget the Score Again                    │
│          Simple Tracking for Any Game                    │
│                                                           │
│                         [App Icon]                        │
└─────────────────────────────────────────────────────────┘
```

**Color Scheme**:
- Background: solid brand teal (#0E8F88) or White
- Text: White (on teal) or teal (on white)
- Bold, modern font (60-100px) — Nunito, the app's own (`assets/fonts/`)

**Use Cases**: Best for clear, direct messaging

**Difficulty**: Very Easy (just text and color)

---

### Template 4: Split Screen Design

**Layout Description**:
- Left half: Colored background with text
- Right half: Screenshot or app visual
- Clear division creates visual interest

**Visual Layout**:
```
┌──────────────────────────┬──────────────────────────────┐
│                          │                              │
│  CountScore              │                              │
│  ─────────────           │      [App Screenshot]        │
│  Track scores for        │                              │
│  board games, card       │      [or Phone Mockup]       │
│  games, and sports       │                              │
│                          │                              │
└──────────────────────────┴──────────────────────────────┘
    Teal side                   Screenshot side
```

**Color Scheme**:
- Left: brand teal (#0E8F88)
- Right: White or light grey background with screenshot
- Text: White on teal, dark on light

**Use Cases**: Balanced approach, shows UI and messaging

**Difficulty**: Medium

---

### Template 5: Minimalist Modern

**Layout Description**:
- Clean, lots of white space
- App icon prominently featured
- Short, punchy headline
- Modern, sophisticated aesthetic

**Visual Layout**:
```
┌─────────────────────────────────────────────────────────┐
│                                                           │
│                                                           │
│            [Large App Icon]                               │
│                                                           │
│            CountScore                                     │
│            Simple Score Tracking                          │
│                                                           │
└─────────────────────────────────────────────────────────┘
```

**Color Scheme**:
- Background: White (#FFFFFF) or very light grey
- Icon: the app icon as it is, on its ink ground
- Text: brand teal (#0E8F88) or dark grey

**Use Cases**: Premium feel, less is more approach

**Difficulty**: Easy

---

## Recommended Template

### **SHIPPED: Template 1 - App Name + Screenshot Mockup**

`scripts/generate_feature_graphic.py` draws it. **Why it won over Template 2** (2026-09-20):
the four-icon board of Template 2 says what the app promises, while the real scoring grid in
a phone frame shows that it delivers — and the app name stays legible at thumbnail size
either way. The three promises survive as gold pills under the tagline.

**What it puts on the canvas**:
- Left: the app icon, `CountScore` in Nunito ExtraBold, the tagline *Keep score for every
  game*, the line *Offline scores · Stats · Share with your group*, and the gold pills
  *No ads · No tracking · Open source*
- Right: an ink phone frame holding the en-US board capture, bleeding off the bottom edge
- Background: a teal gradient with two soft lighter discs behind the phone

**Detailed Specifications**:

**Canvas**: 1024×500px
**Safe Zone**: 924×400 (keep critical content within)

**Layout Breakdown** (the geometry the script draws, in canvas pixels):
```
Left column (x 58 → 640):
- Icon:     126×126 at (58, 98), corners rounded 23.5 %
- App name: "CountScore", Nunito ExtraBold 72px, white, beside the icon
- Tagline:  "Keep score for every game", Nunito Bold 38px, baseline y 262
- Sub-line: "Offline scores · Stats · Share with your group", Nunito 25px, baseline y 310
- Pills:    three, 48px high, gold, top y 336

Right column:
- Phone: 322×556 ink frame at (664, 46) — it runs off the bottom edge on purpose

Padding: 50px all sides (the 924×400 safe zone)
```

**Color Recipe** (the values `scripts/generate_feature_graphic.py` uses):
```
Background: Linear gradient
  - Start: #189890 (the teal, lifted 12 % towards #5ED8CF)
  - End:   #095954 (the same teal at 62 %)
  - Direction: top to bottom

Text: #FFFFFF (White)

Accents:
  - Promise pills: #F2B705 (leader gold) with #0E1716 (ink) text
  - Phone frame:   #0E1716 (ink)
```

---

## Step-by-Step Creation Guide

### Using Figma (Free, Recommended)

**Step 1: Setup** (5 minutes)
1. Go to https://figma.com (create free account if needed)
2. Create new file
3. Create frame: 1024×500px
4. Name it "CountScore Feature Graphic"

**Step 2: Background** (5 minutes)
1. Select frame
2. Fill > Linear gradient
3. Top color: #189890
4. Bottom color: #095954
5. Adjust gradient angle (try 90° or 135°)

**Step 3: Safe Zone Guide** (2 minutes)
1. Create rectangle: 924×400px
2. Center it in frame (auto-layout)
3. Set to outline only (no fill)
4. Lock this layer (it's just a guide)

**Step 4: Add App Name** (10 minutes)
1. Add text: "CountScore"
2. Font: Roboto Bold or Montserrat Bold
3. Size: 60-80px
4. Color: White (#FFFFFF)
5. Position: Top center, within safe zone
6. Optional: Add subtle drop shadow

**Step 5: Add Tagline** (5 minutes)
1. Add text: "Track Any Game Score" (or your preferred tagline)
2. Font: Same as app name, but Regular weight
3. Size: 30-40px
4. Color: White or light grey
5. Position: Below app name

**Step 6: Add Feature Icons** (20 minutes)
1. Use Material Design icons or simple shapes
2. Create 4 icons, each ~80-100px
3. Space evenly across bottom half
4. Colors: Amber, Green, Blue, White (representing game variety)
5. Below each icon, add label text:
   - "Multiple Games"
   - "Easy Player Management"
   - "Complete History"
   - "No Ads"

**Step 7: Final Touches** (8 minutes)
1. Adjust spacing and alignment
2. Ensure all critical content within safe zone
3. Add app icon somewhere (optional)
4. Review overall balance and readability

**Step 8: Export** (5 minutes)
1. Select frame
2. Export settings:
   - Format: PNG
   - Scale: 1x
   - Suffix: Leave blank
3. Export as `feature_graphic.png`
4. Verify: Exactly 1024×500px, under 1MB

**Total Time**: ~60 minutes

---

### Using Canva (Free, Easiest)

**Step 1: Setup**
1. Go to https://canva.com
2. Create design > Custom size: 1024×500px
3. Choose template or start blank

**Step 2: Background**
1. Elements > Gradients
2. Search "teal gradient"
3. Apply to background
4. Adjust colors to match #0E8F88

**Step 3: Add Text**
1. Text > Add heading: "CountScore"
2. Choose bold font (Montserrat, Roboto)
3. Size: Large (80-100pt)
4. Color: White
5. Position: Top center

**Step 4: Add Tagline**
1. Text > Add subheading
2. Text: "Track Any Game Score"
3. Size: Medium (40-50pt)
4. Position: Below app name

**Step 5: Add Icons**
1. Elements > Icons
2. Search: "game", "user", "history", "check"
3. Add 4 icons
4. Color icons: teal, gold, vermilion, blue
5. Add text labels below each

**Step 6: Export**
1. Share > Download
2. File type: PNG
3. Size: Original (1024×500)
4. Download

**Total Time**: ~45 minutes

---

## Content Ideas

### Headlines (Choose One)

**Value Proposition Focus**:
- "Never Forget the Score Again"
- "Track Any Game Score, Anytime"
- "Simple Score Tracking for Game Night"
- "Your Digital Scorekeeper"

**Feature Focus**:
- "Multiple Games • Unlimited Players • Complete History"
- "Track Scores for Any Game"
- "From Board Games to Card Games"

**Privacy Focus**:
- "Score Tracking. Privacy Focused."
- "No Ads. No Tracking. Just Scores."
- "Your Scores Stay on Your Device"

### Taglines (Secondary Text)

- "Simple, Powerful, Private"
- "Free Forever • Open Source"
- "Works Offline • No Account Required"
- "Perfect for Game Night"
- "Supports Any Game Type"

### Feature Highlights (If Using Template 2)

**Pick 4 from these**:
1. Multiple Games (Icon: Grid/gamepad)
2. Easy Player Management (Icon: People/users)
3. Complete History (Icon: Clock/calendar)
4. No Ads (Icon: Block/shield)
5. Offline First (Icon: Cloud with X/airplane)
6. Privacy Focused (Icon: Lock/shield)
7. Free Forever (Icon: Tag/money with X)
8. Open Source (Icon: Code brackets/GitHub)

---

## Color Scheme Variations

### Variation 1: Teal Gradient (what ships)
```
Background: #189890 → #095954
Text: White
Accents: gold #F2B705, ink #0E1716
Style: Modern, calm
```

### Variation 2: Light & Clean
```
Background: White (#FFFFFF)
Text: brand teal (#0E8F88)
Accents: the icon's own colors (gold, vermilion #E4572E, blue #3B82F6, teal #5ED8CF)
Style: Professional, clean
```

### Variation 3: Dark
```
Background: ink (#0E1716), the icon's own ground
Text: White
Accents: the lifted teal #5ED8CF and the gold
Style: Modern, tech-focused
```

### Variation 4: Multi-Color
```
Background: White
Colored sections: teal, gold, vermilion, blue blocks
Text: White on colored sections
Style: Playful, colorful
```

---

## Safe Zone Guidelines

**Critical**: Keep important content within safe zone!

**Safe Zone**: 924×400px centered
**Total Canvas**: 1024×500px

**Padding from Edges**:
- Left/Right: 50px minimum
- Top/Bottom: 50px minimum

**What to Keep in Safe Zone**:
- App name
- Tagline
- Feature text
- Important graphics

**What Can Extend to Edges**:
- Background colors/gradients
- Decorative elements
- Non-critical graphics

---

## Technical Specifications

### Export Requirements

**Dimensions**: Exactly 1024×500 pixels
**Format**: JPEG or 24-bit PNG (NO alpha channel)
**File Size**: Under 1 MB recommended
**Color Space**: sRGB
**Quality**: High (no visible compression artifacts)

### Export Settings by Tool

**Figma**:
```
Export > PNG
Scale: 1x (1024×500)
Include background: Yes (no transparency)
```

**Photoshop**:
```
File > Export > Export As
Format: PNG-24 or JPEG (quality 90)
No transparency
1024×500px
```

**Canva**:
```
Share > Download
PNG or JPEG
1024×500px
Background included
```

**GIMP**:
```
Image > Scale: 1024×500
File > Export As
Format: PNG or JPEG
No alpha channel
```

---

## Common Mistakes

### Design Mistakes

❌ **Text Outside Safe Zone**
```
Problem: App name cut off at edges
Solution: Keep all text within 924×400 center area
```

❌ **Too Much Text**
```
Problem: Entire app description in feature graphic
Solution: Keep to 1-2 short sentences maximum
```

❌ **Low Contrast**
```
Problem: Light text on light background
Solution: Ensure 4.5:1 contrast ratio minimum
```

❌ **Too Cluttered**
```
Problem: 10+ elements competing for attention
Solution: Limit to 3-5 key elements
```

### Technical Mistakes

❌ **Alpha Channel Present**
```
Problem: PNG with transparency
Solution: Export as 24-bit PNG or JPEG (no alpha)
```

❌ **Wrong Dimensions**
```
Problem: 1023×499 or 1025×501
Solution: Exactly 1024×500px
```

❌ **Too Large File**
```
Problem: 2 MB JPEG
Solution: Compress to under 1 MB
```

---

## Testing Your Feature Graphic

### Visual Tests

**Full Size Review** (1024×500):
- Is the message clear?
- Are colors attractive?
- Is text readable?

**Thumbnail Test** (~200px wide):
- Can you still read the app name?
- Is it recognizable?
- Does it stand out?

**Context Test**:
- View alongside other apps' graphics
- Does it look professional?
- Does it compete effectively?

### Technical Validation

```bash
# Check dimensions
file feature_graphic.png
# Should show: 1024 x 500

# Check file size
ls -lh feature_graphic.png
# Should be under 1 MB

# Check for alpha channel
file feature_graphic.png
# Should NOT mention "alpha" or "transparency"
```

---

## Quick Checklist

Before finalizing your feature graphic:

### Design Quality
- [ ] Message is clear and concise
- [ ] Uses brand colors (teal #0E8F88 primary, gold #F2B705 accent)
- [ ] Text is readable (good contrast)
- [ ] Not too cluttered (3-5 main elements)
- [ ] Professional appearance
- [ ] Eye-catching and attractive

### Technical Requirements
- [ ] Exactly 1024×500 pixels
- [ ] JPEG or 24-bit PNG (no alpha)
- [ ] Under 1 MB file size
- [ ] sRGB color space
- [ ] High quality (no artifacts)

### Safe Zone Compliance
- [ ] All critical content within 924×400 center
- [ ] App name in safe zone
- [ ] Tagline in safe zone
- [ ] Important graphics in safe zone

### Testing Complete
- [ ] Looks good at full size
- [ ] Readable at thumbnail size
- [ ] Tested on different backgrounds
- [ ] Shown to 2-3 people for feedback

---

## Resources

### Design Tools
- **Figma** (Free): https://figma.com
- **Canva** (Free): https://canva.com
- **Photoshop** (Paid): Adobe Creative Cloud
- **GIMP** (Free): https://gimp.org

### Stock Resources
- **Icons**: https://fonts.google.com/icons
- **Illustrations**: https://undraw.co/ (free)
- **Mockups**: https://mockuphone.com/

### Inspiration
- **Dribbble**: Search "app store banner"
- **Behance**: Search "feature graphic"
- **Play Store**: Browse top apps' graphics

---

## Example Timeline

**If you have 90 minutes**:

- **0-15 min**: Review templates, choose design
- **15-30 min**: Setup tool (Figma/Canva), create canvas
- **30-50 min**: Design background, add text
- **50-70 min**: Add icons/graphics, adjust layout
- **70-85 min**: Final touches, test readability
- **85-90 min**: Export, verify dimensions and size

**Result**: Professional feature graphic ready for Play Store!

---

**You can do this!** 🎨

Feature graphics are easier than they seem. Keep it simple, use your brand colors, and focus on clear messaging. Good luck! 🚀
