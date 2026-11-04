import 'package:sunat_cpe_sovos/sunat_cpe_sovos.dart';
import 'package:test/test.dart';

void main() {
  group('SovosUblExtensionBuilder & SovosConfig', () {
    test(
      'injects customPrintFields inside UBLExtensions without corrupting XML',
      () {
        const sampleXml = '''<?xml version="1.0" encoding="UTF-8"?>
<Invoice xmlns="urn:oasis:names:specification:ubl:schema:xsd:Invoice-2"
  xmlns:ext="urn:oasis:names:specification:ubl:schema:xsd:CommonExtensionComponents-2">
  <ext:UBLExtensions>
    <ext:UBLExtension>
      <ext:ExtensionContent/>
    </ext:UBLExtension>
  </ext:UBLExtensions>
</Invoice>''';

        final modified = const SovosUblExtensionBuilder()
            .injectCustomPrintFields(sampleXml, const {
              'CAJERO': 'CAJA-04',
              'SUCURSAL': 'MIRAFLORES',
            });

        expect(modified, contains('<SovosCustomPrintFields>'));
        expect(modified, contains('<Field name="CAJERO">CAJA-04</Field>'));
        expect(modified, contains('<Field name="SUCURSAL">MIRAFLORES</Field>'));
      },
    );

    test(
      'SovosConfig exposes official production and certification endpoints',
      () {
        expect(
          SovosConfig.productionEndpoint.toString(),
          'https://ose.sovos.com.pe/ol-ti-itcpe/billService',
        );
        expect(
          SovosConfig.certificationEndpoint.toString(),
          'https://ose-cert.sovos.com.pe/ol-ti-itcpe/billService',
        );
      },
    );
  });
}
