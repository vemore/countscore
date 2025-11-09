# CountScore - Color Theme Guide

Design guide for creating consistent visual assets using CountScore's color theme.

**Last Updated**: November 9, 2025
**Purpose**: Ensure icon, feature graphic, and promotional materials match app's color scheme

---

## App Color Scheme

### Primary Colors

**Primary Brand Color: Deep Purple**
- **Material Color**: `Colors.deepPurple`
- **Hex**: `#673AB7`
- **RGB**: `rgb(103, 58, 183)`
- **Usage**: Main theme, app bar, primary elements, settings icons
- **Why**: Professional, creative, quality-focused (perfect for productivity/tools apps)

**Accent/Secondary**: Generated from Deep Purple by Material Design 3
- Lighter tints and darker shades auto-generated
- Follows Material You dynamic color system

---

## Game Type Colors

CountScore uses distinct colors for different game types:

### 1. Amber (ZapZap Game)
- **Material Color**: `Colors.amber`
- **Hex**: `#FFC107`
- **RGB**: `rgb(255, 193, 7)`
- **Association**: Energy, excitement, fast-paced
- **Usage**: ZapZap game cards, icons

### 2. Red (Uno Game)
- **Material Color**: `Colors.red`
- **Hex**: `#F44336`
- **RGB**: `rgb(244, 67, 54)`
- **Association**: Bold, classic card game colors
- **Usage**: Uno game cards, delete/error actions

### 3. Green (Scrabble Game)
- **Material Color**: `Colors.green`
- **Hex**: `#4CAF50`
- **RGB**: `rgb(76, 175, 80)`
- **Association**: Success, growth, board games
- **Usage**: Scrabble game cards, success indicators

### 4. Deep Purple (Custom/Other Games)
- **Material Color**: `Colors.deepPurple`
- **Hex**: `#673AB7`
- **RGB**: `rgb(103, 58, 183)`
- **Association**: Creativity, versatility
- **Usage**: Custom games, default theme

---

## Supporting Colors

### Player Default Color
- **Material Color**: `Colors.blue`
- **Hex**: `#2196F3`
- **RGB**: `rgb(33, 150, 243)`
- **Usage**: Default player avatars, player cards

### Neutral Colors
- **Grey**: `Colors.grey` - Empty states, disabled elements
- **Light Grey**: Used for backgrounds and dividers

---

## Color Palette for Asset Design

### Recommended Primary Palette

For icon, feature graphic, and promotional materials:

```
Primary:   #673AB7 (Deep Purple) - Main brand color
Secondary: #FFC107 (Amber)       - Energy and warmth
Accent 1:  #4CAF50 (Green)       - Success and growth
Accent 2:  #2196F3 (Blue)        - Trust and reliability
Warning:   #F44336 (Red)         - Attention (use sparingly)
```

### Color Usage Guidelines

**Do**:
- ✅ Use Deep Purple as primary brand color
- ✅ Use game type colors (Amber, Red, Green) for variety
- ✅ Combine colors for visual interest
- ✅ Maintain good contrast for readability

**Don't**:
- ❌ Don't mix too many colors in one asset
- ❌ Don't use colors that clash with brand palette
- ❌ Don't ignore accessibility (contrast ratios)

---

## Asset-Specific Color Recommendations

### App Icon (512×512)

**Concept 1: Single Color Focus**
- Background: Deep Purple (#673AB7)
- Icon/Symbol: White or light color
- Simple, recognizable, professional

**Concept 2: Multi-Color (Game Variety)**
- Use 2-3 game type colors (Amber, Green, Purple)
- Represents different game support
- More playful and energetic

**Concept 3: Gradient**
- Gradient from Deep Purple to Blue
- Modern, dynamic feel
- Popular in 2025 app design

### Feature Graphic (1024×500)

**Option 1: Purple Gradient Background**
```
Background: Linear gradient
  - From: #673AB7 (Deep Purple)
  - To: #9C27B0 (Purple 500)
Text: White (#FFFFFF)
Accents: Amber (#FFC107) or Green (#4CAF50)
```

**Option 2: White/Light Background**
```
Background: #FFFFFF or #F5F5F5
Text: Deep Purple (#673AB7) or Dark Grey (#212121)
Accents: Game type colors for icons
```

**Option 3: Dark Mode Aesthetic**
```
Background: Dark blue-grey (#263238)
Text: White (#FFFFFF)
Accents: Bright game type colors (Amber, Green, Blue)
```

### Screenshots

Screenshots will naturally show the app's color scheme:
- App bar: Deep Purple
- Game cards: Amber, Red, Green, Purple
- Player elements: Blue and custom colors
- Clean Material Design 3 interface

**No enhancement needed** - the app's colors speak for themselves!

---

## Color Accessibility

### Contrast Ratios (WCAG AA Standard)

**Text on Deep Purple Background**:
- White text: ✅ 7.1:1 (Excellent, AAA)
- Light grey: ⚠️ Check contrast
- Black text: ❌ Insufficient contrast

**Text on White Background**:
- Deep Purple text: ✅ 6.7:1 (Excellent, AAA)
- Blue text: ✅ 5.8:1 (Good, AA)
- Green text: ⚠️ 3.5:1 (Marginal, AA Large)
- Amber text: ❌ 2.1:1 (Insufficient)

**Recommendations**:
- Use white text on colored backgrounds
- Use colored text on white backgrounds (except Amber)
- Ensure minimum 4.5:1 contrast for normal text
- Ensure minimum 3:1 contrast for large text (18pt+)

### Color Blindness Considerations

**Protanopia (Red-blind)**:
- Purple appears blue ✓ (Still distinctive)
- Red appears brown ⚠️ (Use with labels)
- Green appears yellow ⚠️ (Use with labels)

**Deuteranopia (Green-blind)**:
- Similar to Protanopia
- Don't rely on Red vs Green alone
- Add icons or text labels

**Tritanopia (Blue-blind)**:
- Purple/Blue distinction difficult
- Green and Red remain distinct
- Use labels and icons

**Best Practice**: Never rely on color alone - always use icons, text, or patterns alongside color.

---

## Material Design 3 Integration

CountScore uses **Material Design 3** with dynamic color:

### Color Roles
- **Primary**: Deep Purple (#673AB7)
- **On Primary**: White (text/icons on primary)
- **Primary Container**: Light purple tint
- **On Primary Container**: Dark purple
- **Secondary**: Auto-generated from primary
- **Tertiary**: Auto-generated complementary

### Tonal Palette
Material 3 generates tonal variations:
- 0 (black) to 100 (white)
- Primary tones: 10, 20, 30, 40, 50, 60, 70, 80, 90, 95, 99
- Used for elevation, states, surfaces

**For Asset Design**: You can use the primary color (#673AB7) and its tints/shades:
- Lighter: #9575CD, #B39DDB
- Darker: #512DA8, #4527A0

---

## Color Export Formats

### For Design Tools

**Hex Codes** (most common):
```
Primary:   #673AB7
Amber:     #FFC107
Red:       #F44336
Green:     #4CAF50
Blue:      #2196F3
```

**RGB Values**:
```
Primary:   rgb(103, 58, 183)
Amber:     rgb(255, 193, 7)
Red:       rgb(244, 67, 54)
Green:     rgb(76, 175, 80)
Blue:      rgb(33, 150, 243)
```

**CSS Variables**:
```css
--countscore-primary:   #673AB7;
--countscore-amber:     #FFC107;
--countscore-red:       #F44336;
--countscore-green:     #4CAF50;
--countscore-blue:      #2196F3;
```

### Figma Color Styles

If using Figma:
1. Create color styles with these names and values
2. Apply to your design elements
3. Ensures consistency across all assets

---

## Asset Color Examples

### App Icon Ideas

**Concept 1: Solid Purple**
```
Shape: Rounded square or circle
Background: #673AB7 (Deep Purple)
Symbol: White scorecard or "CS" letters
Style: Flat, minimal, professional
```

**Concept 2: Split Colors**
```
Layout: Divided into 4 quadrants
Colors: Purple, Amber, Green, Blue
Symbol: Central white game icon or numbers
Style: Playful, representing game variety
```

**Concept 3: Gradient Modern**
```
Background: Purple to Blue gradient
Symbol: Simple score counter or tally
Overlay: Subtle shine or glass effect
Style: Modern, premium, 2025 trend
```

### Feature Graphic Color Schemes

**Scheme 1: Purple Dominant**
```
Background: Deep Purple (#673AB7)
Headline: White
Tagline: Amber (#FFC107)
Icons/Elements: Green, Blue accents
```

**Scheme 2: Light and Colorful**
```
Background: White or light grey
Headline: Deep Purple (#673AB7)
Elements: Colorful game cards (all colors)
Phone mockup: Showing purple app bar
```

**Scheme 3: Gradient Background**
```
Background: Purple to Pink gradient
Text: White with shadow for depth
Accents: Bright yellow-green (#CDDC39)
Style: Modern, eye-catching, vibrant
```

---

## Tools with Color Palettes

### Import into Design Tools

**Adobe Color**:
- Visit: https://color.adobe.com/
- Create palette with these hex codes
- Export to Photoshop/Illustrator

**Coolors**:
- Visit: https://coolors.co/
- Enter hex codes
- Generate variations and harmonies

**Material Design Color Tool**:
- Visit: https://material.io/resources/color/
- Input #673AB7 as primary
- See full Material palette generated

### Color Picker Values

For design tools that use different formats:

**HSL (Hue, Saturation, Lightness)**:
```
Primary Purple: hsl(262°, 52%, 47%)
Amber:          hsl(45°, 100%, 51%)
Red:            hsl(4°, 90%, 58%)
Green:          hsl(122°, 39%, 49%)
Blue:           hsl(207°, 90%, 54%)
```

**HSV/HSB (Hue, Saturation, Value/Brightness)**:
```
Primary Purple: hsv(262°, 68%, 72%)
Amber:          hsv(45°, 97%, 100%)
Red:            hsv(4°, 78%, 96%)
Green:          hsv(122°, 57%, 69%)
Blue:           hsv(207°, 86%, 95%)
```

---

## Brand Consistency Checklist

When creating assets, ensure:

- [ ] Primary color (Deep Purple) is prominent
- [ ] Colors match the exact hex codes provided
- [ ] Game type colors (Amber, Red, Green) used appropriately
- [ ] Good contrast ratios maintained (WCAG AA minimum)
- [ ] Colors work in both light and dark contexts
- [ ] Not too many colors in one asset (3-4 maximum)
- [ ] Colors align with Material Design 3 principles
- [ ] Consistent color usage across all assets

---

## Quick Reference Card

**Copy this for easy reference while designing:**

```
CountScore Color Palette

Brand Primary:  #673AB7 (Deep Purple) - Use predominantly
Game Colors:
  - Amber:      #FFC107 (ZapZap)
  - Red:        #F44336 (Uno)
  - Green:      #4CAF50 (Scrabble)
  - Blue:       #2196F3 (Players)

Text on Purple: White
Text on White:  Deep Purple or Black
Gradients:      Purple → Blue, Purple → Pink

Style: Material Design 3, Modern, Clean, Professional
```

---

## Resources

- **Material Design Colors**: https://material.io/design/color/
- **Color Contrast Checker**: https://webaim.org/resources/contrastchecker/
- **Adobe Color**: https://color.adobe.com/
- **Coolors Palette Generator**: https://coolors.co/

---

**Your assets will look cohesive and professional when using these colors consistently!** 🎨

Use this guide as a reference while creating your icon, feature graphic, and any other promotional materials.
