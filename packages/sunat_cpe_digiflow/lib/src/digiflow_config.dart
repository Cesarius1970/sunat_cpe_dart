import 'package:sunat_cpe_core/sunat_cpe_core.dart';

/// Entorno de operación para los endpoints OSE de Digiflow.
enum DigiflowEnvironment {
  /// Entorno de producción oficial de Digiflow OSE.
  production,

  /// Entorno de pruebas / homologación de Digiflow OSE.
  testing,
}

/// Modo de envío para Guías de Remisión Electrónicas (`09` / `31`) en Digiflow OSE.
enum DigiflowDespatchMode {
  /// Envía la GRE mediante `urn:sendSummary` retornando un Ticket asíncrono inmediatamente.
  asyncTicket,

  /// Envía la GRE mediante `urn:sendBill` recibiendo el CDR de forma síncrona y envolviéndolo en un Ticket sintético en caché.
  syncSendBill,
}

/// Configuración de conexión, credenciales WS-Security y modo GRE para [DigiflowProvider].
final class DigiflowConfig {
  /// Endpoint oficial SOAP 1.1 de Digiflow OSE en producción.
  static final Uri productionEndpoint = Uri.parse(
    'https://ose.digiflow.pe/ol-ti-itcpe/billService',
  );

  /// Endpoint oficial SOAP 1.1 de Digiflow OSE en homologación / pruebas.
  static final Uri testingEndpoint = Uri.parse(
    'https://osetest.digiflow.pe/ol-ti-itcpe/billService',
  );

  /// URI del servicio SOAP 1.1 `billService` de Digiflow.
  final Uri endpointUri;

  /// Usuario de autenticación WS-Security (`UsernameToken`) asignado por Digiflow.
  final String username;

  /// Contraseña de autenticación WS-Security (`PasswordText`) asignada por Digiflow.
  final String password;

  /// Credenciales del certificado digital X.509 y llave privada RSA para firma XAdES-BES.
  final CpeCertificateCredentials certificate;

  /// Modo de transmisión para Guías de Remisión (`asyncTicket` o `syncSendBill`).
  final DigiflowDespatchMode despatchMode;

  /// Crea una configuración de [DigiflowConfig] especificando un [endpointUri] explícito.
  const DigiflowConfig({
    required this.endpointUri,
    required this.username,
    required this.password,
    required this.certificate,
    this.despatchMode = DigiflowDespatchMode.asyncTicket,
  });

  /// Construye una instancia de [DigiflowConfig] seleccionando automáticamente la URL oficial según [environment].
  factory DigiflowConfig.forEnvironment({
    required DigiflowEnvironment environment,
    required String username,
    required String password,
    required CpeCertificateCredentials certificate,
    DigiflowDespatchMode despatchMode = DigiflowDespatchMode.asyncTicket,
  }) {
    return DigiflowConfig(
      endpointUri: environment == DigiflowEnvironment.production
          ? productionEndpoint
          : testingEndpoint,
      username: username,
      password: password,
      certificate: certificate,
      despatchMode: despatchMode,
    );
  }
}
