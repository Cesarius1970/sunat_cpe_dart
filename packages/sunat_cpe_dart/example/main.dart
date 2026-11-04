import 'package:sunat_cpe_dart/sunat_cpe_dart.dart';

void main() {
  final router = SunatCpeRouter.fromDescriptors(
    primaryDescriptor: NubefactDescriptor(
      NubefactConfig(
        routeUri: Uri.parse('https://api.nubefact.com/api/v1/demo'),
        apiToken: 'DEMO_TOKEN',
      ),
    ),
    routeDescriptorsByDocumentType: {
      CpeDocumentType.guiaRemisionRemitente: DirectSunatDescriptor(
        SunatDirectConfig.beta(),
      ),
    },
  );

  print(
    'Router initialized: ${router.providerId}, '
    'GRE target: ${router.resolveProviderForDocumentType(CpeDocumentType.guiaRemisionRemitente).providerId}',
  );
}
