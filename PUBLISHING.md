# CountScore - Google Play Store Publishing Guide

Complete step-by-step guide for publishing CountScore to Google Play Store.

**Last Updated**: 2025-11-09
**Target Audience**: Developers preparing for Play Store submission
**Prerequisites**: Flutter development environment, Play Console account

---

## Table of Contents

1. [Pre-Publishing Setup](#1-pre-publishing-setup)
2. [App Signing Configuration](#2-app-signing-configuration)
3. [Build Configuration](#3-build-configuration)
4. [Legal Requirements](#4-legal-requirements)
5. [Store Listing Assets](#5-store-listing-assets)
6. [Play Console Setup](#6-play-console-setup)
7. [Building for Release](#7-building-for-release)
8. [Testing](#8-testing)
9. [Submission](#9-submission)
10. [Post-Launch](#10-post-launch)

---

## 1. Pre-Publishing Setup

### 1.1 Verify Development Environment

```bash
# Check Flutter version (should be 3.9.2 or higher)
flutter --version

# Ensure no issues
flutter doctor

# Clean build
flutter clean
flutter pub get
```

### 1.2 Play Console Account

**Status Required**: Active Google Play Console developer account

**If you don't have one**:
1. Visit https://play.google.com/console/signup
2. Pay one-time $25 registration fee
3. Complete identity verification (required):
   - **Personal**: Government-issued ID
   - **Organization**: D-U-N-S number
4. Enable two-factor authentication (required)
5. **Timeline**: Verification can take 1-14 days

**⚠️ Start this early** - you cannot publish until verification completes.

---

## 2. App Signing Configuration

### 2.1 Generate Upload Keystore

**Run the keystore generation script**:

```bash
# Navigate to project root
cd /home/vemore/workspace/countscore

# Run keystore generation script
./scripts/generate_keystore.sh
```

**What the script does**:
- Creates a new JKS keystore at `~/countscore-upload-keystore.jks`
- Uses 2048-bit RSA encryption
- Valid for ~27 years (10,000 days)
- Alias: `countscore-upload`

**You will be prompted for**:
1. **Keystore password** (remember this!)
2. **Key password** (can be same as keystore password)
3. **Your name** (or organization name)
4. **Organizational unit** (optional, can skip)
5. **Organization** (optional)
6. **City/Locality**
7. **State/Province**
8. **Country code** (e.g., US, FR, CA)

**🔐 CRITICAL**: Store these passwords securely in a password manager!

### 2.2 Create key.properties File

```bash
# Copy the template
cp android/key.properties.template android/key.properties

# Edit with your actual credentials
nano android/key.properties  # or use your preferred editor
```

**Fill in your values**:
```properties
storeFile=/home/vemore/countscore-upload-keystore.jks
storePassword=YOUR_ACTUAL_STORE_PASSWORD
keyAlias=countscore-upload
keyPassword=YOUR_ACTUAL_KEY_PASSWORD
```

**⚠️ Security Checklist**:
- [ ] Keystore file backed up to 3+ secure locations
- [ ] Passwords stored in password manager
- [ ] `key.properties` NOT committed to git (verify with `git status`)
- [ ] Keystore file permissions are restrictive: `chmod 600 ~/countscore-upload-keystore.jks`

### 2.3 Verify Signing Configuration

```bash
# Test that signing works
flutter build appbundle --release --no-tree-shake-icons

# Should succeed and show: ✓ Built build/app/outputs/bundle/release/app-release.aab
```

---

## 3. Build Configuration

### 3.1 Verify Build Settings

**Already configured** ✅:
- Release signing: `android/app/build.gradle.kts`
- ProGuard/R8 optimization: enabled
- Code shrinking: enabled
- Resource shrinking: enabled
- App name: "CountScore"

**Check current configuration**:
```bash
# View build.gradle.kts signing config
cat android/app/build.gradle.kts | grep -A 20 "signingConfigs"

# View ProGuard rules
cat android/app/proguard-rules.pro | head -20
```

### 3.2 Version Management

**Current version**: 1.0.0+1 (from `pubspec.yaml`)

**Update version for releases**:
```yaml
# pubspec.yaml
version: 1.0.0+1  # Format: MAJOR.MINOR.PATCH+BUILD_NUMBER
```

**Version scheme**:
- `1.0.0` = Version name (user-visible)
- `+1` = Version code (incremental, Play Store requirement)

**For future updates**:
- Bug fixes: `1.0.1+2`, `1.0.2+3`
- New features: `1.1.0+4`, `1.2.0+5`
- Major changes: `2.0.0+6`

---

## 4. Legal Requirements

### 4.1 Privacy Policy

**Status**: Required for ALL apps

**What to include**:
1. **Data Collection**: What data the app collects (if any)
2. **Data Usage**: How the data is used
3. **Data Storage**: Where data is stored (local only for CountScore)
4. **Third-Party Services**: List any third-party SDKs
5. **User Rights**: How users can delete data
6. **Contact Information**: Developer email address

**For CountScore** (based on dependencies):
- SQLite: Local database storage only
- SharedPreferences: Local key-value storage
- File Picker: User-initiated file selection
- Wakelock: Screen wake lock (no data)
- **No data sent to servers** (if accurate)
- **No analytics** (if accurate)
- **No ads** (if accurate)

**Privacy Policy Template** (customize as needed):
```
Privacy Policy for CountScore

Last updated: [DATE]

This policy describes how CountScore ("we", "our", or "the app") handles your information.

DATA COLLECTION AND STORAGE
CountScore stores game scores and player information locally on your device using:
- SQLite database for score history
- Local file storage for app preferences
- No data is transmitted to external servers
- No personal information is collected
- No analytics or tracking

DATA DELETION
All app data is stored locally on your device. To delete your data:
1. Uninstall the app, OR
2. Clear app data in Android Settings > Apps > CountScore > Storage > Clear Data

THIRD-PARTY SERVICES
CountScore does not use any third-party analytics, advertising, or tracking services.

CONTACT
For questions about this privacy policy, contact: [YOUR_EMAIL]
```

**Hosting Options**:
1. **GitHub Pages** (free, recommended):
   - Create `docs/privacy-policy.html` in your repo
   - Enable GitHub Pages in repository settings
   - URL: `https://yourusername.github.io/countscore/privacy-policy.html`

2. **Privacy Policy Generators**:
   - https://app-privacy-policy-generator.firebaseapp.com/
   - https://www.termsfeed.com/privacy-policy-generator/

3. **Personal Website**: Host on your own website

**⚠️ The URL must be permanent** - changing it later is difficult.

### 4.2 Data Safety Form

**Where**: Play Console > App Content > Data Safety

**For CountScore** (if no data is collected):
1. Does your app collect or share user data? **No**
2. Is all of the user data collected by your app encrypted in transit? **N/A**
3. Do you provide a way for users to request that their data is deleted? **N/A**

**If any data is collected**, you must:
- Declare each data type
- Specify collection purpose
- Indicate if it's optional or required
- State if it's shared with third parties

---

## 5. Store Listing Assets

### 5.1 App Icon (512×512)

**Requirements**:
- Size: 512×512 pixels exactly
- Format: 32-bit PNG with alpha channel
- Max file size: 1024 KB
- Full square (Google Play handles rounding/masking)
- No text promoting ranking (e.g., "#1 App")

**Design Tips**:
- Simple, recognizable design
- Works at small sizes (48×48)
- Matches app theme colors
- Professional appearance

**Current app icon location**: `android/app/src/main/res/mipmap-*/ic_launcher.png`

**Tools**:
- Figma/Adobe XD/Sketch for design
- Android Asset Studio: https://romannurik.github.io/AndroidAssetStudio/
- Export at 512×512 for Play Store

### 5.2 Feature Graphic (1024×500)

**Requirements**:
- Size: 1024×500 pixels exactly
- Format: JPEG or 24-bit PNG (no alpha)
- No rounded corners (Google Play handles masking)
- Professional, promotional design

**Design Ideas**:
- App name + tagline
- Screenshot mockup
- Key features highlight
- Consistent with app branding

**Tool**: Canva, Figma, or Photoshop

### 5.3 Screenshots

**Requirements**:
- **Minimum**: 2 screenshots
- **Recommended**: 4-8 screenshots
- **Format**: JPEG or 24-bit PNG (no alpha)
- **Dimensions**:
  - Min: 320px on shortest side
  - Max: 3840px on longest side
  - Aspect ratio: Max dimension ≤ 2× min dimension
- **File size**: Max 8 MB each
- **Recommended resolution**: 1080×1920 (portrait) or 1920×1080 (landscape)

**What to capture**:
1. Main score tracking screen
2. Player management interface
3. Game board/active game view
4. Settings or customization features
5. (Optional) Additional key features

**How to capture**:
```bash
# Connect Android device
adb devices

# Run app
flutter run --release

# Take screenshot from Android Studio or device
# Or use: adb exec-out screencap -p > screenshot1.png
```

**Tips**:
- Use realistic data (not lorem ipsum)
- First 3-4 screenshots are most important
- Show actual UI, not mockups
- Highlight key features
- Consider adding subtle text overlays explaining features

### 5.4 Store Listing Copy

#### App Name (max 50 characters)
**Recommended**: `CountScore - Score Tracker`
- Clear, descriptive
- Includes primary function
- Fits character limit

#### Short Description (max 80 characters)
**Example**: `Simple, powerful score tracking for games and activities`

**Tips**:
- Concise value proposition
- Include primary keywords
- User benefit-focused

#### Full Description (max 4000 characters)

**Template**:
```
CountScore - The Simple Way to Track Game Scores

Keep track of scores for all your favorite games and activities with CountScore. Whether it's board games with family, card games with friends, or sports activities, CountScore makes score management easy and organized.

KEY FEATURES

✓ Multiple Game Types
Pre-configured support for popular games (Uno, Scrabble, and more) with custom game creation

✓ Flexible Scoring
Support for both lowest-wins and highest-wins scoring systems

✓ Player Management
Easily add, edit, and manage players across different games

✓ Score History
Full game history with detailed score tracking and statistics

✓ Customization
Custom icons and colors for each game type

✓ Offline First
All data stored locally on your device - no internet required

✓ Clean Interface
Modern Material Design 3 interface for easy navigation

✓ No Ads or Tracking
Completely ad-free with no data collection

PERFECT FOR

• Board game nights with family and friends
• Card game tournaments
• Sports score keeping
• Classroom activities
• Any activity where you need to track scores

PRIVACY

CountScore stores all data locally on your device. No personal information is collected or shared. See our privacy policy for details.

OPEN SOURCE

CountScore is open source software licensed under MIT License.

SUPPORT

Having issues or suggestions? Contact us at [YOUR_EMAIL]

Made with ❤️ using Flutter
```

**Tips for ASO (App Store Optimization)**:
- Include relevant keywords naturally
- Front-load important features
- Use bullet points for readability
- Highlight unique selling points
- Include call-to-action
- Mention "free", "no ads", "offline" if applicable

---

## 6. Play Console Setup

### 6.1 Create App Listing

1. **Sign in** to Play Console: https://play.google.com/console
2. Click **Create app**
3. Fill in:
   - App name: `CountScore`
   - Default language: `English (United States)` (or your preference)
   - App or game: `App`
   - Free or paid: `Free`
4. Accept declarations
5. Click **Create app**

### 6.2 Store Presence

Navigate to **Store presence > Main store listing**:

1. **App name**: CountScore - Score Tracker
2. **Short description**: Your 80-character description
3. **Full description**: Your 4000-character description
4. **App icon**: Upload 512×512 PNG
5. **Feature graphic**: Upload 1024×500 image
6. **Phone screenshots**: Upload 2-8 screenshots
7. **(Optional) Tablet screenshots**: Upload if you have tablet-optimized screenshots
8. **Category**: Choose appropriate category
   - Suggested: `Tools` or `Sports`
9. **Tags** (optional): Add relevant tags
10. **Contact details**:
    - Email: Your support email (publicly visible)
    - Phone: Optional
    - Website: Optional but recommended

### 6.3 App Content

#### Data Safety
Navigate to **App content > Data safety**:

1. Click **Start**
2. Answer questions about data collection
3. For CountScore (if no data collected):
   - Does your app collect or share user data? **No**
   - Submit
4. **If data is collected**: Follow questionnaire carefully

#### Privacy Policy
Navigate to **App content > Privacy policy**:

1. Enter your privacy policy URL
2. **Must be a permanent, publicly accessible URL**
3. Save

#### App Access
Navigate to **App content > App access**:

1. All or some functionality is restricted? **No** (unless you have restricted features)
2. Save

#### Ads
Navigate to **App content > Ads**:

1. Does your app contain ads? **No** (for CountScore)
2. Save

#### Content Ratings
Navigate to **App content > Content rating**:

1. Click **Start questionnaire**
2. Select **IARC questionnaire**
3. Enter your email
4. Answer questions honestly:
   - **Violence**: None (for CountScore)
   - **Sexual content**: None
   - **Language**: None
   - **Controlled substances**: None
   - **User interaction**: None (no chat, social features)
   - **Shares user data**: No
   - **In-app purchases**: No
5. Submit and receive ratings from:
   - ESRB (USA)
   - PEGI (Europe)
   - USK (Germany)
   - ClassInd (Brazil)
   - And others
6. Apply ratings to your app

#### Target Audience
Navigate to **App content > Target audience**:

1. Select age groups: **18+** (safest for general apps)
2. Appeal to children? **No**
3. Save

#### News Apps
Navigate to **App content > News apps**:

1. Is this a news app? **No**
2. Save

### 6.4 Countries and Regions

Navigate to **Production > Countries/regions**:

1. **Add countries**: Select where you want to distribute
   - **Start with**: Your own country for testing
   - **Later**: Expand to more countries after validation
2. Click **Add countries/regions**

### 6.5 Pricing

Navigate to **Production > Pricing**:

1. **Free or paid**: Free
2. **In-app products**: No (unless you add IAP)
3. Save

### 6.6 App Signing

Navigate to **Setup > App integrity > App signing**:

**Google Play App Signing** (recommended):
- **Enabled by default** for new apps
- Google manages your app signing key
- You upload with upload key (created earlier)
- Benefits:
  - Can recover if you lose upload key
  - Smaller download sizes with optimized APK splits
  - Support for Google Play's advanced delivery features

**Steps**:
1. Review app signing settings
2. Ensure "App signing by Google Play" is enabled
3. Note: Your upload certificate SHA-1 (for services integration if needed)

---

## 7. Building for Release

### 7.1 Pre-Build Checklist

```bash
# 1. Ensure code is clean
flutter analyze
# Should show: No issues found!

# 2. Run tests
flutter test
# All tests should pass

# 3. Check version
grep "version:" pubspec.yaml
# Should show: version: 1.0.0+1

# 4. Verify signing configuration
cat android/key.properties
# Should show your keystore details (not template values)

# 5. Clean previous builds
flutter clean
flutter pub get
```

### 7.2 Build App Bundle

**Build the release AAB** (App Bundle):

```bash
flutter build appbundle --release --no-tree-shake-icons
```

**Expected output**:
```
Running Gradle task 'bundleRelease'...
✓ Built build/app/outputs/bundle/release/app-release.aab (XX.XMB)
```

**File location**: `build/app/outputs/bundle/release/app-release.aab`

**Why App Bundle (AAB) not APK?**
- Required by Google Play (since August 2021)
- Smaller download sizes for users
- Automatic optimization for different devices
- Supports advanced Play Store features

### 7.3 Verify Build

```bash
# Check file exists and size
ls -lh build/app/outputs/bundle/release/app-release.aab

# Typical size: 30-60 MB (depends on dependencies)
```

---

## 8. Testing

### 8.1 Internal Testing Track

**Recommended**: Test with internal testers before production release.

**Setup Internal Testing**:
1. Navigate to **Production > Internal testing**
2. Click **Create new release**
3. Upload `app-release.aab`
4. Add release notes:
   ```
   Initial release (v1.0.0)
   - Score tracking for multiple game types
   - Player management
   - Local database storage
   - Material Design 3 interface
   ```
5. Click **Next**
6. Add internal testers:
   - Email addresses of testers (up to 100)
   - Create an email list
7. Click **Save** and **Send for review**
8. Share testing link with testers

**Testing Period**: 1-7 days recommended

### 8.2 Testing Checklist

Testers should verify:
- [ ] App installs successfully
- [ ] All features work as expected
- [ ] No crashes or errors
- [ ] Database operations work correctly
- [ ] UI is responsive and looks good
- [ ] Performance is acceptable
- [ ] Permissions are requested properly
- [ ] App can be uninstalled cleanly

### 8.3 Fix Issues

If issues are found:
1. Fix bugs in code
2. Increment version: `1.0.0+2` → `1.0.1+2` or `1.0.0+3`
3. Rebuild: `flutter build appbundle --release --no-tree-shake-icons`
4. Upload new AAB to internal testing
5. Retest

---

## 9. Submission

### 9.1 Production Release

Once testing is complete:

1. Navigate to **Production > Production**
2. Click **Create new release**
3. **Upload AAB**: Upload `app-release.aab`
4. **Release notes** (what's new):
   ```
   CountScore 1.0.0 - Initial Release

   Welcome to CountScore! Track scores for all your games and activities.

   Features:
   • Multiple game type support (Uno, Scrabble, custom games)
   • Player management across games
   • Score history and tracking
   • Customizable game colors and icons
   • Offline-first design
   • No ads, no tracking

   We hope you enjoy using CountScore!
   ```
5. **Release name** (optional): `1.0.0 - Initial Release`
6. Click **Next**

### 9.2 Review and Rollout

1. **Review release**: Check all details
2. **Rollout percentage**:
   - **First release**: Start with 10-20% staged rollout
   - Monitor for crashes/issues
   - Increase to 50%, then 100% if stable
3. **Alternative**: 100% rollout if you're confident after testing
4. Click **Save**
5. Click **Start rollout to Production**

### 9.3 Google Play Review

**Timeline**: Typically 2-5 business days (can be faster or slower)

**What Google reviews**:
- App content policy compliance
- Privacy policy completeness
- Data safety accuracy
- Content rating accuracy
- Functionality (basic testing)
- App quality guidelines

**Status Tracking**:
- Monitor: **Dashboard > Release overview**
- Email notifications enabled by default

**Possible outcomes**:
1. ✅ **Approved**: App goes live automatically
2. ❌ **Rejected**: Review rejection reasons, fix issues, resubmit
3. ⚠️ **Needs information**: Respond to Google's questions

---

## 10. Post-Launch

### 10.1 Monitor Release

**First 48 hours**:
- Check Play Console **Dashboard**
- Monitor **Crashes & ANRs**
- Review **Ratings and reviews**
- Check **Installation metrics**

**Key metrics**:
- Install success rate (should be >98%)
- Crash rate (should be <1%)
- ANR rate (should be <0.5%)
- Uninstall rate

### 10.2 Respond to Reviews

**Best practices**:
- Respond within 24-48 hours
- Be professional and helpful
- Thank users for positive reviews
- Address concerns in negative reviews
- Offer support email for issues
- Don't argue or be defensive

### 10.3 Plan Updates

**Version strategy**:
- Bug fixes: Release quickly (within days)
- Minor features: Monthly releases
- Major features: Quarterly releases

**Update process**:
1. Update version in `pubspec.yaml`
2. Build new AAB
3. Create new release in Production
4. Add detailed release notes
5. Submit for review

---

## Common Issues and Solutions

### Issue: Build fails with "key.properties not found"
**Solution**:
- Ensure `android/key.properties` exists
- Check file path in `storeFile` property
- Verify file is not in `.gitignore` (it should be, but check you created it)

### Issue: "Keystore was tampered with, or password was incorrect"
**Solution**:
- Verify password in `key.properties` is correct
- Check for extra spaces or quotes
- Ensure keystore file path is correct

### Issue: App bundle too large
**Solution**:
- Verify ProGuard/R8 is enabled
- Remove unused assets
- Optimize images
- Check for large libraries

### Issue: App rejected for privacy policy
**Solution**:
- Ensure privacy policy URL is accessible
- Privacy policy must cover all data collection
- URL must match exactly what's entered in Play Console

### Issue: Content rating incomplete
**Solution**:
- Complete IARC questionnaire fully
- Answer all questions honestly
- Resubmit questionnaire if needed

---

## Security Reminders

🔐 **CRITICAL - Never commit these files**:
- `android/key.properties`
- `*.jks` or `*.keystore` files
- Passwords or API keys

🔐 **Backup your keystore**:
- Multiple secure locations
- Password manager for credentials
- Losing keystore = cannot update app

🔐 **Protect your Play Console account**:
- Enable 2FA (required)
- Use strong password
- Don't share credentials
- Monitor account activity

---

## Next Steps After Publishing

1. **App Store Optimization (ASO)**:
   - Monitor keyword rankings
   - A/B test screenshots
   - Iterate on description

2. **User Acquisition**:
   - Share on social media
   - Create a website/landing page
   - Engage with user communities

3. **Analytics** (optional):
   - Consider Firebase Analytics
   - Track user behavior
   - Identify improvement opportunities

4. **Support**:
   - Set up support email
   - Create FAQ documentation
   - Respond to user inquiries

5. **Iterate**:
   - Collect feedback
   - Plan new features
   - Release regular updates

---

## Useful Resources

- **Flutter Deployment**: https://docs.flutter.dev/deployment/android
- **Play Console Help**: https://support.google.com/googleplay/android-developer
- **Content Policies**: https://play.google.com/about/developer-content-policy/
- **App Quality Guidelines**: https://developer.android.com/quality
- **Play Academy** (free courses): https://playacademy.exceedlms.com/

---

**Good luck with your launch!** 🚀

If you encounter issues not covered here, consult the official documentation or reach out to Google Play support.
