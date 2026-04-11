import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class BannerAdWidget extends StatefulWidget {
  const BannerAdWidget({
    super.key,
    this.forceTestMode,
    this.showFallbackPlaceholder = true,
  });

  // null: debug/profile=テスト広告, release=本番広告
  final bool? forceTestMode;
  // 広告未ロード時に高さを維持してプレースホルダー表示する
  final bool showFallbackPlaceholder;

  @override
  State<BannerAdWidget> createState() => _BannerAdWidgetState();
}

class _BannerAdWidgetState extends State<BannerAdWidget> {
  static const double _fallbackHeight = 50;

  BannerAd? _bannerAd;
  bool _isLoaded = false;

  bool get _useTestMode => widget.forceTestMode ?? !kReleaseMode;

  @override
  void initState() {
    super.initState();
    _createAndLoadBanner();
  }

  void _createAndLoadBanner() {
    try {
      final adUnitId = _AdMobIds.bannerAdUnitId(useTestMode: _useTestMode);
      if (adUnitId == null) {
        _isLoaded = false;
        return;
      }

      final ad = BannerAd(
        size: AdSize.banner,
        adUnitId: adUnitId,
        request: const AdRequest(),
        listener: BannerAdListener(
          onAdLoaded: (loadedAd) {
            if (!mounted || loadedAd != _bannerAd) return;
            setState(() {
              _isLoaded = true;
            });
          },
          onAdFailedToLoad: (failedAd, error) {
            failedAd.dispose();
            if (!mounted || failedAd != _bannerAd) return;
            debugPrint('BannerAd failed to load: $error');
            setState(() {
              _isLoaded = false;
              _bannerAd = null;
            });
          },
        ),
      );

      _bannerAd = ad;
      _bannerAd?.load();
    } catch (e, st) {
      debugPrint('BannerAd create/load error: $e');
      debugPrint('$st');
      _isLoaded = false;
      _bannerAd = null;
    }
  }

  @override
  void dispose() {
    try {
      _bannerAd?.dispose();
    } catch (e) {
      debugPrint('BannerAd dispose error: $e');
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bannerAd = _bannerAd;
    if (!_isLoaded || bannerAd == null) {
      if (!widget.showFallbackPlaceholder) {
        return const SizedBox.shrink();
      }
      return SafeArea(
        top: false,
        bottom: false,
        child: Container(
          width: double.infinity,
          height: _fallbackHeight,
          alignment: Alignment.center,
          color: Colors.grey.shade300,
          child: const Text('広告を読み込み中...'),
        ),
      );
    }

    try {
      return SafeArea(
        top: false,
        bottom: false,
        child: Container(
          alignment: Alignment.center,
          width: bannerAd.size.width.toDouble(),
          height: bannerAd.size.height.toDouble(),
          child: AdWidget(ad: bannerAd),
        ),
      );
    } catch (e) {
      debugPrint('BannerAd build error: $e');
      return const SizedBox.shrink();
    }
  }
}

class _AdMobIds {
  static const String _androidBannerProd =
      'ca-app-pub-2825080143851134/1327603730';

  static const String _androidBannerTest =
      'ca-app-pub-3940256099942544/6300978111';

  static const String _iosBannerTest =
      'ca-app-pub-3940256099942544/2934735716';

  static String? bannerAdUnitId({required bool useTestMode}) {
    if (kIsWeb) return null;

    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return useTestMode ? _androidBannerTest : _androidBannerProd;
      case TargetPlatform.iOS:
        return _iosBannerTest;
      default:
        return null;
    }
  }
}
