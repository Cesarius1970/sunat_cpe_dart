import 'package:sunat_cpe_core/sunat_cpe_core.dart';

/// Delegado interno que extiende [BaseUblOseProvider] para el modo SOAP 1.1 de EFACT (`ol-ti-itcpe/billService`).
final class EfactSoapDelegate extends BaseUblOseProvider {
  /// Crea un delegado SOAP 1.1 configurado para el endpoint `billService` de EFACT.
  EfactSoapDelegate({
    required super.endpointUri,
    required super.wsseUsername,
    required super.wssePassword,
    required super.certificate,
    super.httpClient,
    super.validator,
    super.xmlBuilder,
    super.signer,
    super.zipCodec,
  });

  @override
  String get providerId => 'efact_soap';
}
