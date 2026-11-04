import 'dart:convert';
import 'dart:typed_data';

import 'package:sunat_cpe_core/sunat_cpe_core.dart';
import 'package:sunat_cpe_mifact/sunat_cpe_mifact.dart';
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
      issuerRuc: '20100113612',
      type: CpeDocumentType.factura,
      series: 'F001',
      number: 1,
    ),
    issueDate: DateTime(2026, 10, 30),
    issuer: const CompanyParty(
      ruc: '20100113612',
      legalName: 'EMPRESA DEMO S.A.C.',
      address: Address(ubigeo: '150101', streetLine: 'AV. DEMO 123 LIMA'),
    ),
    customer: const CustomerParty(
      documentType: IdentityDocumentType.ruc,
      documentNumber: '20600695771',
      legalName: 'CLIENTE S.A.C.',
    ),
    currency: CurrencyCode.pen,
    items: [
      CpeLineItem(
        lineNumber: 1,
        internalCode: 'P001',
        description: 'SERVICIO DE CONSULTORIA',
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

void main() {
  group('MifactProvider & MifactInvoiceMapper', () {
    test('maps InvoiceDocument to Mifact UPPER_SNAKE_CASE JSON with TOKEN', () {
      final json = const MifactInvoiceMapper().mapSalesDocument(
        _sampleInvoice(),
        MifactConfig(
          baseUri: Uri.parse('https://demo.mifact.net.pe'),
          token: MifactConfig.demoToken,
        ),
      );

      expect(json['TOKEN'], MifactConfig.demoToken);
      expect(json['COD_TIP_DOCU'], '01');
      expect(json['NUM_SERIE_CPE'], 'F001');
      expect(json['NUM_CORRE_CPE'], '00000001');
      expect(json['MNT_TOT_GRAVADO'], '100.00');
      expect(json['MNT_TOT_TRIB_IGV'], '18.00');
      expect(json['MNT_TOT'], '118.00');
      expect((json['ITEMS'] as List).first['COD_TIP_AFECT_IGV_ITEM'], '10');
    });

    test(
      'sendDocument maps estado_documento 102 to CpeProcessStatus.accepted',
      () async {
        final mockHttp = _MockHttpClient((req) async {
          expect(req.uri.path, endsWith('/service.asmx/SendInvoice'));
          return CpeHttpResponse(
            statusCode: 200,
            headers: const {'content-type': 'application/json'},
            bodyBytes: Uint8List.fromList(
              utf8.encode(
                jsonEncode({
                  'estado_documento': '102',
                  'codigo_hash': 'kL9pQ2==',
                  'cadena_para_codigo_qr': '20100113612|01|F001|00000001|18.00|118.00|2026-10-30|6|20600695771|kL9pQ2==|',
                  'sunat_description':
                      'La Factura numero F001-00000001, ha sido aceptada',
                  'url_pdf': 'https://demo.mifact.net.pe/pdf/F001-1.pdf',
                  'errors': '',
                }),
              ),
            ),
          );
        });

        final provider = MifactProvider(
          config: MifactConfig(
            baseUri: Uri.parse('https://demo.mifact.net.pe'),
            token: MifactConfig.demoToken,
          ),
          httpClient: mockHttp,
        );

        final res = (await provider.sendDocument(_sampleInvoice()))
            .getOrThrow();
        expect(res.status, CpeProcessStatus.accepted);
        expect(res.digestValue, 'kL9pQ2==');
        expect(res.cdr?.isAccepted, isTrue);
      },
    );

    test(
      'sendDocument maps estado_documento 104 to SunatRejectionException',
      () async {
        final mockHttp = _MockHttpClient((req) async {
          return CpeHttpResponse(
            statusCode: 200,
            headers: const {'content-type': 'application/json'},
            bodyBytes: Uint8List.fromList(
              utf8.encode(
                jsonEncode({
                  'estado_documento': '104',
                  'errors':
                      '2800 - El tipo de documento del receptor no es valido',
                }),
              ),
            ),
          );
        });

        final provider = MifactProvider(
          config: MifactConfig(
            baseUri: Uri.parse('https://demo.mifact.net.pe'),
            token: MifactConfig.demoToken,
          ),
          httpClient: mockHttp,
        );

        final result = await provider.sendDocument(_sampleInvoice());
        expect(result, isA<CpeFailure<CpeEmissionResponse>>());
        expect(
          () => result.getOrThrow(),
          throwsA(
            isA<SunatRejectionException>().having(
              (e) => e.sunatCode,
              'sunatCode',
              2800,
            ),
          ),
        );
      },
    );
  });
}
