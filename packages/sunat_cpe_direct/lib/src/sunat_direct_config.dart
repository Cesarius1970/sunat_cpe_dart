import 'package:sunat_cpe_core/sunat_cpe_core.dart';

import 'sunat_direct_mock_certificate.dart';

/// Operating environments for direct SUNAT Web Services (SOAP & REST GRE).
enum SunatDirectEnvironment {
  /// SUNAT Beta testing environment (`e-beta.sunat.gob.pe`).
  beta,

  /// SUNAT Homologation / SQA environment.
  homologacion,

  /// SUNAT Production environment (`e-factura.sunat.gob.pe`).
  produccion;

  /// SOAP endpoint for Invoices (01), Boletas (03), Settlements (04), Notes (07/08), RC, and RA.
  Uri get soapInvoiceUri => Uri.parse(switch (this) {
    SunatDirectEnvironment.beta =>
      'https://e-beta.sunat.gob.pe/ol-ti-itcpfegem-beta/billService',
    SunatDirectEnvironment.homologacion =>
      'https://www.sunat.gob.pe/ol-ti-itcpgem-sqa/billService',
    SunatDirectEnvironment.produccion =>
      'https://e-factura.sunat.gob.pe/ol-ti-itcpfegem/billService',
  });

  /// SOAP endpoint for Retentions (20), Perceptions (40), and Reversions (RR).
  Uri get soapOtrosCpeUri => Uri.parse(switch (this) {
    SunatDirectEnvironment.beta => 'https://e-beta.sunat.gob.pe/ol-ti-itemision-otroscpe-gem-beta/billService',
    SunatDirectEnvironment.homologacion =>
      'https://www.sunat.gob.pe/ol-ti-itemision-otroscpe-gem-sqa/billService',
    SunatDirectEnvironment.produccion =>
      'https://e-factura.sunat.gob.pe/ol-ti-itemision-otroscpe-gem/billService',
  });

  /// Legacy SOAP endpoint for Despatch Advice (09/31) when `useRestForGre` is false.
  Uri get soapGuiaRemisionUri => Uri.parse(switch (this) {
    SunatDirectEnvironment.beta =>
      'https://e-beta.sunat.gob.pe/ol-ti-itemision-guia-gem-beta/billService',
    SunatDirectEnvironment.homologacion =>
      'https://www.sunat.gob.pe/ol-ti-itemision-guia-gem-sqa/billService',
    SunatDirectEnvironment.produccion => 'https://e-guiaremision.sunat.gob.pe/ol-ti-itemision-guia-gem/billService',
  });

  /// OAuth2 token endpoint for SUNAT REST API (`api-seguridad.sunat.gob.pe`).
  Uri restOAuthTokenUri(String clientId) => Uri.parse(
    'https://api-seguridad.sunat.gob.pe/v1/clientessol/$clientId/oauth2/token',
  );

  /// Base URL for SUNAT REST GRE API (`api-cpe.sunat.gob.pe`).
  Uri get restGreBaseUri =>
      Uri.parse('https://api-cpe.sunat.gob.pe/v1/contribuyente/gem');
}

/// Configuration and SOL / OAuth2 credentials for [SunatDirectProvider].
final class SunatDirectConfig {
  /// 11-digit RUC of the issuing taxpayer.
  final String ruc;

  /// Secondary SOL username (e.g. `MODDATOS` in beta).
  final String usuarioSol;

  /// SOL password.
  final String claveSol;

  /// OAuth2 Client ID for SUNAT REST GRE API (`09`/`31`).
  final String? clientId;

  /// OAuth2 Client Secret for SUNAT REST GRE API (`09`/`31`).
  final String? clientSecret;

  /// Target SUNAT environment.
  final SunatDirectEnvironment environment;

  /// Digital certificate used for XAdES-BES signing.
  final CpeCertificateCredentials certificate;

  /// Whether [certificate] is a synthetic mock certificate (only allowed in [SunatDirectEnvironment.beta]).
  final bool isMockCertificate;

  /// Uses SUNAT REST OAuth2 API (`api-cpe.sunat.gob.pe`) for Despatch Advice (`09`/`31`) when true.
  final bool useRestForGre;

  final Duration timeout;

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

  /// Convenience factory for SUNAT Beta (`20100066603` / `MODDATOS` / `moddatos`).
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

  /// Composite WS-Security and OAuth2 username (`{RUC}{USUARIO_SOL}`).
  String get wsseUsername =>
      usuarioSol.startsWith(ruc) ? usuarioSol : '$ruc$usuarioSol';

  /// True if `clientId` and `clientSecret` are configured for SUNAT REST GRE OAuth2.
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
