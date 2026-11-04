import 'package:sunat_cpe_bizlinks/sunat_cpe_bizlinks.dart';

void main() {
  print(
    'Bizlinks OSE endpoints:\n'
    ' - Production: ${BizlinksConfig.productionEndpoint}\n'
    ' - Testing:    ${BizlinksConfig.testingEndpoint}',
  );
}
