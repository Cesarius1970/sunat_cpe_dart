import 'dart:convert';
import 'dart:typed_data';

import 'package:sunat_cpe_core/sunat_cpe_core.dart';
import 'package:sunat_cpe_efact/sunat_cpe_efact.dart';
import 'package:test/test.dart';

final class _MockHttpClient implements CpeHttpClient {
  final Future<CpeHttpResponse> Function(CpeHttpRequest request) handler;

  _MockHttpClient(this.handler);

  @override
  Future<CpeHttpResponse> send(CpeHttpRequest request) => handler(request);

  @override
  void close() {}
}

InvoiceDocument _sampleInvoice() {
  return InvoiceDocument(
    id: const DocumentId(
      issuerRuc: '20100066603',
      type: CpeDocumentType.factura,
      series: 'F001',
      number: 1,
    ),
    issueDate: DateTime(2026, 11, 4),
    issuer: const CompanyParty(
      ruc: '20100066603',
      legalName: 'EMPRESA DEMO S.A.C.',
      address: Address(ubigeo: '150101', streetLine: 'AV. CENTRAL 123'),
    ),
    customer: const CustomerParty(
      documentType: IdentityDocumentType.ruc,
      documentNumber: '20600055519',
      legalName: 'CLIENTE CORPORATIVO S.A.C.',
    ),
    currency: CurrencyCode.pen,
    items: [
      CpeLineItem(
        lineNumber: 1,
        description: 'SERVICIO CLOUD OSE EFACT',
        quantity: Decimal.fromInt(1),
        unitValue: Decimal.parse('100.00'),
        unitPrice: Decimal.parse('118.00'),
        lineExtensionAmount: Decimal.parse('100.00'),
        taxableBaseAmount: Decimal.parse('100.00'),
        igvAffectation: IgvAffectationType.gravadoOperacionOnerosa,
        igvPercentage: Decimal.parse('18.00'),
        igvAmount: Decimal.parse('18.00'),
        totalLineTaxAmount: Decimal.parse('18.00'),
        totalLineAmount: Decimal.parse('118.00'),
      ),
    ],
    totals: MonetaryTotals(
      totalGravadas: Decimal.parse('100.00'),
      totalIgv: Decimal.parse('18.00'),
      totalValorVenta: Decimal.parse('100.00'),
      totalImpuestos: Decimal.parse('18.00'),
      totalPrecioVenta: Decimal.parse('118.00'),
      importeTotalPagar: Decimal.parse('118.00'),
    ),
  );
}

const _sampleCdrXml = '''<?xml version="1.0" encoding="UTF-8"?>
<ar:ApplicationResponse xmlns:ar="urn:oasis:names:specification:ubl:schema:xsd:ApplicationResponse-2"
  xmlns:cac="urn:oasis:names:specification:ubl:schema:xsd:CommonAggregateComponents-2"
  xmlns:cbc="urn:oasis:names:specification:ubl:schema:xsd:CommonBasicComponents-2">
  <cbc:ID>R-20100066603-01-F001-1</cbc:ID>
  <cbc:ResponseDate>2026-11-04</cbc:ResponseDate>
  <cbc:ResponseTime>14:20:00</cbc:ResponseTime>
  <cac:DocumentResponse>
    <cac:Response>
      <cbc:ReferenceID>F001-1</cbc:ReferenceID>
      <cbc:ResponseCode>0</cbc:ResponseCode>
      <cbc:Description>La Factura numero F001-1, ha sido aceptada</cbc:Description>
    </cac:Response>
  </cac:DocumentResponse>
</ar:ApplicationResponse>''';

void main() {
  group('EfactOAuth2Interceptor & EfactProvider (REST & SOAP)', () {
    test('EfactOAuth2Interceptor caches and attaches Bearer token', () async {
      var tokenCalls = 0;
      final authClient = _MockHttpClient((req) async {
        tokenCalls++;
        expect(req.uri.path, endsWith('/oauth/token'));
        expect(req.headers['Authorization'], startsWith('Basic '));
        return CpeHttpResponse(
          statusCode: 200,
          headers: const {'content-type': 'application/json'},
          bodyBytes: Uint8List.fromList(
            utf8.encode('{"access_token":"jwt-efact-123","expires_in":3600}'),
          ),
        );
      });

      final interceptor = EfactOAuth2Interceptor(
        tokenEndpoint: Uri.parse(
          'https://ose.efact.pe/api-efact-ose/oauth/token',
        ),
        username: '20100066603',
        password: 'secret-password',
        authHttpClient: authClient,
      );

      final req1 = await interceptor.onRequest(
        CpeHttpRequest(
          method: 'POST',
          uri: Uri.parse('https://ose.efact.pe/api-efact-ose/v1/document'),
        ),
      );
      final req2 = await interceptor.onRequest(
        CpeHttpRequest(
          method: 'GET',
          uri: Uri.parse('https://ose.efact.pe/api-efact-ose/v1/cdr/uuid-1'),
        ),
      );

      expect(tokenCalls, 1);
      expect(req1.headers['Authorization'], 'Bearer jwt-efact-123');
      expect(req2.headers['Authorization'], 'Bearer jwt-efact-123');
    });

    test('REST JSON mode submits multipart and auto-polls /v1/cdr/{ticket} until 200 OK', () async {
      var cdrPollAttempts = 0;
      final mockHttp = _MockHttpClient((req) async {
        if (req.uri.path.endsWith('/v1/document')) {
          expect(
            req.headers['Content-Type'],
            startsWith('multipart/form-data'),
          );
          return CpeHttpResponse(
            statusCode: 200,
            headers: const {'content-type': 'application/json'},
            bodyBytes: Uint8List.fromList(
              utf8.encode(
                '{"code":"0","description":"550e8400-e29b-41d4-a716-446655440000"}',
              ),
            ),
          );
        }
        if (req.uri.path.endsWith(
          '/v1/cdr/550e8400-e29b-41d4-a716-446655440000',
        )) {
          cdrPollAttempts++;
          if (cdrPollAttempts == 1) {
            return CpeHttpResponse(
              statusCode: 412,
              headers: const {'content-type': 'application/json'},
              bodyBytes: Uint8List.fromList(
                utf8.encode('{"code":"-9998","description":"En proceso"}'),
              ),
            );
          }
          return CpeHttpResponse(
            statusCode: 200,
            headers: const {'content-type': 'application/xml'},
            bodyBytes: Uint8List.fromList(utf8.encode(_sampleCdrXml)),
          );
        }
        throw StateError('Unexpected URI ${req.uri}');
      });

      final provider = EfactProvider(
        config: EfactConfig.restJson(
          username: '20100066603',
          password: 'hash',
          pollingConfig: const PollingConfig(
            initialDelay: Duration(milliseconds: 5),
            maxAttempts: 4,
          ),
        ),
        httpClient: mockHttp,
      );

      final result = await provider.sendDocument(_sampleInvoice());
      final emission = result.getOrThrow();

      expect(cdrPollAttempts, 2);
      expect(emission.status, CpeProcessStatus.accepted);
      expect(emission.ticket, '550e8400-e29b-41d4-a716-446655440000');
      expect(emission.cdr?.responseCode, '0');
      expect(
        emission.pdfDownloadUrl,
        'https://ose.efact.pe/api-efact-ose/v1/pdf/550e8400-e29b-41d4-a716-446655440000',
      );
    });

    test('REST mode with autoPollInRest: false returns inProcess with Ticket UUID immediately', () async {
      final mockHttp = _MockHttpClient((req) async {
        return CpeHttpResponse(
          statusCode: 200,
          headers: const {'content-type': 'application/json'},
          bodyBytes: Uint8List.fromList(
            utf8.encode('{"code":"0","description":"ticket-deferred-999"}'),
          ),
        );
      });

      final provider = EfactProvider(
        config: EfactConfig.restJson(
          username: '20100066603',
          password: 'hash',
          autoPollInRest: false,
        ),
        httpClient: mockHttp,
      );

      final emission = (await provider.sendDocument(_sampleInvoice()))
          .getOrThrow();
      expect(emission.status, CpeProcessStatus.inProcess);
      expect(emission.ticket, 'ticket-deferred-999');
      expect(emission.cdr, isNull);
    });
  });
}
