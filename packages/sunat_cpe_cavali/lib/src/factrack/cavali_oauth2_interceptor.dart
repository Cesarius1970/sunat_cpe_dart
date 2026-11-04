import 'dart:convert';

import 'package:sunat_cpe_core/sunat_cpe_core.dart';

/// Interceptor OAuth2 `client_credentials` + `x-api-key` para la API REST Cavali Factrack v2.
final class CavaliOAuth2Interceptor implements CpeHttpInterceptor {
  /// Endpoint OAuth2 para la obtención del token (`/oauth/token`).
  final Uri tokenEndpoint;

  /// Identificador de cliente OAuth2 (`client_id`).
  final String clientId;

  /// Secreto de cliente OAuth2 (`client_secret`).
  final String clientSecret;

  /// Llave opcional de API Gateway (`x-api-key`).
  final String? apiKey;

  /// Cliente HTTP dedicado a la autenticación OAuth2.
  final CpeHttpClient authHttpClient;

  /// Margen de seguridad previo a la expiración para refrescar el token en caché.
  final Duration refreshBuffer;

  String? _cachedToken;
  DateTime? _expiresAt;

  /// Crea una instancia de [CavaliOAuth2Interceptor].
  CavaliOAuth2Interceptor({
    required this.tokenEndpoint,
    required this.clientId,
    required this.clientSecret,
    this.apiKey,
    CpeHttpClient? authHttpClient,
    this.refreshBuffer = const Duration(seconds: 60),
  }) : authHttpClient = authHttpClient ?? DefaultCpeHttpClient();

  /// Obtiene un token de acceso OAuth2 vigente (desde caché o solicitando uno nuevo).
  Future<String> getValidAccessToken() async {
    final now = DateTime.now();
    if (_cachedToken != null &&
        _expiresAt != null &&
        now.isBefore(_expiresAt!.subtract(refreshBuffer))) {
      return _cachedToken!;
    }

    final formBody =
        'grant_type=client_credentials'
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
        message:
            'Cavali Factrack OAuth2 failed (HTTP ${response.statusCode}): ${response.bodyAsString}',
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
