# Google Play Store — Data Safety Form Guide

Complete guide for filling out the Data Safety section in Google Play Console for CountScore.

**Last Updated**: September 16, 2026
**Applies to**: CountScore v1.1.0 and later
**Privacy Policy**: `privacy_policy.md`, published at
https://vemore.github.io/countscore/privacy-policy.html

> **History — the declaration changed with 1.1.0.** Versions 1.0.x contained no networking
> code, and the declaration for them was correctly "no data collected". Version 1.1.0 added
> the game analysis and group sharing, which transmit game data off the device — and group
> sharing **stores** it on the server the user configures. The owner updated the Console form
> to this guide and submitted 1.1.0 (4) to production on **2026-09-15**.
>
> Keep the form and this guide in step: a declaration that does not match app behaviour is a
> Play policy violation and a common cause of suspension. Any new outbound data flow changes
> this file, `privacy_policy.md`, README Privacy and the Console form together
> (`.llmwiki/Documentation.md`).

> **Corrected 2026-09-16 — the document contradicted itself, the declaration did not change.**
> §Data Types to Declare has declared **three** types since 1.1.0, including *Device or other
> IDs*, while the Quick Summary, the copy-paste block and `PUBLISHING.md` §3 still described
> two and said "collects no device identifiers". The Console answers were right and were left
> untouched; the prose around them was brought in line, because softening a Play answer to
> make the public card read better is the mistake this whole file exists to prevent. The
> store descriptions now explain the third entry rather than talk past it
> (`.llmwiki/StoreListing.md`).

---

## Quick Summary

**CountScore can collect and share game data, and only after the user has configured a server
of their own.**

Everything the app does by default — creating games, entering scores, viewing statistics — is
local to the device. Two optional features use the server the user configures:

- the **AI game analysis** sends one game's player names, scores and round comments to that
  backend, which forwards them to an LLM provider to generate the analysis text. Nothing is
  stored on the backend for this feature;
- **group sharing**, once the user has created or joined a group, sends the games the user
  shares — name, type, player names and colours, round comments, scores, analysis — plus the
  group name and a user-chosen device name to that backend, which **stores** them (with a
  change log) and serves them to the group's other devices. The server also issues the device
  a random identifier and access token — which is why **Device or other IDs** is one of the
  three declared data types, even though no hardware or advertising identifier is ever read.

**The app ships with no backend address.** There is no default and none is compiled in: the
user enters one in Settings → Server, pointing at a server they host themselves from the
public `backend/` sources. Until they do, the feature is not offered and the app makes no
network request at all. The developer operates no service that the published app talks to.

The declaration is still made, because the *binary is capable* of the transfer and the form
describes capability rather than the default — see below.

---

## Table of Contents

1. [What Changed and Why](#what-changed-and-why)
2. [Check Before Submitting](#check-before-submitting)
3. [Question-by-Question Guide](#question-by-question-guide)
4. [Data Types to Declare](#data-types-to-declare)
5. [App Permissions Justification](#app-permissions-justification)
6. [Completion Checklist](#completion-checklist)
7. [Common Questions & Answers](#common-questions--answers)
8. [Quick Reference Card](#quick-reference-card)

---

## What Changed and Why

### Group sharing (sync client, September 13, 2026)

`lib/providers/group_provider.dart` and `lib/services/sync/` implement the group sync client
against `POST /groups`, `POST /groups/join`, `POST /sync/push`, `GET /sync/pull`,
`POST /sync/ws-ticket` and the `/sync/stream` WebSocket. A game the user shares (on by default
for new games while the device is in a group, per game otherwise) is uploaded with:

| Entity | Content |
|---|---|
| `game` | Name, game type, scoring rule, start date |
| `game_type` | Name, built-in identifier, icon, colour, elimination / game-over rules, **free-text rules you wrote** |
| `player` | **Player name**, colour |
| `round` | Number, **free-text comment** |
| `score` | Score value |
| `game_analysis` | **Generated analysis text**, model id, date |
| group create/join | **Group name**, **device name** typed by the user |

The server persists all of it, and a `change_log` of every change, until its operator deletes
it; other devices in the group download it. The device receives a server-generated identifier
and a secret token (stored argon2-hashed on the server, in Keystore / encrypted browser storage
on the device). No LLM provider is involved.

**Device list (September 14, 2026).** `GET /groups/me/devices` returns to every device of a
group the other devices' **device name**, join date and last-seen date, so a member can remove
a lost phone (`POST /groups/me/devices/{id}/revoke`). No new data type and no new recipient
outside the group: the device name is already declared above under App activity, and the
server already stored both dates. The recipients are the devices of the group the user chose
to join — the same audience that already receives the shared games — so the answers below are
unchanged.

### Report control for AI commentary (September 14, 2026)

The analysis screen's **Report this commentary** action (Play AI-Generated Content policy)
opens a `mailto:` to the listing contact in the **user's own email app**, prefilled with the
analysis text, its model id and generation time. The app makes no network request for it and
receives nothing back; the user reviews the message and sends it — or not — from another app.
Data a user chooses to send by email from a separate app is not collected *by this app*, so
nothing in the form below changes.

### AI game analysis

The analysis feature (`lib/screens/game_analysis_screen.dart`, issuing the request via
`lib/services/backend_client.dart`) posts a JSON payload to `POST /comments/game-analysis`
on the backend the user configured. Until 2026-09-16 it covered only games of one type and
was called the ZapZap analysis; the path `/comments/zapzap-analysis` still reaches the same
endpoint. The payload contains:

| Field | Content |
|---|---|
| `game` | Name, scoring rule, creation date |
| `game_type` | e.g. "Skyjo" — including a game type the user named themselves |
| `game_type_rules` | That type's scoring direction and its score thresholds |
| `style` | The voice the user picked, e.g. `noir` — app configuration, not user content |
| `language` | The language the app is displayed in, e.g. `fr` — app configuration |
| `players[].name` | **Player names entered by the user** |
| `rounds[].comment` | **Free text the user typed on a round** |
| `rounds[].scores[]` | Score values |
| `history_by_player_name` | Past results for each player, from up to 10 of their other games |

`style` and `language` are settings of the app, not content about a person, so they change
none of the declared categories below. They are listed because this table is the inventory
of what leaves the device.

The backend is stateless for this endpoint — it persists nothing — but it forwards the payload
to an LLM provider (**AWS Bedrock**, **Google Gemini**, or **Mistral AI**, depending on that
server's `LLM_PROVIDER` setting) whose retention is governed by that provider's own terms.

**Why we declare rather than claim an exemption.** Google's "ephemeral processing" exemption
allows answering "not collected" when data is used only in memory and kept no longer than
needed to serve the request. The server software meets that bar; the LLM provider is not under
anyone's control here, and at least one supported configuration (free-tier Gemini) may use
submitted prompts for product improvement. The exemption cannot be claimed for every
configuration the server supports, so the declaration is made on the conservative reading.
Declaring more than strictly required is permitted; declaring less is what gets apps removed.

**Why the user-configured destination does not reduce the declaration.** It is tempting to
answer "no data collected" on the grounds that the shipped app has nowhere to send anything.
Google's form asks what the app *can* do, and a code path that transmits player names once a
URL is entered is a transmission capability. Declaring it is the conservative reading, and the
only one that survives a reviewer who types a URL into Settings.

---

## Check Before Submitting

✅ **The release build declares `INTERNET`.** It is in
`android/app/src/main/AndroidManifest.xml`, and it is the only permission the app declares.

This was not always true: until 2026-09-09 the permission existed only in
`android/app/src/debug/AndroidManifest.xml` and the profile manifest, where Flutter puts it
for hot reload. Neither is merged into a release build, so a signed release could not make
the analysis request at all — it failed at runtime while working perfectly in debug. The
declaration on this form and the permission in the binary have to move together, which is why
they landed in the same change.

Re-run the check on every release, against the **merged** manifest and not the source one:

```bash
flutter build apk --release --no-tree-shake-icons
grep uses-permission build/app/intermediates/merged_manifests/release/*/AndroidManifest.xml
```

Expect `android.permission.INTERNET` alongside the generated
`DYNAMIC_RECEIVER_NOT_EXPORTED_PERMISSION`. A CI step asserts the source manifest still
declares it (`.github/workflows/ci.yml`, the `android` job); CI cannot check the merged
release manifest, because release signing needs the gitignored `android/key.properties`.

---

## Question-by-Question Guide

### Section 1: Data Collection and Security

#### Q1: Does your app collect or share any of the required user data types?

**Answer**: ✅ **Yes**

**Explanation**: When the user has configured a backend server of their own, (a) explicitly
requesting an analysis transmits that game's player names, scores and round comments to
that server and on to an LLM provider, and (b) joining a group and sharing a game uploads that
game — player names, scores, comments, analysis — to that server, which stores it and serves it
to the group's other devices. No server is configured by default, so a user who never sets one
up transmits nothing. Unshared games stay on the device.

---

#### Q2: Is all of the user data collected by your app encrypted in transit?

**Answer**: ✅ **Yes**

**Explanation**: Requests are sent over HTTPS/TLS (and the sync signal over a TLS WebSocket) to
the server address the user configured.
The app refuses to store an `http://` address unless its host is a private or loopback address
(`192.168.x.x`, `10.x.x.x`, `172.16–31.x.x`, `127.x.x.x`, `localhost`, `*.local`), so the only
unencrypted path possible is one that never leaves the user's own local network, to a server
they operate. That rule is enforced in `lib/providers/backend_provider.dart` and covered by
`test/providers/backend_provider_test.dart`.

`android/app/src/main/res/xml/network_security_config.xml` sets
`cleartextTrafficPermitted="true"` — necessary because Android's network security config
matches host names and cannot express an address range, so the LAN exception cannot be written
there. The app-level rule above is what actually constrains it. Mention this if a reviewer
queries the manifest.

---

#### Q3: Do you provide a way for users to request that their data is deleted?

**Answer**: ✅ **Yes**

**Explanation**:

1. **In-app deletion** — delete individual games, rounds, players or custom game types;
   deleting a game also deletes its cached analysis.
2. **Clear app data** — Android Settings → Apps → CountScore → Storage → Clear Data.
3. **Uninstall** — removes all app data permanently.
4. **Shared games** — deleting a shared game deletes it on every device of the group and marks
   it deleted on the server; leaving the group revokes the device. Removing the stored data
   from the server is done by its operator (the user, for a self-hosted server): deleting the
   group row cascades to everything it holds.
5. **Analysis** — nothing to delete server-side: the analysis endpoint stores no game data.

---

### Section 2: Privacy Policy

#### Q4: Privacy policy URL

**Answer**: `https://vemore.github.io/countscore/privacy-policy.html`

That page is `docs/privacy-policy.html`, a static rendering of the **current**
`privacy_policy.md` (v2.5, September 14, 2026), which describes the analysis feature, group
sharing and the AI-commentary report control.
Publishing the older v1.0 text alongside a "Yes" declaration is exactly the mismatch
reviewers look for, so the two must be regenerated together — see `docs/README.md`.

**One manual step remains**: GitHub Pages has to be switched on for the repository —
*Settings → Pages → Source: Deploy from a branch → `main` / `docs`*. Confirm the URL loads
publicly, in a private window, before pasting it into the Console.

**CRITICAL**: the URL must be publicly accessible (no login), permanent, and HTTPS.

---

## Data Types to Declare

Declare **three** data types. For all three, the answers to the sub-questions are the same:

| Sub-question | Answer | Why |
|---|---|---|
| Collected? | **Yes** | It is transmitted off the device |
| Shared? | **Yes** | Forwarded to a third-party LLM provider |
| Processed ephemerally? | **No** | Group sharing stores it; for the analysis the exemption is not claimed — see [What Changed and Why](#what-changed-and-why) |
| Required or optional? | **Optional** | The app is fully usable without a server, a group or an analysis |
| Purpose | **App functionality** | Only to produce the requested analysis text and to keep shared games in sync |
| Linked to the user's identity? | **No** | No accounts, no device or advertising identifiers, nothing to link to |
| Used for tracking? | **No** | No cross-app or cross-site tracking of any kind |

### 1. Personal info → Name

Player names the user creates. These are user-chosen labels — often first names or nicknames —
but a user may enter a real name, so this is declared as **Name** rather than treated as
anonymous.

### 2. App activity → Other user-generated content

Game names, round comments (free text the user types), score values, per-player history from
previous games (analysis), and for group sharing: game-type settings, generated analysis text,
the group name and the device name the user types.

### 3. Device or other IDs

Group sharing assigns the app installation a random identifier and access token when it joins
a group, sent with every sync request. It is not a hardware or advertising identifier, but it
identifies an app instance, which is what this category covers — declared on the conservative
reading. Not linked to identity (there are no accounts), not used for tracking.

### Do NOT declare

- **Location, Financial info, Health, Contacts, Calendar, Photos, Audio, Files** — never
  accessed.
- **IP address** — the user's own backend inspects the requesting IP address in memory for rate
  limiting and never stores it; transient anti-abuse use of an IP address is not a declarable
  data type.
- **App info and performance** — no crash reporting, no diagnostics, no analytics SDK.

---

## App Permissions Justification

### 1. INTERNET

**Status**: ✅ **Declared** in `android/app/src/main/AndroidManifest.xml`, and it is the only
permission the app declares — see [Check Before Submitting](#check-before-submitting).

**Justification**:
"The INTERNET permission is used for two optional features, both against a server the user
configures themselves: generating a written analysis of a completed game on request, and
synchronising the games the user chooses to share with a group of their own devices while the
app is open. The app ships with no server address, so the permission goes unused until the user
supplies one. No telemetry, analytics or advertising traffic occurs."

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

- [ ] `INTERNET` confirmed in the **merged release** manifest, not just the source one
- [ ] The release build contains no backend hostname:
      `strings build/app/outputs/flutter-apk/app-release.apk` — or grep the sources for a
      `defaultValue` on `BACKEND_URL`, which must not exist
- [ ] **Q1**: answered "Yes" for data collection/sharing
- [ ] **Data types**: Personal info → Name, App activity → Other user-generated content, and
      Device or other IDs
- [ ] All three marked **Optional**, purpose **App functionality**, **not** linked to identity,
      **not** used for tracking
- [ ] **Q2**: answered "Yes" for encryption in transit
- [ ] **Q3**: answered "Yes" for data deletion
- [ ] **GitHub Pages enabled** (Settings → Pages → `main` / `docs`)
- [ ] **Privacy Policy**: https://vemore.github.io/countscore/privacy-policy.html live over
      HTTPS, publicly accessible in a private window, and serving the **current** text —
      v2.5 as of 2026-09-16, per `privacy_policy.md` §Version History
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

### Q: "The app has no server address at all. Why declare anything?"

**A**: Same reasoning. The shipped binary contains a code path that transmits player names as
soon as a URL is entered in Settings → Server, and a reviewer can enter one. Capability is
what the form asks about. The absence of a default is a privacy improvement to state in the
explanations, not a reason to answer "no data collected".

### Q: "What about the group sharing and sync endpoints in the backend?"

**A**: Declared, since 1.1.0: the app contains the client (`lib/services/sync/`). Shared games
are **stored** on the user's server, so the ephemeral-processing exemption does not apply to
them in any reading. (Until 2026-09-13 this answer said there was no client.)

### Q: "What if I add analytics later?"

**A**: Update the privacy policy and the Data Safety form before the update is published.

---

## What If Google Questions the Declaration?

**Response template**:

```
Hello Google Play Review Team,

Thank you for reviewing CountScore. Our data handling is as follows:

1. All game data (game types, players, scores, preferences) is stored locally on the
   device using SQLite and SharedPreferences, unless the user shares a game with a
   group (point 6).
2. One optional feature ("AI game analysis") transmits a single game's player names,
   scores and round comments over HTTPS to a backend server. The app ships with no
   server address and none is compiled into it: the user must first enter the address
   of a server they host themselves (the server source is in the backend/ directory of
   the public repository). The backend forwards the payload to a large language model
   provider to generate an analysis text. This occurs only when a server has been
   configured and the user explicitly taps the generate button.
3. That backend stores none of this data; it is stateless for this endpoint. We operate
   no server that the published app communicates with.
4. We use no analytics, advertising or tracking SDKs, and collect no hardware or
   advertising identifiers.
5. The app is open source and can be audited at:
   https://github.com/vemore/countscore
   The network request in question is in lib/services/backend_client.dart, and the
   address it uses comes from lib/providers/backend_provider.dart, which has no
   default value.
6. Optional group sharing: after configuring that same self-hosted server and creating
   or joining a group, the user can share games. A shared game's name, player names,
   scores, round comments, end date and analysis are stored on that server and synchronised
   to the group's other devices, with a random per-installation identifier and access token.
   Games that are not shared never leave the device.

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
- Collects no hardware or advertising identifier and requires no account. A user who
  joins a group receives a random per-installation identifier and access token, issued
  by the server that user configured, used only to authenticate that group's sync
- Allows users to delete their data at any time
- Is open-source software (MIT License)

Two optional features use a server the user hosts and configures. One, at the user's
explicit request, sends a single game's player names, scores and round comments over an
encrypted connection to that server and on to a large language model provider, solely
to produce a written analysis; that data is not stored on the server. The other, group
sharing, stores the games the user chooses to share on that server and synchronises
them to the group's other devices. Neither is linked to any identity or used for
tracking or advertising.
```

---

## Updates and Maintenance

**When to update the Data Safety form**:
- ✅ Before changing what group sharing sends (a new synced field or entity)
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

Q: Collect or share data?        A: YES (optional: user-initiated analysis, and
                                    games the user shares with a group; only to a
                                    server the user configures; no server address
                                    ships with the app)
Q: Data encrypted in transit?    A: YES (HTTPS/TLS; http:// accepted only for a
                                    private/loopback host, i.e. the user's own LAN)
Q: Data deletion available?      A: YES
Privacy Policy URL:              https://vemore.github.io/countscore/privacy-policy.html

Data types declared:
- Personal info > Name .................. player names
- App activity > Other user-generated ... game names, round comments, scores,
                                          analyses, group and device names
- Device or other IDs ................... per-installation group device id
All three: collected YES, shared YES, optional, App functionality,
      NOT linked to identity, NOT used for tracking.

Permissions: INTERNET (declared in the main manifest; the only one the app declares)
             + DYNAMIC_RECEIVER_NOT_EXPORTED_PERMISSION, injected by androidx.core:
               signature-level, private to the app, grants access to nothing.
             No WAKE_LOCK, no storage permissions.
             networkSecurityConfig points at res/xml/network_security_config.xml.

Summary: local-only by default, with no backend address shipped at all; two
         optional features use a server the user configures: an analysis
         (forwarded to an LLM provider, not stored) and group sharing (shared
         games stored on that server and synced to the group's devices).
```

---

**Before submitting, re-read `privacy_policy.md` and confirm every statement in it still
matches the code.** A declaration is only as good as the policy backing it.
