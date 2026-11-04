import 'package:sunat_cpe_core/sunat_cpe_core.dart';
import 'bizlinks_config.dart';
import 'soap/bizlinks_soap_fault_parser.dart';

/// Bizlinks OSE Provider extending [BaseUblOseProvider] for SOAP 1.1 `billService`.
final class BizlinksProvider extends BaseUblOseProvider {
  final BizlinksConfig config;
  final BizlinksSoapFaultParser faultParser;

  BizlinksProvider({
    required this.config,
    super.httpClient,
    super.validator,
    super.xmlBuilder,
    super.signer,
    super.zipCodec,
    this.faultParser = const BizlinksSoapFaultParser(),
  }) : super(
          endpointUri: config.endpointUri,
          wsseUsername: config.username,
          wssePassword: config.password,
          certificate: config.certificate,
        );

  @override
  String get providerId => 'bizlinks';

  @override
  CpeException? parseSoapFaultIfPresent(CpeHttpResponse response) {
    return faultParser.parseFault(response) ??
        super.parseSoapFaultIfPresent(response);
  }
}
