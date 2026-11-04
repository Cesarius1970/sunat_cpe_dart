import 'dart:convert';
import 'dart:typed_data';

import 'package:sunat_cpe_dart/sunat_cpe_dart.dart';
import 'package:test/test.dart';

final class _FakeOseProvider with TicketPollingMixin implements OseProvider {
  @override
  final String providerId;

  @override
  Set<ProviderCapability> get capabilities => const {
        ProviderCapability.invoiceAndNotes,
        ProviderCapability.despatchAdvice,
        ProviderCapability.dailySummary,
        ProviderCapability.voidedDocuments,
        ProviderCapability.statusQuery,
      };

  final List<String> callLog = [];

  Future<CpeResult<CpeEmissionResponse>> Function(SalesCpeDocument doc)?
      onSendDocument;

  _FakeOseProvider({
    required this.providerId,
    this.onSendDocument,
  });

  @override
  Future<CpeResult<CpeEmissionResponse>> sendDocument(
    SalesCpeDocument document,
  ) async {
    callLog.add('sendDocument:${document.id.ublId}');
    if (onSendDocument != null) {
      return onSendDocument!(document);
    }
    return CpeSuccess(
      CpeEmissionResponse(
        documentId: document.id,
        status: CpeProcessStatus.accepted,
        cdr: CdrData(
          id: 'R-${document.id.fileNameBase}',
          responseCode: '0',
          description: 'La Factura ha sido aceptada por $providerId',
          responseDateTime: DateTime(2026, 11, 4, 15, 0),
        ),
      ),
    );
  }

  @override
  Future<CpeResult<TicketResponse>> sendDailySummary(
    DailySummaryDocument summary,
  ) async {
    callLog.add('sendDailySummary:${summary.id.ublId}');
    return CpeSuccess(
      TicketResponse(
        ticket: 'TCK-RC-$providerId',
        referenceId: summary.id,
        receivedAt: DateTime(2026, 11, 4, 15, 0),
      ),
    );
  }

  @override
  Future<CpeResult<TicketResponse>> sendVoidedDocument(
    VoidedDocument voided,
  ) async {
    callLog.add('sendVoidedDocument:${voided.id.ublId}');
    return CpeSuccess(
      TicketResponse(
        ticket: 'TCK-RA-$providerId',
        referenceId: voided.id,
        receivedAt: DateTime(2026, 11, 4, 15, 0),
      ),
    );
  }

  @override
  Future<CpeResult<TicketResponse>> sendDespatchAdvice(
    DespatchAdviceDocument guide,
  ) async {
    callLog.add('sendDespatchAdvice:${guide.id.ublId}');
    return CpeSuccess(
      TicketResponse(
        ticket: 'TCK-GRE-$providerId',
        referenceId: guide.id,
        receivedAt: DateTime(2026, 11, 4, 15, 0),
      ),
    );
  }

  @override
  Future<CpeResult<CpeEmissionResponse>> sendRetentionOrPerception(
    AgentCpeDocument document,
  ) async {
    callLog.add('sendRetentionOrPerception:${document.id.ublId}');
    return CpeSuccess(
      CpeEmissionResponse(
        documentId: document.id,
        status: CpeProcessStatus.accepted,
      ),
    );
  }

  @override
  Future<CpeResult<TicketStatusResponse>> checkTicket(
    String ticket, {
    DocumentId? referenceId,
  }) async {
    callLog.add('checkTicket:$ticket');
    return CpeSuccess(
      TicketStatusResponse(
        ticket: ticket,
        status: CpeProcessStatus.accepted,
        statusCode: '0',
        statusMessage: 'Aceptado en $providerId',
        cdr: CdrData(
          id: ticket,
          responseCode: '0',
          description: 'Aceptado en $providerId',
          responseDateTime: DateTime(2026, 11, 4, 15, 1),
        ),
      ),
    );
  }

  @override
  Future<CpeResult<CpeStatusQueryResponse>> queryDocumentStatus(
    DocumentStatusQuery query,
  ) async {
    callLog.add('queryDocumentStatus:${query.series}-${query.number}');
    return const CpeSuccess(
      CpeStatusQueryResponse(
        status: CpeProcessStatus.accepted,
        statusCode: '0001',
        statusMessage: 'Existe',
      ),
    );
  }
}

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
      number: 100,
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
        description: 'SERVICIO CLOUD',
        quantity: Decimal.one,
        unitValue: Decimal.fromInt(100),
        unitPrice: Decimal.fromInt(118),
        lineExtensionAmount: Decimal.fromInt(100),
        taxableBaseAmount: Decimal.fromInt(100),
        igvAffectation: IgvAffectationType.gravadoOperacionOnerosa,
        igvPercentage: Decimal.fromInt(18),
        igvAmount: Decimal.fromInt(18),
        totalLineTaxAmount: Decimal.fromInt(18),
        totalLineAmount: Decimal.fromInt(118),
      ),
    ],
    totals: MonetaryTotals(
      totalGravadas: Decimal.fromInt(100),
      totalIgv: Decimal.fromInt(18),
      totalValorVenta: Decimal.fromInt(100),
      totalImpuestos: Decimal.fromInt(18),
      totalPrecioVenta: Decimal.fromInt(118),
      importeTotalPagar: Decimal.fromInt(118),
    ),
  );
}

DespatchAdviceDocument _sampleGuide() {
  return DespatchAdviceDocument(
    id: const DocumentId(
      issuerRuc: '20100066603',
      type: CpeDocumentType.guiaRemisionRemitente,
      series: 'T001',
      number: 1,
    ),
    issueDate: DateTime(2026, 11, 4),
    issuer: const CompanyParty(
      ruc: '20100066603',
      legalName: 'EMPRESA DEMO S.A.C.',
      address: Address(ubigeo: '150101', streetLine: 'AV. CENTRAL 123'),
    ),
    recipient: const CustomerParty(
      documentType: IdentityDocumentType.ruc,
      documentNumber: '20600055519',
      legalName: 'CLIENTE DESTINO S.A.C.',
    ),
    transferReason: DespatchReasonCode.venta,
    transportMode: TransportModeCode.transportePublico,
    transferStartDate: DateTime(2026, 11, 5),
    grossWeight: Decimal.parse('50.00'),
    originAddress: const Address(
      ubigeo: '150101',
      streetLine: 'ALMACEN ORIGEN 100',
    ),
    deliveryAddress: const Address(
      ubigeo: '150122',
      streetLine: 'ALMACEN DESTINO 200',
    ),
    carrier: const CarrierParty(
      ruc: '20555555551',
      legalName: 'TRANSPORTES RAPIDOS S.A.C.',
    ),
    items: [
      DespatchLineItem(
        lineNumber: 1,
        internalCode: 'PROD-01',
        description: 'CAJA DE SERVIDORES',
        quantity: Decimal.fromInt(2),
      ),
    ],
  );
}

void main() {
  group('SunatCpeRouter - Content-Based Routing & Ticket Origin Registry', () {
    test(
      'routes Facturas (01) to primary OSE/PSE and Guías (09) to sunat_cpe_direct, tracking ticket origin automatically',
      () async {
        final osePrimary = _FakeOseProvider(providerId: 'nubefact');

        final directRestMock = _MockHttpClient((req) async {
          if (req.uri.path.endsWith('/comprobantes/20100066603-09-T001-1')) {
            return CpeHttpResponse(
              statusCode: 200,
              headers: const {'content-type': 'application/json'},
              bodyBytes: Uint8List.fromList(
                utf8.encode(
                  '{"numTicket":"SUNAT-DIRECT-TICKET-777","fecRecepcion":"2026-11-04T15:00:00"}',
                ),
              ),
            );
          }
          if (req.uri.path.endsWith('/comprobantes/envios/SUNAT-DIRECT-TICKET-777')) {
            return CpeHttpResponse(
              statusCode: 200,
              headers: const {'content-type': 'application/json'},
              bodyBytes: Uint8List.fromList(
                utf8.encode('{"codRespuesta":"0","indCdrGenerado":"1"}'),
              ),
            );
          }
          throw StateError('Unexpected URI: ${req.uri}');
        });

        final directProvider = SunatDirectProvider(
          config: SunatDirectConfig.beta(
            clientId: 'client-id-sunat',
            clientSecret: 'client-secret-sunat',
          ),
          restHttpClient: directRestMock,
        );

        final router = SunatCpeRouter.simple(
          primaryProvider: osePrimary,
          routesByDocumentType: {
            CpeDocumentType.guiaRemisionRemitente: directProvider,
            CpeDocumentType.guiaRemisionTransportista: directProvider,
          },
        );

        // 1. Send Invoice (01) -> Must route to osePrimary ('nubefact')
        final invoiceResult = await router.sendDocument(_sampleInvoice());
        expect(invoiceResult.isSuccess, isTrue);
        expect(osePrimary.callLog, contains('sendDocument:F001-100'));
        expect(
          (invoiceResult as CpeSuccess<CpeEmissionResponse>)
              .providerRawMetadata['routedProviderId'],
          'nubefact',
        );

        // 2. Send Despatch Advice (09) -> Must route to directProvider ('sunat_direct')
        final guideResult = await router.sendDespatchAdvice(_sampleGuide());
        expect(guideResult.isSuccess, isTrue);
        final ticketData = guideResult.getOrThrow();
        expect(ticketData.ticket, 'SUNAT-DIRECT-TICKET-777');
        expect(
          router.getRegisteredProviderForTicket('SUNAT-DIRECT-TICKET-777')?.providerId,
          'sunat_direct',
        );

        // 3. Check Ticket WITHOUT referenceId -> Router remembers it came from sunat_direct!
        final statusResult = await router.checkTicket('SUNAT-DIRECT-TICKET-777');
        expect(statusResult.isSuccess, isTrue);
        expect(statusResult.getOrThrow().status, CpeProcessStatus.accepted);
        expect(osePrimary.callLog, isNot(contains('checkTicket:SUNAT-DIRECT-TICKET-777')));
      },
    );
  });

  group('SunatCpeRouter - Circuit-Safe Fallback Policy', () {
    test('triggers fallbackProvider on OseTransportException and SunatExceptionError (0100-1999)', () async {
      final primary = _FakeOseProvider(
        providerId: 'efact',
        onSendDocument: (_) async => const CpeFailure(
          OseTransportException(
            message: 'HTTP 503 Service Unavailable',
            httpStatusCode: 503,
          ),
        ),
      );
      final fallback = _FakeOseProvider(providerId: 'sunat_direct');

      final router = SunatCpeRouter.simple(
        primaryProvider: primary,
        fallbackProvider: fallback,
      );

      final result = await router.sendDocument(_sampleInvoice());
      expect(result.isSuccess, isTrue);
      expect(primary.callLog, ['sendDocument:F001-100']);
      expect(fallback.callLog, ['sendDocument:F001-100']);

      final success = result as CpeSuccess<CpeEmissionResponse>;
      expect(success.providerRawMetadata['usedFallback'], isTrue);
      expect(success.providerRawMetadata['routedProviderId'], 'sunat_direct');
      expect(success.providerRawMetadata['primaryProviderId'], 'efact');
    });

    test('triggers fallbackProvider on SunatExceptionError (code 0130)', () async {
      final primary = _FakeOseProvider(
        providerId: 'bizlinks',
        onSendDocument: (_) async => CpeFailure(
          SunatExceptionError(
            sunatCode: 130,
            message: 'No se pudo procesar su solicitud (Error técnico)',
          ),
        ),
      );
      final fallback = _FakeOseProvider(providerId: 'sunat_direct');

      final router = SunatCpeRouter.simple(
        primaryProvider: primary,
        fallbackProvider: fallback,
      );

      final result = await router.sendDocument(_sampleInvoice());
      expect(result.isSuccess, isTrue);
      expect(fallback.callLog, ['sendDocument:F001-100']);
    });

    test('NEVER triggers fallbackProvider on SunatRejectionException (codes 2000-3999) or CpeValidationException', () async {
      final fallback = _FakeOseProvider(providerId: 'sunat_direct');

      final primaryRejected = _FakeOseProvider(
        providerId: 'nubefact',
        onSendDocument: (_) async => CpeFailure(
          SunatRejectionException(
            sunatCode: 2800,
            message: 'El RUC del receptor no está activo',
          ),
        ),
      );

      final routerReject = SunatCpeRouter.simple(
        primaryProvider: primaryRejected,
        fallbackProvider: fallback,
      );

      final rejectResult = await routerReject.sendDocument(_sampleInvoice());
      expect(rejectResult.isFailure, isTrue);
      expect(rejectResult.errorOrNull, isA<SunatRejectionException>());
      expect(fallback.callLog, isEmpty);

      final primaryInvalid = _FakeOseProvider(
        providerId: 'nubefact',
        onSendDocument: (_) async => const CpeFailure(
          CpeValidationException(
            message: 'Diferencia aritmética en IGV',
            issues: [
              ValidationIssue(
                field: 'totals.totalIgv',
                message: 'Esperado 18.00',
              ),
            ],
          ),
        ),
      );

      final routerInvalid = SunatCpeRouter.simple(
        primaryProvider: primaryInvalid,
        fallbackProvider: fallback,
      );

      final validationResult = await routerInvalid.sendDocument(_sampleInvoice());
      expect(validationResult.isFailure, isTrue);
      expect(validationResult.errorOrNull, isA<CpeValidationException>());
      expect(fallback.callLog, isEmpty);
    });
  });

  group('SunatProviderFactory & SunatCpeRouter.fromDescriptors', () {
    test('creates router declaratively from DirectSunatDescriptor and NubefactDescriptor', () {
      final router = SunatCpeRouter.fromDescriptors(
        primaryDescriptor: NubefactDescriptor(
          NubefactConfig(
            routeUri: Uri.parse('https://api.nubefact.com/api/v1/demo'),
            apiToken: 'demo-token',
          ),
        ),
        routeDescriptorsByDocumentType: {
          CpeDocumentType.guiaRemisionRemitente: DirectSunatDescriptor(
            SunatDirectConfig.beta(),
          ),
        },
      );

      expect(router.providerId, 'router(nubefact)');
      expect(
        router.resolveProviderForDocumentType(CpeDocumentType.factura).providerId,
        'nubefact',
      );
      expect(
        router
            .resolveProviderForDocumentType(CpeDocumentType.guiaRemisionRemitente)
            .providerId,
        'sunat_direct',
      );
    });
  });
}
