import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import 'ad_config.dart';

/// Owns consent, SDK initialization, and conservatively paced interstitials.
abstract final class AdService {
  static final ValueNotifier<bool> adsReady = ValueNotifier(false);
  static final ValueNotifier<bool> privacyOptionsRequired =
      ValueNotifier(false);
  static InterstitialAd? _interstitial;
  static bool _initializing = false;
  static bool _showingInterstitial = false;
  static int _completedCasesSinceInterstitial = 0;

  static Future<void> initialize() async {
    if (!AdConfig.isSupported || _initializing || adsReady.value) return;
    _initializing = true;

    final consentFinished = Completer<void>();
    ConsentInformation.instance.requestConsentInfoUpdate(
      ConsentRequestParameters(),
      () async {
        await ConsentForm.loadAndShowConsentFormIfRequired((_) {
          if (!consentFinished.isCompleted) consentFinished.complete();
        });
      },
      (_) {
        // A previous consent decision may still permit ads while offline.
        if (!consentFinished.isCompleted) consentFinished.complete();
      },
    );

    try {
      await consentFinished.future.timeout(const Duration(seconds: 12));
      final privacyStatus = await ConsentInformation.instance
          .getPrivacyOptionsRequirementStatus();
      privacyOptionsRequired.value =
          privacyStatus == PrivacyOptionsRequirementStatus.required;
      if (await ConsentInformation.instance.canRequestAds()) {
        await MobileAds.instance.initialize();
        adsReady.value = true;
        _loadInterstitial();
      }
    } catch (error) {
      debugPrint('AdMob initialization skipped: $error');
    } finally {
      _initializing = false;
    }
  }

  static Future<FormError?> showPrivacyOptions() async {
    if (!AdConfig.isSupported) return null;
    final completer = Completer<FormError?>();
    await ConsentForm.showPrivacyOptionsForm((error) {
      if (!completer.isCompleted) completer.complete(error);
    });
    return completer.future;
  }

  static void _loadInterstitial() {
    if (!adsReady.value || _interstitial != null) return;
    InterstitialAd.load(
      adUnitId: AdConfig.interstitialAdUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) => _interstitial = ad,
        onAdFailedToLoad: (error) {
          _interstitial = null;
          debugPrint('Interstitial failed to load: $error');
        },
      ),
    );
  }

  /// Shows at most one interstitial after every three solved cases, never in
  /// the middle of gameplay. Navigation always continues if no ad is ready.
  static void showAfterSolvedCase({required VoidCallback onComplete}) {
    _completedCasesSinceInterstitial++;
    if (_completedCasesSinceInterstitial < 3 ||
        _showingInterstitial ||
        _interstitial == null) {
      _loadInterstitial();
      onComplete();
      return;
    }

    final ad = _interstitial!;
    _interstitial = null;
    _showingInterstitial = true;
    _completedCasesSinceInterstitial = 0;

    var didComplete = false;
    void finish() {
      if (didComplete) return;
      didComplete = true;
      _showingInterstitial = false;
      _loadInterstitial();
      onComplete();
    }

    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        finish();
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        ad.dispose();
        finish();
      },
    );
    ad.show();
  }
}
