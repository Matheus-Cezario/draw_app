import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:path_provider/path_provider.dart';

import 'subs_api.dart';

/// Subscription product ids created in the Play Console.
const Set<String> premiumProductIds = {'premium_monthly', 'premium_yearly'};

/// The entitlement the backend grants to these products.
const String premiumEntitlement = 'premium';

/// How long a subscriber keeps premium past the last known expiry when the
/// backend cannot be reached (offline, server down).
const Duration offlineGrace = Duration(days: 3);

/// What survives a restart: the purchase token and what the backend said.
class CachedEntitlement {
  const CachedEntitlement({this.token, this.active = false, this.expiresAt});

  final String? token;
  final bool active;
  final DateTime? expiresAt;

  Map<String, dynamic> toJson() => {
        'token': token,
        'active': active,
        'expiresAt': expiresAt?.toIso8601String(),
      };

  factory CachedEntitlement.fromJson(Map<String, dynamic> json) =>
      CachedEntitlement(
        token: json['token'] as String?,
        active: json['active'] as bool? ?? false,
        expiresAt: json['expiresAt'] == null
            ? null
            : DateTime.tryParse(json['expiresAt'] as String),
      );
}

abstract class EntitlementCache {
  Future<CachedEntitlement> load();
  Future<void> save(CachedEntitlement value);
}

class FileEntitlementCache implements EntitlementCache {
  Future<File> _file() async => File(
      '${(await getApplicationSupportDirectory()).path}/entitlement.json');

  @override
  Future<CachedEntitlement> load() async {
    try {
      final file = await _file();
      if (file.existsSync()) {
        return CachedEntitlement.fromJson(
          jsonDecode(await file.readAsString()) as Map<String, dynamic>,
        );
      }
    } catch (_) {}
    return const CachedEntitlement();
  }

  @override
  Future<void> save(CachedEntitlement value) async {
    try {
      await (await _file()).writeAsString(jsonEncode(value.toJson()));
    } catch (_) {}
  }
}

/// Knows whether the user is a subscriber. The Play purchase token is the only
/// identity: the backend validates it with Google and says what it unlocks.
class EntitlementService extends ChangeNotifier {
  EntitlementService({
    SubsApi? api,
    EntitlementCache? cache,
    DateTime Function()? now,
  })  : _api = api ?? SubsApi(),
        _cache = cache ?? FileEntitlementCache(),
        _now = now ?? DateTime.now;

  static final EntitlementService instance = EntitlementService();

  final SubsApi _api;
  final EntitlementCache _cache;
  final DateTime Function() _now;

  CachedEntitlement _state = const CachedEntitlement();
  StreamSubscription<List<PurchaseDetails>>? _purchases;
  List<ProductDetails> _products = const [];
  String? _error;
  bool _busy = false;
  String? _productsProblem;
  bool _loadingProducts = false;

  bool get isPremium {
    if (!_state.active) return false;
    final expiry = _state.expiresAt;
    return expiry == null || _now().isBefore(expiry.add(offlineGrace));
  }

  /// Plans to show in the paywall, cheapest period first as Play returns them.
  List<ProductDetails> get products => _products;
  String? get error => _error;
  bool get busy => _busy;

  /// Why [products] is empty, to show in the paywall; null when they loaded.
  String? get productsProblem => _productsProblem;
  bool get loadingProducts => _loadingProducts;

  @visibleForTesting
  Future<void> loadCache() async {
    _state = await _cache.load();
    notifyListeners();
  }

  Future<void> init() async {
    await loadCache();
    await loadProducts();
    unawaited(refresh());
  }

  /// Asks Play for the plans. Called at start and again whenever the paywall
  /// opens without plans, so plans that were activated later still show up.
  Future<void> loadProducts() async {
    if (_loadingProducts) return;
    _loadingProducts = true;
    notifyListeners();
    try {
      final iap = InAppPurchase.instance;
      if (!await iap.isAvailable()) {
        _productsProblem = 'Google Play billing is not available here. '
            'Install the app from Google Play with a tester account.';
        return;
      }
      _purchases ??= iap.purchaseStream.listen(
        _onPurchases,
        onError: (Object e) => _fail('$e'),
      );
      final response = await iap.queryProductDetails(premiumProductIds);
      _products = response.productDetails;
      if (response.error != null) {
        _productsProblem = 'Google Play error: ${response.error!.message}';
      } else if (_products.isEmpty) {
        _productsProblem = 'Google Play did not find the plans '
            '${response.notFoundIDs.join(', ')}. Check that they are active '
            'and that this account is a tester.';
      } else {
        _productsProblem = null;
      }
    } catch (e) {
      _productsProblem = 'Could not load the plans: $e';
    } finally {
      _loadingProducts = false;
      notifyListeners();
    }
  }

  /// Re-checks the saved token with the backend. If the backend is
  /// unreachable the saved status is kept (see [offlineGrace]).
  Future<void> refresh() async {
    final token = _state.token;
    if (token == null) return;
    try {
      await _apply(token, await _api.status(token));
    } on SubsApiException {
      // Keep the cached status.
    }
  }

  Future<void> buy(ProductDetails product) async {
    _setBusy(true);
    try {
      await InAppPurchase.instance
          .buyNonConsumable(purchaseParam: PurchaseParam(productDetails: product));
    } catch (e) {
      _fail('$e');
    }
  }

  /// Asks Play for past purchases; they arrive through the purchase stream.
  Future<void> restore() async {
    _setBusy(true);
    try {
      await InAppPurchase.instance.restorePurchases();
    } catch (e) {
      _fail('$e');
    }
    // Nothing to restore produces no event, so stop spinning after a moment.
    unawaited(Future<void>.delayed(const Duration(seconds: 4), () {
      if (_busy) _setBusy(false);
    }));
  }

  Future<void> _onPurchases(List<PurchaseDetails> purchases) async {
    for (final purchase in purchases) {
      switch (purchase.status) {
        case PurchaseStatus.pending:
          _setBusy(true);
        case PurchaseStatus.error:
          _fail(purchase.error?.message ?? 'Purchase failed');
        case PurchaseStatus.canceled:
          _setBusy(false);
        case PurchaseStatus.purchased:
        case PurchaseStatus.restored:
          final token = purchase.verificationData.serverVerificationData;
          try {
            await _apply(token, await _api.verify(token));
            if (purchase.pendingCompletePurchase) {
              await InAppPurchase.instance.completePurchase(purchase);
            }
          } on SubsApiException catch (e) {
            // Not completed on purpose: Play re-delivers it next launch.
            _fail(e.message);
          }
      }
    }
  }

  Future<void> _apply(String token, SubscriptionStatus status) async {
    _state = CachedEntitlement(
      token: token,
      active: status.has(premiumEntitlement),
      expiresAt: status.expiresAt,
    );
    _error = null;
    _busy = false;
    notifyListeners();
    await _cache.save(_state);
  }

  void _setBusy(bool value) {
    _busy = value;
    if (value) _error = null;
    notifyListeners();
  }

  void _fail(String message) {
    _error = message;
    _busy = false;
    notifyListeners();
  }

  @override
  void dispose() {
    _purchases?.cancel();
    super.dispose();
  }
}
