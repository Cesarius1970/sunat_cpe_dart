import 'package:sunat_cpe_tci/sunat_cpe_tci.dart';

void main() {
  print(
    'TCI OSE endpoints:\n'
    ' - Production: ${TciConfig.productionEndpoint}\n'
    ' - Testing:    ${TciConfig.testingEndpoint}',
  );
}
