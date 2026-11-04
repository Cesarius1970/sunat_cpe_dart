import 'package:sunat_cpe_core/sunat_cpe_core.dart';

/// Modo de integración para EFACT OSE / PSE.
enum EfactIntegrationMode {
  /// API REST (`api-efact-ose`) que envía XML UBL 2.1 firmado localmente mediante `multipart/form-data`.
  restXml,

  /// API REST (`api-efact-ose`) que envía el payload JSON UBL de EFACT (firma en la nube PSE).
  restJson,

  /// Servicio SOAP 1.1 `billService` (`ol-ti-itcpe/billService`) con WS-Security y `.zip` UBL 2.1.
  soapUbl,
}

/// Configuración para [EfactProvider].
final class EfactConfig {
  /// URL base REST de Producción.
  static final Uri productionRestUri = Uri.parse(
    'https://ose.efact.pe/api-efact-ose',
  );

  /// URL base REST de Pruebas / Homologación.
  static final Uri testRestUri = Uri.parse(
    'https://ose-gw1.efact.pe:443/api-efact-ose',
  );

  /// Endpoint SOAP 1.1 `billService` de Producción.
  static final Uri productionSoapUri = Uri.parse(
    'https://ose.efact.pe/ol-ti-itcpe/billService',
  );

  /// Endpoint SOAP 1.1 `billService` de Pruebas / Homologación.
  static final Uri testSoapUri = Uri.parse(
    'https://ose-gw1.efact.pe/ol-ti-itcpe/billService',
  );

  /// Modo de operación seleccionado (`restXml`, `restJson` o `soapUbl`).
  final EfactIntegrationMode mode;

  /// URI base del servicio REST o endpoint SOAP de EFACT.
  final Uri baseUri;

  /// Usuario (RUC del emisor en REST o usuario WS-Security en SOAP).
  final String username;

  /// Contraseña o clave secundaria configurada en EFACT.
  final String password;

  /// Identificador de cliente OAuth2 para el endpoint `/oauth/token`.
  final String oauthClientId;

  /// Secreto de cliente OAuth2 para el endpoint `/oauth/token`.
  final String oauthClientSecret;

  /// Credenciales del certificado digital X.509 (obligatorio en `restXml` y `soapUbl`).
  final CpeCertificateCredentials? certificate;

  /// Indica si en modo REST se debe realizar polling automático a `/v1/cdr/{ticket}` tras enviar un documento.
  final bool autoPollInRest;

  /// Estrategia de reintentos y backoff exponencial para el polling de tickets.
  final PollingConfig pollingConfig;

  /// Tiempo máximo de espera por petición HTTP.
  final Duration timeout;

  /// Crea una configuración personalizada para [EfactProvider].
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

  /// Crea una configuración EFACT REST XML (XML UBL 2.1 firmado localmente + OAuth2).
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

  /// Crea una configuración EFACT REST JSON (modo PSE con firma en la nube + OAuth2).
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

  /// Crea una configuración EFACT SOAP 1.1 UBL 2.1 (`billService` + WS-Security).
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
