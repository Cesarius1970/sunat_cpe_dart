/// Configuración de conexión y opciones de emisión para [FacturaloProvider].
final class FacturaloConfig {
  /// URL base del servidor FacturaloPeru / Facturador PRO.
  final Uri baseUri;

  /// Token de autenticación (`Bearer Token`) del tenant o empresa.
  final String apiToken;

  /// Formato de representación impresa PDF (`a4`, `ticket`, `a5`).
  final String pdfFormat;

  /// Indica si el servidor PSE debe enviar el comprobante por correo al cliente.
  final bool sendEmail;

  /// Permite enviar `"#"` como correlativo cuando el número es `<= 0` para que el servidor lo autoincremente.
  final bool allowServerAutoIncrement;

  /// Tiempo máximo de espera por petición HTTP.
  final Duration timeout;

  /// Crea una configuración inmutable para [FacturaloProvider].
  const FacturaloConfig({
    required this.baseUri,
    required this.apiToken,
    this.pdfFormat = 'a4',
    this.sendEmail = false,
    this.allowServerAutoIncrement = false,
    this.timeout = const Duration(seconds: 30),
  });
}
