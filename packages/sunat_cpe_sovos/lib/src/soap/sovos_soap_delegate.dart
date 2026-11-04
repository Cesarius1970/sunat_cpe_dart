import 'package:sunat_cpe_core/sunat_cpe_core.dart';

import '../ubl/sovos_ubl_extension_builder.dart';

/// Custom [CpeZipCodec] wrapper that injects Sovos/Paperless print extensions into XML if needed,
/// or delegates directly to [BaseUblOseProvider].
final class SovosSoapDelegate extends BaseUblOseProvider {
  final SovosUblExtensionBuilder extensionBuilder;
  final Map<String, String> customPrintFields;

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
