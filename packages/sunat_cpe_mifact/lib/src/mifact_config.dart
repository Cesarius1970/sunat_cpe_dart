/// Configuración para [MifactProvider].
final class MifactConfig {
  /// Token público de demostración / pruebas (beta) de Mifact.
  static const String demoToken = 'gN8zNRBV+/FVxTLwdaZx0w==';

  /// URI base del servicio web REST JSON de Mifact (ej. `https://demo.mifact.net.pe`).
  final Uri baseUri;

  /// Token de seguridad inyectado como propiedad `"TOKEN"` en cada cuerpo JSON.
  final String token;

  /// Indica si Mifact debe enviar inmediatamente el comprobante a SUNAT (`"ENVIAR_A_SUNAT": "true"`).
  final bool sendImmediatelyToSunat;

  /// Tiempo máximo de espera por petición HTTP.
  final Duration timeout;

  /// Crea una instancia de configuración para el adaptador de Mifact.
  const MifactConfig({
    required this.baseUri,
    required this.token,
    this.sendImmediatelyToSunat = true,
    this.timeout = const Duration(seconds: 30),
  });
}
