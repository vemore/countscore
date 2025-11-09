# Asset Creation Checklist for CountScore

Complete checklist for creating all visual assets needed for Google Play Store publication.

**Last Updated**: November 9, 2025
**Status Tracking**: Use this document to track your progress

---

## Overview

**Required Assets**:
1. App Icon (512×512) - REQUIRED
2. Feature Graphic (1024×500) - REQUIRED
3. Screenshots (2-8 phone screenshots) - REQUIRED

**Timeline Estimate**: 3-6 hours total

---

## Phase 1: Preparation (30 minutes)

### Setup Checklist

- [ ] **Review all documentation**
  - [ ] Read `ASSET_REQUIREMENTS.md`
  - [ ] Read `COLOR_THEME_GUIDE.md`
  - [ ] Read `SCREENSHOT_GUIDE.md`

- [ ] **Gather resources**
  - [ ] Choose design tool (Figma, Canva, GIMP, etc.)
  - [ ] Install tool if needed
  - [ ] Bookmark color hex codes (#673AB7, #FFC107, etc.)

- [ ] **Understand app colors**
  - [ ] Primary: Deep Purple (#673AB7)
  - [ ] Game colors: Amber, Red, Green, Blue
  - [ ] Style: Material Design 3

- [ ] **Review existing app icon**
  - Location: `android/app/src/main/res/mipmap-xxxhdpi/ic_launcher.png`
  - [ ] Viewed current icon
  - [ ] Decided if keeping similar design or redesigning

---

## Phase 2: App Icon Creation (1-2 hours)

### Design Phase

- [ ] **Choose icon concept**
  - [ ] Concept 1: Solid Purple with white symbol
  - [ ] Concept 2: Multi-color (game variety)
  - [ ] Concept 3: Modern gradient
  - [ ] Custom concept: _________________

- [ ] **Create icon design**
  - [ ] Canvas size: 512 × 512 pixels
  - [ ] Format: PNG with alpha channel
  - [ ] Background color chosen
  - [ ] Symbol/graphic added
  - [ ] Colors match brand (#673AB7 primary)

- [ ] **Design validation**
  - [ ] Works on light backgrounds
  - [ ] Works on dark backgrounds
  - [ ] Recognizable at 48×48px
  - [ ] No text too small to read
  - [ ] Professional appearance
  - [ ] Unique and memorable

### Technical Checklist

- [ ] **Export settings**
  - [ ] Dimensions: Exactly 512 × 512 pixels
  - [ ] Format: 32-bit PNG (with alpha)
  - [ ] File size: Under 1 MB
  - [ ] Color space: sRGB
  - [ ] No compression artifacts

- [ ] **File management**
  - [ ] Saved as: `store_listing/assets/icon_512.png`
  - [ ] Backup/source file saved: `store_listing/assets/source_files/icon.fig` (or .psd)

- [ ] **Quality check**
  - [ ] Viewed at 512×512 (full size)
  - [ ] Viewed at 48×48 (app drawer size)
  - [ ] Tested on white background
  - [ ] Tested on dark background
  - [ ] No pixel artifacts or blur

### Icon Approval

- [ ] **Get feedback**
  - [ ] Shown to 2-3 people
  - [ ] Recognizable? Yes / No
  - [ ] Professional? Yes / No
  - [ ] Matches app purpose? Yes / No

- [ ] **Final approval**
  - [ ] Icon meets all technical requirements
  - [ ] Icon looks professional
  - [ ] Ready to upload

**Status**: ⬜ Not Started | 🔄 In Progress | ✅ Complete

---

## Phase 3: Feature Graphic Creation (1-2 hours)

### Design Phase

- [ ] **Choose layout concept**
  - [ ] Option 1: App name + screenshot mockup
  - [ ] Option 2: Feature highlights with icons
  - [ ] Option 3: Typography focus with tagline
  - [ ] Option 4: Phone mockup with gradient background
  - [ ] Custom concept: _________________

- [ ] **Create feature graphic design**
  - [ ] Canvas size: 1024 × 500 pixels
  - [ ] Background designed
  - [ ] App name/logo added
  - [ ] Tagline or features added
  - [ ] Visual elements added (mockup, icons, etc.)
  - [ ] Colors match brand palette

- [ ] **Safe zone compliance**
  - [ ] Critical content within 924 × 400 center area
  - [ ] Text readable and not too close to edges
  - [ ] Important elements won't be cropped

### Content Checklist

- [ ] **Text content** (if applicable)
  - [ ] App name: "CountScore" visible
  - [ ] Tagline chosen: _______________________________
  - [ ] Font is readable (40-100px for headlines)
  - [ ] Text has good contrast with background

- [ ] **Visual elements**
  - [ ] Consistent with app icon
  - [ ] Uses brand colors
  - [ ] Professional and attractive
  - [ ] No misleading images

### Technical Checklist

- [ ] **Export settings**
  - [ ] Dimensions: Exactly 1024 × 500 pixels
  - [ ] Format: JPEG or 24-bit PNG (no alpha)
  - [ ] File size: Under 1 MB recommended
  - [ ] Color space: sRGB
  - [ ] High quality (no compression artifacts)

- [ ] **File management**
  - [ ] Saved as: `store_listing/assets/feature_graphic.png`
  - [ ] Backup/source file saved

- [ ] **Quality check**
  - [ ] Looks good at full size (1024×500)
  - [ ] Text is readable
  - [ ] Colors are vibrant and accurate
  - [ ] No pixelation or blur

### Feature Graphic Approval

- [ ] **Get feedback**
  - [ ] Shown to 2-3 people
  - [ ] Eye-catching? Yes / No
  - [ ] Clear what app does? Yes / No
  - [ ] Professional? Yes / No

- [ ] **Final approval**
  - [ ] Graphic meets all technical requirements
  - [ ] Graphic is attractive and compelling
  - [ ] Ready to upload

**Status**: ⬜ Not Started | 🔄 In Progress | ✅ Complete

---

## Phase 4: Screenshot Capture (1-2 hours)

### Preparation

- [ ] **App ready for screenshots**
  - [ ] Release build installed: `flutter install --release`
  - [ ] Test data populated (3-4 players, games, scores)
  - [ ] Data looks realistic (not "Test User", "123", etc.)
  - [ ] All features working properly

- [ ] **Device/emulator ready**
  - [ ] Device connected or emulator running
  - [ ] ADB working: `adb devices`
  - [ ] Resolution adequate (1080×1920 recommended)
  - [ ] Status bar clean
  - [ ] Screenshot capture tool ready

### Screenshot Capture

**Use the automated script**: `./scripts/capture_screenshots.sh`

Or manually capture each:

**Screenshot 1: Main Score Tracking** (REQUIRED)
- [ ] Screen: Active game with scores
- [ ] Players: 3-4 players visible
- [ ] Scores: Varied, realistic numbers
- [ ] UI: Clean, no errors
- [ ] File: `01_main_screen.png` ✅ / ⬜

**Screenshot 2: Player Management** (REQUIRED)
- [ ] Screen: Player list or add player
- [ ] Content: 4-6 players listed
- [ ] UI: Clear organization
- [ ] File: `02_player_management.png` ✅ / ⬜

**Screenshot 3: Game Types** (Recommended)
- [ ] Screen: Game selection/list
- [ ] Content: ZapZap, Uno, Scrabble visible
- [ ] Colors: Game cards show different colors
- [ ] File: `03_game_types.png` ✅ / ⬜

**Screenshot 4: Game History** (Recommended)
- [ ] Screen: Past games list
- [ ] Content: 2-3 completed games
- [ ] Dates: Realistic dates shown
- [ ] File: `04_game_history.png` ✅ / ⬜

**Screenshot 5: Game Board** (Optional)
- [ ] Screen: Full game board view
- [ ] Content: All players, scores visible
- [ ] File: `05_game_board.png` ✅ / ⬜

**Screenshot 6: Customization** (Optional)
- [ ] Screen: Settings or game editor
- [ ] Content: Color picker or customization
- [ ] File: `06_customization.png` ✅ / ⬜

**Screenshot 7-8: Additional** (Optional)
- [ ] Screen: ___________________________
- [ ] File: `07_*.png` ✅ / ⬜
- [ ] Screen: ___________________________
- [ ] File: `08_*.png` ✅ / ⬜

### Technical Checklist

- [ ] **Quantity**
  - [ ] Minimum 2 screenshots captured
  - [ ] Recommended 4-8 screenshots captured
  - Total captured: ____ screenshots

- [ ] **Quality**
  - [ ] All screenshots are clear (not blurry)
  - [ ] Resolution adequate (1080+ width)
  - [ ] Aspect ratio valid (max 2:1)
  - [ ] File sizes under 8 MB each
  - [ ] No alpha channel (fully opaque)

- [ ] **Content**
  - [ ] All show real app UI
  - [ ] No bugs or errors visible
  - [ ] Data looks realistic
  - [ ] UI is complete (not loading)

- [ ] **Organization**
  - [ ] Files numbered (01, 02, 03, etc.)
  - [ ] Saved in: `store_listing/assets/screenshots/phone/`
  - [ ] First 2-3 screenshots are strongest

### Screenshot Enhancement (Optional)

- [ ] **Text overlays** (if desired)
  - [ ] Short feature descriptions added
  - [ ] Text doesn't cover UI
  - [ ] Font is readable
  - [ ] Professional appearance

- [ ] **Device frames** (if desired)
  - [ ] Frames added using MockUPhone or similar
  - [ ] Consistent frame style across all screenshots
  - [ ] Still under 8 MB file size

### Screenshot Approval

- [ ] **Self-review**
  - [ ] Viewed all screenshots in sequence
  - [ ] Tell a clear story about the app
  - [ ] First 2 are most compelling
  - [ ] All look professional

- [ ] **External feedback**
  - [ ] Shown to 2-3 people
  - [ ] Can they tell what the app does? Yes / No
  - [ ] Do screenshots look professional? Yes / No

- [ ] **Final approval**
  - [ ] All screenshots meet requirements
  - [ ] Ready to upload

**Status**: ⬜ Not Started | 🔄 In Progress | ✅ Complete

---

## Phase 5: Final Review (30 minutes)

### Complete Asset Check

- [ ] **All assets created**
  - [ ] App icon (512×512): `icon_512.png` ✅
  - [ ] Feature graphic (1024×500): `feature_graphic.png` ✅
  - [ ] Screenshots (2-8): ____ files ✅

- [ ] **Technical compliance**
  - [ ] Icon: 512×512, PNG with alpha, <1MB
  - [ ] Feature graphic: 1024×500, JPEG/PNG no alpha, <1MB
  - [ ] Screenshots: 2-8 files, valid dimensions, <8MB each

- [ ] **Visual consistency**
  - [ ] All use brand colors (Deep Purple primary)
  - [ ] Style is consistent across assets
  - [ ] Professional appearance throughout

- [ ] **File organization**
  - [ ] All files in `store_listing/assets/`
  - [ ] Proper naming convention used
  - [ ] Source files backed up

### Quality Assurance

- [ ] **View all assets together**
  - [ ] Icon, feature graphic, and screenshots reviewed side-by-side
  - [ ] Consistent branding and style
  - [ ] All look professional and polished

- [ ] **Test at different sizes**
  - [ ] Icon viewed at 48×48 (still recognizable)
  - [ ] Feature graphic viewed at thumbnail size
  - [ ] Screenshots viewed at thumbnail size

- [ ] **Accessibility check**
  - [ ] Good contrast ratios (text readable)
  - [ ] Not relying on color alone for meaning
  - [ ] Clear and understandable visuals

### Pre-Upload Checklist

- [ ] **Documentation updated**
  - [ ] `PLACE_ASSETS_HERE.md` removed (or marked complete)
  - [ ] This checklist completed
  - [ ] Asset creation date noted: _________________

- [ ] **Backup created**
  - [ ] All assets backed up to secure location
  - [ ] Source files saved for future edits
  - [ ] Backup location: _________________

- [ ] **Ready for upload**
  - [ ] All requirements met
  - [ ] All quality checks passed
  - [ ] Approved by stakeholders (if applicable)

**Final Status**: ⬜ Not Ready | 🔄 In Progress | ✅ Ready to Upload

---

## Phase 6: Upload to Play Console (15 minutes)

### Google Play Console Upload

- [ ] **Navigate to Play Console**
  - URL: https://play.google.com/console
  - [ ] Logged in to developer account
  - [ ] CountScore app selected

- [ ] **Main Store Listing**
  - Path: Store presence > Main store listing

- [ ] **Upload app icon**
  - [ ] Clicked "App icon" section
  - [ ] Uploaded `icon_512.png`
  - [ ] Preview looks correct
  - [ ] Saved

- [ ] **Upload feature graphic**
  - [ ] Clicked "Feature graphic" section
  - [ ] Uploaded `feature_graphic.png`
  - [ ] Preview looks correct
  - [ ] Saved

- [ ] **Upload phone screenshots**
  - [ ] Clicked "Phone screenshots" section
  - [ ] Uploaded all screenshots from `screenshots/phone/`
  - [ ] Reordered (most important first)
  - [ ] Preview looks correct
  - [ ] Saved

- [ ] **Preview store listing**
  - [ ] Clicked "View in Play Store" or preview button
  - [ ] Reviewed how listing appears
  - [ ] All assets display correctly
  - [ ] Text and images look professional

- [ ] **Save all changes**
  - [ ] All sections marked complete
  - [ ] No errors or warnings
  - [ ] Changes saved successfully

**Upload Status**: ⬜ Not Started | ✅ Complete

---

## Troubleshooting

### Common Issues

**Icon upload fails**:
- Check dimensions are exactly 512×512
- Ensure PNG format with alpha channel
- Verify file size under 1 MB
- Try re-exporting with different compression

**Feature graphic upload fails**:
- Check dimensions are exactly 1024×500
- Remove alpha channel (save as 24-bit PNG or JPEG)
- Verify file size under 1 MB
- Ensure no transparency

**Screenshot upload fails**:
- Check file size under 8 MB
- Ensure aspect ratio is valid (max 2:1)
- Remove alpha channel
- Try JPEG format instead of PNG

**Preview looks wrong**:
- Clear browser cache
- Wait a few minutes and refresh
- Try different browser
- Check that files uploaded correctly

---

## Final Checklist Summary

### Must Have (Required for Submission)

- [ ] ✅ App icon (512×512)
- [ ] ✅ Feature graphic (1024×500)
- [ ] ✅ Phone screenshots (minimum 2, recommended 4-8)

### Nice to Have (Optional but Recommended)

- [ ] Tablet screenshots (1-8)
- [ ] Promotional video (YouTube URL)
- [ ] Screenshot enhancements (frames, overlays)

### Quality Standards Met

- [ ] All assets are professional quality
- [ ] Brand colors used consistently
- [ ] Technical requirements met
- [ ] No errors or warnings in Play Console
- [ ] Store listing preview looks excellent

---

## Success Metrics

**Asset Creation Complete When**:
- ✅ All required assets created and uploaded
- ✅ Play Console shows no errors
- ✅ Store listing preview looks professional
- ✅ Ready to submit app for review

---

## Notes Section

**Design Decisions**:
- Icon concept chosen: _______________________________
- Feature graphic layout: _______________________________
- Screenshot count: ____ screenshots
- Enhancement applied: Yes / No

**Time Tracking**:
- Icon creation time: ____ hours
- Feature graphic time: ____ hours
- Screenshot capture: ____ hours
- Total time: ____ hours

**Feedback Received**:
- _________________________________________________
- _________________________________________________
- _________________________________________________

**Future Improvements**:
- _________________________________________________
- _________________________________________________
- _________________________________________________

---

**Congratulations on completing your asset creation!** 🎉

Your CountScore app now has professional visual assets ready for the Google Play Store. Good luck with your launch! 🚀
