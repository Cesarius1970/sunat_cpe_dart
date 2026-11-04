import 'dart:convert';
import 'dart:typed_data';

import 'package:sunat_cpe_core/sunat_cpe_core.dart';
import 'package:sunat_cpe_direct/sunat_cpe_direct.dart';

/// Genera un archivo CDR `.zip` codificado en Base64 para simular respuestas SOAP y REST de SUNAT.
String _buildMockSunatCdrBase64({
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
  <cbc:ResponseTime>16:00:00</cbc:ResponseTime>
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

/// Cliente HTTP simulado para los canales SOAP de SUNAT (`e-factura` y `otroscpe`).
final class _SimulatedSunatSoapHttpClient implements CpeHttpClient {
  @override
  Future<CpeHttpResponse> send(CpeHttpRequest request) async {
    final body = request.body.toString();
    final endpoint = request.uri.toString();

    if (body.contains('<ser:sendBill>')) {
      final isOtrosCpe = endpoint.contains('otroscpe');
      final cdrB64 = _buildMockSunatCdrBase64(
        id: isOtrosCpe ? '20100066603-20-R001-1' : '20100066603-01-F001-1',
        responseCode: '0',
        description: isOtrosCpe
            ? 'El Comprobante de Agente (Retencion/Percepcion) ha sido aceptado en canal otroscpe'
            : 'El Comprobante de Venta (Factura/Nota) ha sido aceptado en canal e-factura',
      );
      return _soapResponse(
        '<br:sendBillResponse xmlns:br="http://service.sunat.gob.pe">'
        '<applicationResponse>$cdrB64</applicationResponse>'
        '</br:sendBillResponse>',
      );
    }

    if (body.contains('<ser:sendSummary>')) {
      final isRa = body.contains('-RA-');
      final ticket = isRa ? '202600888811112' : '202600777711111';
      return _soapResponse(
        '<br:sendSummaryResponse xmlns:br="http://service.sunat.gob.pe">'
        '<ticket>$ticket</ticket>'
        '</br:sendSummaryResponse>',
      );
    }

    if (body.contains('<ser:getStatus>')) {
      final cdrB64 = _buildMockSunatCdrBase64(
        id: '20100066603-RC-20261104-1',
        responseCode: '0',
        description: 'Resumen o Baja procesada exitosamente en SOAP e-factura',
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

    throw StateError('Operación SOAP no simulada: $endpoint');
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

/// Cliente HTTP simulado para la API REST OAuth2 GRE (`api-cpe.sunat.gob.pe`).
final class _SimulatedSunatRestGreHttpClient implements CpeHttpClient {
  int _grePollCount = 0;

  @override
  Future<CpeHttpResponse> send(CpeHttpRequest request) async {
    final path = request.uri.path;

    // Envío de Guía de Remisión Remitente (09) o Transportista (31)
    if (request.method == 'POST' && path.contains('/comprobantes/')) {
      final decoded =
          jsonDecode(request.body as String) as Map<String, dynamic>;
      final archivo = decoded['archivo'] as Map<String, dynamic>;
      final nomArchivo = archivo['nomArchivo'] as String;
      final arcGreZip = archivo['arcGreZip'] as String;
      final hashZip = archivo['hashZip'] as String;

      print(
        '   [REST GRE HTTP] POST $path\n'
        '   [REST GRE HTTP] nomArchivo: $nomArchivo | arcGreZip (Base64 len): ${arcGreZip.length} '
        '| hashZip (SHA-256 len ${hashZip.length}): ${hashZip.substring(0, 16)}...',
      );

      final isTransportista = nomArchivo.contains('-31-');
      return _jsonResponse({
        'numTicket': isTransportista
            ? 'GRE-REST-TCK-31-9002'
            : 'GRE-REST-TCK-09-9001',
        'fecRecepcion': '2026-11-04T16:10:00',
      });
    }

    // Consulta de Ticket GRE en GET /comprobantes/envios/{ticket}
    if (request.method == 'GET' && path.contains('/comprobantes/envios/')) {
      _grePollCount++;
      if (_grePollCount == 1) {
        return _jsonResponse({'codRespuesta': '98', 'indCdrGenerado': '0'});
      }
      final cdrB64 = _buildMockSunatCdrBase64(
        id: '20100066603-09-T001-1',
        responseCode: '0',
        description: 'La Guia de Remision Electronica ha sido aceptada en API REST GRE SUNAT',
      );
      return _jsonResponse({
        'codRespuesta': '0',
        'indCdrGenerado': '1',
        'arcCdr': cdrB64,
      });
    }

    throw StateError('Ruta REST GRE no simulada: $path');
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

Future<void> main() async {
  print('===================================================================');
  print(' DEMO OFFLINE: sunat_cpe_direct (SUNAT Operaciones en Línea - SOL)');
  print(
    '===================================================================\n',
  );

  // ---------------------------------------------------------------------------
  // 1. Configuración de Entornos y Seguridad de Certificados Digitales
  // ---------------------------------------------------------------------------
  print('1. Configuración de Entornos y Validación de Certificado Digital');
  final betaConfig = SunatDirectConfig.beta(
    clientId: 'sunat-oauth-client-id',
    clientSecret: 'sunat-oauth-client-secret',
  );
  print(
    '   -> Ambiente Beta configurado: usuario WSSE="${betaConfig.wsseUsername}", '
    'isMockCertificate=${betaConfig.isMockCertificate}',
  );

  try {
    SunatDirectConfig(
      ruc: '20100066603',
      usuarioSol: 'PRODUSER',
      claveSol: 'PRODPASS',
      environment: SunatDirectEnvironment.produccion,
      certificate:
          SunatDirectMockCertificateFactory.createBetaMockCertificate(),
      isMockCertificate: true,
    );
  } on ArgumentError catch (e) {
    print('   -> Protección en Producción verificada: ${e.message}\n');
  }

  final provider = SunatDirectProvider(
    config: betaConfig,
    soapHttpClient: _SimulatedSunatSoapHttpClient(),
    restHttpClient: _SimulatedSunatRestGreHttpClient(),
  );

  const issuer = CompanyParty(
    ruc: '20100066603',
    legalName: 'EMPRESA INDUSTRIAL PERUANA S.A.C.',
    address: Address(ubigeo: '150101', streetLine: 'AV. COLONIAL 1500, LIMA'),
  );

  const customer = CustomerParty(
    documentType: IdentityDocumentType.ruc,
    documentNumber: '20600055519',
    legalName: 'COMERCIALIZADORA DEL PACIFICO S.A.C.',
  );

  // ---------------------------------------------------------------------------
  // 2. Canal 1 — SOAP e-factura: Factura (01), Nota de Crédito (07), RC y RA
  // ---------------------------------------------------------------------------
  print(
    '2. Canal 1 — SOAP e-factura (${betaConfig.environment.soapInvoiceUri})',
  );

  final invoice = InvoiceDocument(
    id: const DocumentId(
      issuerRuc: '20100066603',
      type: CpeDocumentType.factura,
      series: 'F001',
      number: 1,
    ),
    issueDate: DateTime(2026, 11, 4),
    issuer: issuer,
    customer: customer,
    currency: CurrencyCode.pen,
    items: [
      CpeLineItem(
        lineNumber: 1,
        description: 'MAQUINARIA INDUSTRIAL MODELO X1',
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
      totalIgv: Decimal.parse('180.00'),
      totalValorVenta: Decimal.parse('1000.00'),
      totalImpuestos: Decimal.parse('180.00'),
      totalPrecioVenta: Decimal.parse('1180.00'),
      importeTotalPagar: Decimal.parse('1180.00'),
    ),
  );
  final invRes = (await provider.sendDocument(invoice)).getOrThrow();
  print(
    '   -> Factura (01) F001-1: ${invRes.status.name} | ${invRes.cdr?.description}',
  );

  final creditNote = CreditNoteDocument(
    id: const DocumentId(
      issuerRuc: '20100066603',
      type: CpeDocumentType.notaCredito,
      series: 'FC01',
      number: 1,
    ),
    issueDate: DateTime(2026, 11, 4),
    issuer: issuer,
    customer: customer,
    currency: CurrencyCode.pen,
    reasonCode: CreditNoteReasonCode.descuentoGlobal,
    reasonDescription: 'DESCUENTO PRONTO PAGO',
    affectedDocument: const DocumentReference(
      documentType: CpeDocumentType.factura,
      series: 'F001',
      number: 1,
    ),
    items: invoice.items,
    totals: invoice.totals,
  );
  final ncRes = (await provider.sendDocument(creditNote)).getOrThrow();
  print('   -> Nota de Crédito (07) FC01-1: ${ncRes.status.name}');

  final summary = DailySummaryDocument(
    id: const DocumentId(
      issuerRuc: '20100066603',
      type: CpeDocumentType.resumenDiario,
      series: 'RC-20261104',
      number: 1,
    ),
    issueDate: DateTime(2026, 11, 4),
    referenceDate: DateTime(2026, 11, 4),
    issuer: issuer,
    lines: [
      DailySummaryLine(
        lineNumber: 1,
        documentType: CpeDocumentType.boleta,
        series: 'B001',
        number: 1,
        status: SummaryLineStatus.adicionar,
        customerDocumentType: IdentityDocumentType.dni,
        customerDocumentNumber: '45678912',
        totalGravadas: Decimal.parse('100.00'),
        totalIgv: Decimal.parse('18.00'),
        totalSaleAmount: Decimal.parse('118.00'),
      ),
    ],
  );
  final rcTicket = (await provider.sendDailySummary(summary)).getOrThrow();
  print('   -> Resumen Diario (RC) enviado: Ticket ${rcTicket.ticket}');

  final voided = VoidedDocument(
    id: const DocumentId(
      issuerRuc: '20100066603',
      type: CpeDocumentType.comunicacionBaja,
      series: 'RA-20261104',
      number: 1,
    ),
    issueDate: DateTime(2026, 11, 4),
    referenceDate: DateTime(2026, 11, 3),
    issuer: issuer,
    lines: const [
      VoidedLine(
        lineNumber: 1,
        documentType: CpeDocumentType.factura,
        series: 'F001',
        number: 1,
        voidReason: 'ANULACION DE OPERACION',
      ),
    ],
  );
  final raTicket = (await provider.sendVoidedDocument(voided)).getOrThrow();
  print('   -> Comunicación de Baja (RA) enviada: Ticket ${raTicket.ticket}\n');

  // ---------------------------------------------------------------------------
  // 3. Canal 2 — SOAP otroscpe: Retención (20) y Percepción (40)
  // ---------------------------------------------------------------------------
  print(
    '3. Canal 2 — SOAP otroscpe (${betaConfig.environment.soapOtrosCpeUri})',
  );

  final retention = RetentionDocument(
    id: const DocumentId(
      issuerRuc: '20100066603',
      type: CpeDocumentType.comprobanteRetencion,
      series: 'R001',
      number: 1,
    ),
    issueDate: DateTime(2026, 11, 4),
    issuer: issuer,
    partner: customer,
    regime: RetentionRegimeCode.tasaTresPorCiento,
    ratePercentage: Decimal.parse('3.00'),
    totalAmountInPen: Decimal.parse('35.40'),
    totalPaidOrCollectedInPen: Decimal.parse('1144.60'),
    lines: [
      AgentDocumentLine(
        relatedDocumentType: CpeDocumentType.factura,
        relatedSeriesAndNumber: 'F001-50',
        relatedIssueDate: DateTime(2026, 11, 1),
        relatedTotalAmount: Decimal.parse('1180.00'),
        paymentOrCollectionDate: DateTime(2026, 11, 4),
        paymentAmountBeforeTax: Decimal.parse('1180.00'),
        retainedOrPerceivedAmountInPen: Decimal.parse('35.40'),
        netPaidOrCollectedAmountInPen: Decimal.parse('1144.60'),
      ),
    ],
  );
  final retRes = (await provider.sendRetentionOrPerception(retention))
      .getOrThrow();
  print(
    '   -> Retención (20) R001-1: ${retRes.status.name} | ${retRes.cdr?.description}',
  );

  final perception = PerceptionDocument(
    id: const DocumentId(
      issuerRuc: '20100066603',
      type: CpeDocumentType.comprobantePercepcion,
      series: 'P001',
      number: 1,
    ),
    issueDate: DateTime(2026, 11, 4),
    issuer: issuer,
    partner: customer,
    regime: PerceptionRegimeCode.ventaInterna,
    ratePercentage: Decimal.parse('2.00'),
    totalAmountInPen: Decimal.parse('23.60'),
    totalPaidOrCollectedInPen: Decimal.parse('1203.60'),
    lines: [
      AgentDocumentLine(
        relatedDocumentType: CpeDocumentType.factura,
        relatedSeriesAndNumber: 'F001-60',
        relatedIssueDate: DateTime(2026, 11, 1),
        relatedTotalAmount: Decimal.parse('1180.00'),
        paymentOrCollectionDate: DateTime(2026, 11, 4),
        paymentAmountBeforeTax: Decimal.parse('1180.00'),
        retainedOrPerceivedAmountInPen: Decimal.parse('23.60'),
        netPaidOrCollectedAmountInPen: Decimal.parse('1203.60'),
      ),
    ],
  );
  final perRes = (await provider.sendRetentionOrPerception(perception))
      .getOrThrow();
  print('   -> Percepción (40) P001-1: ${perRes.status.name}\n');

  // ---------------------------------------------------------------------------
  // 4. Canal 3 — REST OAuth2 GRE (api-cpe.sunat.gob.pe): Guías 09 y 31 + Polling
  // ---------------------------------------------------------------------------
  print(
    '4. Canal 3 — REST OAuth2 GRE (${betaConfig.environment.restGreBaseUri})',
  );

  final remitenteGuide = DespatchAdviceDocument(
    id: const DocumentId(
      issuerRuc: '20100066603',
      type: CpeDocumentType.guiaRemisionRemitente,
      series: 'T001',
      number: 1,
    ),
    issueDate: DateTime(2026, 11, 4),
    issuer: issuer,
    recipient: customer,
    transferReason: DespatchReasonCode.venta,
    transportMode: TransportModeCode.transportePublico,
    transferStartDate: DateTime(2026, 11, 5),
    grossWeight: Decimal.parse('250.00'),
    originAddress: const Address(
      ubigeo: '150101',
      streetLine: 'AV. COLONIAL 1500, LIMA',
    ),
    deliveryAddress: const Address(
      ubigeo: '150122',
      streetLine: 'AV. PARDO 450, MIRAFLORES',
    ),
    carrier: const CarrierParty(
      ruc: '20555999888',
      legalName: 'LOGISTICA EXPRESA DEL PERU S.A.C.',
    ),
    items: [
      DespatchLineItem(
        lineNumber: 1,
        internalCode: 'MAQ-01',
        description: 'MAQUINARIA INDUSTRIAL MODELO X1',
        quantity: Decimal.one,
      ),
    ],
  );

  final gre09Ticket = (await provider.sendDespatchAdvice(remitenteGuide))
      .getOrThrow();
  print(
    '   -> Guía Remitente (09) T001-1 enviada -> Ticket: ${gre09Ticket.ticket}',
  );

  final transportistaGuide = DespatchAdviceDocument(
    id: const DocumentId(
      issuerRuc: '20100066603',
      type: CpeDocumentType.guiaRemisionTransportista,
      series: 'V001',
      number: 1,
    ),
    issueDate: DateTime(2026, 11, 4),
    issuer: issuer,
    recipient: customer,
    transferReason: DespatchReasonCode.venta,
    transportMode: TransportModeCode.transportePrivado,
    transferStartDate: DateTime(2026, 11, 5),
    grossWeight: Decimal.parse('250.00'),
    originAddress: const Address(
      ubigeo: '150101',
      streetLine: 'AV. COLONIAL 1500, LIMA',
    ),
    deliveryAddress: const Address(
      ubigeo: '150122',
      streetLine: 'AV. PARDO 450, MIRAFLORES',
    ),
    vehicles: const [TransportVehicle(plateNumber: 'ABC-123')],
    drivers: const [
      DriverPerson(
        documentNumber: '45678912',
        firstName: 'JUAN',
        lastName: 'PEREZ',
        licenseNumber: 'Q45678912',
      ),
    ],
    items: remitenteGuide.items,
  );

  final gre31Ticket = (await provider.sendDespatchAdvice(transportistaGuide))
      .getOrThrow();
  print(
    '   -> Guía Transportista (31) V001-1 enviada -> Ticket: ${gre31Ticket.ticket}',
  );

  // checkTicket y pollTicketUntilDone enrutan automáticamente al canal REST GRE gracias al registro interno
  final firstCheck = (await provider.checkTicket(gre09Ticket.ticket))
      .getOrThrow();
  print(
    '   -> Primera consulta checkTicket(${gre09Ticket.ticket}): '
    '${firstCheck.status.name} (código ${firstCheck.statusCode})',
  );

  final finalGreCdr = (await provider.pollTicketUntilDone(
    gre09Ticket.ticket,
    config: const PollingConfig(
      initialDelay: Duration(milliseconds: 10),
      maxAttempts: 3,
    ),
  )).getOrThrow();
  print(
    '   -> CDR final obtenido con pollTicketUntilDone: '
    'código=${finalGreCdr.responseCode} | ${finalGreCdr.description}',
  );
}
