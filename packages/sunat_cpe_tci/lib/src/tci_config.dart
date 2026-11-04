import 'package:sunat_cpe_core/sunat_cpe_core.dart';

/// Entorno de operación para los endpoints OSE de TCI.
enum TciEnvironment {
  /// Entorno de producción oficial de TCI OSE.
  production,

  /// Entorno de pruebas / homologación de TCI OSE.
  testing,
}

/// Configuración de conexión, formato de credenciales WS-Security y certificado para [TciProvider].
final class TciConfig {
  /// Endpoint oficial SOAP 1.1 de TCI OSE en producción.
  static final Uri productionEndpoint = Uri.parse(
    'https://ose.tci.net.pe/ol-ti-itcpe/billService',
  );

  /// Endpoint oficial SOAP 1.1 de TCI OSE en homologación / pruebas.
  static final Uri testingEndpoint = Uri.parse(
    'https://osetest.tci.net.pe/ol-ti-itcpe/billService',
  );

  /// URI del servicio SOAP 1.1 `billService` de TCI.
  final Uri endpointUri;

  /// Número de RUC de 11 dígitos de la empresa emisora.
  final String ruc;

  /// Usuario secundario OSE asignado por TCI (se concatena automáticamente con [ruc]).
  final String oseUser;

  /// Contraseña de autenticación WS-Security (`PasswordText`) asignada por TCI.
  final String osePassword;

  /// Credenciales del certificado digital X.509 y llave privada RSA para firma XAdES-BES.
  final CpeCertificateCredentials certificate;

  /// Crea una configuración de [TciConfig] especificando un [endpointUri] explícito.
  const TciConfig({
    required this.endpointUri,
    required this.ruc,
    required this.oseUser,
    required this.osePassword,
    required this.certificate,
  });

  /// Usuario WS-Security formateado como `{RUC}{USUARIO_OSE_TCI}` (salvo que `oseUser` ya inicie con `ruc`).
  String get formattedWsseUsername =>
      oseUser.startsWith(ruc) ? oseUser : '$ruc$oseUser';

  /// Construye una instancia de [TciConfig] seleccionando automáticamente la URL oficial según [environment].
  factory TciConfig.forEnvironment({
    required TciEnvironment environment,
    required String ruc,
    required String oseUser,
    required String osePassword,
    required CpeCertificateCredentials certificate,
  }) {
    return TciConfig(
      endpointUri: environment == TciEnvironment.production
          ? productionEndpoint
          : testingEndpoint,
      ruc: ruc,
      oseUser: oseUser,
      osePassword: osePassword,
      certificate: certificate,
    );
  }
}
