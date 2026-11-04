import 'package:sunat_cpe_core/sunat_cpe_core.dart';

/// Entorno de operación para los endpoints OSE de Bizlinks.
enum BizlinksEnvironment {
  /// Entorno de producción oficial de Bizlinks OSE.
  production,

  /// Entorno de pruebas / homologación de Bizlinks OSE.
  testing,
}

/// Configuración de conexión, credenciales WS-Security y certificado digital para [BizlinksProvider].
final class BizlinksConfig {
  /// Endpoint oficial SOAP 1.1 de Bizlinks OSE en producción.
  static final Uri productionEndpoint = Uri.parse(
    'https://ose.bizlinks.com.pe/ol-ti-itcpe/billService',
  );

  /// Endpoint oficial SOAP 1.1 de Bizlinks OSE en homologación / pruebas.
  static final Uri testingEndpoint = Uri.parse(
    'https://osetesting.bizlinks.com.pe/ol-ti-itcpe/billService',
  );

  /// URI del servicio SOAP 1.1 `billService` de Bizlinks.
  final Uri endpointUri;

  /// Usuario de autenticación WS-Security (`UsernameToken`) asignado por Bizlinks.
  final String username;

  /// Contraseña de autenticación WS-Security (`PasswordText`) asignada por Bizlinks.
  final String password;

  /// Credenciales del certificado digital X.509 y llave privada RSA para firma XAdES-BES.
  final CpeCertificateCredentials certificate;

  /// Crea una configuración de [BizlinksConfig] especificando un [endpointUri] explícito.
  const BizlinksConfig({
    required this.endpointUri,
    required this.username,
    required this.password,
    required this.certificate,
  });

  /// Construye una instancia de [BizlinksConfig] seleccionando automáticamente la URL oficial según [environment].
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
