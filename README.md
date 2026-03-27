# Rhemalize

Rhemalize is a Flutter-based church audio app built for discovering, streaming, and managing sermon content across mobile and web. It combines a polished listener experience with an admin workflow for uploading sermons, organizing series, and managing ministry content from Firebase-backed services.

## Highlights

- Google and email authentication with Firebase Auth
- Sermon streaming with background playback support
- Continue listening and listening history
- Favorites and personal library
- Search and browse flows for sermon discovery
- Admin tools for uploading single messages and series
- Firestore-powered content and user data
- Firebase Storage for hosted audio files and media assets

## Tech Stack

- Flutter
- Provider
- Firebase Auth
- Cloud Firestore
- Firebase Storage
- Firebase Messaging
- just_audio
- shared_preferences

## Project Structure

```text
lib/
  models/        Data models for sermons, users, pastors, and episodes
  providers/     App state, auth, audio, favorites, and sermon data
  screens/       Listener and admin UI screens
  services/      Storage, connectivity, and audio helpers
  widgets/       Reusable UI components and modals
assets/
  images/        App artwork and ministry images
  audio/         Bundled audio assets
```

## Getting Started

### Prerequisites

- Flutter SDK 3.x
- Dart SDK 3.x
- Firebase project configured for the target platforms
- Android Studio or VS Code with Flutter tooling

### Install

```bash
flutter pub get
```

### Configure Firebase

1. Create or select a Firebase project.
2. Enable Authentication, Firestore, Storage, and Messaging.
3. Add Android, iOS, and Web apps in Firebase.
4. Generate the FlutterFire config for this project.
5. Confirm `lib/firebase_options.dart` matches your Firebase project.

### Run the App

```bash
flutter run
```

### Analyze the Codebase

```bash
flutter analyze
```

## Core Features

### Listener Experience

- Sign in with Google or email/password
- Browse recent sermons and featured content
- Search sermons and series
- Save favorites
- Resume playback from the last saved position
- Keep listening history in the library until it is cleared manually

### Admin Experience

- Upload one-time messages
- Upload and manage sermon series
- Manage pastors and user-related content
- Review ministry content from dedicated admin screens

## Firebase Notes

This app depends heavily on Firebase services. Before production release, verify:

- Authentication providers are enabled
- Firestore security rules are production-ready
- Storage rules restrict uploads appropriately
- Cloud Messaging is configured for supported platforms
- All production package names, SHA certificates, and OAuth client IDs are correct

## Play Store Readiness Checklist

Before uploading to Google Play Console, make sure the following are complete:

- Update the app `version` and build number in `pubspec.yaml`
- Confirm the Android application ID and signing config
- Replace placeholder graphics with final launcher icon, feature graphic, and screenshots
- Test Google Sign-In in release mode with production SHA-1 and SHA-256 fingerprints
- Review privacy policy and data safety disclosures
- Verify audio playback, login, search, favorites, and library flows on a physical Android device
- Verify Firebase rules for production access control
- Remove debug logging that should not ship to production
- Build and test an Android App Bundle:

```bash
flutter build appbundle --release
```

## Recommended Next Steps

- Add widget and integration tests for auth, playback, and library persistence
- Sweep deprecated Flutter API usage such as `withOpacity`
- Replace deprecated sharing calls with the current `share_plus` API
- Do a final QA pass on admin flows and release-mode authentication

## Status

The app is close to releaseable, but it still benefits from one more stabilization pass focused on cleanup, release QA, and Play Store submission assets.
