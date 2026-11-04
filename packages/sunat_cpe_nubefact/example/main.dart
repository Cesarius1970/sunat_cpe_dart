import 'package:sunat_cpe_nubefact/sunat_cpe_nubefact.dart';

void main() {
  final provider = NubefactProvider(
    config: NubefactConfig(
      routeUri: Uri.parse('https://api.nubefact.com/api/v1/demo-endpoint'),
      apiToken: 'DEMO_NUBEFACT_TOKEN',
    ),
  );

  print(
    'Initialized ${provider.providerId} with capabilities: ${provider.capabilities}',
  );
}
