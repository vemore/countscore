---
name: release-android
description: Build and publish a CountScore release to the Google Play Store — release worktree, keystore, version bump, release notes, Play policy gate, signed App Bundle, artifact verification (upload key, versionCode, target API 36, INTERNET, 16 KB pages), then a filled-in brief that lets Claude Cowork or Claude in Chrome do the Play Console steps. Use when preparing a release, cutting a new version, building or verifying a signed AAB, uploading to a Play track, handing the Console work to a browser agent, or regenerating the app icon. Triggers: "build a release", "publier sur le Play Store", "release build", "appbundle", "sign the app", "keystore", "new version", "bump version", "upload to Play Console", "internal testing", "Cowork", "Claude in Chrome".
---

# Releasing CountScore to the Play Store

This is the executable path, from a clean worktree to a release sitting on a Play track.
State facts — signing, target, policy constraints — are in `.llmwiki/Release.md`. What each
Console form must say is in `PUBLISHING.md` and `PLAY_STORE_DATA_SAFETY.md`; this skill does
not repeat their answers.

`--no-tree-shake-icons` is **mandatory on every build** (why: `.llmwiki/MobileApp.md`).

## 0. Build in a release worktree

Never build a release in a checkout another session is editing — the bundle would ship
whatever is half-done there. Branch the release off `origin/main`:

```bash
git fetch --prune origin
git worktree add ../countscore-release-<version> -b chore/release-<version> origin/main
cd ../countscore-release-<version>
git branch --unset-upstream          # it tracks origin/main; push it under its own name later
scripts/worktree_setup.sh            # pub get, build_runner, gen-l10n, links key.properties
```

`key.properties` is gitignored: without the link the release build has no signing config. Its
`storeFile` is absolute, so the link works as is.

## 1. Signing setup — first time only

```bash
./scripts/generate_keystore.sh       # → $HOME/countscore-upload-keystore.jks, alias countscore-upload
cp android/key.properties.template android/key.properties   # fill in the two passwords
```

**Back the keystore up off this machine, with its passwords in a password manager.** Play App
Signing holds the *app signing* key, so a lost *upload* key can be reset through Play support
— but that takes days during which nothing ships.

Signing and R8 shrinking are already wired in `android/app/build.gradle.kts` (`signingConfigs`,
`isMinifyEnabled`/`isShrinkResources`). Shrinking is on for size, not obfuscation.

## 2. Version bump

`version:` in `pubspec.yaml` is `x.y.z+build`; `build` becomes the `versionCode` and must be
**higher than every version code on every track**, not just production. Tags so far
(`git ls-remote --tags origin`): `1.0.0+1`, `1.0.1+2`, `1.0.1+3` — the Console's *Release
explorer* is the authority.

Commit the bump on the release branch; the commit hook runs the gates in this worktree.

## 3. Release notes

One file per locale: `store_listing/en-US/release_notes_v<x.y.z>.txt` and
`store_listing/fr-FR/release_notes_v<x.y.z>.txt` (the `v` matches the existing files).

- **At most 500 characters each** — Play's limit. `wc -m` them; `stage_handoff.sh` refuses
  longer ones.
- No claim that contradicts the Data Safety declaration ("no data collection", "fully
  offline").

## 3b. Pruning pass — before the build

A release is the checkpoint where the process shrinks as well as grows
(`.llmwiki/Release.md`). With `<tag>` the last release tag (`git describe --tags --abbrev=0
origin/main`):

1. List each refusal of `.claude/hooks/guard-bash.sh` (the table in `.llmwiki/Hooks.md`) and
   each rule of `CLAUDE.md`.
2. For each, look for evidence it fired or was needed since `<tag>`: `git log <tag>..`, the
   `wip/done/` entries closed since, the pull requests merged since
   (`gh pr list --state merged --search "merged:>=<tag date>"`), and reports that quote a
   refusal.
3. Propose removing or merging those with no evidence, and check `wc -l CLAUDE.md` against
   its budget. The proposal is its own pull request, decided by the user — never folded into
   the release branch, and never a reason to hold the release.

## 4. Policy gate — before building

Each of these is a rejection, a removal or a blocked update if it is false. Check against the
code, not against the previous release.

| Check | How |
|---|---|
| **Listing text matches the app** | `store_listing/*/full_description.txt` vs what leaves the device: the ZapZap analysis, plus group sharing and sync (`lib/services/sync/`, `/sync/stream` WebSocket) — both to the server the **user** configures in Settings → Server; the app ships no server URL. |
| **Data Safety and privacy policy match** | `PLAY_STORE_DATA_SAFETY.md`, `privacy_policy.md`, README Privacy — a new flow means all three plus the manifest (rule in `.llmwiki/Documentation.md`). If the policy changed: `python3 scripts/build_privacy_page.py`, and the page is live: `curl -sI https://vemore.github.io/countscore/privacy-policy.html` → `200`. |
| **AI-generated content is reportable in the app** | Play's AI-Generated Content policy requires an in-app way to flag offensive generated content; ZapZap commentary is LLM output. See `.llmwiki/Release.md` for whether the app has it yet. |
| **Target API ≥ 36** | Required for every update since 2026-08-31. `verify_aab.sh` checks it. |
| **16 KB page size** | Required for apps targeting Android 15+ with native code (`libflutter`, `libsqlite3`, …). `verify_aab.sh` checks it. |
| **App registered** in the Console | Unregistered apps are removed from 2026-09-30. Part A of the brief reads the status. |

A failure here is not fixed inside the release: stop, add a `wip/todo/` entry, tell the user
and let them decide whether it blocks.

## 5. Pre-flight

```bash
flutter clean && flutter pub get && dart run build_runner build && flutter gen-l10n
flutter analyze
flutter test
```

Then a real device — the `flutter-device-test` skill. **Export/import, the wakelock toggle,
the ZapZap analysis and group join/leave have no automated coverage in a release build**;
exercise them on the release APK:

```bash
flutter build apk --release --no-tree-shake-icons && adb install -r build/app/outputs/flutter-apk/app-release.apk
```

Install it **over the store version**, not over a debug build: the database must survive the
upgrade.

## 6. Build

```bash
flutter build appbundle --release --no-tree-shake-icons
# → build/app/outputs/bundle/release/app-release.aab
```

## 7. Verify the artifact

```bash
.claude/skills/release-android/scripts/verify_aab.sh
```

One line per check, non-zero on the first failure:

- the bundle verifies and is signed with the **upload** key — its SHA-256 compared with the
  keystore named by `key.properties`, debug key refused;
- the bundle manifest declares `INTERNET` (it shipped missing once — `wip/done/ARCHIVE-2026-09.md`, 2026-09-09);
- `versionCode` equals the `pubspec.yaml` build number, read from a merged manifest no staler
  than the bundle;
- `targetSdk` ≥ 36;
- every 64-bit `.so` has LOAD segments aligned ≥ 16384.

A stale `build/` fails the freshness or `INTERNET` check — rebuild rather than work around it.

## 8. Stage the hand-off

```bash
.claude/skills/release-android/scripts/stage_handoff.sh internal
#   or: closed · production 20 · production 20 "store listing, screenshots"
```

It re-runs `verify_aab.sh`, then creates `C:\Users\<you>\Downloads\countscore-release-<x.y.z+n>\`
with the bundle, `HANDOFF.md` (filled in from `references/play-console-handoff.md`: version
code, upload key fingerprint, track, rollout, release notes in Play's `<en-US>…</en-US>`
block), the listing text, the phone screenshots, `PLAY_STORE_DATA_SAFETY.md` and
`PUBLISHING.md`.

Windows, because Cowork and Claude in Chrome run there and their upload only sees folders the
user grants.

## 9. Play Console — delegated or by hand

**Delegated.** Hand `HANDOFF.md` to the user with the two lines the script prints — **Claude
Cowork** (grant the folder, "Read HANDOFF.md and carry it out") or **Claude in Chrome** (paste
it into the side panel on play.google.com/console). The brief has:

- **Part A**, read-only survey: banners, app registration, pending changes, whether production
  still needs a **12-tester / 14-day closed test** (personal accounts created after
  2023-11-13), version codes per track, incomplete App content;
- **Part B**: create the release on the track, upload, check the version code, paste the
  notes, copy every error and warning — **then stop**;
- **Part C**: only the optional tasks named on the command line.

The agent is forbidden to send for review, start a rollout, or save Data Safety / Content
rating changes without the user's explicit go; to accept terms; or to touch signing, pricing,
users or verification. The user handles sign-in and 2FA.

You cannot drive the Console from this session and should not relay the browser agent's
questions on its behalf: give the user the brief and the folder path, and wait for their report.

**By hand.** `PUBLISHING.md` §5.

Either way: **internal → closed (if required) → production at a staged percentage**, and
watch Crashes & ANRs for 48 h before widening.

## 10. After the rollout

- The release branch's PR is merged (the user's call). Tag the released commit — pushing a tag
  is outward-facing, so ask first:
  ```bash
  git tag -a <x.y.z+n> <commit> -m "<x.y.z+n>" && git push origin <x.y.z+n>
  ```
- Update **Submission state** in `.llmwiki/Release.md` (what is live on which track) and its
  `Updated:` date.
- Once the release pull request is merged: `scripts/cleanup_local.sh --apply` removes the
  release worktree (and the `key.properties` link with it) and the local release branch. Run it
  dry first; a `keep` line means something from the release is not on GitHub yet.
- Delete the Windows hand-off folder: it holds a signed bundle.

## Icons — only if the artwork changed

```bash
# replace store_listing/assets/icon_512.png (512×512 PNG) first
dart run flutter_launcher_icons
```
Adaptive icon on white `#FFFFFF`; every density is generated.

## Checklist

- [ ] Built in a release worktree off `origin/main`, not in a shared checkout
- [ ] Version code above every track's; bump committed on `chore/release-<version>`
- [ ] Release notes en-US and fr-FR, ≤ 500 characters, no claim contradicting Data Safety
- [ ] Pruning pass (§3b) proposed to the user
- [ ] Policy gate (§4) passed, or its failures in `wip/todo/` and cleared by the user
- [ ] `flutter analyze` and `flutter test` clean; release APK exercised on a device over the store version
- [ ] `verify_aab.sh` all OK
- [ ] No keystore, `key.properties` or `.env` staged
- [ ] Hand-off staged; Console report received; review/rollout started by the user or on their explicit go
- [ ] Tag pushed, `Release.md` Submission state updated, worktree and hand-off folder removed
- [ ] Keystore backup exists and is current
