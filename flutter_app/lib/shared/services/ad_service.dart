import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class AdService {
  static final AdService _instance = AdService._internal();
  factory AdService() => _instance;
  AdService._internal();

  RewardedAd? _rewardedAd;
  bool _isLoading = false;
  static bool _isSupported = false;

  static String get _androidRewardedAdUnitId => kDebugMode
    ? 'ca-app-pub-3940256099942544/5224354917' // ID de test
    : 'ca-app-pub-6743392628237404/2396801579'; // Ton vrai ID prod

  static String get _iosRewardedAdUnitId => kDebugMode
    ? 'ca-app-pub-3940256099942544/1712485313' // ID de test
    // TODO : Ton vrai ID prod iOS (à remplacer si tu publies sur iOS)
    : 'ca-app-pub-6743392628237404/2396801579';

  String get _rewardedAdUnitId {
    if (defaultTargetPlatform == TargetPlatform.android) {
      return _androidRewardedAdUnitId;
    } else {
      return _iosRewardedAdUnitId;
    }
  }

  static bool get _isMobilePlatform =>
      defaultTargetPlatform == TargetPlatform.android ||
      defaultTargetPlatform == TargetPlatform.iOS;

  static Future<void> initialize() async {
    if (!_isMobilePlatform) {
      debugPrint('[AdService] Ads not supported on this platform');
      return;
    }
    try {
      await MobileAds.instance.initialize();
      _isSupported = true;
      AdService().loadRewardedAd();
    } catch (e) {
      debugPrint('[AdService] Failed to initialize: $e');
      _isSupported = false;
    }
  }

  bool get isAdReady => _isSupported && _rewardedAd != null;

  void loadRewardedAd() {
    if (!_isSupported || _isLoading || _rewardedAd != null) return;
    _isLoading = true;

    RewardedAd.load(
      adUnitId: _rewardedAdUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          _rewardedAd = ad;
          _isLoading = false;
          debugPrint('[AdService] Rewarded ad loaded');
        },
        onAdFailedToLoad: (error) {
          _rewardedAd = null;
          _isLoading = false;
          debugPrint('[AdService] Failed to load rewarded ad: ${error.message}');
        },
      ),
    );
  }

  /// Affiche la pub rewarded.
  /// Retourne true si l'utilisateur a regardé la pub jusqu'au bout (reward gagné).
  /// Retourne false si la pub n'est pas prête ou si l'utilisateur l'a fermée avant la fin.
  Future<bool> showRewardedAd() async {
    if (_rewardedAd == null) {
      debugPrint('[AdService] Rewarded ad not ready');
      loadRewardedAd();
      return false;
    }

    final completer = Completer<bool>();
    bool rewarded = false;

    _rewardedAd!.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        debugPrint('[AdService] Ad dismissed, rewarded=$rewarded');
        ad.dispose();
        _rewardedAd = null;
        loadRewardedAd();
        if (!completer.isCompleted) {
          completer.complete(rewarded);
        }
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        debugPrint('[AdService] Failed to show rewarded ad: ${error.message}');
        ad.dispose();
        _rewardedAd = null;
        loadRewardedAd();
        if (!completer.isCompleted) {
          completer.complete(false);
        }
      },
    );

    await _rewardedAd!.show(
      onUserEarnedReward: (ad, reward) {
        debugPrint('[AdService] User earned reward: ${reward.amount} ${reward.type}');
        rewarded = true;
      },
    );

    return completer.future;
  }

  void dispose() {
    _rewardedAd?.dispose();
    _rewardedAd = null;
  }
}
