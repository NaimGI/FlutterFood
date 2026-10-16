# Food Delivery Flutter App

This project is a Flutter mobile app for a food delivery platform. It includes login/register flows, restaurant browsing, meal selection, cart management, and order tracking. The app connects to a backend API over HTTPS and uses a token-based authentication flow.

## Project overview

- Flutter front-end for food ordering and restaurant browsing
- Login and registration pages
- Restaurant and meal listings
- Cart and checkout flow
- Order history and order note editing
- Admin-like restaurant/meal management screens
- Secure token storage for authenticated sessions

## Prerequisites

Before you start, make sure you have:

- Flutter SDK installed and available on your PATH
- Dart SDK (included with Flutter)
- A supported device or emulator:
  - Android emulator / physical Android device
  - iOS simulator (macOS only)
  - Chrome for web testing
- The backend API running on HTTPS port 7157

This project currently expects the API host to be:

- Desktop / simulator: `https://localhost:7157`
- Android emulator: `https://10.66.206.8:7157`

The API URL is configured in `lib/core/api_constants.dart`.

## Install dependencies

From the project root:

```bash
flutter pub get
```

## Run the app

### On a connected device or emulator

```bash
flutter run
```

### On Chrome

```bash
flutter run -d chrome
```

### On a specific device

```bash
flutter devices
flutter run -d <device_id>
```

## Backend requirement

This app talks to an ASP.NET backend API over HTTPS and uses a self-signed certificate on port 7157 for local development. The app includes a debug override in `lib/main.dart` to accept that certificate while running locally.

If your backend is running on a different machine or different local URL, update the `host` value in `lib/core/api_constants.dart`.

Example:

```dart
static String get host {
  if (Platform.isAndroid) return 'https://10.0.2.2:7157';
  return 'https://localhost:7157';
}
```

For Android emulator, `10.0.2.2` is usually the correct host when the backend is running on the same machine as the emulator.

## Common startup checklist

1. Install Flutter and confirm it works:
   ```bash
   flutter doctor
   ```
2. Install project dependencies:
   ```bash
   flutter pub get
   ```
3. Start the backend API on HTTPS port 7157.
4. Launch the app:
   ```bash
   flutter run
   ```

## Notes

- This app currently accepts the local self-signed HTTPS certificate in debug mode only.
- Token storage is handled with secure storage, so users remain logged in between app restarts.
- If you see login or API connection issues, confirm that the backend is running and that the API host in `lib/core/api_constants.dart` matches your environment.

## Useful commands

```bash
flutter clean
flutter pub get
flutter analyze
flutter test
```
