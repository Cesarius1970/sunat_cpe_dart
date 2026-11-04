import 'package:sunat_cpe_core/sunat_cpe_core.dart';

/// Integration mode for EFACT OSE / PSE.
enum EfactIntegrationMode {
  /// REST API (`api-efact-ose`) sending locally signed UBL 2.1 XML via `multipart/form-data`.
  restXml,

  /// REST API (`api-efact-ose`) sending EFACT JSON UBL payload (cloud PSE signing).
  restJson,

  /// SOAP 1.1 `billService` (`ol-ti-itcpe/billService`) with WS-Security and `.zip` UBL 2.1.
  soapUbl,
}

/// Configuration for [EfactProvider].
final class EfactConfig {
  /// Production REST base URL.
  static final Uri productionRestUri = Uri.parse(
    'https://ose.efact.pe/api-efact-ose',
  );

  /// Testing / Homologation REST base URL.
  static final Uri testRestUri = Uri.parse(
    'https://ose-gw1.efact.pe:443/api-efact-ose',
  );

  /// Production SOAP 1.1 `billService` endpoint.
  static final Uri productionSoapUri = Uri.parse(
    'https://ose.efact.pe/ol-ti-itcpe/billService',
  );

  /// Testing / Homologation SOAP 1.1 `billService` endpoint.
  static final Uri testSoapUri = Uri.parse(
    'https://ose-gw1.efact.pe/ol-ti-itcpe/billService',
  );

  final EfactIntegrationMode mode;
  final Uri baseUri;
  final String username;
  final String password;
  final String oauthClientId;
  final String oauthClientSecret;
  final CpeCertificateCredentials? certificate;
  final bool autoPollInRest;
  final PollingConfig pollingConfig;
  final Duration timeout;

  const EfactConfig({
    required this.mode,
    required this.baseUri,
    required this.username,
    required this.password,
    this.oauthClientId = 'efact-ose-client',
    this.oauthClientSecret = 'secret',
    this.certificate,
    this.autoPollInRest = true,
    this.pollingConfig = const PollingConfig(
      initialDelay: Duration(milliseconds: 300),
      maxAttempts: 8,
    ),
    this.timeout = const Duration(seconds: 30),
  });

  /// Creates an EFACT REST XML configuration (locally signed UBL 2.1 XML + OAuth2).
  factory EfactConfig.restXml({
    required String username,
    required String password,
    required CpeCertificateCredentials certificate,
    Uri? baseUri,
    String oauthClientId = 'efact-ose-client',
    String oauthClientSecret = 'secret',
    bool autoPollInRest = true,
    PollingConfig pollingConfig = const PollingConfig(
      initialDelay: Duration(milliseconds: 300),
      maxAttempts: 8,
    ),
  }) {
    return EfactConfig(
      mode: EfactIntegrationMode.restXml,
      baseUri: baseUri ?? productionRestUri,
      username: username,
      password: password,
      oauthClientId: oauthClientId,
      oauthClientSecret: oauthClientSecret,
      certificate: certificate,
      autoPollInRest: autoPollInRest,
      pollingConfig: pollingConfig,
    );
  }

  /// Creates an EFACT REST JSON configuration (cloud-signed PSE mode + OAuth2).
  factory EfactConfig.restJson({
    required String username,
    required String password,
    Uri? baseUri,
    String oauthClientId = 'efact-ose-client',
    String oauthClientSecret = 'secret',
    bool autoPollInRest = true,
    PollingConfig pollingConfig = const PollingConfig(
      initialDelay: Duration(milliseconds: 300),
      maxAttempts: 8,
    ),
  }) {
    return EfactConfig(
      mode: EfactIntegrationMode.restJson,
      baseUri: baseUri ?? productionRestUri,
      username: username,
      password: password,
      oauthClientId: oauthClientId,
      oauthClientSecret: oauthClientSecret,
      autoPollInRest: autoPollInRest,
      pollingConfig: pollingConfig,
    );
  }

  /// Creates an EFACT SOAP 1.1 UBL 2.1 configuration (`billService` + WS-Security).
  factory EfactConfig.soap({
    required String username,
    required String password,
    required CpeCertificateCredentials certificate,
    Uri? endpointUri,
  }) {
    return EfactConfig(
      mode: EfactIntegrationMode.soapUbl,
      baseUri: endpointUri ?? productionSoapUri,
      username: username,
      password: password,
      certificate: certificate,
    );
  }
}
