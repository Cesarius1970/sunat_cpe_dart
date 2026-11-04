import 'package:sunat_cpe_core/sunat_cpe_core.dart';

/// Environment for TCI OSE endpoints.
enum TciEnvironment { production, testing }

/// Configuration for [TciProvider].
final class TciConfig {
  /// Production TCI OSE SOAP 1.1 endpoint.
  static final Uri productionEndpoint = Uri.parse(
    'https://ose.tci.net.pe/ol-ti-itcpe/billService',
  );

  /// Testing / Homologation TCI OSE SOAP 1.1 endpoint.
  static final Uri testingEndpoint = Uri.parse(
    'https://osetest.tci.net.pe/ol-ti-itcpe/billService',
  );

  final Uri endpointUri;
  final String ruc;
  final String oseUser;
  final String osePassword;
  final CpeCertificateCredentials certificate;

  const TciConfig({
    required this.endpointUri,
    required this.ruc,
    required this.oseUser,
    required this.osePassword,
    required this.certificate,
  });

  /// Formatted WS-Security username `{RUC}{USUARIO_OSE_TCI}` (unless `oseUser` already starts with `ruc`).
  String get formattedWsseUsername =>
      oseUser.startsWith(ruc) ? oseUser : '$ruc$oseUser';

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
