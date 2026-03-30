# Rhemalize

Rhemalize is a Flutter sermon streaming app for listening, discovering, and managing church audio content across listener and admin experiences. The app combines a polished playback flow with Firebase-backed content management, user auth, search, favorites, listening history, and ministry administration tools.

## Product Overview

- Listener home, discovery, search, favorites, library, and playback flows
- Background sermon playback with continue listening support
- Account-aware listening history and playback persistence
- Google sign-in and email authentication with Firebase
- Admin tools for sermon uploads, series management, pastors, users, dashboard, analytics, and settings
- Firebase-backed content, storage, and push-notification plumbing

## Tech Stack

- Flutter
- Provider
- Firebase Auth
- Cloud Firestore
- Firebase Storage
- Firebase Messaging
- just_audio
- just_audio_background
- shared_preferences

## Project Structure

```text
lib/
  models/        Sermons, users, pastors, and episode models
  providers/     Auth, audio, favorites, theme, and sermon state
  screens/       Listener and admin screens
  services/      Audio, storage, connectivity, and notification helpers
  widgets/       Shared UI widgets, cards, and modals
assets/
  images/        Logos, artwork, and ministry photos
  audio/         Bundled audio assets
android/         Android release and manifest configuration
ios/             iOS runner, workspace, and platform configuration
```

## Local Setup

### Requirements

- Flutter SDK 3.x
- Dart SDK 3.x
- Firebase project with Auth, Firestore, Storage, and Messaging enabled
- Android Studio or VS Code with Flutter tooling
- CocoaPods installed for iOS builds

### Install Dependencies

```bash
flutter pub get
```

### iOS Dependencies

```bash
cd ios
pod install
cd ..
```

### Run The App

```bash
flutter run
```

### Static Analysis

```bash
flutter analyze
```

## Firebase Configuration

Rhemalize uses generated FlutterFire options at `lib/firebase_options.dart`. Before release, confirm that each platform registered in Firebase matches the real production app identifiers.

- Android app ID should match `com.rhemalize.app`
- iOS app registration should match the final production bundle identifier
- Google Sign-In OAuth clients should be created for every release platform
- Release SHA-1 and SHA-256 certificates should be added in Firebase for Android Google Sign-In
- APNs key or certificate should be configured for iOS messaging

## Release Readiness

### Play Store

- Update store listing copy, screenshots, feature graphic, and privacy policy
- Build and test a signed App Bundle
- Verify Firebase Auth, playback, search, library, favorites, and admin flows on a physical Android device
- Confirm notification behavior on Android 13+ with `POST_NOTIFICATIONS`
- Review Data Safety disclosures for auth, analytics, and notifications

```bash
flutter build appbundle --release
```

### App Store

- Finalize the production iOS bundle identifier in Apple Developer and Firebase
- Re-run FlutterFire config if the iOS bundle identifier changes
- Install CocoaPods dependencies and build on a macOS machine with Xcode
- Verify Google Sign-In callback handling, background audio, and push notifications
- Complete App Privacy answers, screenshots, and age rating in App Store Connect

```bash
flutter build ios --release
```

## QA Checklist

- Sign in with Google and email/password
- Confirm the profile avatar and account metadata load correctly
- Play a sermon, close the app, and confirm resume playback works
- Confirm library history survives logout and only clears manually
- Verify admin playback does not pollute user history or analytics
- Upload and edit sermons, episodes, series, pastors, and user-facing content from the admin area
- Review dashboard, analytics, and settings in admin on real data

## Status

The codebase is analyzer-clean and in a much stronger release state. The remaining production-critical work is mostly external release setup: final store assets, Apple/Firebase production identifiers, signing, and device QA.
