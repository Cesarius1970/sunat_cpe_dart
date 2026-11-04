import 'package:sunat_cpe_core/sunat_cpe_core.dart';

/// Environment for Digiflow OSE endpoints.
enum DigiflowEnvironment { production, testing }

/// Submission mode for Despatch Advice (`09` / `31`) in Digiflow OSE.
enum DigiflowDespatchMode {
  /// Sends GRE via `urn:sendSummary` returning a Ticket immediately.
  asyncTicket,

  /// Sends GRE via `urn:sendBill` receiving the CDR synchronously and wrapping it in a synthetic Ticket.
  syncSendBill,
}

/// Configuration for [DigiflowProvider].
final class DigiflowConfig {
  /// Production SOAP 1.1 OSE endpoint.
  static final Uri productionEndpoint = Uri.parse(
    'https://ose.digiflow.pe/ol-ti-itcpe/billService',
  );

  /// Testing / Homologation SOAP 1.1 OSE endpoint.
  static final Uri testingEndpoint = Uri.parse(
    'https://osetest.digiflow.pe/ol-ti-itcpe/billService',
  );

  final Uri endpointUri;
  final String username;
  final String password;
  final CpeCertificateCredentials certificate;
  final DigiflowDespatchMode despatchMode;

  const DigiflowConfig({
    required this.endpointUri,
    required this.username,
    required this.password,
    required this.certificate,
    this.despatchMode = DigiflowDespatchMode.asyncTicket,
  });

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
