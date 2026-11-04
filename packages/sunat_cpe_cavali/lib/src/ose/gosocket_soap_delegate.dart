import 'package:sunat_cpe_core/sunat_cpe_core.dart';

/// Delegado interno SOAP 1.1 para la validación OSE en Gosocket / Carvajal.
final class GosocketSoapDelegate extends BaseUblOseProvider {
  /// Crea una instancia de [GosocketSoapDelegate].
  GosocketSoapDelegate({
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
  String get providerId => 'cavali_gosocket_ose';
}
