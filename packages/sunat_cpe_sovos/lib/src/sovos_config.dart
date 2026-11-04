import 'package:sunat_cpe_core/sunat_cpe_core.dart';

/// Modo de integración con la plataforma Sovos / Paperless.
enum SovosIntegrationMode {
  /// Servicio estándar OSE SOAP 1.1 `billService` con XML UBL 2.1 firmado localmente con XAdES-BES.
  oseUblSigned,

  /// Modo PSE con firma HSM en la nube de Sovos (`OnlineGeneration`).
  pseCloudSign,
}

/// Configuración de conexión, modo de firma, campos personalizados de impresión e idempotencia para [SovosProvider].
final class SovosConfig {
  /// Endpoint oficial SOAP 1.1 de Sovos OSE en producción.
  static final Uri productionEndpoint = Uri.parse(
    'https://ose.sovos.com.pe/ol-ti-itcpe/billService',
  );

  /// Endpoint oficial SOAP 1.1 de Sovos OSE en certificación / QA.
  static final Uri certificationEndpoint = Uri.parse(
    'https://ose-cert.sovos.com.pe/ol-ti-itcpe/billService',
  );

  /// URI del servicio SOAP 1.1 de Sovos / Paperless.
  final Uri endpointUri;

  /// Usuario de autenticación WS-Security (`UsernameToken`) asignado por Sovos.
  final String username;

  /// Contraseña de autenticación WS-Security (`PasswordText`) asignada por Sovos.
  final String password;

  /// Credenciales del certificado digital X.509 y llave privada RSA para firma XAdES-BES.
  final CpeCertificateCredentials certificate;

  /// Modalidad de integración (`oseUblSigned` o `pseCloudSign`).
  final SovosIntegrationMode mode;

  /// Si es `true`, recupera automáticamente el CDR original vía `getStatusCdr` cuando un reintento devuelve código de duplicado (`1033` o `2017`).
  final bool autoRecoverCdrOnDuplicate;

  /// Campos adicionales personalizados para la representación impresa PDF de Paperless.
  final Map<String, String> customPrintFields;

  /// Crea una configuración inmutable [SovosConfig].
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
