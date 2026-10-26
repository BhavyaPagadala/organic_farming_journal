# Organic Farming Journal

An offline-first Flutter course project for recording farm details, crops, plots, journal activities, and tasks. It uses on-device storage and does not require a backend or account on a server.

## Platforms

- Android: records are saved in the app's local documents folder.
- Web: records are saved in the browser's IndexedDB storage for this site and browser profile.

Android and Web keep separate local copies. They do not sync with each other. Clearing browser data can erase the Web copy; uninstalling the Android app can erase its copy.

## Run locally

1. Install Flutter and a supported Dart SDK.
2. Run `flutter pub get`.
3. Run `flutter run -d chrome` for Web, or select an Android device for Android.

The Web build uses Sembast on IndexedDB, so it does not need the SQLite WASM or service worker files used by the old Web database setup.

## FlutLab

Upload the project ZIP, let FlutLab resolve the packages, then run the Web target or build the Android APK. Build a new APK from this project after importing it; the previously created APK still contains the earlier version.
