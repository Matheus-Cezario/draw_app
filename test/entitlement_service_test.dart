import 'package:draw_app/core/billing/entitlement_service.dart';
import 'package:draw_app/core/billing/subs_api.dart';
import 'package:flutter_test/flutter_test.dart';

class _MemoryCache implements EntitlementCache {
  _MemoryCache(this.value);
  CachedEntitlement value;

  @override
  Future<CachedEntitlement> load() async => value;

  @override
  Future<void> save(CachedEntitlement v) async => value = v;
}

class _FakeApi extends SubsApi {
  _FakeApi() : super(baseUrl: 'http://fake');

  SubscriptionStatus? answer;

  @override
  Future<SubscriptionStatus> status(String token) async =>
      answer ?? (throw SubsApiException('offline'));
}

void main() {
  final now = DateTime(2026, 1, 10);

  test('free until a subscription is known', () {
    final service = EntitlementService(
      api: _FakeApi(),
      cache: _MemoryCache(const CachedEntitlement()),
      now: () => now,
    );
    expect(service.isPremium, isFalse);
  });

  test('backend answer replaces the cache and revokes when inactive', () async {
    final api = _FakeApi();
    final cache = _MemoryCache(CachedEntitlement(
      token: 't',
      active: true,
      expiresAt: now.add(const Duration(days: 5)),
    ));
    final service = EntitlementService(api: api, cache: cache, now: () => now);
    await service.loadCache();
    expect(service.isPremium, isTrue);

    api.answer = const SubscriptionStatus(active: false, entitlements: []);
    await service.refresh();
    expect(service.isPremium, isFalse);
    expect(cache.value.active, isFalse);
  });

  test('offline keeps premium inside the grace period only', () async {
    final api = _FakeApi(); // always offline
    final inside = EntitlementService(
      api: api,
      cache: _MemoryCache(CachedEntitlement(
        token: 't',
        active: true,
        expiresAt: now.subtract(const Duration(days: 2)),
      )),
      now: () => now,
    );
    await inside.loadCache();
    await inside.refresh();
    expect(inside.isPremium, isTrue);

    final outside = EntitlementService(
      api: api,
      cache: _MemoryCache(CachedEntitlement(
        token: 't',
        active: true,
        expiresAt: now.subtract(const Duration(days: 4)),
      )),
      now: () => now,
    );
    await outside.loadCache();
    await outside.refresh();
    expect(outside.isPremium, isFalse);
  });
}
