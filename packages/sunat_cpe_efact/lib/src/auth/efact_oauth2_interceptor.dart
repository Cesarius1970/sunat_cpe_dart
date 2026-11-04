import 'dart:convert';

import 'package:sunat_cpe_core/sunat_cpe_core.dart';

/// Interceptor que adquiere y renueva tokens OAuth2 Bearer de EFACT (`/oauth/token`).
final class EfactOAuth2Interceptor implements CpeHttpInterceptor {
  /// URL del endpoint de autenticación OAuth2 (`/oauth/token`).
  final Uri tokenEndpoint;

  /// Usuario RUC o credencial asignada por EFACT.
  final String username;

  /// Contraseña de acceso al API REST de EFACT.
  final String password;

  /// Identificador de cliente OAuth2 (`efact-ose-client` por defecto).
  final String clientId;

  /// Secreto de cliente OAuth2 (`secret` por defecto).
  final String clientSecret;

  /// Cliente HTTP empleado para solicitar el token OAuth2.
  final CpeHttpClient authHttpClient;

  /// Margen de seguridad previo a la expiración para renovar el token en caché.
  final Duration refreshBuffer;

  String? _cachedToken;
  DateTime? _expiresAt;

  /// Crea un interceptor OAuth2 para las peticiones REST hacia EFACT.
  EfactOAuth2Interceptor({
    required this.tokenEndpoint,
    required this.username,
    required this.password,
    this.clientId = 'efact-ose-client',
    this.clientSecret = 'secret',
    CpeHttpClient? authHttpClient,
    this.refreshBuffer = const Duration(seconds: 60),
  }) : authHttpClient = authHttpClient ?? DefaultCpeHttpClient();

  /// Limpia cualquier token OAuth2 almacenado en caché.
  void invalidateToken() {
    _cachedToken = null;
    _expiresAt = null;
  }

  /// Obtiene un token Bearer válido, solicitando uno nuevo si no existe o está por expirar.
  Future<String> getValidAccessToken() async {
    final now = DateTime.now();
    if (_cachedToken != null &&
        _expiresAt != null &&
        now.isBefore(_expiresAt!.subtract(refreshBuffer))) {
      return _cachedToken!;
    }

    final basicCredentials = base64.encode(
      utf8.encode('$clientId:$clientSecret'),
    );
    final formBody =
        'grant_type=password'
        '&username=${Uri.encodeQueryComponent(username)}'
        '&password=${Uri.encodeQueryComponent(password)}';

    final response = await authHttpClient.send(
      CpeHttpRequest(
        method: 'POST',
        uri: tokenEndpoint,
        headers: {
          'Authorization': 'Basic $basicCredentials',
          'Content-Type': 'application/x-www-form-urlencoded',
          'Accept': 'application/json',
        },
        body: formBody,
      ),
    );

    if (response.statusCode != 200) {
      throw OseAuthException(
        message:
            'Failed to obtain EFACT OAuth2 token (HTTP ${response.statusCode}): ${response.bodyAsString}',
        code: response.statusCode.toString(),
        rawResponse: response.bodyAsString,
      );
    }

    final decoded = jsonDecode(response.bodyAsString);
    if (decoded is! Map<String, dynamic>) {
      throw OseAuthException(
        message:
            'Invalid OAuth2 JSON response from EFACT: ${response.bodyAsString}',
        rawResponse: response.bodyAsString,
      );
    }

    final token = decoded['access_token']?.toString();
    if (token == null || token.isEmpty) {
      throw OseAuthException(
        message:
            'Missing access_token in EFACT OAuth2 response: ${response.bodyAsString}',
        rawResponse: decoded,
      );
    }

    final expiresInSeconds = (decoded['expires_in'] is int)
        ? decoded['expires_in'] as int
        : int.tryParse(decoded['expires_in']?.toString() ?? '') ?? 3600;

    _cachedToken = token;
    _expiresAt = now.add(Duration(seconds: expiresInSeconds));
    return token;
  }

  @override
  Future<CpeHttpRequest> onRequest(CpeHttpRequest request) async {
    if (request.uri.path.endsWith('/oauth/token')) {
      return request;
    }
    final token = await getValidAccessToken();
    return request.copyWith(
      headers: {...request.headers, 'Authorization': 'Bearer $token'},
    );
  }

  @override
  Future<CpeHttpResponse> onResponse(
    CpeHttpRequest request,
    CpeHttpResponse response,
  ) async {
    if (response.statusCode == 401) {
      invalidateToken();
    }
    return response;
  }
}
