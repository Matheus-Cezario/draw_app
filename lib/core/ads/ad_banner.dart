import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../billing/entitlement_service.dart';
import 'ad_service.dart';

/// A banner for the free plan. Takes no space for subscribers or when ads
/// are not available.
class AdBanner extends StatefulWidget {
  const AdBanner({super.key});

  @override
  State<AdBanner> createState() => _AdBannerState();
}

class _AdBannerState extends State<AdBanner> {
  BannerAd? _ad;

  @override
  void initState() {
    super.initState();
    EntitlementService.instance.addListener(_onEntitlement);
    _load();
  }

  void _onEntitlement() {
    if (EntitlementService.instance.isPremium) {
      _ad?.dispose();
      setState(() => _ad = null);
    } else if (_ad == null) {
      _load();
    }
  }

  void _load() {
    if (!AdService.instance.showAds) return;
    final ad = BannerAd(
      adUnitId: AdService.instance.bannerUnitId,
      size: AdSize.banner,
      request: AdService.instance.request,
      listener: BannerAdListener(
        onAdLoaded: (_) => setState(() {}),
        onAdFailedToLoad: (ad, _) {
          ad.dispose();
          if (mounted) setState(() => _ad = null);
        },
      ),
    );
    _ad = ad;
    ad.load();
  }

  @override
  void dispose() {
    EntitlementService.instance.removeListener(_onEntitlement);
    _ad?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ad = _ad;
    if (ad == null) return const SizedBox.shrink();
    return SizedBox(
      width: ad.size.width.toDouble(),
      height: ad.size.height.toDouble(),
      child: AdWidget(ad: ad),
    );
  }
}
