import 'dart:async';
import 'dart:io';
import 'package:app_tracking_transparency/app_tracking_transparency.dart';
import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../../features/auth/data/repositories/auth_repository.dart';

class AdService {
  static final AdService _instance = AdService._internal();
  factory AdService() => _instance;
  AdService._internal();

  // Android uses RewardedAd, iOS uses RewardedInterstitialAd.
  RewardedAd? _rewardedAdAndroid;
  RewardedInterstitialAd? _rewardedAdIos;

  bool _isLoading = false;
  bool _isShowing = false;
  static bool _isSupported = false;

  bool get isSupported => _isSupported;

  // ─── Ad unit IDs ──────────────────────────────────────────────────────────

  static String get _androidAdUnitId => kDebugMode
      ? 'ca-app-pub-3940256099942544/5224354917' // Test ID (rewarded)
      : 'ca-app-pub-6743392628237404/2396801579'; // Prod ID Android

  static String get _iosAdUnitId => kDebugMode
      ? 'ca-app-pub-3940256099942544/6978759866' // Test ID (rewarded interstitial)
      : 'ca-app-pub-6743392628237404/8998427429'; // Prod ID iOS

  String get _adUnitId =>
      Platform.isAndroid ? _androidAdUnitId : _iosAdUnitId;

  // ─── Init ─────────────────────────────────────────────────────────────────

  static bool get _isMobilePlatform =>
      defaultTargetPlatform == TargetPlatform.android ||
      defaultTargetPlatform == TargetPlatform.iOS;

  static Future<void> initialize() async {
    if (!_isMobilePlatform) {
      debugPrint('[AdService] Ads not supported on this platform');
      return;
    }
    try {
      if (Platform.isIOS) {
        try {
          final status =
              await AppTrackingTransparency.trackingAuthorizationStatus;
          if (status == TrackingStatus.notDetermined) {
            await AppTrackingTransparency.requestTrackingAuthorization();
          }
          debugPrint('[AdService] ATT status: $status');
        } catch (e) {
          debugPrint('[AdService] ATT error (non-fatal): $e');
        }
      }
      await MobileAds.instance.initialize();
      _isSupported = true;
      AdService().loadRewardedAd();
    } catch (e) {
      debugPrint('[AdService] Failed to initialize: $e');
      _isSupported = false;
    }
  }

  // ─── State ────────────────────────────────────────────────────────────────

  bool get isAdReady {
    if (!_isSupported) return false;
    return Platform.isAndroid
        ? _rewardedAdAndroid != null
        : _rewardedAdIos != null;
  }

  /// Waits until the ad is ready or [timeout] expires.
  Future<bool> waitUntilReady(
      {Duration timeout = const Duration(seconds: 10)}) async {
    if (!_isSupported) return false;
    if (isAdReady) return true;
    loadRewardedAd();
    final deadline = DateTime.now().add(timeout);
    while (DateTime.now().isBefore(deadline)) {
      await Future.delayed(const Duration(milliseconds: 500));
      if (isAdReady) return true;
      // Retry if loading failed and not currently loading
      if (!_isLoading) loadRewardedAd();
    }
    return false;
  }

  // ─── Load ─────────────────────────────────────────────────────────────────

  void loadRewardedAd() {
    if (!_isSupported || _isLoading || isAdReady) return;
    _isLoading = true;

    final userId = AuthRepository().getCurrentUserId();

    if (Platform.isAndroid) {
      _loadAndroid(userId);
    } else {
      _loadIos(userId);
    }
  }

  void _loadAndroid(String? userId) {
    RewardedAd.load(
      adUnitId: _adUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          if (userId != null) {
            ad.setServerSideOptions(
                ServerSideVerificationOptions(userId: userId));
          }
          _rewardedAdAndroid = ad;
          _isLoading = false;
          debugPrint('[AdService] Android rewarded ad loaded');
        },
        onAdFailedToLoad: (error) {
          _rewardedAdAndroid = null;
          _isLoading = false;
          debugPrint('[AdService] Android failed to load: ${error.message}');
        },
      ),
    );
  }

  void _loadIos(String? userId) {
    RewardedInterstitialAd.load(
      adUnitId: _adUnitId,
      request: const AdRequest(),
      rewardedInterstitialAdLoadCallback: RewardedInterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          if (userId != null) {
            ad.setServerSideOptions(
                ServerSideVerificationOptions(userId: userId));
          }
          _rewardedAdIos = ad;
          _isLoading = false;
          debugPrint('[AdService] iOS rewarded interstitial ad loaded');
        },
        onAdFailedToLoad: (error) {
          _rewardedAdIos = null;
          _isLoading = false;
          debugPrint('[AdService] iOS failed to load: ${error.message}');
        },
      ),
    );
  }

  // ─── Show ─────────────────────────────────────────────────────────────────

  Future<bool> showRewardedAd() async {
    if (!isAdReady) {
      debugPrint('[AdService] Ad not ready');
      loadRewardedAd();
      return false;
    }
    if (_isShowing) {
      debugPrint('[AdService] Ad already showing');
      return false;
    }

    _isShowing = true;
    final completer = Completer<bool>();
    bool rewarded = false;

    if (Platform.isAndroid) {
      final ad = _rewardedAdAndroid!;
      ad.fullScreenContentCallback = FullScreenContentCallback(
        onAdDismissedFullScreenContent: (_) {
          debugPrint('[AdService] Android ad dismissed, rewarded=$rewarded');
          ad.dispose();
          _rewardedAdAndroid = null;
          _isShowing = false;
          loadRewardedAd();
          if (!completer.isCompleted) completer.complete(rewarded);
        },
        onAdFailedToShowFullScreenContent: (_, error) {
          debugPrint('[AdService] Android failed to show: ${error.message}');
          ad.dispose();
          _rewardedAdAndroid = null;
          _isShowing = false;
          loadRewardedAd();
          if (!completer.isCompleted) completer.complete(false);
        },
      );
      await ad.show(
        onUserEarnedReward: (_, reward) {
          debugPrint('[AdService] Reward earned: ${reward.amount}');
          rewarded = true;
        },
      );
    } else {
      final ad = _rewardedAdIos!;
      ad.fullScreenContentCallback = FullScreenContentCallback(
        onAdDismissedFullScreenContent: (_) {
          debugPrint('[AdService] iOS ad dismissed, rewarded=$rewarded');
          ad.dispose();
          _rewardedAdIos = null;
          _isShowing = false;
          loadRewardedAd();
          if (!completer.isCompleted) completer.complete(rewarded);
        },
        onAdFailedToShowFullScreenContent: (_, error) {
          debugPrint('[AdService] iOS failed to show: ${error.message}');
          ad.dispose();
          _rewardedAdIos = null;
          _isShowing = false;
          loadRewardedAd();
          if (!completer.isCompleted) completer.complete(false);
        },
      );
      await ad.show(
        onUserEarnedReward: (_, reward) {
          debugPrint('[AdService] Reward earned: ${reward.amount}');
          rewarded = true;
        },
      );
    }

    return completer.future;
  }

  void dispose() {
    _rewardedAdAndroid?.dispose();
    _rewardedAdAndroid = null;
    _rewardedAdIos?.dispose();
    _rewardedAdIos = null;
  }
}
