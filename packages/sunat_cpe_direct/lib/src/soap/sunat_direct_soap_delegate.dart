import 'package:sunat_cpe_core/sunat_cpe_core.dart';

/// Delegado interno SOAP 1.1 que extiende [BaseUblOseProvider] para los endpoints `billService` directos de SUNAT.
final class SunatDirectSoapDelegate extends BaseUblOseProvider {
  /// Identificador interno del canal SOAP (`sunat_direct_soap_factura`, `sunat_direct_soap_otroscpe`, etc.).
  final String channelId;

  /// Crea una instancia de [SunatDirectSoapDelegate].
  SunatDirectSoapDelegate({
    required this.channelId,
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
  String get providerId => channelId;
}
