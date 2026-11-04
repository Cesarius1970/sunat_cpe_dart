/// Configuration for the Nubefact PSE/OSE JSON REST API.
final class NubefactConfig {
  /// Personal endpoint URL provided in Nubefact's control panel (RUTA).
  final Uri routeUri;

  /// Authentication token provided in Nubefact's control panel (TOKEN).
  final String apiToken;

  /// Whether Nubefact should immediately forward the document to SUNAT/OSE (`enviar_automaticamente_a_la_sunat`).
  final bool autoSendToSunat;

  /// Whether Nubefact should email the PDF/XML to the customer (`enviar_automaticamente_al_cliente`).
  final bool autoSendToCustomer;

  /// Default PDF layout format (`"A4"`, `"A5"`, `"TICKET"`).
  final String pdfFormat;

  const NubefactConfig({
    required this.routeUri,
    required this.apiToken,
    this.autoSendToSunat = true,
    this.autoSendToCustomer = false,
    this.pdfFormat = 'A4',
  });
}
