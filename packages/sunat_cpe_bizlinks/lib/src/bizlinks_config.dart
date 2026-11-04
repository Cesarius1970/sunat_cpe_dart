import 'package:sunat_cpe_core/sunat_cpe_core.dart';

/// Environment for Bizlinks OSE endpoints.
enum BizlinksEnvironment {
  production,
  testing,
}

/// Configuration for [BizlinksProvider].
final class BizlinksConfig {
  /// Production SOAP 1.1 OSE endpoint.
  static final Uri productionEndpoint = Uri.parse(
    'https://ose.bizlinks.com.pe/ol-ti-itcpe/billService',
  );

  /// Testing / Homologation SOAP 1.1 OSE endpoint.
  static final Uri testingEndpoint = Uri.parse(
    'https://osetesting.bizlinks.com.pe/ol-ti-itcpe/billService',
  );

  final Uri endpointUri;
  final String username;
  final String password;
  final CpeCertificateCredentials certificate;

  const BizlinksConfig({
    required this.endpointUri,
    required this.username,
    required this.password,
    required this.certificate,
  });

  factory BizlinksConfig.forEnvironment({
    required BizlinksEnvironment environment,
    required String username,
    required String password,
    required CpeCertificateCredentials certificate,
  }) {
    return BizlinksConfig(
      endpointUri: environment == BizlinksEnvironment.production
          ? productionEndpoint
          : testingEndpoint,
      username: username,
      password: password,
      certificate: certificate,
    );
  }
}
