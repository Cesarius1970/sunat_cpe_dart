import 'package:sunat_cpe_cavali/sunat_cpe_cavali.dart';

void main() {
  print(
    'Cavali / Gosocket OSE & Factrack endpoints:\n'
    ' - OSE SOAP Testing:      ${CavaliConfig.testingOseSoapUri}\n'
    ' - Factrack REST Testing: ${CavaliConfig.testingFactrackUri}',
  );
}
