import 'package:sunat_cpe_core/sunat_cpe_core.dart';

import 'sunat_direct_mock_certificate.dart';

/// Entornos operativos para los Web Services directos de SUNAT (SOAP y API REST GRE).
enum SunatDirectEnvironment {
  /// Ambiente de pruebas Beta de SUNAT (`e-beta.sunat.gob.pe`).
  beta,

  /// Ambiente de Homologación / SQA de SUNAT.
  homologacion,

  /// Ambiente de Producción de SUNAT (`e-factura.sunat.gob.pe`).
  produccion;

  /// Endpoint SOAP para Facturas (01), Boletas (03), Liquidaciones (04), Notas (07/08), RC y RA.
  Uri get soapInvoiceUri => Uri.parse(switch (this) {
    SunatDirectEnvironment.beta =>
      'https://e-beta.sunat.gob.pe/ol-ti-itcpfegem-beta/billService',
    SunatDirectEnvironment.homologacion =>
      'https://www.sunat.gob.pe/ol-ti-itcpgem-sqa/billService',
    SunatDirectEnvironment.produccion =>
      'https://e-factura.sunat.gob.pe/ol-ti-itcpfegem/billService',
  });

  /// Endpoint SOAP para Retenciones (20), Percepciones (40) y Reversiones (RR).
  Uri get soapOtrosCpeUri => Uri.parse(switch (this) {
    SunatDirectEnvironment.beta => 'https://e-beta.sunat.gob.pe/ol-ti-itemision-otroscpe-gem-beta/billService',
    SunatDirectEnvironment.homologacion =>
      'https://www.sunat.gob.pe/ol-ti-itemision-otroscpe-gem-sqa/billService',
    SunatDirectEnvironment.produccion =>
      'https://e-factura.sunat.gob.pe/ol-ti-itemision-otroscpe-gem/billService',
  });

  /// Endpoint SOAP heredado para Guías de Remisión (09/31) cuando `useRestForGre` es `false`.
  Uri get soapGuiaRemisionUri => Uri.parse(switch (this) {
    SunatDirectEnvironment.beta =>
      'https://e-beta.sunat.gob.pe/ol-ti-itemision-guia-gem-beta/billService',
    SunatDirectEnvironment.homologacion =>
      'https://www.sunat.gob.pe/ol-ti-itemision-guia-gem-sqa/billService',
    SunatDirectEnvironment.produccion => 'https://e-guiaremision.sunat.gob.pe/ol-ti-itemision-guia-gem/billService',
  });

  /// Endpoint OAuth2 para la obtención de tokens en la API REST de SUNAT (`api-seguridad.sunat.gob.pe`).
  Uri restOAuthTokenUri(String clientId) => Uri.parse(
    'https://api-seguridad.sunat.gob.pe/v1/clientessol/$clientId/oauth2/token',
  );

  /// URL base para la API REST de Guías de Remisión Electrónicas de SUNAT (`api-cpe.sunat.gob.pe`).
  Uri get restGreBaseUri =>
      Uri.parse('https://api-cpe.sunat.gob.pe/v1/contribuyente/gem');
}

/// Configuración y credenciales SOL / OAuth2 para [SunatDirectProvider].
final class SunatDirectConfig {
  /// RUC de 11 dígitos del contribuyente emisor.
  final String ruc;

  /// Usuario secundario SOL (p. ej. `MODDATOS` en el ambiente Beta).
  final String usuarioSol;

  /// Contraseña de la Clave SOL.
  final String claveSol;

  /// Client ID OAuth2 para la API REST GRE de SUNAT (`09`/`31`).
  final String? clientId;

  /// Client Secret OAuth2 para la API REST GRE de SUNAT (`09`/`31`).
  final String? clientSecret;

  /// Entorno objetivo de SUNAT.
  final SunatDirectEnvironment environment;

  /// Certificado digital utilizado para la firma XAdES-BES.
  final CpeCertificateCredentials certificate;

  /// Indica si [certificate] es un certificado simulado de prueba (permitido únicamente en [SunatDirectEnvironment.beta]).
  final bool isMockCertificate;

  /// Utiliza la API REST OAuth2 de SUNAT (`api-cpe.sunat.gob.pe`) para Guías de Remisión (`09`/`31`) cuando es `true`.
  final bool useRestForGre;

  /// Tiempo máximo de espera por petición HTTP.
  final Duration timeout;

  /// Crea una configuración validada para [SunatDirectProvider].
  SunatDirectConfig({
    required this.ruc,
    required this.usuarioSol,
    required this.claveSol,
    this.clientId,
    this.clientSecret,
    this.environment = SunatDirectEnvironment.beta,
    CpeCertificateCredentials? certificate,
    this.isMockCertificate = false,
    this.useRestForGre = true,
    this.timeout = const Duration(seconds: 30),
  }) : certificate = _resolveCertificate(
         environment: environment,
         certificate: certificate,
         isMockCertificate: isMockCertificate,
       );

  /// Constructor de fábrica para el ambiente Beta de SUNAT (`20100066603` / `MODDATOS` / `moddatos`).
  factory SunatDirectConfig.beta({
    String ruc = '20100066603',
    String usuarioSol = 'MODDATOS',
    String claveSol = 'moddatos',
    String? clientId,
    String? clientSecret,
    CpeCertificateCredentials? certificate,
    bool useRestForGre = true,
  }) {
    return SunatDirectConfig(
      ruc: ruc,
      usuarioSol: usuarioSol,
      claveSol: claveSol,
      clientId: clientId,
      clientSecret: clientSecret,
      environment: SunatDirectEnvironment.beta,
      certificate: certificate,
      isMockCertificate: certificate == null,
      useRestForGre: useRestForGre,
    );
  }

  /// Nombre de usuario compuesto para WS-Security y OAuth2 (`{RUC}{USUARIO_SOL}`).
  String get wsseUsername =>
      usuarioSol.startsWith(ruc) ? usuarioSol : '$ruc$usuarioSol';

  /// Devuelve `true` si `clientId` y `clientSecret` están configurados para OAuth2 en la API REST GRE de SUNAT.
  bool get hasRestCredentials =>
      clientId != null &&
      clientId!.trim().isNotEmpty &&
      clientSecret != null &&
      clientSecret!.trim().isNotEmpty;

  static CpeCertificateCredentials _resolveCertificate({
    required SunatDirectEnvironment environment,
    required CpeCertificateCredentials? certificate,
    required bool isMockCertificate,
  }) {
    if (certificate != null) {
      if (isMockCertificate && environment != SunatDirectEnvironment.beta) {
        throw ArgumentError(
          'No se permite utilizar un certificado mock en ambiente de ${environment.name}. '
          'Debe proporcionar un certificado digital X.509 válido.',
        );
      }
      return certificate;
    }

    if (environment == SunatDirectEnvironment.beta) {
      return SunatDirectMockCertificateFactory.createBetaMockCertificate();
    }

    throw ArgumentError(
      'El parámetro [certificate] es obligatorio para emitir comprobantes en ambiente de ${environment.name}. '
      'El uso de certificados mock está restringido únicamente a SunatDirectEnvironment.beta.',
    );
  }
}
