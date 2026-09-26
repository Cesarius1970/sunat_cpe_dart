// Copyright (c) 2026, César A Vergara Buenaventura <cesarvergarab@gmail.com>.
// Todos los derechos reservados. Uso sujeto a la licencia en el archivo LICENSE.

import 'cpe_entorno.dart';

/// Credenciales de autenticación ante SUNAT para servicios SOAP (Clave SOL) y REST (API OAuth2).
class CPE_Credenciales {
  /// Número de RUC del contribuyente emisor (11 dígitos).
  final String ruc;

  /// Usuario del sistema SOL (SUNAT Operaciones en Línea).
  final String usuarioSol;

  /// Contraseña del sistema SOL.
  final String claveSol;

  /// Client ID para la API REST de SUNAT (obtenido en Clave SOL -> Credenciales de API).
  final String? clientId;

  /// Client Secret para la API REST de SUNAT.
  final String? clientSecret;

  /// Entorno de destino (por defecto pruebas [CPE_Entorno.beta]).
  final CPE_Entorno entorno;

  const CPE_Credenciales({
    required this.ruc,
    required this.usuarioSol,
    required this.claveSol,
    this.clientId,
    this.clientSecret,
    this.entorno = CPE_Entorno.beta,
  });

  /// Identificador compuesto de usuario para WS-Security de SOAP (formato: `RUC + USUARIO_SOL`).
  String get usuarioWsSecurity => '$ruc$usuarioSol';

  /// Nombre de usuario para flujo Resource Owner Password Credentials en OAuth2.
  String get usernameOAuth2 => '$ruc$usuarioSol';

  /// Verifica si las credenciales contienen lo necesario para consumir el canal REST.
  bool get tieneCredencialesRest =>
      clientId != null &&
      clientId!.trim().isNotEmpty &&
      clientSecret != null &&
      clientSecret!.trim().isNotEmpty;
}
