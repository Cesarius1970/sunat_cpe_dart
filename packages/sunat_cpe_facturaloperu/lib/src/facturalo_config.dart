/// Configuration for [FacturaloProvider].
final class FacturaloConfig {
  final Uri baseUri;
  final String apiToken;
  final String pdfFormat;
  final bool sendEmail;
  final bool allowServerAutoIncrement;
  final Duration timeout;

  const FacturaloConfig({
    required this.baseUri,
    required this.apiToken,
    this.pdfFormat = 'a4',
    this.sendEmail = false,
    this.allowServerAutoIncrement = false,
    this.timeout = const Duration(seconds: 30),
  });
}
