import 'package:sunat_cpe_core/sunat_cpe_core.dart';

/// Configuración para [CavaliProvider] (Validación OSE SOAP 1.1 en Gosocket + Factoring REST OAuth2 en Cavali Factrack).
final class CavaliConfig {
  /// Endpoint SOAP 1.1 de producción para el OSE Gosocket / Carvajal.
  static final Uri productionOseSoapUri = Uri.parse(
    'https://ose.gosocket.net/ol-ti-itcpe/billService',
  );

  /// Endpoint SOAP 1.1 de pruebas para el OSE Gosocket / Carvajal.
  static final Uri testingOseSoapUri = Uri.parse(
    'https://osetest.gosocket.net/ol-ti-itcpe/billService',
  );

  /// URL base de producción para la API REST Cavali Factrack v2.
  static final Uri productionFactrackUri = Uri.parse(
    'https://api.cavali.com.pe/factrack/v2',
  );

  /// URL base de pruebas / QA para la API REST Cavali Factrack v2.
  static final Uri testingFactrackUri = Uri.parse(
    'https://apidev.cavali.com.pe/factrack/v2',
  );

  /// Endpoint SOAP 1.1 utilizado para la validación OSE.
  final Uri oseSoapEndpoint;

  /// Usuario WS-Security para el servicio SOAP OSE.
  final String wsseUsername;

  /// Contraseña WS-Security para el servicio SOAP OSE.
  final String wssePassword;

  /// Credenciales del certificado digital X.509 para la firma XAdES-BES local.
  final CpeCertificateCredentials certificate;

  /// URL base de la API REST Cavali Factrack v2.
  final Uri factrackBaseUri;

  /// Client ID OAuth2 para Cavali Factrack v2.
  final String? factrackClientId;

  /// Client Secret OAuth2 para Cavali Factrack v2.
  final String? factrackClientSecret;

  /// Llave de suscripción (`x-api-key`) para el API Gateway de Cavali Factrack.
  final String? factrackApiKey;

  /// Tiempo máximo de espera por petición HTTP.
  final Duration timeout;

  /// Crea una configuración para [CavaliProvider].
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
