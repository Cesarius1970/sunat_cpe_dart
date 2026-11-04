import 'package:sunat_cpe_core/sunat_cpe_core.dart';

import 'soap/tci_soap_fault_parser.dart';
import 'tci_config.dart';

/// Proveedor OSE de TCI (Transporte Confidencial de Información / Efacturación) sobre SOAP 1.1 `billService`.
final class TciProvider extends BaseUblOseProvider {
  /// Configuración de endpoint, credenciales formateadas `{RUC}{USUARIO_OSE_TCI}` y certificado digital.
  final TciConfig config;

  /// Analizador especializado de fallos SOAP (`<soap-env:Fault>`) de TCI OSE.
  final TciSoapFaultParser faultParser;

  /// Inicializa el proveedor [TciProvider] con la configuración y dependencias opcionales.
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
