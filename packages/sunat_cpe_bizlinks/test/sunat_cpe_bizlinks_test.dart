import 'dart:convert';
import 'dart:typed_data';

import 'package:sunat_cpe_bizlinks/sunat_cpe_bizlinks.dart';
import 'package:sunat_cpe_core/sunat_cpe_core.dart';
import 'package:test/test.dart';

void main() {
  group('BizlinksSoapFaultParser & BizlinksConfig', () {
    const parser = BizlinksSoapFaultParser();

    test('extracts SUNAT rejection code when faultstring is numeric and description is in detail/message', () {
      const faultXml = '''<?xml version="1.0" encoding="UTF-8"?>
<soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/">
  <soapenv:Body>
    <soapenv:Fault>
      <faultcode>soapenv:Client</faultcode>
      <faultstring>2017</faultstring>
      <detail>
        <message>El comprobante ya fue informado anteriormente a Bizlinks OSE</message>
      </detail>
    </soapenv:Fault>
  </soapenv:Body>
</soapenv:Envelope>''';

      final ex = parser.parseFault(
        CpeHttpResponse(
          statusCode: 500,
          headers: const {},
          bodyBytes: Uint8List.fromList(utf8.encode(faultXml)),
        ),
      );

      expect(ex, isA<SunatRejectionException>());
      final rejection = ex as SunatRejectionException;
      expect(rejection.sunatCode, 2017);
      expect(rejection.message, contains('informado anteriormente'));
    });

    test(
      'extracts SUNAT exception code (0100-1999) from Client.0151 faultcode',
      () {
        const faultXml = '''<?xml version="1.0" encoding="UTF-8"?>
<soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/">
  <soapenv:Body>
    <soapenv:Fault>
      <faultcode>soap-env:Client.0151</faultcode>
      <faultstring>El nombre del archivo XML no corresponde al ZIP</faultstring>
    </soapenv:Fault>
  </soapenv:Body>
</soapenv:Envelope>''';

        final ex = parser.parseFault(
          CpeHttpResponse(
            statusCode: 500,
            headers: const {},
            bodyBytes: Uint8List.fromList(utf8.encode(faultXml)),
          ),
        );

        expect(ex, isA<SunatExceptionError>());
        expect((ex as SunatExceptionError).sunatCode, 151);
      },
    );

    test('BizlinksConfig.forEnvironment selects official production and testing URLs', () {
      expect(
        BizlinksConfig.productionEndpoint.toString(),
        'https://ose.bizlinks.com.pe/ol-ti-itcpe/billService',
      );
      expect(
        BizlinksConfig.testingEndpoint.toString(),
        'https://osetesting.bizlinks.com.pe/ol-ti-itcpe/billService',
      );
    });
  });
}
