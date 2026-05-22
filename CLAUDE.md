# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Commands

```bash
# Install dependencies
flutter pub get

# iOS dependencies (macOS only)
cd ios && pod install && cd ..

# Run the app
flutter run

# Static analysis
flutter analyze

# Run tests
flutter test

# Run specific test
flutter test test/app_logger_test.dart

# Build release bundle (Android)
flutter build appbundle --release

# Build release (iOS, macOS only)
flutter build ios --release
```

## Architecture

**State Management:** Provider pattern with 5 core providers:
- `AuthProvider` - Firebase authentication (Google + email/password)
- `ThemeProvider` - Light/dark mode
- `SermonProvider` - Sermon/series/pastor data from Firestore
- `AudioProvider` - just_audio playback controller (synced with SermonProvider)
- `FavoritesProvider` - User favorites (synced with SermonProvider)

**Directory Structure:**
- `lib/models/` - Data models (Sermon, Episode, Pastor, User)
- `lib/providers/` - State management providers
- `lib/screens/` - Full screens (listener + admin subtrees)
- `lib/services/` - Business logic (audio, storage, connectivity, push notifications)
- `lib/widgets/` - Reusable UI components
- `lib/utils/` - Helpers (colors, constants, logger, dialogs)

**Firebase Integration:**
- Auth: `firebase_auth` with Google Sign-In
- Database: `cloud_firestore` with offline persistence enabled
- Storage: `firebase_storage` for sermon audio/images
- Messaging: `firebase_messaging` for push notifications (topic: `new_sermons`)

**Audio System:**
- `just_audio` + `just_audio_background` for foreground/background playback
- Media notifications and lock screen controls configured
- Playback state persists across app sessions

**Dual Experience:**
- `AuthRoot` routes to `MainApp` (listeners) or `AdminMainScreen` (admins) based on user role from Firestore

## Release Info

- Version: 1.2.1+4
- Android package: `com.rhemalize.app`
- iOS bundle: `com.example.rhemalizeChurchAudioAppV2` (update for production)
- Signing: Local keystore via `android/key.properties` (not in git)
