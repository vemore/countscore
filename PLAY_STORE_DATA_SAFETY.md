# Google Play Store - Data Safety Form Guide

Complete guide for filling out the Data Safety section in Google Play Console for CountScore.

**Last Updated**: November 9, 2025
**App**: CountScore v1.0.0
**Privacy Policy**: See `privacy_policy.md`

---

## Quick Summary

**CountScore collects NO user data.**

All data is stored locally on the user's device. No data is transmitted to external servers, and no third-party services are used.

---

## Table of Contents

1. [Data Safety Form Overview](#data-safety-form-overview)
2. [Question-by-Question Guide](#question-by-question-guide)
3. [App Permissions Justification](#app-permissions-justification)
4. [Testing Your Answers](#testing-your-answers)

---

## Data Safety Form Overview

**Where to Find**: Google Play Console > App content > Data safety

**What Google Requires**:
- Declaration of all data collection practices
- Transparency about how data is used
- Information about data sharing
- Security practices

**CountScore's Status**: ✅ **No data collection**

---

## Question-by-Question Guide

### Section 1: Data Collection and Security

#### Q1: Does your app collect or share any of the required user data types?

**Answer**: ❌ **No**

**Explanation**: CountScore stores all data locally on the user's device. No data is collected, transmitted, or shared with any external parties.

**What this means**:
- All game scores, player names, and settings remain on the device
- No analytics or tracking
- No third-party services
- No server communication

---

### Section 2: Data Types (Skip if answered "No" above)

**Since you answered "No" to Q1, you can skip all data type questions.**

The form will show: ✅ "This app doesn't collect any of the required user data types"

---

### Section 3: Security Practices

These questions appear regardless of data collection:

#### Q2: Is all of the user data collected by your app encrypted in transit?

**Answer**: **Not Applicable (N/A)**

**Explanation**: Since CountScore does not transmit any data, encryption in transit is not applicable.

**Alternative wording if required**: "No data transmission occurs"

---

#### Q3: Do you provide a way for users to request that their data is deleted?

**Answer**: **Yes**

**Explanation**: Users can delete their data through:

1. **In-app deletion**: Delete individual games, scores, or players through the app interface
2. **Clear app data**: Android Settings > Apps > CountScore > Storage > Clear Data
3. **Uninstall**: Uninstalling the app removes all data

**Note**: Even though data is local only, Google requires this answer for user control.

---

### Section 4: Privacy Policy

#### Q4: Privacy policy URL

**Answer**: `[YOUR_PRIVACY_POLICY_URL]`

**Hosting Options**:

1. **GitHub Pages** (Recommended - Free):
   - URL format: `https://yourusername.github.io/countscore/privacy-policy.html`
   - Setup: Create `docs/privacy-policy.html` from `privacy_policy.md`, enable GitHub Pages

2. **GitHub Raw** (Simple but not recommended for production):
   - URL format: `https://raw.githubusercontent.com/yourusername/countscore/main/privacy_policy.md`
   - Note: Not ideal for user-facing content

3. **Personal Website**:
   - Host `privacy_policy.md` on your own website
   - Must be permanent and publicly accessible

**Converting privacy_policy.md to HTML**:
```bash
# Using pandoc (if installed)
pandoc privacy_policy.md -o privacy-policy.html --standalone

# Or use online Markdown to HTML converters
```

**CRITICAL**: Privacy policy URL must be:
- ✅ Publicly accessible (no login required)
- ✅ Permanent (won't change or be removed)
- ✅ HTTPS (secure connection)

---

## App Permissions Justification

### Permissions CountScore Uses

CountScore requests the following Android permissions. Here's how to justify them:

#### 1. WAKE_LOCK

**Declared in**: Automatically by `wakelock_plus` plugin

**Purpose**: Keeps device screen awake during active games

**Justification**:
"The WAKE_LOCK permission is used to prevent the screen from turning off while users are actively tracking game scores. This ensures uninterrupted gameplay without requiring users to constantly unlock their device. The wake lock is only active during games and is released when the game ends or the app is closed."

**Data Collection**: None - this permission does not access or collect any user data

---

#### 2. INTERNET (if declared)

**Status**: Check `android/app/src/main/AndroidManifest.xml`

**If present**: Usually added automatically by Flutter

**Justification** (if needed):
"The INTERNET permission may be declared by the Flutter framework but is not actively used by CountScore. No network communication occurs, and all data remains local to the device."

**Data Collection**: None - no network requests are made

---

#### 3. READ_EXTERNAL_STORAGE / WRITE_EXTERNAL_STORAGE (if implemented)

**Status**: Currently not used (as of v1.0.0)

**If you add import/export features**:

**Purpose**: Allow users to export/import game data

**Justification**:
"Storage permissions are used only when users explicitly choose to export their game data to a file or import previously exported data. No automatic access to device storage occurs. These features are entirely user-initiated and optional."

**Data Collection**: None - files remain on user's device

---

### Checking Your Permissions

Run this command to see all permissions your app requests:

```bash
# View AndroidManifest.xml permissions
grep -A 1 "uses-permission" android/app/src/main/AndroidManifest.xml

# Or check the merged manifest after build
./gradlew :app:processDebugManifest
cat android/app/build/intermediates/merged_manifests/debug/AndroidManifest.xml | grep uses-permission
```

---

## Data Safety Form Completion Checklist

Before submitting, verify:

- [ ] **Q1**: Answered "No" for data collection
- [ ] **Q3**: Answered "Yes" for data deletion option
- [ ] **Privacy Policy**: URL entered and publicly accessible
- [ ] **Privacy Policy**: URL uses HTTPS
- [ ] **Privacy Policy**: Content matches your actual practices
- [ ] **Permissions**: All permissions justified (if asked)
- [ ] **Review**: All sections marked as complete
- [ ] **Saved**: Changes saved in Play Console

---

## Testing Your Answers

### Before Submission

1. **Privacy Policy Accessibility**:
   ```bash
   # Test your privacy policy URL
   curl -I [YOUR_PRIVACY_POLICY_URL]
   # Should return: HTTP/2 200
   ```

2. **Policy Content Accuracy**:
   - [ ] Policy reflects current app version
   - [ ] All permissions mentioned
   - [ ] Contact email is correct
   - [ ] No false claims about data practices

3. **Form Completeness**:
   - [ ] All required sections completed
   - [ ] No warnings or errors in Play Console
   - [ ] Data Safety preview looks correct

---

## Common Questions & Answers

### Q: "Do I need to declare SQLite database usage?"

**A**: No. SQLite is local storage on the device. Google's Data Safety form is concerned with data that's *collected* (transmitted to external parties), not local storage.

### Q: "What about SharedPreferences?"

**A**: Same as SQLite - it's local storage, not data collection.

### Q: "Should I mention player names users enter?"

**A**: No. User-entered data that stays on the device is not "collected data" in Google's definition.

### Q: "What if I add analytics later?"

**A**: You must update the Data Safety form and privacy policy before the update is published.

### Q: "Can I skip the data deletion question?"

**A**: No. Google requires you to provide a data deletion method even for local-only apps.

### Q: "What if Google asks for more details?"

**A**: Respond through Play Console messages with:
- Reference to your privacy policy
- Explanation that all data is local only
- Screenshots showing no network activity (if requested)

---

## What If Google Rejects Your Form?

**Common Rejection Reasons**:

1. **Privacy policy not accessible**
   - Fix: Ensure URL works in incognito/private browsing
   - Verify HTTPS connection

2. **Privacy policy doesn't match declaration**
   - Fix: Ensure policy mentions all permissions
   - Update policy to match app functionality

3. **Unclear data handling**
   - Fix: Provide additional clarification through Play Console messages
   - Offer to provide app walkthrough or screenshots

**Response Template**:
```
Hello Google Play Review Team,

Thank you for reviewing CountScore. I'd like to clarify our data handling:

1. CountScore stores all data locally on the user's device using SQLite database and SharedPreferences
2. No data is transmitted to external servers
3. No third-party analytics or advertising services are integrated
4. The app's source code is open source and can be audited at: [GITHUB_URL]

Our privacy policy at [PRIVACY_POLICY_URL] provides detailed information about our data practices.

Please let me know if you need any additional information or clarification.

Best regards,
[YOUR_NAME]
```

---

## Data Safety Summary for Copy-Paste

Use this summary when communicating with Google or users:

```
CountScore is a local-only score tracking application that:
- Stores all data locally on the user's device
- Does not collect, transmit, or share any user data
- Does not use analytics, advertising, or third-party services
- Allows users to delete their data at any time
- Is open-source software (MIT License)

All game scores, player information, and app preferences are stored using Android's local storage (SQLite and SharedPreferences) and never leave the device.
```

---

## Review Timeline

**Typical Timeline**:
- Initial submission: Usually approved within minutes to hours
- If questions arise: 1-3 business days for Google to respond
- Resubmission after changes: 24-48 hours

**Pro Tip**: Complete the Data Safety form accurately the first time to avoid delays.

---

## Updates and Maintenance

**When to Update Data Safety Form**:
- ✅ Before adding analytics
- ✅ Before adding advertising
- ✅ Before adding cloud sync features
- ✅ Before adding social features
- ✅ When adding new permissions
- ✅ When changing data handling practices

**Update Process**:
1. Update privacy policy first
2. Update Data Safety form in Play Console
3. Submit app update with changes
4. Both must be consistent

---

## Additional Resources

- **Play Console Help**: https://support.google.com/googleplay/android-developer/answer/10787469
- **Data Safety Guide**: https://developer.android.com/google/play/data-safety
- **Privacy Policy Guide**: https://play.google.com/about/privacy-security-deception/user-data/

---

## Quick Reference Card

Print or save this for easy reference:

```
DATA SAFETY QUICK REFERENCE - CountScore

Q: Collect or share data?          A: NO
Q: Data encrypted in transit?      A: N/A (no transmission)
Q: Data deletion available?        A: YES
Privacy Policy URL:                 [YOUR_URL]

Permissions Used:
- WAKE_LOCK: Keep screen awake during games (no data collection)

Summary: All data local only, no collection, no sharing.
```

---

**You're ready to complete the Data Safety form!** 🎉

Follow this guide step-by-step in Google Play Console, and you should have no issues with approval.
