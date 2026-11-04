import 'package:sunat_cpe_mifact/sunat_cpe_mifact.dart';

void main() {
  final provider = MifactProvider(
    config: MifactConfig(
      baseUri: Uri.parse('https://demo.mifact.net.pe/api/invoice.svc'),
      token: MifactConfig.demoToken,
    ),
  );

  print(
    'Initialized ${provider.providerId} with capabilities: ${provider.capabilities}',
  );
}
