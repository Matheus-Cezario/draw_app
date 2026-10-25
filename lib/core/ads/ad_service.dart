import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../billing/entitlement_service.dart';

/// Ad unit ids. The defaults are Google's public test ids, so debug builds
/// never show real ads. Release builds pass the real ones:
/// `--dart-define=ADMOB_BANNER_ID=ca-app-pub-.../...`.
const String _bannerId = String.fromEnvironment(
  'ADMOB_BANNER_ID',
  defaultValue: 'ca-app-pub-3940256099942544/6300978111',
);
const String _interstitialId = String.fromEnvironment(
  'ADMOB_INTERSTITIAL_ID',
  defaultValue: 'ca-app-pub-3940256099942544/1033173712',
);

/// Ads for the free plan. The app is for children, so every request is
/// child-directed, rated G and non-personalised. Subscribers see no ads.
class AdService {
  AdService._();

  static final AdService instance = AdService._();

  /// One interstitial every this many times a drawing is closed.
  static const int interstitialEvery = 3;

  bool _ready = false;
  int _closedDrawings = 0;
  InterstitialAd? _interstitial;

  bool get supported => !kIsWeb && Platform.isAndroid;
  bool get showAds => supported && _ready && !EntitlementService.instance.isPremium;
  String get bannerUnitId => _bannerId;

  Future<void> init() async {
    if (!supported) return;
    await MobileAds.instance.updateRequestConfiguration(RequestConfiguration(
      ageRestrictedTreatment: AgeRestrictedTreatment.child,
      maxAdContentRating: MaxAdContentRating.g,
    ));
    await MobileAds.instance.initialize();
    _ready = true;
    _loadInterstitial();
  }

  AdRequest get request => const AdRequest(nonPersonalizedAds: true);

  void _loadInterstitial() {
    if (!showAds) return;
    InterstitialAd.load(
      adUnitId: _interstitialId,
      request: request,
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) => _interstitial = ad,
        onAdFailedToLoad: (_) => _interstitial = null,
      ),
    );
  }

  /// Call when the user leaves a drawing. Never shows while drawing, only on
  /// the way back to the gallery, and only every [interstitialEvery] times.
  void onDrawingClosed() {
    if (!showAds) return;
    _closedDrawings++;
    final ad = _interstitial;
    if (ad == null || _closedDrawings % interstitialEvery != 0) return;
    _interstitial = null;
    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        _loadInterstitial();
      },
      onAdFailedToShowFullScreenContent: (ad, _) {
        ad.dispose();
        _loadInterstitial();
      },
    );
    ad.show();
  }
}
