# Organic Farming Journal

An offline-first Flutter application for keeping everyday organic farm records. The project was built as a Flutter course project and works on Android and the Web without a backend or server account.

## Try the app

- **Web app:** [Open Organic Farming Journal](https://bhavyapagadala.github.io/organic_farming_journal/)
- **Android app:** Scan the QR code below with an Android phone to open the APK download/install page.

![QR code for the Android APK](android-apk-qr.png)

## What it does

- Create a local account and sign in on the current device or browser.
- Save a farm profile with its name, location, and area.
- Organize the farm with plots and crops.
- Record activities and observations in a journal.
- Add tasks and mark them complete.

## Offline storage

The app stores records locally. Android data stays on that Android device, while Web data stays in the browser’s local storage. The two copies do not sync. Clearing browser data or uninstalling the Android app may erase the records stored there. There is no cloud account, backend, or password-recovery service.

## Built with

- Flutter and Dart
- Riverpod for app state
- Sembast for local storage (browser IndexedDB on Web)
- Material 3 widgets

## Run from source

From the Flutter project folder:

```sh
flutter pub get
flutter run -d chrome
```

To run on Android, connect/select an Android device and run:

```sh
flutter run
```
