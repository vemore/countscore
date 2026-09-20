---
name: release-android
description: Build and publish a CountScore release to the Google Play Store — release worktree, keystore, version bump, release notes, Play policy gate, signed App Bundle, artifact verification (upload key, versionCode, target API 36, INTERNET, 16 KB pages), then publishing to a Play track through the Google Play Developer Publishing API (play_publish.py: status, validate, commit on the user's go), publishing the store listing alone — title, descriptions, screenshots, translations — with no version bump and no rebuild (play_publish.py listing), plus a brief for the Console-only tasks (content rating, declarations, Data Safety review, category and tags) that Claude Cowork or Claude in Chrome can do. Use when preparing a release, cutting a new version, building or verifying a signed AAB, uploading to a Play track, updating or translating the store listing, setting up the Play API service account, handing the Console-only work to a browser agent, or regenerating the app icon. Triggers: "build a release", "publier sur le Play Store", "release build", "appbundle", "sign the app", "keystore", "new version", "bump version", "upload to Play Console", "update the store listing", "publier la fiche", "ASO", "store listing translation", "screenshots on Play", "Play API", "service account", "internal testing", "Cowork", "Claude in Chrome".
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
scripts/worktree_setup.sh --release  # pub get, build_runner, gen-l10n, links key.properties
```

`key.properties` is gitignored: without the link the release build has no signing config, and
only `--release` makes it — no other worktree gets the keystore passwords. Its `storeFile` is
absolute, so the link works as is.

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
(`git ls-remote --tags origin`): `1.0.0+1`, `1.0.1+2`, `1.0.1+3` — `play_publish.py status`
(§8) is the authority.

Commit the bump on the release branch; the commit hook runs the gates in this worktree.

## 3. Release notes

Release notes are **bilingual, whatever the listing speaks**: `play_publish.py` reads them
for `NOTES_LOCALES` only — `en-US` and `fr-FR`. One file each:
`store_listing/en-US/release_notes_v<x.y.z>.txt` and
`store_listing/fr-FR/release_notes_v<x.y.z>.txt` (the `v` matches the existing files).

- **At most 500 characters each** — Play's limit. `play_publish.py` refuses longer ones.
- A missing `fr-FR` file **falls back to `en-US`** with a note on stderr; a missing `en-US`
  file is a refusal.
- A store-listing locale outside `NOTES_LOCALES` (see §8a) requires **nothing** here: adding
  a language to the listing never makes a third release-notes file mandatory.
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
| **App registered** in the Console | Unregistered apps are removed from 2026-09-30. The API cannot read it: Part A of the Console brief (§9) does. |

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
exercise them on the release APK, installed as below.

**Not over the store version.** An APK built here carries the upload key, the store build the
app signing key (`.llmwiki/Release.md` §Signing), so `adb install -r` over a Play install fails
`INSTALL_FAILED_UPDATE_INCOMPATIBLE` — and over a debug build it fails the same way. The
upgrade is tested instead by carrying an old database into a **clean** release install through
the app's own Settings → Import, which runs the migration chain inside the R8-shrunk build.
`device_db_roundtrip.sh` does the pull and the push; the device is `-s <serial>` or
`ANDROID_SERIAL`, never guessed:

```bash
export ANDROID_SERIAL=<ip>:<port>              # flutter-device-test: ask, never scan
S=.claude/skills/release-android/scripts

# 1. An old database. `run-as` needs a debuggable build: the Pixel's own debug install, or a
#    debug APK of the previous tag (git worktree add ../countscore-prev <tag>; setup; build
#    apk --debug; install), used for a few games. From a Play install, use Settings → Export
#    instead and `adb pull` the file it writes — then skip `pull`.
$S/device_db_roundtrip.sh pull                 # → build/device_db/countscore.db, prints user_version and row counts

# 2. A clean release install — only once pull has printed user_version=…; this wipes the data.
flutter build apk --release --no-tree-shake-icons
adb uninstall com.vemore.countscore
adb install build/app/outputs/flutter-apk/app-release.apk

# 3. The file to /sdcard/Download/countscore-upgrade-test.db, then in the app: Settings →
#    Import → that file → confirm; the app closes, reopen it.
$S/device_db_roundtrip.sh push
```

Pass: the games, players and scores of the old database are on screen after the reopen, and
the counts `pull` printed match. `pull` folds a leftover `-wal` into one file, so a killed app
loses nothing. Then exercise export, the wakelock, ZapZap and groups on that same install.

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

## 8. Publish through the Play API

`scripts/play_publish.py` drives the Google Play Developer Publishing API (androidpublisher
v3) from this terminal, with the service account of *Play API access* below. Every change goes
into one **edit**, invisible in the Console until it is committed. Run it from the release
worktree; `uv` fetches its dependencies (inline, PEP 723).

```bash
P=.claude/skills/release-android/scripts/play_publish.py
uv run --script $P status                                # read-only: releases per track, listings
uv run --script $P publish --track internal              # validate only — nothing is published
uv run --script $P publish --track internal --commit     # ONLY on the user's explicit go
uv run --script $P publish --track production --promote --rollout 0.2 --commit   # internal -> production
#   --track closed (API track "alpha") · --track production [--rollout 0.2]
#   --draft · --listing (title, descriptions) · --graphics (feature graphic, phone screenshots)
#   --aab <path>, default build/app/outputs/bundle/release/app-release.aab
#   --promote: move a build Play already holds to this track — no build, no upload
uv run --script $P listing [--graphics]                  # the store listing alone, validate only
uv run --script $P listing [--graphics] --commit         # ONLY on the user's explicit go — §8a
```

1. **`status`** — the version codes on every track. `publish` refuses a `versionCode` not
   above the highest of them, but read it first: a surprise here stops the release.
2. **`publish` without `--commit`** — re-runs `verify_aab.sh`, uploads the bundle, sets the
   release `x.y.z (n)` on the track with the en-US and fr-FR notes (≤ 500 characters), the
   listing and graphics if asked, runs `edits.validate` — Google's full check — and deletes
   the edit. Free to run; report its output to the user.
3. **`--commit`** — only after the user's explicit go for *this* track: a commit publishes.
   Internal and closed releases go out `completed`; production goes out `inProgress` at
   `--rollout` (default `0.2`, always strictly between 0 and 1 — widening to 100 % is a later
   decision, in the Console). If Google answers that `changesNotSentForReview` must be set,
   the script prints it and stops: nothing was published, and the changes are sent for review
   from the Console.

4. **`--promote`** moves a build Play **already holds** to another track — the internal →
   production step. Play refuses a version code it has seen before, so a promotion references
   the build instead of re-uploading it: no `flutter build`, no bundle, and `verify_aab.sh` is
   not re-run (it passed when that build was published). It refuses a code that is on no track
   yet, and one that is already on the target track. Without it, a second `publish` of the same
   version is refused as "not above" the code sitting on internal — the release that is being
   promoted (`wip/done/2026-09-20-play-publish-cannot-promote.md`).

Order: **internal → closed (if required) → production at a staged percentage**, and watch
Crashes & ANRs for 48 h before widening.

## 8a. The store listing on its own

ASO work — a new title, a rewritten description, fresh screenshots, a translation — does
**not** need a version bump or a rebuilt bundle. `listing` is its own subcommand:

```bash
uv run --script $P listing              # every locale's text, validated, nothing published
uv run --script $P listing --graphics   # also the feature graphic and the phone screenshots
uv run --script $P listing --commit     # ONLY on the user's explicit go
```

It opens an edit, pushes `edits.listings().update()` per locale, replaces the images with
`--graphics`, runs `edits.validate` and then either commits (`--commit`) or deletes the edit.
It reads neither `pubspec.yaml` nor the bundle, and never touches a track — so nothing about a
release moves. The Console must still not be used for this: the listing is API-owned
(`references/play-console-handoff.md`, rule 2).

> **`listing --commit` has no staged rollout.** A `Listing` has no `userFraction`: the text
> and images go live for everyone, in every locale, as soon as Play accepts the edit. There is
> no 20 % equivalent and no halting it — the only way back is another `listing --commit` with
> the previous text. Say this to the user before asking for the go.

**Which locales.** There is no locale constant for the listing: `listing_locales()` reads
`store_listing/` and takes every directory holding a `title.txt`, `assets/` excluded, sorted.
Adding a language is creating its directory — the script does not change, and there is no
second list to drift from. Release notes are the other half and stay on `NOTES_LOCALES`
(§3).

```
store_listing/
  assets/                          # shared fallback: feature_graphic.png only
  <locale>/                        # a locale iff it holds title.txt
    title.txt  short_description.txt  full_description.txt
    video.txt                      # optional: a YouTube URL -> the Listing `video` field
    feature_graphic.png            # optional: overrides assets/feature_graphic.png
    raw/*.png                      # the locale's raw captures (scripts/capture_screenshots.sh)
    screenshot_captions.txt        # one caption per raw capture
    screenshots/phone/*.png        # required: the composed set, no fallback
    release_notes_v<x.y.z>.txt     # NOTES_LOCALES only (en-US, fr-FR)
```

- A per-locale **feature graphic** is opt-in: without one, the locale gets
  `assets/feature_graphic.png`. The **phone screenshots have no fallback**: `--graphics`
  uploads only `<locale>/screenshots/phone/` and refuses a locale without it, and the
  composer takes a locale's own `raw/` set only (the old shared captures were deleted
  2026-09-19). Compose each locale's set first, then check that none is missing, before any
  `--graphics`:
  `uv run --script scripts/compose_screenshots.py` then `... --check`
  (captions: `store_listing/<locale>/screenshot_captions.txt`; `.llmwiki/StoreListing.md`).
- The screenshot glob is **`*.png` only**. A JPEG in that directory is ignored in silence;
  convert it. Play's limit is **8 phone screenshots**, and the script refuses a ninth.
- `video.txt` absent means the `video` field is not sent at all, so Play keeps whatever is
  already there. It must hold an `http(s)` URL.

Tests (fake Google service, fake `adb` for `device_db_roundtrip.sh`; no network, no device):
`uv run --no-project --with pytest --with google-api-python-client --with google-auth pytest .claude/skills/release-android/scripts/`

### Play API access — first time only (the user does this)

1. **Google Cloud**: a project (new or existing) with **Google Play Android Developer API**
   enabled.
2. **Service account**: IAM → Service accounts → create `countscore-play-publisher` with **no
   GCP role**; Keys → add a **JSON** key and download it.
3. **On this machine**: move it to `~/.config/countscore/play-service-account.json`,
   `chmod 600` it, and add `playServiceAccount=<that absolute path>` to
   `android/key.properties` (the release worktree reaches that file through
   `scripts/worktree_setup.sh --release`'s link). **Back the key up like the keystore.** It never enters the repository: `.gitignore`
   has `*service-account*.json`, and the commit hook refuses any JSON holding
   `"type": "service_account"`.
4. **Play Console** → Users and permissions → invite the service account's e-mail, **limited
   to CountScore**, with *View app information*, *Release apps to testing tracks*, *Release
   to production*, *Manage store presence*. Propagation can take **up to 24 h**; until then
   `status` answers 401/403.

`status` listing the tracks proves the setup.

## 9. What the API cannot do — the Console brief

The API does not reach the content rating (IARC questionnaire), the App content
declarations, the Data Safety form review, app registration / developer verification, the
12-tester / 14-day closed-test requirement, or the **app category and store tags** (androidpublisher
has no endpoint for them — *Grow → Store presence → Store listing settings*). When one of
those needs attention — a change to what the app declares, a Console banner, the first
production release, an ASO pass that changes the category:

```bash
.claude/skills/release-android/scripts/stage_handoff.sh ["content rating, Data safety review"]
```

It creates `C:\Users\<you>\Downloads\countscore-console-<x.y.z+n>\` with `HANDOFF.md` (from
`references/play-console-handoff.md`), `PLAY_STORE_DATA_SAFETY.md` and `PUBLISHING.md` — no
bundle, no release notes. Hand it to **Claude Cowork** (grant the folder, "Read HANDOFF.md
and carry it out") or **Claude in Chrome** (paste it into the side panel). Part A surveys the
Console read-only (banners, registration, pending changes, production access, App content);
Part B does only the tasks named on the command line — compare, report, and save a
declaration only on the user's go. The agent never sends for review, accepts terms, or
touches signing, pricing, users or verification; the user handles sign-in and 2FA. Do not
relay the browser agent's questions yourself: give the user the folder, wait for the report.

**By hand.** `PUBLISHING.md` §3 and §5.

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
- Delete the Windows Console-brief folder, if §9 staged one.

## Icons — only if the artwork changed

The source is vector, in `design/icon/`, and `scripts/generate_icons.py` writes **every**
raster: the store icon, the two Android layers and the five web files. Never hand-edit a PNG.

```bash
uv run --script scripts/generate_icons.py --svg   # only if the artwork itself changed
uv run --script scripts/generate_icons.py         # every raster, from design/icon/*.svg
dart run flutter_launcher_icons                   # densities, colors.xml, ic_launcher.xml
```

`flutter_launcher_icons` emits **no web icons**: `web/icons/*.png` and `web/favicon.png` come
only from the first command, which is why they were the Flutter logo until 2026-09-20. Run it
even when only Android seems to be affected.

Adaptive icon on the artwork's ink `#0E1716`, with a monochrome layer and an 8 % foreground
inset; the favicon carries the "+1" alone, not the whole ensemble. The generator prints the
measured subject radius against each mask's limit — read that print, it is the check.
Requires `rsvg-convert` and Pillow. Full rationale: `.llmwiki/Release.md` §Icons.

## Checklist

- [ ] Built in a release worktree off `origin/main`, not in a shared checkout
- [ ] Version code above every track's; bump committed on `chore/release-<version>`
- [ ] Release notes en-US and fr-FR, ≤ 500 characters, no claim contradicting Data Safety
- [ ] Pruning pass (§3b) proposed to the user
- [ ] Policy gate (§4) passed, or its failures in `wip/todo/` and cleared by the user
- [ ] `flutter analyze` and `flutter test` clean; release APK installed clean on a device, an old database restored into it through Settings → Import (`device_db_roundtrip.sh pull`/`push`, §5)
- [ ] `verify_aab.sh` all OK
- [ ] No keystore, `key.properties`, `.env` or service-account key staged
- [ ] `play_publish.py status` read; `publish` without `--commit` validated
- [ ] `--commit` run only on the user's explicit go; production at a partial rollout
- [ ] Store listing text/graphics published through `listing` (never the Console), and the
      user told that `listing --commit` is live at once with no staged rollout
- [ ] Console-only tasks (content rating, declarations, Data Safety, category and tags) checked, through the brief if needed
- [ ] Tag pushed, `Release.md` Submission state updated, worktree and brief folder removed
- [ ] A `wip-refine` pass proposed to the user for the next release
- [ ] Keystore and service-account key backups exist and are current
