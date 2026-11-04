import 'package:sunat_cpe_direct/sunat_cpe_direct.dart';

void main() {
  final provider = SunatDirectProvider(
    config: SunatDirectConfig.beta(
      clientId: 'demo-client-id',
      clientSecret: 'demo-client-secret',
    ),
  );

  print(
    'Initialized ${provider.providerId} in ${provider.config.environment.name} mode',
  );
}
