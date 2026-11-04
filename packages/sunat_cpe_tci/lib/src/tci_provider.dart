import 'package:sunat_cpe_core/sunat_cpe_core.dart';
import 'soap/tci_soap_fault_parser.dart';
import 'tci_config.dart';

/// TCI (Transporte Confidencial de Información / Efacturación) OSE Provider.
final class TciProvider extends BaseUblOseProvider {
  final TciConfig config;
  final TciSoapFaultParser faultParser;

  TciProvider({
    required this.config,
    super.httpClient,
    super.validator,
    super.xmlBuilder,
    super.signer,
    super.zipCodec,
    this.faultParser = const TciSoapFaultParser(),
  }) : super(
          endpointUri: config.endpointUri,
          wsseUsername: config.formattedWsseUsername,
          wssePassword: config.osePassword,
          certificate: config.certificate,
        );

  @override
  String get providerId => 'tci';

  @override
  CpeException? parseSoapFaultIfPresent(CpeHttpResponse response) {
    return faultParser.parseFault(response) ??
        super.parseSoapFaultIfPresent(response);
  }
}
