# Google Play Store — Data Safety Form Guide

Complete guide for filling out the Data Safety section in Google Play Console for CountScore.

**Last Updated**: September 9, 2026
**Applies to**: CountScore v1.1.0 and later
**Privacy Policy**: See `privacy_policy.md`

> **This guide changed materially in September 2026.** Versions 1.0.x contained no networking
> code, and the declaration for them was correctly "no data collected". **Version 1.1.0 adds
> the ZapZap analysis**, which transmits game data off the device. The form must be updated
> **before** 1.1.0 is submitted — a declaration that does not match app behaviour is a Play
> policy violation and a common cause of suspension.

---

## Quick Summary

**CountScore collects and shares a small amount of data, only when the user asks for an
analysis.**

Everything the app does normally — creating games, entering scores, viewing statistics — is
local to the device. One optional, user-initiated feature (the **ZapZap analysis**) sends that
game's player names, scores and round comments to the developer's backend, which forwards them
to an LLM provider to generate the analysis text. Nothing is stored on the backend.

---

## Table of Contents

1. [What Changed and Why](#what-changed-and-why)
2. [Prerequisite Before Submitting](#prerequisite-before-submitting)
3. [Question-by-Question Guide](#question-by-question-guide)
4. [Data Types to Declare](#data-types-to-declare)
5. [App Permissions Justification](#app-permissions-justification)
6. [Completion Checklist](#completion-checklist)
7. [Common Questions & Answers](#common-questions--answers)
8. [Quick Reference Card](#quick-reference-card)

---

## What Changed and Why

The ZapZap analysis feature (`lib/screens/game_analysis_screen.dart`) posts a JSON payload to
`POST /comments/zapzap-analysis` on the CountScore backend. The payload contains:

| Field | Content |
|---|---|
| `game` | Name, scoring rule, creation date |
| `game_type` | e.g. "ZapZap" |
| `players[].name` | **Player names entered by the user** |
| `rounds[].comment` | **Free text the user typed on a round** |
| `rounds[].scores[]` | Score values |
| `history_by_player_name` | Past results for each player, from up to 10 of their other games |

The backend is stateless for this endpoint — it persists nothing — but it forwards the payload
to an LLM provider (**AWS Bedrock**, **Google Gemini**, or **Mistral AI**, depending on the
`LLM_PROVIDER` server setting) whose retention is governed by that provider's own terms.

**Why we declare rather than claim an exemption.** Google's "ephemeral processing" exemption
allows answering "not collected" when data is used only in memory and kept no longer than
needed to serve the request. Our own backend meets that bar; the LLM provider is not under our
control, and at least one supported configuration (free-tier Gemini) may use submitted prompts
for product improvement. The exemption cannot be claimed for every configuration the server
supports, so the declaration is made on the conservative reading. Declaring more than strictly
required is permitted; declaring less is what gets apps removed.

---

## Prerequisite Before Submitting

⚠️ **The release build currently declares no `INTERNET` permission.**
`android/app/src/main/AndroidManifest.xml` requests no permissions at all; `INTERNET` is
present only in `android/app/src/debug/AndroidManifest.xml` and the profile manifest, which
Flutter adds for hot reload. A signed release build therefore **cannot make the analysis
request** — it will fail at runtime.

Before shipping 1.1.0, add to `android/app/src/main/AndroidManifest.xml`:

```xml
<uses-permission android:name="android.permission.INTERNET"/>
```

Then verify it survived the merge:

```bash
flutter build apk --release --no-tree-shake-icons
grep uses-permission build/app/intermediates/merged_manifests/release/*/AndroidManifest.xml
```

Both the permission and this declaration must land in the same release. See `TODO.md`.

---

## Question-by-Question Guide

### Section 1: Data Collection and Security

#### Q1: Does your app collect or share any of the required user data types?

**Answer**: ✅ **Yes**

**Explanation**: When the user explicitly requests a ZapZap analysis, the app transmits that
game's player names, scores and round comments to the developer's backend and on to an LLM
provider. All other app data stays on the device.

---

#### Q2: Is all of the user data collected by your app encrypted in transit?

**Answer**: ✅ **Yes**

**Explanation**: The request is sent over HTTPS/TLS to
`https://countscore.ombivince.synology.me`, terminated by Synology Web Station. There is no
cleartext transmission path.

---

#### Q3: Do you provide a way for users to request that their data is deleted?

**Answer**: ✅ **Yes**

**Explanation**:

1. **In-app deletion** — delete individual games, rounds, players or custom game types;
   deleting a game also deletes its cached analysis.
2. **Clear app data** — Android Settings → Apps → CountScore → Storage → Clear Data.
3. **Uninstall** — removes all app data permanently.
4. **Server-side** — nothing to delete: the analysis endpoint stores no game data.

---

### Section 2: Privacy Policy

#### Q4: Privacy policy URL

**Answer**: `[YOUR_PRIVACY_POLICY_URL]`

The published policy must be the **current** `privacy_policy.md` (v2.0, September 9, 2026),
which describes the analysis feature. Publishing the older v1.0 text alongside a "Yes"
declaration is exactly the mismatch reviewers look for.

**Hosting options**:

1. **GitHub Pages** (recommended, free) — `https://vemore.github.io/countscore/privacy-policy.html`;
   create `docs/privacy-policy.html` from `privacy_policy.md` and enable Pages.
2. **Personal website** — must be permanent and publicly accessible.

```bash
pandoc privacy_policy.md -o privacy-policy.html --standalone
```

**CRITICAL**: the URL must be publicly accessible (no login), permanent, and HTTPS.

---

## Data Types to Declare

Declare **two** data types. For both, the answers to the sub-questions are the same:

| Sub-question | Answer | Why |
|---|---|---|
| Collected? | **Yes** | It is transmitted off the device |
| Shared? | **Yes** | Forwarded to a third-party LLM provider |
| Processed ephemerally? | **No** | Not claimed — see [What Changed and Why](#what-changed-and-why) |
| Required or optional? | **Optional** | The app is fully usable without ever generating an analysis |
| Purpose | **App functionality** | Only to produce the requested analysis text |
| Linked to the user's identity? | **No** | No accounts, no device or advertising identifiers, nothing to link to |
| Used for tracking? | **No** | No cross-app or cross-site tracking of any kind |

### 1. Personal info → Name

Player names the user creates. These are user-chosen labels — often first names or nicknames —
but a user may enter a real name, so this is declared as **Name** rather than treated as
anonymous.

### 2. App activity → Other user-generated content

Game names, round comments (free text the user types), score values, and per-player history
from previous games.

### Do NOT declare

- **Location, Financial info, Health, Contacts, Calendar, Photos, Audio, Files** — never
  accessed.
- **Device or other IDs** — none collected. The backend inspects the requesting IP address in
  memory for rate limiting (5/min, 30/h) and never stores it; transient anti-abuse use of an
  IP address is not a declarable data type.
- **App info and performance** — no crash reporting, no diagnostics, no analytics SDK.

---

## App Permissions Justification

### 1. INTERNET

**Status**: must be added to the main manifest before 1.1.0 — see
[Prerequisite](#prerequisite-before-submitting).

**Justification**:
"The INTERNET permission is used for a single, optional, user-initiated feature: generating a
written analysis of a completed game. The app makes no other network requests. No background
networking, telemetry, analytics or advertising traffic occurs."

### 2. WAKE_LOCK

**Status**: ❌ **Not requested.** Earlier versions of this guide stated that CountScore
declares `WAKE_LOCK`; it does not. The `wakelock_plus` plugin keeps the screen on using the
`FLAG_KEEP_SCREEN_ON` window flag, which requires no permission. Verified against the merged
release manifest, which contains no `WAKE_LOCK` entry.

### 3. Storage permissions

**Status**: ❌ **Not requested.** The export/import feature uses the system file picker
(Storage Access Framework), which needs no storage permission.

### Checking your permissions

```bash
# Source manifests
grep -rn "uses-permission" android/app/src/main/AndroidManifest.xml

# Authoritative: the merged manifest after a release build
flutter build apk --release --no-tree-shake-icons
grep uses-permission build/app/intermediates/merged_manifests/release/*/AndroidManifest.xml
```

The merged manifest is the one that ships — always verify there, not in the source manifest.

---

## Completion Checklist

Before submitting:

- [ ] `INTERNET` added to the main manifest and confirmed in the merged release manifest
- [ ] **Q1**: answered "Yes" for data collection/sharing
- [ ] **Data types**: Personal info → Name, and App activity → Other user-generated content
- [ ] Both marked **Optional**, purpose **App functionality**, **not** linked to identity,
      **not** used for tracking
- [ ] **Q2**: answered "Yes" for encryption in transit
- [ ] **Q3**: answered "Yes" for data deletion
- [ ] **Privacy Policy**: URL live, HTTPS, publicly accessible, and serving the **v2.0** text
- [ ] Policy content matches the declaration — no leftover "no data is transmitted" claims
- [ ] Data Safety preview reviewed in Play Console
- [ ] Changes saved

---

## Common Questions & Answers

### Q: "Do I need to declare the SQLite database?"

**A**: No. Local storage is not "collection" in Google's definition — only data that leaves
the device counts. The SQLite database itself is never uploaded.

### Q: "Should I mention player names users enter?"

**A**: **Yes, as of v1.1.0.** They stay local while the user only tracks scores, but they are
transmitted as part of an analysis request, and transmission is what makes them declarable.
(This answer was "No" in earlier versions of this guide, correctly, for 1.0.x.)

### Q: "The backend stores nothing. Isn't that 'ephemeral processing'?"

**A**: For our own server, yes. But the payload is forwarded to a third-party LLM provider
whose retention we do not control, and free-tier Gemini may use prompts for product
improvement. We therefore do not claim the exemption. If production is ever pinned to a
provider with a contractual no-retention, no-training guarantee, this is worth revisiting —
with the reasoning recorded, not silently.

### Q: "Is it 'shared' if the LLM provider is just our processor?"

**A**: Arguably not — Google exempts transfers to a service provider acting on your behalf.
We answer "Yes" anyway, because the answer is defensible either way and over-declaring carries
no penalty while under-declaring does.

### Q: "What if the user never uses the analysis?"

**A**: Then nothing is transmitted. That is why both data types are declared **Optional**. The
declaration describes what the app *can* do, not what every user does.

### Q: "What about the group sharing and sync endpoints in the backend?"

**A**: Not declarable yet — the app contains no client code for them, so no user data reaches
them. When a sync client ships, this guide and the privacy policy must be updated **before**
that release.

### Q: "What if I add analytics later?"

**A**: Update the privacy policy and the Data Safety form before the update is published.

---

## What If Google Questions the Declaration?

**Response template**:

```
Hello Google Play Review Team,

Thank you for reviewing CountScore. Our data handling is as follows:

1. All game data (game types, players, scores, preferences) is stored locally on the
   device using SQLite and SharedPreferences.
2. One optional, user-initiated feature ("ZapZap analysis") transmits a single game's
   player names, scores and round comments over HTTPS to our backend, which forwards
   them to a large language model provider to generate an analysis text. This occurs
   only when the user explicitly taps the generate button.
3. Our backend stores none of this data; it is stateless for this endpoint.
4. We use no analytics, advertising or tracking SDKs, and collect no device identifiers.
5. The app is open source and can be audited at:
   https://github.com/vemore/countscore
   The network request in question is in lib/screens/game_analysis_screen.dart.

Our privacy policy at [PRIVACY_POLICY_URL] describes this in detail.

Best regards,
vemore
```

---

## Data Safety Summary for Copy-Paste

```
CountScore is a score-tracking application that:
- Stores all game data locally on the user's device
- Uses no analytics, advertising or tracking services
- Collects no device identifiers and requires no account
- Allows users to delete their data at any time
- Is open-source software (MIT License)

One optional feature, generated only at the user's explicit request, sends a single
game's player names, scores and round comments over an encrypted connection to the
developer's backend and on to a large language model provider, solely to produce a
written analysis of that game. That data is not stored on the backend, is not linked
to any identity, and is not used for tracking or advertising.
```

---

## Updates and Maintenance

**When to update the Data Safety form**:
- ✅ Before shipping the sync/group client
- ✅ Before adding analytics or advertising
- ✅ Before changing the LLM provider in a way that changes retention
- ✅ When adding new permissions
- ✅ When changing data handling practices

**Update process**: update the privacy policy first, then the Data Safety form, then submit
the app update. All three must be consistent.

---

## Additional Resources

- **Play Console Help**: https://support.google.com/googleplay/android-developer/answer/10787469
- **Data Safety Guide**: https://developer.android.com/google/play/data-safety
- **Privacy Policy Guide**: https://play.google.com/about/privacy-security-deception/user-data/

---

## Quick Reference Card

```
DATA SAFETY QUICK REFERENCE — CountScore v1.1.0+

Q: Collect or share data?        A: YES (optional, user-initiated analysis only)
Q: Data encrypted in transit?    A: YES (HTTPS/TLS)
Q: Data deletion available?      A: YES
Privacy Policy URL:              [YOUR_URL]  (must serve the v2.0 text)

Data types declared:
- Personal info > Name .................. player names
- App activity > Other user-generated ... game names, round comments, scores
Both: collected YES, shared YES, optional, App functionality,
      NOT linked to identity, NOT used for tracking.

Permissions: INTERNET (must be added to the main manifest before release)
             No WAKE_LOCK, no storage permissions.

Summary: local-only by default; one optional feature transmits one game's data
         to an LLM provider at the user's explicit request.
```

---

**Before submitting, re-read `privacy_policy.md` and confirm every statement in it still
matches the code.** A declaration is only as good as the policy backing it.
