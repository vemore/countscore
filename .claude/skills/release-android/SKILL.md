---
name: release-android
description: Build and publish a CountScore release to the Google Play Store — keystore setup, signed App Bundle, launcher icons, store assets, and the pre-submission checklist. Use when preparing a release, cutting a new version, building a signed AAB or APK, regenerating the app icon, or verifying an artifact's signature. Triggers: "build a release", "publier sur le Play Store", "release build", "appbundle", "sign the app", "keystore", "new version", "bump version".
---

# Releasing CountScore to the Play Store

The full narrative guide is `PUBLISHING.md`. This is the executable path. State facts are
in `.llmwiki/Release.md`.

## Before anything

`--no-tree-shake-icons` is **mandatory on every build**. Game-type icons are built from
`IconData` codepoints stored in the database, so the tree-shaker cannot see them and the
build fails without the flag. It costs ~200 KB.

## 1. Signing setup — first time only

```bash
./scripts/generate_keystore.sh
cp android/key.properties.template android/key.properties
# fill in storePassword, keyPassword, keyAlias, storeFile
```

**Back the keystore up somewhere durable and off this machine. Losing it means the app can
never be updated again** — Play will not accept a differently-signed upload.

Neither the keystore nor `key.properties` may be committed. Confirm before every release:

```bash
git check-ignore -v android/key.properties && echo "ignored — good"
git status --porcelain | grep -Ei 'keystore|\.jks|key\.properties' && echo "STOP: staged secret"
```

Release signing is already configured in `android/app/build.gradle.kts`. R8/ProGuard is
disabled on purpose — the app is open source.

## 2. Version bump

Bump `version:` in `pubspec.yaml` (`x.y.z+build`). The build number must **increase** on
every upload or Play rejects it.

## 3. Icons — only if the artwork changed

```bash
# replace store_listing/assets/icon_512.png (512x512 PNG) first
flutter pub run flutter_launcher_icons
```
Adaptive icon on white `#FFFFFF`; all densities are generated.

## 4. Pre-flight

```bash
flutter clean
flutter pub get
dart run build_runner build --delete-conflicting-outputs   # *.g.dart is gitignored
flutter gen-l10n
flutter analyze
flutter test
```

Then test on a real device — the `flutter-device-test` skill. **Export/import and the
wakelock toggle have no automated coverage**; they must be exercised by hand.

## 5. Build

```bash
flutter build appbundle --release --no-tree-shake-icons
# → build/app/outputs/bundle/release/app-release.aab
```

An APK for sideload testing:
```bash
flutter build apk --release --no-tree-shake-icons
```

## 6. Verify the artifact

```bash
ls -la build/app/outputs/bundle/release/app-release.aab
jarsigner -verify -verbose -certs build/app/outputs/bundle/release/app-release.aab | head -20
```
Confirm the certificate is the upload key and **not** a debug key. Install the release APK
on a device and check it launches, the database survives an upgrade from the store version,
and the locale follows the system language.

## 7. Play Console

Target **API level 35** (Android 15). Compliance documents that must match what ships:
`privacy_policy.md`, `PLAY_STORE_DATA_SAFETY.md`, `THIRD_PARTY_LICENSES.md`.
Store assets are in `store_listing/`; `scripts/capture_screenshots.sh` pulls fresh
screenshots over ADB.

Roll out to internal testing first, then staged production.

## Blocker to check every time

**`PUBLISHING.md` predates the backend.** If the release ships group sharing or LLM
commentary, the Data Safety declaration must be updated first to disclose the network calls
and what is sent — see `.llmwiki/Security.md`. Do not submit such a release against the
current declaration.

## Checklist

- [ ] Version and build number bumped
- [ ] `flutter analyze` and `flutter test` clean
- [ ] Tested on a real device, including export/import and wakelock
- [ ] Built with `--no-tree-shake-icons`
- [ ] Signature verified as the upload key
- [ ] No keystore, `key.properties` or `.env` staged
- [ ] Data Safety declaration matches what the build actually does
- [ ] Keystore backup exists and is current
