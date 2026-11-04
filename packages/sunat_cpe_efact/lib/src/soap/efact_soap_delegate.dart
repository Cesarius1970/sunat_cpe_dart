import 'package:sunat_cpe_core/sunat_cpe_core.dart';

/// Internal delegate extending [BaseUblOseProvider] for EFACT SOAP 1.1 mode (`ol-ti-itcpe/billService`).
final class EfactSoapDelegate extends BaseUblOseProvider {
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
