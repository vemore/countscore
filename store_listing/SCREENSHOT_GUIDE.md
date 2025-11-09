# Screenshot Capture Guide for CountScore

Step-by-step guide for capturing high-quality screenshots for the Google Play Store listing.

**Last Updated**: November 9, 2025
**Target**: 4-8 phone screenshots (1080×1920 portrait)

---

## Table of Contents

1. [Preparation](#preparation)
2. [Screenshot Strategy](#screenshot-strategy)
3. [Capture Methods](#capture-methods)
4. [Screenshot Checklist](#screenshot-checklist)
5. [Enhancement (Optional)](#enhancement-optional)
6. [Upload Instructions](#upload-instructions)

---

## Preparation

### Step 1: Prepare Test Data

Before capturing screenshots, populate your app with realistic data:

**✅ Create Realistic Content**:
- Add 4-6 player names (e.g., "Alice", "Bob", "Charlie", "Diana")
- Create 3-4 game types (use the pre-configured ones: ZapZap, Uno, Scrabble)
- Play a few test games with realistic scores
- Ensure game history has 2-3 completed games

**❌ Avoid**:
- Empty screens
- Lorem ipsum or placeholder text
- Test123, User1, etc.
- Obviously fake data
- Error states or bugs

### Step 2: Set Up Device

**Recommended Setup**:
- **Device**: Physical Android device or emulator
- **Resolution**: 1080×1920 (Full HD, 9:16 ratio)
- **Orientation**: Portrait mode
- **System UI**: Hide status bar if possible (or use clean notification bar)
- **Time**: Set to 10:00 or 2:30 (common mockup times)
- **Battery**: Show full or charging

**Clean the Interface**:
```bash
# If using emulator, hide navigation bar
adb shell settings put global policy_control immersive.full=*
```

### Step 3: Build and Install App

```bash
# Build release version for best visuals
flutter build apk --release --no-tree-shake-icons

# Install on device
flutter install --release

# Or use adb
adb install build/app/outputs/flutter-apk/app-release.apk
```

---

## Screenshot Strategy

### Required Screenshots (4-8 recommended)

**Screenshot 1: Main Score Tracking Screen** (MOST IMPORTANT)
- **Scene**: Active game in progress with scores visible
- **Purpose**: Show core functionality immediately
- **Players**: 3-4 players with varied scores
- **Focus**: Clean score entry interface
- **Why First**: Users need to see what the app does instantly

**Screenshot 2: Player Management**
- **Scene**: Player list or add player screen
- **Purpose**: Show how easy it is to manage players
- **Content**: List of players, maybe "Add Player" dialog
- **Focus**: Intuitive player organization

**Screenshot 3: Game Type Selection/List**
- **Scene**: Game types screen showing custom and preset games
- **Purpose**: Highlight variety and customization
- **Content**: ZapZap, Uno, Scrabble, and 1-2 custom games
- **Focus**: Colorful game cards with icons

**Screenshot 4: Game History**
- **Scene**: Past games list with dates and scores
- **Purpose**: Show score tracking over time
- **Content**: 3-4 completed games with results
- **Focus**: Clear history organization

**Screenshot 5: Game Board/Active Game** (Optional but good)
- **Scene**: Full game board view during play
- **Purpose**: Show immersive gameplay tracking
- **Content**: All players, current round, scores
- **Focus**: Clean, organized layout

**Screenshot 6: Settings/Customization** (Optional)
- **Scene**: Game type editor or settings
- **Purpose**: Show customization capabilities
- **Content**: Color picker, icon selection
- **Focus**: User control and flexibility

---

## Capture Methods

### Method 1: Physical Device (Recommended)

**Using Device Buttons**:
1. Launch CountScore
2. Navigate to desired screen
3. Press **Power + Volume Down** simultaneously
4. Screenshot saved to `Pictures/Screenshots/` or `DCIM/Screenshots/`
5. Transfer to computer via USB

**Transfer Screenshots**:
```bash
# Connect device via USB
adb devices

# Pull all screenshots
adb pull /sdcard/Pictures/Screenshots/ ./store_listing/assets/screenshots/phone/

# Or pull specific file
adb pull /sdcard/DCIM/Screenshots/Screenshot_20251109_100000.png ./01_main_screen.png
```

### Method 2: ADB Command (Precise)

```bash
# Ensure device is connected
adb devices

# Navigate to screen in app, then capture:
adb exec-out screencap -p > store_listing/assets/screenshots/phone/01_main.png

# Repeat for each screenshot
adb exec-out screencap -p > store_listing/assets/screenshots/phone/02_players.png
adb exec-out screencap -p > store_listing/assets/screenshots/phone/03_games.png
```

### Method 3: Android Studio

1. Launch app through Android Studio
2. Open **Logcat** panel (bottom of screen)
3. Click **Camera icon** in Logcat toolbar
4. Click **Save** to save screenshot
5. Choose location: `store_listing/assets/screenshots/phone/`

### Method 4: Emulator (If No Physical Device)

```bash
# Create and start emulator
flutter emulators --launch Pixel_5_API_33

# Run app
flutter run

# In emulator window: Click camera icon on right toolbar
# Or press Cmd+S (Mac) / Ctrl+S (Windows)
# Screenshots saved to: ~/Pictures/ or Desktop
```

**Recommended Emulator Settings**:
- **Device**: Pixel 5, Pixel 6, or any 1080×1920 device
- **API Level**: 30+ (Android 11+)
- **Graphics**: Hardware acceleration
- **Clear notification bar** before capturing

---

## Screenshot Checklist

### Pre-Capture Checklist

For each screenshot, verify:

- [ ] **Data is realistic** (not Test123, User1, etc.)
- [ ] **No bugs visible** (crashes, errors, blank screens)
- [ ] **No developer tools** (debug info, toast messages)
- [ ] **UI is complete** (no loading indicators unless intentional)
- [ ] **Orientation is portrait**
- [ ] **Resolution is adequate** (minimum 1080px width)
- [ ] **Status bar is clean** (or hidden)
- [ ] **App is in focus** (no other apps visible)

### Post-Capture Checklist

After capturing all screenshots:

- [ ] **Minimum 2 screenshots captured** (4-8 recommended)
- [ ] **Screenshots are numbered** (01, 02, 03, etc.)
- [ ] **Files are PNG or JPEG**
- [ ] **Resolution meets requirements** (1080×1920 recommended)
- [ ] **File sizes under 8 MB each**
- [ ] **No alpha channel** (fully opaque)
- [ ] **First 2-3 are strongest** (most important features)
- [ ] **Screenshots tell a story** (progression makes sense)

### Screenshot Naming Convention

**Format**: `##_description.png`

```
01_main_screen.png          # Active game with scores
02_player_management.png    # Player list or add player
03_game_types.png           # Game type selection
04_game_history.png         # Past games list
05_game_board.png           # Full game board view
06_customization.png        # Settings or customization
07_score_entry.png          # Score input interface
08_statistics.png           # Player stats (if available)
```

---

## Specific Screenshot Instructions

### Screenshot 1: Main Score Tracking

**Setup**:
1. Start a new game with 3-4 players
2. Enter scores for 2-3 rounds
3. Make scores varied (not all the same)
4. Navigate to main score screen

**What to Show**:
- Player names clearly visible
- Current scores displayed
- Round information (if applicable)
- Score entry interface
- App name/title visible

**Timing**: Capture during game, not empty state

---

### Screenshot 2: Player Management

**Setup**:
1. Navigate to player management screen
2. Ensure 4-6 players are listed
3. Optional: Open "Add Player" dialog

**What to Show**:
- List of players
- Add/Edit controls
- Clean organization
- Easy navigation

---

### Screenshot 3: Game Types

**Setup**:
1. Navigate to game selection screen
2. Show preset games (ZapZap, Uno, Scrabble)
3. Include 1-2 custom games if created

**What to Show**:
- Multiple game options
- Colorful cards/tiles
- Icons for each game
- Custom game capability

---

### Screenshot 4: Game History

**Setup**:
1. Play 2-3 complete games first
2. Navigate to history/past games
3. Show completed games with dates

**What to Show**:
- Multiple past games
- Dates and participants
- Final scores
- Clear organization

---

## Enhancement (Optional)

### Adding Text Overlays

If you want to add feature callouts to screenshots:

**Tools**:
- **Figma** (free): Import screenshot, add text
- **Canva** (free): Use template, add text overlay
- **Photoshop/GIMP**: Text tool

**Guidelines**:
- **Placement**: Top or bottom, not covering UI
- **Text Size**: 40-60px, readable at thumbnail size
- **Font**: Bold, sans-serif (Roboto, Open Sans)
- **Color**: Contrasting with background
- **Content**: Short feature highlight (3-5 words)

**Example Text Overlays**:
```
Screenshot 1: "Track Scores in Real Time"
Screenshot 2: "Manage Multiple Players"
Screenshot 3: "Support for Any Game"
Screenshot 4: "Complete Game History"
```

**Keep it minimal** - UI should be the focus, not decorations.

### Adding Device Frames

**Tools**:
- **MockUPhone**: https://mockuphone.com/
- **Device Art Generator**: https://developer.android.com/distribute/marketing-tools/device-art-generator

**Process**:
1. Upload screenshot
2. Select device frame (Pixel, Samsung, etc.)
3. Download framed image
4. Use framed version for Play Store

**Pros**: More attractive, professional look
**Cons**: Larger file sizes, less UI visible

**Recommendation**: Try both and see which looks better.

---

## Upload Instructions

### File Organization

```
store_listing/assets/screenshots/phone/
├── 01_main_screen.png
├── 02_player_management.png
├── 03_game_types.png
├── 04_game_history.png
├── 05_game_board.png (optional)
├── 06_customization.png (optional)
├── 07_score_entry.png (optional)
└── 08_statistics.png (optional)
```

### Verification Before Upload

Run these checks:

```bash
# Check file count
ls store_listing/assets/screenshots/phone/*.png | wc -l
# Should show: 4-8

# Check file sizes
ls -lh store_listing/assets/screenshots/phone/
# All should be under 8 MB

# Check dimensions
file store_listing/assets/screenshots/phone/*.png
# Should show reasonable dimensions (1080+ width)
```

### Play Console Upload

1. Go to **Play Console > Store presence > Main store listing**
2. Scroll to **Phone screenshots**
3. Click **Add screenshots**
4. Select all screenshots from `store_listing/assets/screenshots/phone/`
5. Drag to reorder (first 2-3 are most important!)
6. Click **Save**

**Order Matters**! Ensure:
- Position 1: Most important feature (main game screen)
- Position 2: Key differentiator (player management)
- Position 3: Feature highlight (game variety)

---

## Quality Checklist

### Before Finalizing

Review each screenshot:

**Technical Quality**:
- [ ] Resolution is 1080×1920 or better
- [ ] Image is sharp and clear (not blurry)
- [ ] Colors are accurate (not washed out)
- [ ] No compression artifacts
- [ ] File format is PNG or JPEG
- [ ] File size under 8 MB

**Content Quality**:
- [ ] UI is complete and functional
- [ ] Data looks realistic
- [ ] No bugs or errors visible
- [ ] App name is visible where appropriate
- [ ] Screenshot shows clear value

**Strategic Quality**:
- [ ] First screenshot shows main feature immediately
- [ ] Each screenshot shows different aspect
- [ ] Screenshots tell a coherent story
- [ ] Key features are highlighted
- [ ] No redundant screenshots

### Getting Feedback

Before finalizing, get opinions:

**Ask Friends/Family**:
- "Does this look professional?"
- "Can you tell what the app does from these images?"
- "Which screenshot is most compelling?"

**Self-Review**:
- View screenshots at thumbnail size (like in Play Store search results)
- Are they clear and recognizable?
- Do they make you want to learn more?

---

## Common Issues and Solutions

### Issue: Screenshots are blurry
**Solution**:
- Capture at native device resolution (1080×1920 minimum)
- Don't upscale low-res images
- Use physical device instead of emulator if possible

### Issue: UI looks cluttered
**Solution**:
- Simplify test data (fewer items on screen)
- Use focused screens that highlight one feature
- Ensure adequate white space

### Issue: Colors look washed out
**Solution**:
- Check device brightness (set to 100%)
- Ensure app theme is displaying correctly
- Use sRGB color space
- Avoid over-processing screenshots

### Issue: Screenshots look amateurish
**Solution**:
- Use realistic data (not "Test User")
- Clean up UI (no debug info visible)
- Ensure consistency across screenshots
- Consider adding subtle device frames

---

## Advanced Tips

### Professional Touches

1. **Consistent Theming**: Use same data/players across screenshots for continuity
2. **Feature Progression**: Show logical user journey (setup → play → history)
3. **Visual Variety**: Mix different screen types (list views, detail views, input forms)
4. **Color Balance**: Ensure screenshots have good color variety but remain cohesive

### What Top Apps Do

Study successful apps in Tools category:
- First screenshot always shows main value proposition
- Use of subtle text overlays (not excessive)
- Device frames used sparingly
- Clean, professional UI
- Realistic data throughout

### Time-Saving Tricks

1. **Batch Capture**: Navigate through all screens, capturing as you go
2. **Test Data Reuse**: Keep one test game with good data for future screenshots
3. **Template Setup**: Create one "perfect" screenshot setup, reuse for updates
4. **Script Automation**: Use the provided capture script for consistency

---

## Capture Script Usage

A helper script has been created to automate screenshot capture:

```bash
# Make script executable
chmod +x scripts/capture_screenshots.sh

# Run the script
./scripts/capture_screenshots.sh

# Follow prompts to capture each screenshot
# Screenshots will be numbered and saved automatically
```

The script will:
- Connect to your device via ADB
- Prompt you to navigate to each screen
- Capture and save screenshots with proper naming
- Verify file sizes and formats

---

## Timeline

**Realistic Time Estimates**:

**Setup & Preparation**: 30-60 minutes
- Populate app with realistic data
- Set up device/emulator
- Familiarize with screens

**Screenshot Capture**: 30-45 minutes
- Navigate and capture each screenshot
- Review and retake if needed
- Organize files

**Optional Enhancement**: 1-2 hours (if adding overlays/frames)
- Edit screenshots in design tool
- Add text or device frames
- Export optimized versions

**Total Time**: 1-3 hours depending on complexity

---

## Final Review

Before uploading to Play Console:

1. **View all screenshots in sequence**
   - Do they tell a clear story?
   - Is the app's value obvious?

2. **Check thumbnail visibility**
   - Shrink screenshots to 200px wide
   - Are they still clear and recognizable?

3. **Compare to competitors**
   - Look at similar apps on Play Store
   - Is your quality comparable or better?

4. **Get external feedback**
   - Show to 2-3 people who haven't seen the app
   - Can they understand what it does?

---

## Resources

- **ADB Documentation**: https://developer.android.com/tools/adb
- **Play Console Help**: https://support.google.com/googleplay/android-developer/answer/9866151
- **Material Design**: https://material.io/ (for understanding good UI design)

---

**Ready to capture screenshots?**

Follow this guide step-by-step, and you'll have professional-quality screenshots ready for the Play Store! 📸

Good luck! 🎉
