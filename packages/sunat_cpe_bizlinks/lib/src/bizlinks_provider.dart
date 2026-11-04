import 'package:sunat_cpe_core/sunat_cpe_core.dart';

import 'bizlinks_config.dart';
import 'soap/bizlinks_soap_fault_parser.dart';

/// Proveedor OSE de Bizlinks que extiende [BaseUblOseProvider] para el servicio SOAP 1.1 `billService`.
final class BizlinksProvider extends BaseUblOseProvider {
  /// Configuración del endpoint, credenciales WS-Security y certificado X.509 de Bizlinks.
  final BizlinksConfig config;

  /// Analizador especializado de fallos SOAP (`<soap:Fault>`) de Bizlinks OSE.
  final BizlinksSoapFaultParser faultParser;

  /// Inicializa el proveedor [BizlinksProvider] con la configuración y dependencias opcionales de transporte o firma.
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
