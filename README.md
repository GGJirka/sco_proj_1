# Reverse Engineering Demo Flutter App

This project provides a Flutter application that demonstrates common mobile
security anti-patterns alongside a hardened build flavor for classroom reverse
engineering, instrumentation, and binary protection exercises.

## Project Overview

The application integrates Firebase Authentication, Firestore, Cloud Functions,
and App Check. State is managed exclusively with stateful widgets and
services are exposed via the `get_it` service locator. Two build flavors are
available:

- **Baseline**: intentionally insecure to showcase weak storage, networking,
  and configuration practices.
- **Hardened**: introduces secure storage, certificate pinning, jailbreak/root
  detection, and App Check enforcement.

## Firebase Setup

1. Install the Firebase CLI and FlutterFire CLI.
2. Run `flutterfire configure` to generate `lib/firebase_options.dart` for your
   Firebase project.
3. Update the Android `applicationId` if required before configuration.

### Firestore

Create a `users` collection where each document is the authenticated user UID:

```
users/{uid} {
  balance: <number>,
  updatedAt: <server timestamp>
}
```

Seed balances manually or via the Firebase console to observe the real-time
stream on the home screen.

### Cloud Function

Deploy the included mock function:

```
cd functions
npm install
firebase deploy --only functions:getPremiumReport
```

The function returns the static JSON payload specified in the project brief.

### App Check (Hardened Flavor)

1. Enable App Check for Firestore and Cloud Functions in the Firebase console.
2. Register a debug or production provider (e.g. Play Integrity) for your app.
3. Supply any required debug tokens to your test device.

The hardened build retrieves App Check tokens and attaches them as
`X-Firebase-AppCheck` headers to outbound API calls.

## Running the Application

Install Flutter and run the appropriate flavor:

```bash
# Baseline build (intentionally insecure)
flutter run --dart-define=BUILD_FLAVOR=baseline

# Hardened build with obfuscation and pinned networking
flutter build apk --release --dart-define=BUILD_FLAVOR=hardened --obfuscate --split-debug-info=debug/
```

To test the hardened flavor in debug mode without obfuscation:

```
flutter run --dart-define=BUILD_FLAVOR=hardened
```

## Intentional Vulnerabilities (Baseline Flavor)

- **Hardcoded secrets**: fake API keys, feature flags, and endpoints reside in
  plain Dart code for static analysis exercises.
- **Insecure storage**: shared preferences store Firebase ID tokens, last login
  email, and a `localSecret` string without encryption.
- **Weak networking**: TLS pinning and App Check are disabled and every request
  sends `X-Debug: enabled` headers to simplify traffic interception.
- **No obfuscation**: release builds omit symbol obfuscation for easier
  decompilation.

## Hardened Enhancements

- **Secure storage**: all sensitive values use `flutter_secure_storage` backed by
  the Android Keystore.
- **Certificate pinning**: outbound HTTPS calls validate the server public key
  hash before using the response.
- **Root/jailbreak detection**: the UI downgrades to a limited state whenever
  known binaries or writable system directories are detected.
- **Firebase App Check**: tokens are requested and attached to Firestore and
  Cloud Functions traffic.
- **Obfuscation workflow**: production builds use
  `--obfuscate --split-debug-info=debug/` to harden binaries.

## Directory Layout

```
lib/
  app.dart
  main.dart
  features/
    auth/
      login_page.dart
      register_page.dart
    home/
      home_page.dart
  services/
      api_service.dart
      firebase_service.dart
      security_service.dart
      service_locator.dart
      storage_service.dart
assets/
  config/mock_config.json
functions/
  index.js
```

This structure keeps intentionally vulnerable components separate from the
hardened alternatives, simplifying classroom walkthroughs.
