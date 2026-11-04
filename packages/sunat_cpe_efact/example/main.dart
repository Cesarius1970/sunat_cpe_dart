import 'package:sunat_cpe_efact/sunat_cpe_efact.dart';

void main() {
  final provider = EfactProvider(
    config: EfactConfig(
      baseUri: EfactConfig.testRestUri,
      username: '20100066603',
      password: 'demo-password',
      mode: EfactIntegrationMode.restJson,
    ),
  );

  print(
    'Initialized ${provider.providerId} with capabilities: ${provider.capabilities}',
  );
}
