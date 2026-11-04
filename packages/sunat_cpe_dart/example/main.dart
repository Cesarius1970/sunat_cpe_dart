import 'dart:convert';
import 'dart:typed_data';

import 'package:sunat_cpe_dart/sunat_cpe_dart.dart';

/// Genera un archivo CDR `.zip` codificado en Base64 para simular respuestas SOAP/REST.
String _buildMockCdrBase64({
  required String id,
  required String responseCode,
  required String description,
}) {
  final cdrXml =
      '''<?xml version="1.0" encoding="UTF-8"?>
<ar:ApplicationResponse xmlns:ar="urn:oasis:names:specification:ubl:schema:xsd:ApplicationResponse-2"
                        xmlns:cac="urn:oasis:names:specification:ubl:schema:xsd:CommonAggregateComponents-2"
                        xmlns:cbc="urn:oasis:names:specification:ubl:schema:xsd:CommonBasicComponents-2">
  <cbc:ID>$id</cbc:ID>
  <cbc:ResponseDate>2026-11-04</cbc:ResponseDate>
  <cbc:ResponseTime>16:30:00</cbc:ResponseTime>
  <cac:DocumentResponse>
    <cac:Response>
      <cbc:ResponseCode>$responseCode</cbc:ResponseCode>
      <cbc:Description>$description</cbc:Description>
    </cac:Response>
  </cac:DocumentResponse>
</ar:ApplicationResponse>''';

  return const CpeZipCodec()
      .encodeXmlToZip(fileNameBase: 'R-$id', xmlContent: cdrXml)
      .base64Zip;
}

/// Cliente HTTP simulado para Nubefact (PSE REST JSON).
final class _SimulatedNubefactHttpClient implements CpeHttpClient {
  @override
  Future<CpeHttpResponse> send(CpeHttpRequest request) async {
    final decoded = jsonDecode(request.body as String) as Map<String, dynamic>;
    final serie = decoded['serie'] ?? 'F001';
    final numero = decoded['numero'] ?? 1;

    return CpeHttpResponse(
      statusCode: 200,
      headers: const {'content-type': 'application/json; charset=utf-8'},
      bodyBytes: Uint8List.fromList(
        utf8.encode(
          jsonEncode({
            'aceptada_por_sunat': true,
            'sunat_responsecode': '0',
            'sunat_description':
                'El comprobante $serie-$numero ha sido aceptado vía Nubefact PSE',
            'codigo_hash': 'NubefactHash123==',
            'enlace_del_pdf': 'https://nubefact.com/pdf/$serie-$numero.pdf',
          }),
        ),
      ),
    );
  }

  @override
  void close() {}
}

/// Cliente HTTP simulado para Bizlinks (OSE SOAP 1.1).
final class _SimulatedBizlinksHttpClient implements CpeHttpClient {
  @override
  Future<CpeHttpResponse> send(CpeHttpRequest request) async {
    final body = request.body.toString();

    if (body.contains('<ser:sendBill>')) {
      final cdrB64 = _buildMockCdrBase64(
        id: '20100066603-20-R001-1',
        responseCode: '0',
        description: 'El Comprobante de Retencion R001-1 ha sido aceptado por Bizlinks OSE',
      );
      return _soapResponse(
        '<br:sendBillResponse xmlns:br="http://service.sunat.gob.pe">'
        '<applicationResponse>$cdrB64</applicationResponse>'
        '</br:sendBillResponse>',
      );
    }

    if (body.contains('<ser:sendSummary>')) {
      return _soapResponse(
        '<br:sendSummaryResponse xmlns:br="http://service.sunat.gob.pe">'
        '<ticket>BIZLINKS-TCK-RC-8899</ticket>'
        '</br:sendSummaryResponse>',
      );
    }

    if (body.contains('<ser:getStatus>')) {
      final cdrB64 = _buildMockCdrBase64(
        id: '20100066603-RC-20261104-1',
        responseCode: '0',
        description: 'Resumen Diario RC aceptado en Bizlinks OSE',
      );
      return _soapResponse(
        '<br:getStatusResponse xmlns:br="http://service.sunat.gob.pe">'
        '<status>'
        '<statusCode>0</statusCode>'
        '<content>$cdrB64</content>'
        '</status>'
        '</br:getStatusResponse>',
      );
    }

    throw StateError('Operación SOAP Bizlinks no simulada');
  }

  CpeHttpResponse _soapResponse(String innerBody) {
    final xml =
        '<?xml version="1.0" encoding="UTF-8"?>'
        '<soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/">'
        '<soapenv:Body>$innerBody</soapenv:Body>'
        '</soapenv:Envelope>';
    return CpeHttpResponse(
      statusCode: 200,
      headers: const {'content-type': 'text/xml; charset=utf-8'},
      bodyBytes: Uint8List.fromList(utf8.encode(xml)),
    );
  }

  @override
  void close() {}
}

/// Cliente HTTP simulado para SUNAT Directo (SOAP `billService` + API REST GRE).
final class _SimulatedSunatDirectHttpClient implements CpeHttpClient {
  @override
  Future<CpeHttpResponse> send(CpeHttpRequest request) async {
    final path = request.uri.path;
    final body = request.body.toString();

    // API REST GRE (POST /comprobantes/{id})
    if (request.method == 'POST' && path.contains('/comprobantes/')) {
      return _jsonResponse({
        'numTicket': 'SUNAT-GRE-TCK-5544',
        'fecRecepcion': '2026-11-04T16:35:00',
      });
    }

    // API REST GRE (GET /comprobantes/envios/{ticket})
    if (request.method == 'GET' && path.contains('/comprobantes/envios/')) {
      final cdrB64 = _buildMockCdrBase64(
        id: '20100066603-09-T001-1',
        responseCode: '0',
        description: 'Guia de Remision aceptada en API REST gratuita de SUNAT',
      );
      return _jsonResponse({
        'codRespuesta': '0',
        'indCdrGenerado': '1',
        'arcCdr': cdrB64,
      });
    }

    // SOAP e-factura (Contingencia / Fallback)
    if (body.contains('<ser:sendBill>')) {
      final cdrB64 = _buildMockCdrBase64(
        id: '20100066603-01-F001-100',
        responseCode: '0',
        description: 'Factura procesada exitosamente por proveedor de contingencia SUNAT Directo',
      );
      final xml =
          '<?xml version="1.0" encoding="UTF-8"?>'
          '<soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/">'
          '<soapenv:Body>'
          '<br:sendBillResponse xmlns:br="http://service.sunat.gob.pe">'
          '<applicationResponse>$cdrB64</applicationResponse>'
          '</br:sendBillResponse>'
          '</soapenv:Body>'
          '</soapenv:Envelope>';
      return CpeHttpResponse(
        statusCode: 200,
        headers: const {'content-type': 'text/xml; charset=utf-8'},
        bodyBytes: Uint8List.fromList(utf8.encode(xml)),
      );
    }

    throw StateError('Petición SUNAT Directo no simulada: ${request.uri}');
  }

  CpeHttpResponse _jsonResponse(Map<String, dynamic> map) {
    return CpeHttpResponse(
      statusCode: 200,
      headers: const {'content-type': 'application/json; charset=utf-8'},
      bodyBytes: Uint8List.fromList(utf8.encode(jsonEncode(map))),
    );
  }

  @override
  void close() {}
}

/// Proveedor OSE simulado con comportamiento programable para demostrar la política de Fallback.
final class _ProgrammableOseProvider
    with TicketPollingMixin
    implements OseProvider {
  @override
  final String providerId;

  final Future<CpeResult<CpeEmissionResponse>> Function(SalesCpeDocument doc)
  onSend;

  _ProgrammableOseProvider({required this.providerId, required this.onSend});

  @override
  Set<ProviderCapability> get capabilities => const {
    ProviderCapability.invoiceAndNotes,
  };

  @override
  Future<CpeResult<CpeEmissionResponse>> sendDocument(
    SalesCpeDocument document,
  ) => onSend(document);

  @override
  Future<CpeResult<TicketResponse>> sendDailySummary(
    DailySummaryDocument summary,
  ) => throw UnimplementedError();

  @override
  Future<CpeResult<TicketResponse>> sendVoidedDocument(VoidedDocument voided) =>
      throw UnimplementedError();

  @override
  Future<CpeResult<TicketResponse>> sendDespatchAdvice(
    DespatchAdviceDocument guide,
  ) => throw UnimplementedError();

  @override
  Future<CpeResult<CpeEmissionResponse>> sendRetentionOrPerception(
    AgentCpeDocument document,
  ) => throw UnimplementedError();

  @override
  Future<CpeResult<TicketStatusResponse>> checkTicket(
    String ticket, {
    DocumentId? referenceId,
  }) => throw UnimplementedError();

  @override
  Future<CpeResult<CpeStatusQueryResponse>> queryDocumentStatus(
    DocumentStatusQuery query,
  ) => throw UnimplementedError();
}

const _issuer = CompanyParty(
  ruc: '20100066603',
  legalName: 'HOLDING EMPRESARIAL ANDINO S.A.C.',
  address: Address(ubigeo: '150101', streetLine: 'AV. CENTRAL 500, LIMA'),
);

const _customer = CustomerParty(
  documentType: IdentityDocumentType.ruc,
  documentNumber: '20600055519',
  legalName: 'CORPORACION CLIENTE S.A.C.',
);

InvoiceDocument _buildInvoice({
  CpeDocumentType type = CpeDocumentType.factura,
  String series = 'F001',
  int number = 100,
  Decimal? overrideTotalIgv,
}) {
  return InvoiceDocument(
    id: DocumentId(
      issuerRuc: '20100066603',
      type: type,
      series: series,
      number: number,
    ),
    issueDate: DateTime(2026, 11, 4),
    issuer: _issuer,
    customer: _customer,
    currency: CurrencyCode.pen,
    items: [
      CpeLineItem(
        lineNumber: 1,
        description: 'SERVICIO DE CONSULTORIA EMPRESARIAL',
        quantity: Decimal.one,
        unitValue: Decimal.parse('1000.00'),
        unitPrice: Decimal.parse('1180.00'),
        lineExtensionAmount: Decimal.parse('1000.00'),
        taxableBaseAmount: Decimal.parse('1000.00'),
        igvAffectation: IgvAffectationType.gravadoOperacionOnerosa,
        igvPercentage: Decimal.parse('18.00'),
        igvAmount: Decimal.parse('180.00'),
        totalLineTaxAmount: Decimal.parse('180.00'),
        totalLineAmount: Decimal.parse('1180.00'),
      ),
    ],
    totals: MonetaryTotals(
      totalGravadas: Decimal.parse('1000.00'),
      totalIgv: overrideTotalIgv ?? Decimal.parse('180.00'),
      totalValorVenta: Decimal.parse('1000.00'),
      totalImpuestos: overrideTotalIgv ?? Decimal.parse('180.00'),
      totalPrecioVenta: Decimal.parse('1180.00'),
      importeTotalPagar: Decimal.parse('1180.00'),
    ),
  );
}

Future<void> main() async {
  print('===================================================================');
  print(' DEMO OFFLINE: sunat_cpe_dart (Orquestador y Router Multi-OSE/SOL)');
  print(
    '===================================================================\n',
  );

  final mockCert =
      SunatDirectMockCertificateFactory.createBetaMockCertificate();
  final nubefactHttp = _SimulatedNubefactHttpClient();
  final bizlinksHttp = _SimulatedBizlinksHttpClient();
  final sunatDirectHttp = _SimulatedSunatDirectHttpClient();

  // ---------------------------------------------------------------------------
  // 1. Fábrica Declarativa Multi-Tenant (SunatProviderFactory y fromDescriptors)
  // ---------------------------------------------------------------------------
  print(
    '1. Fábrica Declarativa Multi-Tenant (SunatProviderFactory y fromDescriptors)',
  );

  final nubefactDescriptor = NubefactDescriptor(
    NubefactConfig(
      routeUri: Uri.parse('https://api.nubefact.com/api/v1/tenant-principal'),
      apiToken: 'TOKEN_NUBEFACT_TENANT_1',
    ),
    httpClient: nubefactHttp,
  );

  final bizlinksDescriptor = BizlinksDescriptor(
    BizlinksConfig.forEnvironment(
      environment: BizlinksEnvironment.testing,
      username: '20100066603MODDATOS',
      password: 'moddatos',
      certificate: mockCert,
    ),
    httpClient: bizlinksHttp,
  );

  final efactDescriptor = EfactDescriptor(
    EfactConfig.restJson(
      username: '20100066603',
      password: 'efact-password',
      baseUri: EfactConfig.testRestUri,
    ),
  );

  final directSunatDescriptor = DirectSunatDescriptor(
    SunatDirectConfig.beta(
      clientId: 'sunat-gre-client-id',
      clientSecret: 'sunat-gre-client-secret',
    ),
    soapHttpClient: sunatDirectHttp,
    restHttpClient: sunatDirectHttp,
  );

  // Instanciación individual mediante SunatProviderFactory:
  final standaloneEfact = SunatProviderFactory.create(efactDescriptor);
  print(
    '   -> Proveedor instanciado con SunatProviderFactory: ${standaloneEfact.providerId}',
  );

  // Construcción declarativa completa del router híbrido:
  final router = SunatCpeRouter.fromDescriptors(
    primaryDescriptor: nubefactDescriptor,
    routeDescriptorsByDocumentType: {
      CpeDocumentType.comprobanteRetencion: bizlinksDescriptor,
      CpeDocumentType.resumenDiario: bizlinksDescriptor,
      CpeDocumentType.guiaRemisionRemitente: directSunatDescriptor,
      CpeDocumentType.guiaRemisionTransportista: directSunatDescriptor,
    },
    fallbackDescriptor: directSunatDescriptor,
    prefixTicketsWithProviderId: true,
  );
  print('   -> Router declarativo inicializado: ${router.providerId}');
  print(
    '   -> Capacidades combinadas: ${router.capabilities.map((c) => c.name).join(', ')}\n',
  );

  // ---------------------------------------------------------------------------
  // 2. Enrutamiento Inteligente por Tipo de Comprobante (routesByDocumentType)
  // ---------------------------------------------------------------------------
  print(
    '2. Enrutamiento Inteligente por Tipo de Comprobante (routesByDocumentType)',
  );

  // 2.1 Factura (01) y Boleta (03) -> van al proveedor primario (NubefactProvider)
  final facturaResult = await router.sendDocument(_buildInvoice());
  final facturaMeta =
      (facturaResult as CpeSuccess<CpeEmissionResponse>).providerRawMetadata;
  print(
    '   -> Factura (01) F001-100 enrutada a: [${facturaMeta['routedProviderId']}] '
    '| ${facturaResult.data.cdr?.description}',
  );

  final boletaResult = await router.sendDocument(
    _buildInvoice(type: CpeDocumentType.boleta, series: 'B001', number: 25),
  );
  final boletaMeta =
      (boletaResult as CpeSuccess<CpeEmissionResponse>).providerRawMetadata;
  print(
    '   -> Boleta (03) B001-25 enrutada a:   [${boletaMeta['routedProviderId']}] '
    '| ${boletaResult.data.cdr?.description}',
  );

  // 2.2 Retención (20) -> va al OSE SOAP configurado (BizlinksProvider)
  final retention = RetentionDocument(
    id: const DocumentId(
      issuerRuc: '20100066603',
      type: CpeDocumentType.comprobanteRetencion,
      series: 'R001',
      number: 1,
    ),
    issueDate: DateTime(2026, 11, 4),
    issuer: _issuer,
    partner: _customer,
    ratePercentage: Decimal.parse('3.00'),
    totalAmountInPen: Decimal.parse('35.40'),
    totalPaidOrCollectedInPen: Decimal.parse('1144.60'),
    lines: [
      AgentDocumentLine(
        relatedDocumentType: CpeDocumentType.factura,
        relatedSeriesAndNumber: 'F001-10',
        relatedIssueDate: DateTime(2026, 11, 1),
        relatedTotalAmount: Decimal.parse('1180.00'),
        paymentOrCollectionDate: DateTime(2026, 11, 4),
        paymentAmountBeforeTax: Decimal.parse('1180.00'),
        retainedOrPerceivedAmountInPen: Decimal.parse('35.40'),
        netPaidOrCollectedAmountInPen: Decimal.parse('1144.60'),
      ),
    ],
  );
  final retResult = await router.sendRetentionOrPerception(retention);
  final retMeta =
      (retResult as CpeSuccess<CpeEmissionResponse>).providerRawMetadata;
  print(
    '   -> Retención (20) R001-1 enrutada a: [${retMeta['routedProviderId']}] '
    '| ${retResult.data.cdr?.description}',
  );

  // 2.3 Guía de Remisión (09) -> va directo a la API REST gratuita de SUNAT (SunatDirectProvider)
  final guide = DespatchAdviceDocument(
    id: const DocumentId(
      issuerRuc: '20100066603',
      type: CpeDocumentType.guiaRemisionRemitente,
      series: 'T001',
      number: 1,
    ),
    issueDate: DateTime(2026, 11, 4),
    issuer: _issuer,
    recipient: _customer,
    transferReason: DespatchReasonCode.venta,
    transportMode: TransportModeCode.transportePublico,
    transferStartDate: DateTime(2026, 11, 5),
    grossWeight: Decimal.parse('80.00'),
    originAddress: const Address(ubigeo: '150101', streetLine: 'ALMACEN 1'),
    deliveryAddress: const Address(ubigeo: '150122', streetLine: 'DESTINO 2'),
    carrier: const CarrierParty(
      ruc: '20555111222',
      legalName: 'TRANSPORTES DEL PERU S.A.C.',
    ),
    items: [
      DespatchLineItem(
        lineNumber: 1,
        description: 'CAJAS DE EQUIPOS',
        quantity: Decimal.fromInt(4),
      ),
    ],
  );
  final guideTicketRes = await router.sendDespatchAdvice(guide);
  final guideMeta =
      (guideTicketRes as CpeSuccess<TicketResponse>).providerRawMetadata;
  print(
    '   -> Guía (09) T001-1 enrutada a:      [${guideMeta['routedProviderId']}] '
    '| Ticket con prefijo: ${guideTicketRes.data.ticket}\n',
  );

  // ---------------------------------------------------------------------------
  // 3. Rastreo Automático de Origen de Tickets Asíncronos (prefixTicketsWithProviderId: true)
  // ---------------------------------------------------------------------------
  print('3. Rastreo Automático de Origen de Tickets Asíncronos');

  final summary = DailySummaryDocument(
    id: const DocumentId(
      issuerRuc: '20100066603',
      type: CpeDocumentType.resumenDiario,
      series: 'RC-20261104',
      number: 1,
    ),
    issueDate: DateTime(2026, 11, 4),
    referenceDate: DateTime(2026, 11, 4),
    issuer: _issuer,
    lines: [
      DailySummaryLine(
        lineNumber: 1,
        documentType: CpeDocumentType.boleta,
        series: 'B001',
        number: 25,
        status: SummaryLineStatus.adicionar,
        customerDocumentType: IdentityDocumentType.dni,
        customerDocumentNumber: '45678912',
        totalGravadas: Decimal.parse('1000.00'),
        totalIgv: Decimal.parse('180.00'),
        totalSaleAmount: Decimal.parse('1180.00'),
      ),
    ],
  );

  final rcTicket = (await router.sendDailySummary(summary)).getOrThrow();
  final greTicket = guideTicketRes.data;

  print('   -> Ticket RC emitido por Bizlinks:      ${rcTicket.ticket}');
  print('   -> Ticket GRE emitido por SUNAT Direct: ${greTicket.ticket}');

  final rcStatus = (await router.checkTicket(rcTicket.ticket)).getOrThrow();
  print(
    '   -> router.checkTicket("${rcTicket.ticket}") dirigió la consulta a '
    '[${router.getRegisteredProviderForTicket(rcTicket.ticket)?.providerId}] '
    '-> ${rcStatus.statusMessage}',
  );

  final greFinalCdr = (await router.pollTicketUntilDone(
    greTicket.ticket,
    config: const PollingConfig(
      initialDelay: Duration(milliseconds: 10),
      maxAttempts: 2,
    ),
  )).getOrThrow();
  print(
    '   -> router.pollTicketUntilDone("${greTicket.ticket}") dirigió el polling a '
    '[${router.getRegisteredProviderForTicket(greTicket.ticket)?.providerId}] '
    '-> ${greFinalCdr.description}\n',
  );

  // ---------------------------------------------------------------------------
  // 4. Política de Fallback Contablemente Seguro (fallbackProvider)
  // ---------------------------------------------------------------------------
  print('4. Política de Fallback Contablemente Seguro (fallbackProvider)');
  final fallbackDirectProvider = SunatProviderFactory.create(
    directSunatDescriptor,
  );

  // Caso A.1: Caída de red HTTP 503 (OseTransportException) -> Activa Fallback
  final routerWith503Primary = SunatCpeRouter.simple(
    primaryProvider: _ProgrammableOseProvider(
      providerId: 'ose_caido_503',
      onSend: (_) async => const CpeFailure(
        OseTransportException(
          message: 'HTTP 503 Service Unavailable en OSE primario',
          httpStatusCode: 503,
        ),
      ),
    ),
    fallbackProvider: fallbackDirectProvider,
  );

  final resA1 = await routerWith503Primary.sendDocument(_buildInvoice());
  final metaA1 = (resA1 as CpeSuccess<CpeEmissionResponse>).providerRawMetadata;
  print(
    '   -> Caso A.1 (HTTP 503 OseTransportException): '
    'usedFallback=${metaA1['usedFallback']}, '
    'routedProviderId=${metaA1['routedProviderId']} '
    '(${resA1.data.cdr?.description})',
  );

  // Caso A.2: Excepción Técnica SUNAT 0130 (SunatExceptionError) -> Activa Fallback
  final routerWith0130Primary = SunatCpeRouter.simple(
    primaryProvider: _ProgrammableOseProvider(
      providerId: 'ose_error_tecnico_0130',
      onSend: (_) async => CpeFailure(
        SunatExceptionError(
          sunatCode: 130,
          message: '0130 - No se pudo procesar su solicitud temporalmente',
        ),
      ),
    ),
    fallbackProvider: fallbackDirectProvider,
  );

  final resA2 = await routerWith0130Primary.sendDocument(_buildInvoice());
  final metaA2 = (resA2 as CpeSuccess<CpeEmissionResponse>).providerRawMetadata;
  print(
    '   -> Caso A.2 (Excepción Técnica SUNAT 0130):   '
    'usedFallback=${metaA2['usedFallback']}, '
    'routedProviderId=${metaA2['routedProviderId']}',
  );

  // Caso B.1: Rechazo Tributario SUNAT 2800 (SunatRejectionException) -> BLOQUEA Fallback
  final routerWith2800Rejection = SunatCpeRouter.simple(
    primaryProvider: _ProgrammableOseProvider(
      providerId: 'ose_rechazo_tributario',
      onSend: (_) async => CpeFailure(
        SunatRejectionException(
          sunatCode: 2800,
          message: '2800 - El RUC del receptor se encuentra en baja definitiva',
        ),
      ),
    ),
    fallbackProvider: fallbackDirectProvider,
  );

  final resB1 = await routerWith2800Rejection.sendDocument(_buildInvoice());
  print(
    '   -> Caso B.1 (Rechazo Tributario 2800):        '
    'Fallback bloqueado correctamente -> isFailure=${resB1.isFailure} '
    '(${resB1.errorOrNull.runtimeType}: ${resB1.errorOrNull?.message})',
  );

  // Caso B.2: Error Aritmético Local (CpeValidationException) -> BLOQUEA Fallback
  final routerForValidation = SunatCpeRouter.simple(
    primaryProvider: SunatProviderFactory.create(nubefactDescriptor),
    fallbackProvider: fallbackDirectProvider,
  );

  // Creamos una factura con IGV descuadrado (999.00 en vez de 180.00)
  final invalidInvoice = _buildInvoice(
    overrideTotalIgv: Decimal.parse('999.00'),
  );
  final resB2 = await routerForValidation.sendDocument(invalidInvoice);
  print(
    '   -> Caso B.2 (Descuadre Aritmético Local):     '
    'Fallback bloqueado correctamente -> isFailure=${resB2.isFailure} '
    '(${resB2.errorOrNull.runtimeType})',
  );
}
