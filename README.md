# Memory Detective

## AdMob setup

The app includes an adaptive banner on the home screen, a conservatively paced
interstitial after every three solved cases, and Google's UMP consent flow.
Android release builds use the configured live banner and interstitial IDs.
Debug builds always use Google's official test IDs to keep development traffic
policy-safe. The rewarded unit ID is configured in `lib/ads/ad_config.dart` and
is ready to be connected to a future opt-in reward action.

Before publishing:

1. The Android production App ID and live unit IDs are configured. For iOS,
   replace the sample `GADApplicationIdentifier` in `ios/Runner/Info.plist`.
2. Android unit IDs can optionally be
   overridden for a release build:

```powershell
flutter build appbundle --release `
  --dart-define=ADMOB_ANDROID_BANNER_ID=ca-app-pub-XXXX/YYYY `
  --dart-define=ADMOB_ANDROID_INTERSTITIAL_ID=ca-app-pub-XXXX/ZZZZ `
  --dart-define=ADMOB_ANDROID_REWARDED_ID=ca-app-pub-XXXX/WWWW
```

Use the equivalent `ADMOB_IOS_BANNER_ID` and
`ADMOB_IOS_INTERSTITIAL_ID` defines when building iOS. Never click your own
live ads; keep the defaults while developing.

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Learn Flutter](https://docs.flutter.dev/get-started/learn-flutter)
- [Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Flutter learning resources](https://docs.flutter.dev/reference/learning-resources)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.
