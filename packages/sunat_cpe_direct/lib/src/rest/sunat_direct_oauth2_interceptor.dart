import 'dart:convert';

import 'package:sunat_cpe_core/sunat_cpe_core.dart';

/// Obtiene y almacena en caché tokens OAuth2 Bearer desde `api-seguridad.sunat.gob.pe` para la API REST GRE de SUNAT.
final class SunatDirectOAuth2Interceptor implements CpeHttpInterceptor {
  /// Endpoint OAuth2 de seguridad de SUNAT.
  final Uri tokenEndpoint;

  /// Client ID OAuth2 asignado en SUNAT Operaciones en Línea.
  final String clientId;

  /// Client Secret OAuth2 asignado en SUNAT Operaciones en Línea.
  final String clientSecret;

  /// Usuario compuesto `{RUC}{USUARIO_SOL}`.
  final String usernameOAuth2;

  /// Contraseña de la Clave SOL.
  final String claveSol;

  /// Cliente HTTP dedicado a la solicitud del token OAuth2.
  final CpeHttpClient authHttpClient;

  /// Margen de seguridad previo a la expiración para renovar el token en caché.
  final Duration refreshBuffer;

  String? _cachedToken;
  DateTime? _expiresAt;

  /// Crea una instancia de [SunatDirectOAuth2Interceptor].
  SunatDirectOAuth2Interceptor({
    required this.tokenEndpoint,
    required this.clientId,
    required this.clientSecret,
    required this.usernameOAuth2,
    required this.claveSol,
    CpeHttpClient? authHttpClient,
    this.refreshBuffer = const Duration(seconds: 60),
  }) : authHttpClient = authHttpClient ?? DefaultCpeHttpClient();

  /// Devuelve un token de acceso OAuth2 válido (desde caché o solicitando uno nuevo a SUNAT).
  Future<String> getValidAccessToken() async {
    final now = DateTime.now();
    if (_cachedToken != null &&
        _expiresAt != null &&
        now.isBefore(_expiresAt!.subtract(refreshBuffer))) {
      return _cachedToken!;
    }

    final formFields = <String, String>{
      'grant_type': 'password',
      'scope': 'https://api-cpe.sunat.gob.pe',
      'client_id': clientId,
      'client_secret': clientSecret,
      'username': usernameOAuth2,
      'password': claveSol,
    };

    final response = await authHttpClient.send(
      CpeHttpRequest(
        method: 'POST',
        uri: tokenEndpoint,
        headers: const {
          'Content-Type': 'application/x-www-form-urlencoded',
          'Accept': 'application/json',
        },
        body: formFields,
      ),
    );

    if (response.statusCode != 200) {
      throw OseAuthException(
        message:
            'Fallo en la autenticación OAuth2 de SUNAT (HTTP ${response.statusCode}): ${response.bodyAsString}',
        code: response.statusCode.toString(),
        rawResponse: response.bodyAsString,
      );
    }

    final decoded = jsonDecode(response.bodyAsString) as Map<String, dynamic>;
    final token = decoded['access_token']?.toString();
    if (token == null || token.isEmpty) {
      throw OseAuthException(
        message: 'Respuesta OAuth2 de SUNAT no contiene access_token',
        rawResponse: decoded,
      );
    }

    final expiresIn = (decoded['expires_in'] as num?)?.toInt() ?? 3600;
    _cachedToken = token;
    _expiresAt = now.add(Duration(seconds: expiresIn));
    return token;
  }

  @override
  Future<CpeHttpRequest> onRequest(CpeHttpRequest request) async {
    if (request.uri.path.contains('/oauth2/token')) {
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
      _cachedToken = null;
      _expiresAt = null;
    }
    return response;
  }
}
