import 'package:sunat_cpe_core/sunat_cpe_core.dart';

/// Internal SOAP 1.1 delegate for Gosocket / Carvajal OSE validation.
final class GosocketSoapDelegate extends BaseUblOseProvider {
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
