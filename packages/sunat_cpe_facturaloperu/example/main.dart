import 'package:sunat_cpe_facturaloperu/sunat_cpe_facturaloperu.dart';

void main() {
  final provider = FacturaloProvider(
    config: FacturaloConfig(
      baseUri: Uri.parse('https://demo.facturaloperu.com'),
      apiToken: 'DEMO_BEARER_TOKEN',
    ),
  );

  print(
    'Initialized ${provider.providerId} with capabilities: ${provider.capabilities}',
  );
}
