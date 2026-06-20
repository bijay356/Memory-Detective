import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../ads/ad_config.dart';
import '../ads/ad_service.dart';

/// An anchored adaptive banner that stays hidden until an ad is loaded.
class AdBannerPlaceholder extends StatefulWidget {
  const AdBannerPlaceholder({super.key});

  @override
  State<AdBannerPlaceholder> createState() => _AdBannerPlaceholderState();
}

class _AdBannerPlaceholderState extends State<AdBannerPlaceholder> {
  BannerAd? _banner;
  bool _isLoaded = false;
  int? _lastWidth;

  @override
  void initState() {
    super.initState();
    AdService.adsReady.addListener(_onAdsReady);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadForCurrentWidth();
  }

  void _onAdsReady() => _loadForCurrentWidth();

  Future<void> _loadForCurrentWidth() async {
    if (!mounted || !AdConfig.isSupported || !AdService.adsReady.value) return;
    final width = MediaQuery.sizeOf(context).width.truncate();
    if (width <= 0 || (_lastWidth == width && _banner != null)) return;
    _lastWidth = width;

    final oldBanner = _banner;
    _banner = null;
    _isLoaded = false;
    await oldBanner?.dispose();

    final size = await AdSize.getLargeAnchoredAdaptiveBannerAdSize(width);
    if (!mounted || size == null) return;

    final banner = BannerAd(
      adUnitId: AdConfig.bannerAdUnitId,
      size: size,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          if (!mounted) {
            ad.dispose();
            return;
          }
          setState(() {
            _banner = ad as BannerAd;
            _isLoaded = true;
          });
        },
        onAdFailedToLoad: (ad, _) {
          ad.dispose();
          if (mounted) setState(() => _isLoaded = false);
        },
      ),
    );
    _banner = banner;
    await banner.load();
  }

  @override
  Widget build(BuildContext context) {
    final banner = _banner;
    if (!_isLoaded || banner == null) return const SizedBox.shrink();
    return ColoredBox(
      color: Colors.black,
      child: Center(
        child: SizedBox(
          width: banner.size.width.toDouble(),
          height: banner.size.height.toDouble(),
          child: AdWidget(ad: banner),
        ),
      ),
    );
  }

  @override
  void dispose() {
    AdService.adsReady.removeListener(_onAdsReady);
    _banner?.dispose();
    super.dispose();
  }
}
