import 'dart:convert';
import 'package:sunat_cpe_core/sunat_cpe_core.dart';

/// OAuth2 `client_credentials` + `x-api-key` interceptor for Cavali Factrack v2 REST API.
final class CavaliOAuth2Interceptor implements CpeHttpInterceptor {
  final Uri tokenEndpoint;
  final String clientId;
  final String clientSecret;
  final String? apiKey;
  final CpeHttpClient authHttpClient;
  final Duration refreshBuffer;

  String? _cachedToken;
  DateTime? _expiresAt;

  CavaliOAuth2Interceptor({
    required this.tokenEndpoint,
    required this.clientId,
    required this.clientSecret,
    this.apiKey,
    CpeHttpClient? authHttpClient,
    this.refreshBuffer = const Duration(seconds: 60),
  }) : authHttpClient = authHttpClient ?? DefaultCpeHttpClient();

  Future<String> getValidAccessToken() async {
    final now = DateTime.now();
    if (_cachedToken != null &&
        _expiresAt != null &&
        now.isBefore(_expiresAt!.subtract(refreshBuffer))) {
      return _cachedToken!;
    }

    final formBody = 'grant_type=client_credentials'
        '&client_id=${Uri.encodeQueryComponent(clientId)}'
        '&client_secret=${Uri.encodeQueryComponent(clientSecret)}';

    final response = await authHttpClient.send(
      CpeHttpRequest(
        method: 'POST',
        uri: tokenEndpoint,
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
          'Accept': 'application/json',
          'x-api-key': ?apiKey,
        },
        body: formBody,
      ),
    );

    if (response.statusCode != 200) {
      throw OseAuthException(
        message: 'Cavali Factrack OAuth2 failed (HTTP ${response.statusCode}): ${response.bodyAsString}',
        code: response.statusCode.toString(),
        rawResponse: response.bodyAsString,
      );
    }

    final decoded = jsonDecode(response.bodyAsString) as Map<String, dynamic>;
    final token = decoded['access_token']?.toString();
    if (token == null || token.isEmpty) {
      throw OseAuthException(
        message: 'Missing access_token in Cavali Factrack OAuth2 response',
        rawResponse: decoded,
      );
    }

    final expiresIn = (decoded['expires_in'] is int)
        ? decoded['expires_in'] as int
        : int.tryParse(decoded['expires_in']?.toString() ?? '') ?? 3600;

    _cachedToken = token;
    _expiresAt = now.add(Duration(seconds: expiresIn));
    return token;
  }

  @override
  Future<CpeHttpRequest> onRequest(CpeHttpRequest request) async {
    if (request.uri.path.endsWith('/oauth/token')) {
      return request;
    }
    final token = await getValidAccessToken();
    return request.copyWith(
      headers: {
        ...request.headers,
        'Authorization': 'Bearer $token',
        'x-api-key': ?apiKey,
      },
    );
  }

  @override
  Future<CpeHttpResponse> onResponse(
    CpeHttpRequest request,
    CpeHttpResponse response,
  ) async {
    if (response.statusCode == 401) {
      _cachedToken = null;
      _expiresAt = null;
    }
    return response;
  }
}
