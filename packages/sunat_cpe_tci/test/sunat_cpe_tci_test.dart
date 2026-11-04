import 'dart:convert';
import 'dart:typed_data';

import 'package:sunat_cpe_core/sunat_cpe_core.dart';
import 'package:sunat_cpe_tci/sunat_cpe_tci.dart';
import 'package:test/test.dart';

void main() {
  group('TciSoapFaultParser & TciConfig', () {
    const parser = TciSoapFaultParser();

    test(
      'extracts SUNAT rejection code 2800 from soap-env:Client.2800 faultcode',
      () {
        const faultXml = '''<?xml version="1.0" encoding="UTF-8"?>
<soap-env:Envelope xmlns:soap-env="http://schemas.xmlsoap.org/soap/envelope/">
  <soap-env:Body>
    <soap-env:Fault>
      <faultcode>soap-env:Client.2800</faultcode>
      <faultstring>El dato ingresado en el tipo de documento de identidad del receptor no esta permitido</faultstring>
      <detail>
        <message>Detalle adicional TCI OSE</message>
      </detail>
    </soap-env:Fault>
  </soap-env:Body>
</soap-env:Envelope>''';

        final ex = parser.parseFault(
          CpeHttpResponse(
            statusCode: 500,
            headers: const {},
            bodyBytes: Uint8List.fromList(utf8.encode(faultXml)),
          ),
        );

        expect(ex, isA<SunatRejectionException>());
        final rejection = ex as SunatRejectionException;
        expect(rejection.sunatCode, 2800);
        expect(rejection.message, contains('tipo de documento de identidad'));
      },
    );

    test('TciConfig exposes official production and testing endpoints', () {
      expect(
        TciConfig.productionEndpoint.toString(),
        'https://ose.tci.net.pe/ol-ti-itcpe/billService',
      );
      expect(
        TciConfig.testingEndpoint.toString(),
        'https://osetest.tci.net.pe/ol-ti-itcpe/billService',
      );
    });
  });
}
