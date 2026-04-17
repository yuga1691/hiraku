import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class RewardedAdService {
  // Keep using test ads until production AdMob setup is complete.
  // Set this to false before releasing to production.
  static const bool _forceTestAds = true;

  Future<bool> showBoostRewardedAd({bool? forceTestMode}) async {
    final useTestMode = forceTestMode ?? _forceTestAds || !kReleaseMode;
    final adUnitId = _AdMobIds.rewardedAdUnitId(useTestMode: useTestMode);
    if (adUnitId == null) {
      return false;
    }

    final completer = Completer<bool>();
    bool rewardEarned = false;

    try {
      RewardedAd.load(
        adUnitId: adUnitId,
        request: const AdRequest(),
        rewardedAdLoadCallback: RewardedAdLoadCallback(
          onAdLoaded: (ad) {
            ad.fullScreenContentCallback = FullScreenContentCallback(
              onAdDismissedFullScreenContent: (ad) {
                ad.dispose();
                if (!completer.isCompleted) {
                  completer.complete(rewardEarned);
                }
              },
              onAdFailedToShowFullScreenContent: (ad, error) {
                ad.dispose();
                debugPrint('RewardedAd failed to show: $error');
                if (!completer.isCompleted) {
                  completer.complete(false);
                }
              },
            );
            ad.show(
              onUserEarnedReward: (_, __) {
                rewardEarned = true;
              },
            );
          },
          onAdFailedToLoad: (error) {
            debugPrint('RewardedAd failed to load: $error');
            if (!completer.isCompleted) {
              completer.complete(false);
            }
          },
        ),
      );

      return completer.future.timeout(
        const Duration(minutes: 2),
        onTimeout: () => false,
      );
    } catch (e, st) {
      debugPrint('RewardedAd error: $e');
      debugPrint('$st');
      if (!completer.isCompleted) {
        completer.complete(false);
      }
      return false;
    }
  }
}

class _AdMobIds {
  static const String _androidRewardedProd =
      'ca-app-pub-2825080143851134/2080034317';

  static const String _androidRewardedTest =
      'ca-app-pub-3940256099942544/5224354917';

  static const String _iosRewardedTest =
      'ca-app-pub-3940256099942544/1712485313';

  static String? rewardedAdUnitId({required bool useTestMode}) {
    if (kIsWeb) return null;

    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return useTestMode ? _androidRewardedTest : _androidRewardedProd;
      case TargetPlatform.iOS:
        return _iosRewardedTest;
      default:
        return null;
    }
  }
}
