# Mercer — Full-stack Flutter shop

Flutter client and a Dart REST API. The app covers sign-in, search, cart, favorites, checkout, orders, profile, a store map, and explicit loading, offline, and server-error states.

## Stack

- Flutter, GetX, Dio
- SQLite on mobile and desktop, SharedPreferences on the web
- Shelf API for products, cart, favorites, addresses, test payments, and orders
- Firebase Auth and Firestore when a Firebase project is configured
- Geolocator, with Google Maps tiles behind `USE_GOOGLE_MAPS`
- Local notifications when an order is placed

## Run the API

```bash
cd server
dart pub get
dart run bin/server.dart
```

The API listens on `http://127.0.0.1:8080`.

Demo account: `ada@mercer.shop` / `mercer123`

Stripe test card: `4242424242424242`. Decline card: `4000000000000002`.
PayPal sandbox: `buyer@mercer.test` / `sandbox`.

## Run the app

```bash
flutter pub get
flutter run --dart-define=API_BASE=http://127.0.0.1:8080
```

Android emulators should use `http://10.0.2.2:8080`.

To draw Google Maps tiles, pass `--dart-define=USE_GOOGLE_MAPS=true` and add a Maps key in the platform config. Without that flag the store screen still plots locations and can use device location.

## Firebase

```bash
dart pub global activate flutterfire_cli
flutterfire configure
```

Without that config the app still runs. Orders stay on the API and in the local database.

## Checks

```bash
flutter analyze
flutter test
cd server && dart test
```
