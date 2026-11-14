# Food Delivery Flutter App

This project is a Flutter mobile app for a food delivery platform. It includes login/register flows, restaurant browsing, meal selection, cart management, and order tracking. The app connects to a backend API over HTTPS and uses a token-based authentication flow.

## Project overview

- Flutter front-end for food ordering and restaurant browsing
- Login and registration pages
- Restaurant and meal listings
- Cart and checkout flow
- Order history and order note editing
- Multiple saved delivery locations, a selectable default location, and profile settings
- Admin-like restaurant/meal management screens
- Secure token storage for authenticated sessions

## Requirements

- Flutter SDK (Dart is included)
- Android Studio or Android command-line tools, Android SDK, and an Android emulator or connected device
- Java 17 or newer
- The API running on HTTPS port `7157`

This project currently expects the API host to be:

- Desktop / simulator: `https://localhost:7157`
- Android emulator: `https://10.0.2.2:7157`
- Physical Android device: set `API_HOST` to the computer's LAN address, for example `https://192.168.1.10:7157`

The API URL is configured in `lib/core/api_constants.dart`.

## One-time setup (Linux)

Install Flutter and Android Studio/Android SDK. Set the Android SDK path (adjust if yours differs), then accept the Android SDK licenses:

```bash
export ANDROID_HOME="$HOME/Android/Sdk"
export ANDROID_SDK_ROOT="$ANDROID_HOME"
export PATH="$PATH:$ANDROID_HOME/platform-tools"
flutter doctor
flutter doctor --android-licenses
```

Start an emulator in Android Studio's Device Manager, or list and start one from the command line:

```bash
flutter emulators
flutter emulators --launch <emulator_id>
flutter devices
```

## Install and run

From `FlutterFood`:

```bash
flutter pub get
flutter run
```

To select a specific emulator or device:

```bash
flutter run -d <device_id>
```

For a physical Android device on the same network as the API computer, pass the computer's reachable LAN address:

```bash
flutter run -d <device_id> --dart-define=API_HOST=https://<computer-lan-ip>:7157
```

Start the API first as described in [the backend README](../FoodDeleviry.Net/README.md). The default Android emulator API URL is `https://10.0.2.2:7157`; desktop and iOS simulator use `https://localhost:7157`. These URLs are defined in `lib/core/api_constants.dart`.

## Notes

- Local self-signed HTTPS certificates are accepted in debug mode only.
- Token storage is handled with secure storage, so users remain logged in between app restarts.
- Android emulator's `10.0.2.2` address refers to the host computer. A physical phone needs a reachable host address and matching API configuration.
- Customers can manage multiple saved delivery locations from **Profile → Saved locations**, mark one as the default, and choose a saved location at checkout. New checkout addresses can also be saved to the profile.
- Profile settings support updating the account username and password.

## Useful commands

```bash
flutter clean
flutter pub get
flutter analyze
flutter test
```
