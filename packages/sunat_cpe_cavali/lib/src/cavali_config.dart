import 'package:sunat_cpe_core/sunat_cpe_core.dart';

/// Configuration for [CavaliProvider] (Gosocket OSE SOAP 1.1 + Cavali Factrack REST OAuth2).
final class CavaliConfig {
  /// Production Gosocket / Carvajal OSE SOAP 1.1 endpoint.
  static final Uri productionOseSoapUri = Uri.parse(
    'https://ose.gosocket.net/ol-ti-itcpe/billService',
  );

  /// Testing Gosocket / Carvajal OSE SOAP 1.1 endpoint.
  static final Uri testingOseSoapUri = Uri.parse(
    'https://osetest.gosocket.net/ol-ti-itcpe/billService',
  );

  /// Production Cavali Factrack v2 REST base URL.
  static final Uri productionFactrackUri = Uri.parse(
    'https://api.cavali.com.pe/factrack/v2',
  );

  /// Testing / QA Cavali Factrack v2 REST base URL.
  static final Uri testingFactrackUri = Uri.parse(
    'https://apidev.cavali.com.pe/factrack/v2',
  );

  final Uri oseSoapEndpoint;
  final String wsseUsername;
  final String wssePassword;
  final CpeCertificateCredentials certificate;

  final Uri factrackBaseUri;
  final String? factrackClientId;
  final String? factrackClientSecret;
  final String? factrackApiKey;
  final Duration timeout;

  CavaliConfig({
    Uri? oseSoapEndpoint,
    required this.wsseUsername,
    required this.wssePassword,
    required this.certificate,
    Uri? factrackBaseUri,
    this.factrackClientId,
    this.factrackClientSecret,
    this.factrackApiKey,
    this.timeout = const Duration(seconds: 30),
  }) : oseSoapEndpoint = oseSoapEndpoint ?? productionOseSoapUri,
       factrackBaseUri = factrackBaseUri ?? productionFactrackUri;
}
