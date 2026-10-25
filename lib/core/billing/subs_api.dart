import 'dart:convert';

import 'package:http/http.dart' as http;

/// Where the subscription backend lives. Pass it at build time:
/// `--dart-define=SUBS_API_URL=https://subs.example.com`.
const String subsApiUrl = String.fromEnvironment('SUBS_API_URL');

/// The app id sent to the backend so one backend can serve many apps.
const String appPackageName = 'com.mcezario.colorfun';

/// What the backend knows about one subscription.
class SubscriptionStatus {
  const SubscriptionStatus({
    required this.active,
    required this.entitlements,
    this.expiresAt,
  });

  final bool active;
  final List<String> entitlements;
  final DateTime? expiresAt;

  bool has(String entitlement) => active && entitlements.contains(entitlement);

  factory SubscriptionStatus.fromJson(Map<String, dynamic> json) =>
      SubscriptionStatus(
        active: json['active'] as bool? ?? false,
        entitlements: [
          for (final e in (json['entitlements'] as List? ?? const [])) '$e',
        ],
        expiresAt: json['expiresAt'] == null
            ? null
            : DateTime.tryParse(json['expiresAt'] as String),
      );
}

/// Thrown when the backend cannot be reached or answers with an error, so the
/// caller can keep using its cached status instead of locking the user out.
class SubsApiException implements Exception {
  SubsApiException(this.message);
  final String message;
  @override
  String toString() => 'SubsApiException: $message';
}

/// Talks to the generic subscription backend.
class SubsApi {
  SubsApi({http.Client? client, String? baseUrl})
      : _client = client ?? http.Client(),
        _baseUrl = baseUrl ?? subsApiUrl;

  final http.Client _client;
  final String _baseUrl;

  bool get configured => _baseUrl.isNotEmpty;

  /// Asks the backend to validate [purchaseToken] with Google Play.
  Future<SubscriptionStatus> verify(String purchaseToken) =>
      _send(() => _client.post(
            Uri.parse('$_baseUrl/v1/subscriptions/verify'),
            headers: {'content-type': 'application/json'},
            body: jsonEncode({
              'packageName': appPackageName,
              'purchaseToken': purchaseToken,
            }),
          ));

  /// Current status of an already verified [purchaseToken].
  Future<SubscriptionStatus> status(String purchaseToken) =>
      _send(() => _client.get(
            Uri.parse('$_baseUrl/v1/subscriptions/status'),
            headers: {
              'x-package-name': appPackageName,
              'x-purchase-token': purchaseToken,
            },
          ));

  Future<SubscriptionStatus> _send(Future<http.Response> Function() call) async {
    if (!configured) throw SubsApiException('SUBS_API_URL is not set');
    try {
      final response = await call().timeout(const Duration(seconds: 15));
      if (response.statusCode != 200) {
        throw SubsApiException('HTTP ${response.statusCode}');
      }
      return SubscriptionStatus.fromJson(
        jsonDecode(response.body) as Map<String, dynamic>,
      );
    } on SubsApiException {
      rethrow;
    } catch (e) {
      throw SubsApiException('$e');
    }
  }
}
