import 'dart:convert';
import 'dart:typed_data';

import 'package:sunat_cpe_core/sunat_cpe_core.dart';
import 'package:sunat_cpe_nubefact/sunat_cpe_nubefact.dart';
import 'package:test/test.dart';

final class _FakeHttpClient implements CpeHttpClient {
  final Future<CpeHttpResponse> Function(CpeHttpRequest request) handler;

  _FakeHttpClient(this.handler);

  @override
  Future<CpeHttpResponse> send(CpeHttpRequest request) => handler(request);

  @override
  void close() {}
}

InvoiceDocument _sampleCreditInvoice() {
  return InvoiceDocument(
    id: const DocumentId(
      issuerRuc: '20100066603',
      type: CpeDocumentType.factura,
      series: 'FFF1',
      number: 15,
    ),
    issuer: const CompanyParty(
      ruc: '20100066603',
      legalName: 'EMISOR DEMO S.A.C.',
      address: Address(streetLine: 'AV. LIMA 100'),
    ),
    customer: const CustomerParty(
      documentType: IdentityDocumentType.ruc,
      documentNumber: '20600695771',
      legalName: 'NUBEFACT SA',
      address: Address(streetLine: 'CALLE LIBERTAD 116 MIRAFLORES'),
      email: 'cliente@nubefact.com',
    ),
    issueDate: DateTime(2026, 10, 30),
    dueDate: DateTime(2026, 11, 30),
    currency: CurrencyCode.usd,
    exchangeRate: Decimal.parse('3.750'),
    operationType: OperationType.ventaInterna,
    paymentTerms: CreditPaymentTerms(
      netPendingAmount: Decimal.parse('118.00'),
      installments: [
        PaymentInstallment(
          number: 1,
          amount: Decimal.parse('118.00'),
          dueDate: DateTime(2026, 11, 30),
        ),
      ],
    ),
    totals: MonetaryTotals(
      totalGravadas: Decimal.parse('100.00'),
      totalIgv: Decimal.parse('18.00'),
      totalValorVenta: Decimal.parse('100.00'),
      totalImpuestos: Decimal.parse('18.00'),
      totalPrecioVenta: Decimal.parse('118.00'),
      importeTotalPagar: Decimal.parse('118.00'),
    ),
    items: [
      CpeLineItem(
        lineNumber: 1,
        internalCode: 'PROD-01',
        sunatProductCode: '43231500',
        unitCode: 'NIU',
        description: 'SUSCRIPCION CLOUD',
        quantity: Decimal.one,
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
  );
}

void main() {
  final routeUri = Uri.parse('https://api.nubefact.com/api/v1/demo-route');
  final config = NubefactConfig(
    routeUri: routeUri,
    apiToken: 'secret-nubefact-token',
  );

  group('NubefactCatalogMapper & NubefactRequestMapper', () {
    test('translates SUNAT catalogs to Nubefact integer codes and DD-MM-YYYY dates', () {
      final mapper = NubefactRequestMapper(config);
      final jsonMap = mapper.mapSalesDocument(_sampleCreditInvoice());

      expect(jsonMap['operacion'], 'generar_comprobante');
      expect(jsonMap['tipo_de_comprobante'], 1); // Factura '01' -> 1
      expect(jsonMap['moneda'], 2); // USD -> 2
      expect(jsonMap['sunat_transaction'], 1); // Venta Interna '0101' -> 1
      expect(jsonMap['fecha_de_emision'], '30-10-2026');
      expect(jsonMap['fecha_de_vencimiento'], '30-11-2026');
      expect(jsonMap['condiciones_de_pago'], 'CRÉDITO');

      final creditQuotas = jsonMap['venta_al_credito'] as List<Object?>;
      final firstQuota = creditQuotas.single as Map<String, Object?>;
      expect(firstQuota['cuota'], 1);
      expect(firstQuota['fecha_de_pago'], '30-11-2026');
      expect(firstQuota['importe'], 118.00);

      final items = jsonMap['items'] as List<Object?>;
      final firstItem = items.single as Map<String, Object?>;
      expect(firstItem['tipo_de_igv'], 1); // Catálogo 07 '10' -> 1
    });
  });

  group('NubefactProvider End-to-End Operations', () {
    test(
      'sends Authorization Token header and maps accepted response with links',
      () async {
        final client = _FakeHttpClient((req) async {
          expect(
            req.headers['Authorization'],
            'Token token="secret-nubefact-token"',
          );
          final sentBody =
              json.decode(req.body.toString()) as Map<String, Object?>;
          expect(sentBody['operacion'], 'generar_comprobante');

          return CpeHttpResponse(
            statusCode: 200,
            headers: const {'content-type': 'application/json'},
            bodyBytes: Uint8List.fromList(
              utf8.encode(
                json.encode({
                  'tipo_de_comprobante': 1,
                  'serie': 'FFF1',
                  'numero': 15,
                  'aceptada_por_sunat': true,
                  'sunat_description':
                      'La Factura numero FFF1-15, ha sido aceptada',
                  'sunat_note': null,
                  'sunat_responsecode': '0',
                  'sunat_soap_error': '',
                  'codigo_hash': 'hashNube123=',
                  'cadena_para_codigo_qr': '20100066603|01|FFF1|15|18.00|118.00|30/10/2026|6|20600695771|hashNube123=|',
                  'enlace_del_pdf': 'https://nubefact.com/pdf/15.pdf',
                  'enlace_del_xml': 'https://nubefact.com/xml/15.xml',
                  'enlace_del_cdr': 'https://nubefact.com/cdr/15.zip',
                }),
              ),
            ),
          );
        });

        final provider = NubefactProvider(config: config, httpClient: client);
        final result = await provider.sendDocument(_sampleCreditInvoice());
        final response = result.getOrThrow();

        expect(response.status, CpeProcessStatus.accepted);
        expect(response.digestValue, 'hashNube123=');
        expect(response.pdfDownloadUrl, 'https://nubefact.com/pdf/15.pdf');
        expect(response.cdr?.isAccepted, isTrue);
      },
    );

    test('maps Nubefact error codes (10 -> OseAuthException, 21 -> CpeValidationException) and SUNAT rejections', () async {
      var mockStatus = 401;
      var mockBody = <String, Object?>{
        'errors': 'Token no valido',
        'codigo': 10,
      };

      final client = _FakeHttpClient((_) async {
        return CpeHttpResponse(
          statusCode: mockStatus,
          headers: const {'content-type': 'application/json'},
          bodyBytes: Uint8List.fromList(utf8.encode(json.encode(mockBody))),
        );
      });

      final provider = NubefactProvider(config: config, httpClient: client);

      // 1. Code 10 -> OseAuthException
      final authRes = await provider.sendDocument(_sampleCreditInvoice());
      expect(authRes.errorOrNull, isA<OseAuthException>());

      // 2. Code 21 -> CpeValidationException
      mockStatus = 400;
      mockBody = {'errors': 'Formato de serie incorrecto', 'codigo': 21};
      final valRes = await provider.sendDocument(_sampleCreditInvoice());
      expect(valRes.errorOrNull, isA<CpeValidationException>());

      // 3. HTTP 200 with aceptada_por_sunat: false and sunat_responsecode: "2017" -> SunatRejectionException
      mockStatus = 200;
      mockBody = {
        'aceptada_por_sunat': false,
        'sunat_responsecode': '2017',
        'sunat_description': 'El RUC del receptor no esta activo',
      };
      final rejRes = await provider.sendDocument(_sampleCreditInvoice());
      expect(rejRes.errorOrNull, isA<SunatRejectionException>());
      expect((rejRes.errorOrNull as SunatRejectionException).sunatCode, 2017);
    });

    test(
      'handles generar_anulacion and polls consultar_anulacion until accepted',
      () async {
        var checkCalls = 0;

        final client = _FakeHttpClient((req) async {
          final sent = json.decode(req.body.toString()) as Map<String, Object?>;
          final op = sent['operacion'];

          if (op == 'generar_anulacion') {
            return CpeHttpResponse(
              statusCode: 200,
              headers: const {'content-type': 'application/json'},
              bodyBytes: Uint8List.fromList(
                utf8.encode(
                  json.encode({
                    'aceptada_por_sunat': false,
                    'sunat_ticket_numero': '202600998877',
                  }),
                ),
              ),
            );
          }

          expect(op, 'consultar_anulacion');
          checkCalls++;
          final accepted = checkCalls >= 2;
          return CpeHttpResponse(
            statusCode: 200,
            headers: const {'content-type': 'application/json'},
            bodyBytes: Uint8List.fromList(
              utf8.encode(
                json.encode({
                  'aceptada_por_sunat': accepted,
                  'sunat_responsecode': accepted ? '0' : '',
                  'sunat_description': accepted
                      ? 'La Comunicacion de baja ha sido aceptada'
                      : '',
                }),
              ),
            ),
          );
        });

        final provider = NubefactProvider(config: config, httpClient: client);
        final voided = VoidedDocument(
          id: const DocumentId(
            issuerRuc: '20100066603',
            type: CpeDocumentType.comunicacionBaja,
            series: 'RA-20261030',
            number: 1,
          ),
          issuer: const CompanyParty(
            ruc: '20100066603',
            legalName: 'EMISOR DEMO S.A.C.',
            address: Address(streetLine: 'AV. LIMA 100'),
          ),
          issueDate: DateTime(2026, 10, 30),
          referenceDate: DateTime(2026, 10, 30),
          lines: const [
            VoidedLine(
              lineNumber: 1,
              documentType: CpeDocumentType.factura,
              series: 'FFF1',
              number: 15,
              voidReason: 'ERROR DE DIGITACION',
            ),
          ],
        );

        final ticketRes = (await provider.sendVoidedDocument(voided))
            .getOrThrow();
        expect(ticketRes.ticket, '202600998877');

        final cdr = (await provider.pollTicketUntilDone(
          ticketRes.ticket,
          referenceId: ticketRes.referenceId,
          config: const PollingConfig(
            initialDelay: Duration(milliseconds: 5),
            maxDelay: Duration(milliseconds: 20),
            maxAttempts: 4,
          ),
        )).getOrThrow();

        expect(checkCalls, 2);
        expect(cdr.isAccepted, isTrue);
      },
    );
  });
}
