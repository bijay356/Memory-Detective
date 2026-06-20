import 'dart:io';

import 'package:flutter/foundation.dart';

/// AdMob unit IDs. Debug builds always use Google's test inventory so local
/// development can never create invalid traffic on the live account.
abstract final class AdConfig {
  static bool get isSupported =>
      !kIsWeb && (Platform.isAndroid || Platform.isIOS);

  static String get bannerAdUnitId => Platform.isAndroid
      ? (kReleaseMode
          ? const String.fromEnvironment(
              'ADMOB_ANDROID_BANNER_ID',
              defaultValue: 'ca-app-pub-9880203585326296/9132215132',
            )
          : 'ca-app-pub-3940256099942544/9214589741')
      : const String.fromEnvironment(
          'ADMOB_IOS_BANNER_ID',
          defaultValue: 'ca-app-pub-3940256099942544/2435281174',
        );

  static String get interstitialAdUnitId => Platform.isAndroid
      ? (kReleaseMode
          ? const String.fromEnvironment(
              'ADMOB_ANDROID_INTERSTITIAL_ID',
              defaultValue: 'ca-app-pub-9880203585326296/2504483216',
            )
          : 'ca-app-pub-3940256099942544/1033173712')
      : const String.fromEnvironment(
          'ADMOB_IOS_INTERSTITIAL_ID',
          defaultValue: 'ca-app-pub-3940256099942544/4411468910',
        );

  static String get rewardedAdUnitId => Platform.isAndroid
      ? (kReleaseMode
          ? const String.fromEnvironment(
              'ADMOB_ANDROID_REWARDED_ID',
              defaultValue: 'ca-app-pub-9880203585326296/5074806231',
            )
          : 'ca-app-pub-3940256099942544/5224354917')
      : const String.fromEnvironment(
          'ADMOB_IOS_REWARDED_ID',
          defaultValue: 'ca-app-pub-3940256099942544/1712485313',
        );
}
