import 'package:sunat_cpe_core/sunat_cpe_core.dart';

/// Internal SOAP 1.1 delegate extending [BaseUblOseProvider] for direct SUNAT `billService` endpoints.
final class SunatDirectSoapDelegate extends BaseUblOseProvider {
  final String channelId;

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
