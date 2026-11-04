import 'dart:convert';
import 'dart:typed_data';

import 'package:sunat_cpe_core/sunat_cpe_core.dart';
import 'package:sunat_cpe_facturaloperu/sunat_cpe_facturaloperu.dart';
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
      number: 45,
    ),
    issueDate: DateTime(2026, 10, 30),
    issuer: const CompanyParty(
      ruc: '20100066603',
      legalName: 'EMPRESA DEMO S.A.C.',
      address: Address(ubigeo: '150101', streetLine: 'AV. PRINCIPAL 123'),
    ),
    customer: const CustomerParty(
      documentType: IdentityDocumentType.ruc,
      documentNumber: '20600695771',
      legalName: 'EMPRESA CLIENTE S.A.C.',
    ),
    currency: CurrencyCode.pen,
    items: [
      CpeLineItem(
        lineNumber: 1,
        internalCode: 'PROD-01',
        sunatProductCode: '43231500',
        unitCode: 'ZZ',
        description: 'LICENCIA DE SOFTWARE ANUAL',
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
  group('FacturaloProvider & FacturaloDocumentMapper', () {
    test('maps InvoiceDocument to nested semantic FacturaloPeru JSON', () {
      final config = FacturaloConfig(
        baseUri: Uri.parse('https://demo.facturaloperu.com'),
        apiToken: 'token-pro-123',
      );
      final json = const FacturaloDocumentMapper().mapSalesDocument(
        _sampleInvoice(),
        config,
      );

      expect(json['serie_documento'], 'F001');
      expect(json['numero_documento'], '45');
      expect(json['codigo_tipo_documento'], '01');
      expect(json['codigo_condicion_de_pago'], '01');
      expect((json['totales'] as Map)['total_operaciones_gravadas'], 100.0);
      expect((json['totales'] as Map)['total_venta'], 118.0);
    });

    test('sendDocument maps state_type_id 05 to CpeProcessStatus.accepted with links', () async {
      final mockHttp = _MockHttpClient((req) async {
        expect(req.uri.path, endsWith('/api/documents'));
        expect(req.headers['Authorization'], 'Bearer token-pro-123');
        return CpeHttpResponse(
          statusCode: 200,
          headers: const {'content-type': 'application/json'},
          bodyBytes: Uint8List.fromList(
            utf8.encode(
              jsonEncode({
                'success': true,
                'data': {
                  'number': 'F001-00000045',
                  'filename': '20100066603-01-F001-00000045',
                  'external_id': '9b1deb4d-3b7d-4bad-9bdd-2b0d7b3dcb6d',
                  'state_type_id': '05',
                  'state_type_description': 'Aceptado',
                  'hash': 'aB3dE5fG7==',
                  'qr': 'iVBORw0KGgoAAAANSUhEUgAA==',
                  'cdr_response': {
                    'code': '0',
                    'description':
                        'La Factura numero F001-00000045, ha sido aceptada',
                    'notes': <String>[],
                  },
                },
                'links': {
                  'xml':
                      'https://demo.facturaloperu.com/downloads/xml/9b1deb4d',
                  'pdf':
                      'https://demo.facturaloperu.com/downloads/pdf/9b1deb4d',
                  'cdr':
                      'https://demo.facturaloperu.com/downloads/cdr/9b1deb4d',
                },
              }),
            ),
          ),
        );
      });

      final provider = FacturaloProvider(
        config: FacturaloConfig(
          baseUri: Uri.parse('https://demo.facturaloperu.com'),
          apiToken: 'token-pro-123',
        ),
        httpClient: mockHttp,
      );

      final res = (await provider.sendDocument(_sampleInvoice())).getOrThrow();
      expect(res.status, CpeProcessStatus.accepted);
      expect(res.ticket, '9b1deb4d-3b7d-4bad-9bdd-2b0d7b3dcb6d');
      expect(res.digestValue, 'aB3dE5fG7==');
      expect(
        res.pdfDownloadUrl,
        'https://demo.facturaloperu.com/downloads/pdf/9b1deb4d',
      );
    });
  });
}
