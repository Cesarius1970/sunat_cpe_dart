import 'package:sunat_cpe_core/sunat_cpe_core.dart';

import '../ubl/sovos_ubl_extension_builder.dart';

/// Delegado SOAP 1.1 para Sovos / Paperless que extiende [BaseUblOseProvider]
/// gestionando extensiones personalizadas de impresión.
final class SovosSoapDelegate extends BaseUblOseProvider {
  /// Constructor de extensiones UBL personalizadas para Paperless.
  final SovosUblExtensionBuilder extensionBuilder;

  /// Mapa de campos personalizados de impresión configurados para Sovos / Paperless.
  final Map<String, String> customPrintFields;

  /// Crea una instancia de [SovosSoapDelegate].
  SovosSoapDelegate({
    required super.endpointUri,
    required super.wsseUsername,
    required super.wssePassword,
    required super.certificate,
    super.httpClient,
    super.validator,
    super.xmlBuilder,
    this.extensionBuilder = const SovosUblExtensionBuilder(),
    this.customPrintFields = const {},
    super.signer,
    super.zipCodec,
  });

  @override
  String get providerId => 'sovos';
}
