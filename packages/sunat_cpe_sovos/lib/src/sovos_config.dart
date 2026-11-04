import 'package:sunat_cpe_core/sunat_cpe_core.dart';

/// Integration mode for Sovos / Paperless.
enum SovosIntegrationMode {
  /// Standard OSE SOAP 1.1 `billService` with locally signed UBL 2.1 XML.
  oseUblSigned,

  /// PSE Cloud HSM signing mode (`OnlineGeneration`).
  pseCloudSign,
}

/// Configuration for [SovosProvider].
final class SovosConfig {
  /// Production Sovos OSE SOAP endpoint.
  static final Uri productionEndpoint = Uri.parse(
    'https://ose.sovos.com.pe/ol-ti-itcpe/billService',
  );

  /// Certification / QA Sovos OSE SOAP endpoint.
  static final Uri certificationEndpoint = Uri.parse(
    'https://ose-cert.sovos.com.pe/ol-ti-itcpe/billService',
  );

  final Uri endpointUri;
  final String username;
  final String password;
  final CpeCertificateCredentials certificate;
  final SovosIntegrationMode mode;
  final bool autoRecoverCdrOnDuplicate;
  final Map<String, String> customPrintFields;

  const SovosConfig({
    required this.endpointUri,
    required this.username,
    required this.password,
    required this.certificate,
    this.mode = SovosIntegrationMode.oseUblSigned,
    this.autoRecoverCdrOnDuplicate = true,
    this.customPrintFields = const {},
  });
}
