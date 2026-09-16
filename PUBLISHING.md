# CountScore — Play Store Submission Guide

**Last Updated**: September 15, 2026
**Scope**: what happens in the **Play Console**, for a release that is already built.

Everything on the machine — keystore, signing, version bump, icons, the App Bundle — is the
`release-android` skill in `.claude/skills/release-android/`. Everything about *what we
declare* is `PLAY_STORE_DATA_SAFETY.md` and `privacy_policy.md`. This file does not repeat
either, on purpose: it used to, and the copies drifted for ten months until it was telling
the reader to answer "no data collected" about an app that transmits game data.

| I need to… | Read |
|---|---|
| Build, sign, verify the AAB | `.claude/skills/release-android/SKILL.md` |
| Answer the Data Safety form | `PLAY_STORE_DATA_SAFETY.md` |
| Know what we tell users we do | `privacy_policy.md` (published from `docs/`) |
| Know the signing/target/icon state | `.llmwiki/Release.md` |
| Write or change the listing text | `store_listing/en-US/`, `store_listing/fr-FR/` |
| Produce the listing images | `store_listing/*.md`, `scripts/capture_screenshots.sh` |

---

## Before you open the Console

These must be true. Each is a rejection, a blocked update or a policy violation if it is not.

1. **The AAB is built and passes `verify_aab.sh`** — upload key, version code, target API ≥ 36
   (required for every update since 2026-08-31), 16 KB page-size alignment of the native
   libraries. `release-android` §6–7.
2. **The release manifest declares `INTERNET`.** The ZapZap analysis and group sharing both
   need it and fail silently without it — see
   [Check Before Submitting](PLAY_STORE_DATA_SAFETY.md#check-before-submitting). It is not
   enough that debug builds work; they merge a different manifest.
3. **The privacy policy is live** at
   https://vemore.github.io/countscore/privacy-policy.html, serving the current text. See
   `docs/README.md` — GitHub Pages has to be enabled once, by hand.
4. **The listing copy matches the declaration.** `store_listing/*/full_description.txt`
   describes the ZapZap analysis and says data leaves the device when the user asks. Store
   copy claiming "no data collection" beside a Data Safety form saying "Yes" is the exact
   contradiction reviewers look for.
5. **AI-generated content can be reported from inside the app.** Play's AI-Generated Content
   policy applies to the ZapZap commentary. `.llmwiki/Release.md` records whether the app
   has that control.
6. **The app is registered in the Console** (Android developer verification). Unregistered
   apps are removed from Google Play from 2026-09-30. Done for `com.vemore.countscore` since
   2026-03-06, verified 2026-09-16 — Google registered its own app signing key, and the
   upload key is deliberately absent. Registering it becomes necessary only if the app is
   ever distributed outside Play; `.llmwiki/Release.md` §Developer verification has both
   fingerprints and the reason.

The release itself (§5) — bundle, track, release notes, and the listing text and images of
§2 — is published from the terminal through the Play Publishing API: `release-android` §8,
`play_publish.py`. What the API cannot reach (content rating, App content declarations, the
Data Safety review, registration) can be delegated to Claude Cowork or Claude in Chrome with
the brief `release-android` §9 stages.

---

## 1. Create the app

Play Console → **Create app**. App name `CountScore`, default language English (United
States), type **App**, **Free**. Free cannot be changed to paid later.

## 2. Main store listing

**Store presence → Main store listing.** The text is committed, per locale — paste it, do
not retype it:

| Field | Source | Limit |
|---|---|---|
| App name | `store_listing/<locale>/title.txt` | 30 |
| Short description | `store_listing/<locale>/short_description.txt` | 80 |
| Full description | `store_listing/<locale>/full_description.txt` | 4000 |

Both `en-US` and `fr-FR` are maintained. If you change the wording in the Console, change
the file too, or the next release silently reverts it.

**Graphics**: app icon 512×512 (`store_listing/assets/icon_512.png`), feature graphic
1024×500, and 2–8 phone screenshots. Requirements and design guidance are in
`store_listing/ASSET_REQUIREMENTS.md` and the guides beside it; capture screenshots with
`scripts/capture_screenshots.sh`.

**Category**: Tools. **Contact email** is public — `scribio.ai@gmail.com`, matching the one
in `privacy_policy.md`.

## 3. App content

This is the section that gets releases rejected. Answers below are for CountScore 1.1.0.

### Data safety

Do not answer from memory. `PLAY_STORE_DATA_SAFETY.md` walks the form question by question
and explains *why* each answer is what it is; the short version:

- Collects or shares user data: **Yes** — optional, user-initiated analysis only.
- Two data types: **Personal info → Name** (player names) and **App activity → Other
  user-generated content** (game names, round comments, scores).
- Both: optional, purpose **App functionality**, **not** linked to identity, **not** used
  for tracking. Encrypted in transit: **Yes**. Deletion available: **Yes**.

### Privacy policy

URL: `https://vemore.github.io/countscore/privacy-policy.html`. It must be reachable in a
private window, over HTTPS, with no login.

### The rest

| Question | Answer |
|---|---|
| App access — is functionality restricted? | No |
| Ads — does the app contain ads? | No |
| Content rating (IARC) | Violence, sexual content, language, controlled substances: none. In-app purchases: no. User interaction: none — no chat, no social features. **Shares user data: yes** — the analysis. |
| Target audience | 18+ — the safest answer for a general-purpose app; does not appeal to children |
| News app | No |
| Government app | No |
| Financial features | None |
| Health apps | No |

The IARC answer about sharing data must agree with the Data Safety form. Answering "no"
there because the old version of this guide said so is how the two end up contradicting.

## 4. Countries, pricing, signing

- **Production → Countries/regions**: start with your own country, expand after the first
  release proves stable.
- **Pricing**: free, no in-app products.
- **Setup → App integrity → App signing**: leave **Play App Signing** enabled. Google holds
  the app signing key; we upload with the upload key. It is the only recovery path if the
  upload keystore is lost — but it does not back the upload keystore up for you, so keep
  doing that yourself (`release-android` §1).

## 5. Release: internal, then staged production

**Normally not by hand:** `release-android` §8 publishes the bundle and the notes to a track
with `play_publish.py` (validate, then `--commit` on the owner's go). The Console steps below
are the fallback, and what the testers list still needs.

**Always internal testing first.** Testing → **Internal testing** → Create new release →
upload the AAB → add testers (up to 100) → send for review. Give it a few days of real use.

What testers must exercise, because no automated gate covers it:

- [ ] Install over the **store** version — the database must survive the upgrade
- [ ] The **ZapZap analysis** returns real commentary in the release build (this is the one
      that was broken by the missing permission, and it works in debug either way)
- [ ] Creating, joining and leaving a group, and a score syncing between two devices
- [ ] Export and import a game
- [ ] The wakelock toggle keeps the screen on
- [ ] The app follows the system language

**Personal developer accounts created after 2023-11-13** cannot open production until a
**closed test** has had at least 12 testers opted in for 14 consecutive days. The Production
page says so if it applies.

Then **Production → Create new release**. Staged rollout: 10–20% first, watch Crashes & ANRs
for 48 hours, then 50%, then 100%.

Release notes go in `store_listing/<locale>/release_notes_v<x.y.z>.txt`, one file per
locale, committed alongside the release — **500 characters at most** each, Play's limit.

Google's review is typically 2–5 business days and checks policy compliance, privacy-policy
completeness, **data safety accuracy** and content rating accuracy.

## 6. After the rollout

First 48 hours: Play Console dashboard, Crashes & ANRs, ratings and reviews. Install success
rate should be >98%, crash rate <1%, ANR rate <0.5%. Reply to reviews within a day or two.

Any later release that changes what leaves the device — a new field in the analysis payload,
a new recipient, a new entity carried by group sync — reopens §3 before it ships. That rule
is in `CLAUDE.md` under "A new outbound data flow is a change to three documents".

---

## Common rejections

**Privacy policy URL not accessible** — GitHub Pages was never enabled, or the repository
went private. Check it in a private window, not in your own browser.

**Data safety declaration does not match behaviour** — the most common cause here would be
declaring "no data collected" against a build that ships the analysis. See
`PLAY_STORE_DATA_SAFETY.md`, which explains why we declare rather than claim the
ephemeral-processing exemption.

**Store listing contradicts the declaration** — see §2. The listing files are the source of
truth; keep them true.

**Content rating incomplete** — the IARC questionnaire has to be finished and resubmitted
after any change to what the app shares.

**Upload rejected: version code already used** — the build number must strictly increase.
`release-android` §2.

**Build fails: `key.properties not found`, or "keystore was tampered with"** — local
signing, not a Console problem. `release-android` §1.

---

## Never commit

`android/key.properties`, `*.jks` / `*.keystore`, `.env`, the Play service-account key. A commit hook refuses all four
(`.llmwiki/Hooks.md`), but the hook is a net, not the rule. **Losing the upload keystore
means the app can never be updated again** — back it up somewhere durable, with its
passwords in a password manager.

## Resources

- Flutter deployment: https://docs.flutter.dev/deployment/android
- Play Console help: https://support.google.com/googleplay/android-developer
- Developer content policy: https://play.google.com/about/developer-content-policy/
