/// Configuración para la API REST JSON de Nubefact (PSE/OSE).
final class NubefactConfig {
  /// URL del endpoint personal provisto en el panel de control de Nubefact (RUTA).
  final Uri routeUri;

  /// Token de autenticación provisto en el panel de control de Nubefact (TOKEN).
  final String apiToken;

  /// Indica si Nubefact debe reenviar inmediatamente el comprobante a SUNAT/OSE (`enviar_automaticamente_a_la_sunat`).
  final bool autoSendToSunat;

  /// Indica si Nubefact debe enviar por correo electrónico el PDF/XML al cliente (`enviar_automaticamente_al_cliente`).
  final bool autoSendToCustomer;

  /// Formato de diseño de PDF por defecto (`"A4"`, `"A5"`, `"TICKET"`).
  final String pdfFormat;

  /// Crea una instancia de configuración para el adaptador de Nubefact.
  const NubefactConfig({
    required this.routeUri,
    required this.apiToken,
    this.autoSendToSunat = true,
    this.autoSendToCustomer = false,
    this.pdfFormat = 'A4',
  });
}
