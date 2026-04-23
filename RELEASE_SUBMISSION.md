# Android Release Submission

## Build status

- Version: `1.2.1+4`
- Signed bundle output: `build/app/outputs/bundle/release/app-release.aab`
- Local signing config: `android/key.properties`
- Local upload keystore: `android/upload-keystore.jks`

## Completed in this repo

- Android release signing wired in `android/app/build.gradle.kts`
- `pubspec.yaml` version bumped for the next Play upload
- Local signing files excluded from git in `.gitignore`
- Release-safe debug logging added so development logs do not print in release builds
- `flutter analyze` passes
- `flutter test` passes
- `flutter build appbundle` passes

## Before uploading to Google Play

1. Back up `android/upload-keystore.jks` and `android/key.properties` in a secure password manager or vault.
2. Confirm your Play Console app listing:
   - app title
   - short description
   - full description
   - screenshots
   - 512x512 app icon
   - feature graphic
3. Complete Play Console policy sections:
   - App content
   - Data safety
   - Ads declaration
   - Privacy policy URL
4. Upload `build/app/outputs/bundle/release/app-release.aab` to the production or internal testing track.
5. Increase the version again before the next Play upload.
