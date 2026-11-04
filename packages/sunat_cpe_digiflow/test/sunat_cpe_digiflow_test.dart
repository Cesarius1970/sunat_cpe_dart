import 'package:sunat_cpe_digiflow/sunat_cpe_digiflow.dart';
import 'package:test/test.dart';

void main() {
  group('DigiflowSoapEnvelope & DigiflowConfig', () {
    test('builds Digiflow SOAP 1.1 envelope with mustUnderstand="1" WS-Security header', () {
      final xml = const DigiflowSoapEnvelope().build(
        wsseUsername: '20100066603MODDATOS',
        wssePassword: 'secret',
        bodyXml: '<ser:sendBill/>',
      );

      expect(xml, contains('soapenv:mustUnderstand="1"'));
      expect(
        xml,
        contains('<wsse:Username>20100066603MODDATOS</wsse:Username>'),
      );
      expect(xml, contains('<ser:sendBill/>'));
    });

    test(
      'DigiflowConfig defines official production and testing endpoints',
      () {
        expect(
          DigiflowConfig.productionEndpoint.toString(),
          'https://ose.digiflow.pe/ol-ti-itcpe/billService',
        );
        expect(
          DigiflowConfig.testingEndpoint.toString(),
          'https://osetest.digiflow.pe/ol-ti-itcpe/billService',
        );
      },
    );
  });
}
