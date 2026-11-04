import 'dart:convert';
import 'dart:typed_data';

import 'package:sunat_cpe_core/sunat_cpe_core.dart';
import 'package:sunat_cpe_digiflow/sunat_cpe_digiflow.dart';

/// Llave privada RSA de prueba (PKCS#8 PEM) para firma XAdES-BES en memoria.
const _demoPrivateKeyPem = '''-----BEGIN PRIVATE KEY-----
MIICdwIBADANBgkqhkiG9w0BAQEFAASCAmEwggJdAgEAAoGBALxEz+5yuTRoJ12O
UhXP8hdwDeretYgq9wAw/gStM6G54Q7HGQHC5S+qKNQNlWeqAnWtOkInhkun6R3D
iVDE3QnmBYLrKD7IrzAbD/tA9Uw60LAFVCyEIUkWCXWJIDWiH2fg3USGSLg7rGlx
6u8czNt6yiKfy4tiSzVZ6Ja43eZjAgMBAAECgYAkR4peI8Nmwu9bCvLsex7mv1Qf
P31x2P2yDr7Ufd/mOWCSLXG3MixiDANEIb35tPw2WwRP/TfW2muErcqHQvho+8E6
hdVTTOGe7wNYrWvu6WQ2F+fKQPtO6sQUqWEF8/CuXkP4aIlyZyWjfISbvbGqvyqE
N0T06lOHg/r+3GpkaQJBAPW7D+b1lPJv8DpjcaoFg/VZzUHkOq/wCQ7pXf7YA+wZ
fqkWdxIWcBnZoApdVBwa/E1987vAMVF9LmMiJdSHwv8CQQDEIv8lsDfUZ24VDE2S
i7gHIRHUcmTpLnmdnakyZOlDj693qc04e0c1OMGeCgW+HgHx27aG7+GR+0uMzy5Q
dLCdAkEA3WtCR/1vygidcS9cIzS3E+RoNIBfdVsX/my/uruQxTSv0dKhVhYLyu8y
60PvXyfdwkHE1p+2kNP4cXE6n0f5pwJAAW1zx/VxYpViIrsVMXTc4QhnldFDVMMm
1XPZUGmVnQ1FrKxKtxeGnCeOmTTfd9PGFdmQiYjjbmmS0jKL1sASrQJBALRhsYmL
/zR/QQoGCheXdK3QhKXVXCvEt23E4x+tsOOsX/IvBppgKlPv52lOgvlgQVQNpCC2
0LHt4EkDHIRUoLc=
-----END PRIVATE KEY-----''';

/// Certificado X.509 de prueba en formato PEM.
const _demoCertificatePem = '''-----BEGIN CERTIFICATE-----
TUlJQ0ZqQ0NBWThDQVFBd0RRWUpLb1pJaHZjTkFRRUxCUUF3RURFT01Bd0dBMVVFQXd3RlZVVk5Q
-----END CERTIFICATE-----''';

/// Cliente HTTP simulado para validar el protocolo SOAP 1.1 de Digiflow OSE offline.
final class _SimulatedDigiflowHttpClient implements CpeHttpClient {
  final List<String> recordedSoapActions = [];
  int getStatusNetworkCalls = 0;

  @override
  Future<CpeHttpResponse> send(CpeHttpRequest request) async {
    final soapAction = request.headers['SOAPAction'] ?? '';
    recordedSoapActions.add(soapAction);
    final body = request.body.toString();

    if (body.contains('<ser:sendBill>')) {
      final isRetention = body.contains('-20-');
      final isGre = body.contains('-09-');
      final docLabel = isRetention
          ? 'El Comprobante de Retencion R001-15 ha sido aceptado por Digiflow OSE'
          : (isGre
                ? 'La Guia de Remision T001-77 (modo syncSendBill) ha sido aceptada'
                : 'La Factura F001-250 ha sido aceptada por Digiflow OSE');
      final cdrBase64 = _createMockCdrZipBase64(
        id: 'R-20100066603-01-F001-250',
        referenceId: 'F001-250',
        responseCode: '0',
        description: docLabel,
      );
      return _xmlResponse(
        '<soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/">'
        '<soapenv:Body>'
        '<br:sendBillResponse xmlns:br="http://service.sunat.gob.pe">'
        '<applicationResponse>$cdrBase64</applicationResponse>'
        '</br:sendBillResponse>'
        '</soapenv:Body>'
        '</soapenv:Envelope>',
      );
    }

    if (body.contains('<ser:sendSummary>') || body.contains('<ser:sendPack>')) {
      return _xmlResponse(
        '<soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/">'
        '<soapenv:Body>'
        '<br:sendSummaryResponse xmlns:br="http://service.sunat.gob.pe">'
        '<ticket>DIGIFLOW-ASYNC-TICKET-2026-88</ticket>'
        '</br:sendSummaryResponse>'
        '</soapenv:Body>'
        '</soapenv:Envelope>',
      );
    }

    if (body.contains('<ser:getStatus>')) {
      getStatusNetworkCalls++;
      final cdrBase64 = _createMockCdrZipBase64(
        id: 'R-20100066603-09-T001-78',
        referenceId: 'T001-78',
        responseCode: '0',
        description:
            'La Guia de Remision T001-78 (modo asyncTicket) ha sido aceptada',
      );
      return _xmlResponse(
        '<soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/">'
        '<soapenv:Body>'
        '<br:getStatusResponse xmlns:br="http://service.sunat.gob.pe">'
        '<status>'
        '<statusCode>0</statusCode>'
        '<content>$cdrBase64</content>'
        '</status>'
        '</br:getStatusResponse>'
        '</soapenv:Body>'
        '</soapenv:Envelope>',
      );
    }

    if (body.contains('<ser:getStatusCdr>')) {
      final cdrBase64 = _createMockCdrZipBase64(
        id: 'R-20100066603-01-F001-250',
        referenceId: 'F001-250',
        responseCode: '0',
        description: 'CDR historico recuperado desde Digiflow OSE (F001-250)',
      );
      return _xmlResponse(
        '<soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/">'
        '<soapenv:Body>'
        '<br:getStatusCdrResponse xmlns:br="http://service.sunat.gob.pe">'
        '<statusCdr>'
        '<statusCode>0004</statusCode>'
        '<statusMessage>La constancia existe</statusMessage>'
        '<content>$cdrBase64</content>'
        '</statusCdr>'
        '</br:getStatusCdrResponse>'
        '</soapenv:Body>'
        '</soapenv:Envelope>',
      );
    }

    return _xmlResponse('<soapenv:Envelope/>', statusCode: 400);
  }

  @override
  void close() {}

  static CpeHttpResponse _xmlResponse(String xml, {int statusCode = 200}) {
    return CpeHttpResponse(
      statusCode: statusCode,
      headers: const {'content-type': 'text/xml; charset=utf-8'},
      bodyBytes: Uint8List.fromList(utf8.encode(xml)),
    );
  }
}

String _createMockCdrZipBase64({
  required String id,
  required String referenceId,
  required String responseCode,
  required String description,
}) {
  final cdrXml =
      '<?xml version="1.0" encoding="UTF-8"?>'
      '<ar:ApplicationResponse xmlns:ar="urn:oasis:names:specification:ubl:schema:xsd:ApplicationResponse-2" '
      'xmlns:cac="urn:oasis:names:specification:ubl:schema:xsd:CommonAggregateComponents-2" '
      'xmlns:cbc="urn:oasis:names:specification:ubl:schema:xsd:CommonBasicComponents-2">'
      '<cbc:ID>$id</cbc:ID>'
      '<cbc:ResponseDate>2026-11-04</cbc:ResponseDate>'
      '<cbc:ResponseTime>11:30:00</cbc:ResponseTime>'
      '<cac:DocumentResponse>'
      '<cac:Response>'
      '<cbc:ReferenceID>$referenceId</cbc:ReferenceID>'
      '<cbc:ResponseCode>$responseCode</cbc:ResponseCode>'
      '<cbc:Description>$description</cbc:Description>'
      '</cac:Response>'
      '</cac:DocumentResponse>'
      '</ar:ApplicationResponse>';

  return const CpeZipCodec()
      .encodeXmlToZip(fileNameBase: id, xmlContent: cdrXml)
      .base64Zip;
}

const _issuer = CompanyParty(
  ruc: '20100066603',
  legalName: 'DISTRIBUIDORA DIGIFLOW DEMO S.A.C.',
  tradeName: 'DIGIFLOW DEMO',
  address: Address(
    ubigeo: '150101',
    streetLine: 'AV. REPUBLICA DE PANAMA 3500',
    district: 'SAN ISIDRO',
    province: 'LIMA',
    department: 'LIMA',
  ),
);

const _partner = CustomerParty(
  documentType: IdentityDocumentType.ruc,
  documentNumber: '20600695771',
  legalName: 'PROVEEDORES INDUSTRIALES DEL SUR S.A.C.',
  address: Address(ubigeo: '150140', streetLine: 'AV. EL DERBY 250 SURCO'),
);

DespatchAdviceDocument _buildDespatchGuide(int number) {
  return DespatchAdviceDocument(
    id: DocumentId(
      issuerRuc: '20100066603',
      type: CpeDocumentType.guiaRemisionRemitente,
      series: 'T001',
      number: number,
    ),
    issuer: _issuer,
    recipient: _partner,
    issueDate: DateTime(2026, 11, 4),
    transferReason: DespatchReasonCode.venta,
    transportMode: TransportModeCode.transportePublico,
    transferStartDate: DateTime(2026, 11, 5),
    grossWeight: Decimal.parse('85.00'),
    originAddress: const Address(
      ubigeo: '150101',
      streetLine: 'ALMACEN SAN ISIDRO',
    ),
    deliveryAddress: const Address(
      ubigeo: '150140',
      streetLine: 'AV. EL DERBY 250 SURCO',
    ),
    carrier: const CarrierParty(
      ruc: '20511223344',
      legalName: 'LOGISTICA EXPRESA S.A.C.',
    ),
    items: [
      DespatchLineItem(
        lineNumber: 1,
        internalCode: 'PROD-90',
        description: 'CAJAS DE EQUIPOS DE RED',
        quantity: Decimal.fromInt(10),
      ),
    ],
  );
}

Future<void> main() async {
  print('===================================================================');
  print('  DEMOSTRACIÓN INTEGRAL: sunat_cpe_digiflow (SOAP 1.1 WS-Security)');
  print(
    '===================================================================\n',
  );

  final certificate = CpeCertificateCredentials.fromPem(
    privateKeyPem: _demoPrivateKeyPem,
    certificatePem: _demoCertificatePem,
  );

  // ---------------------------------------------------------------------------
  // 1. Construcción de sobre SOAP 1.1 con DigiflowSoapEnvelope (mustUnderstand="1")
  // ---------------------------------------------------------------------------
  const envelopeBuilder = DigiflowSoapEnvelope();
  final rawEnvelope = envelopeBuilder.build(
    wsseUsername: '20100066603MODDATOS',
    wssePassword: 'moddatos',
    bodyXml: '<ser:getStatus><ticket>DEMO-001</ticket></ser:getStatus>',
  );
  print('1. Construcción de Sobre SOAP 1.1 con DigiflowSoapEnvelope:');
  print(
    '   - Contiene mustUnderstand="1" : ${rawEnvelope.contains('soapenv:mustUnderstand="1"')}',
  );
  print(
    '   - Endpoint Producción         : ${DigiflowConfig.productionEndpoint}',
  );
  print(
    '   - Endpoint Homologación       : ${DigiflowConfig.testingEndpoint}\n',
  );

  final simulatedHttp = _SimulatedDigiflowHttpClient();

  // ---------------------------------------------------------------------------
  // 2. Emisión de Factura (01) y Comprobante de Retención (20)
  // ---------------------------------------------------------------------------
  final syncProvider = DigiflowProvider(
    config: DigiflowConfig.forEnvironment(
      environment: DigiflowEnvironment.testing,
      username: '20100066603MODDATOS',
      password: 'moddatos',
      certificate: certificate,
      despatchMode: DigiflowDespatchMode.syncSendBill,
    ),
    httpClient: simulatedHttp,
  );

  final invoice = InvoiceDocument(
    id: const DocumentId(
      issuerRuc: '20100066603',
      type: CpeDocumentType.factura,
      series: 'F001',
      number: 250,
    ),
    issuer: _issuer,
    customer: _partner,
    issueDate: DateTime(2026, 11, 4),
    currency: CurrencyCode.pen,
    totals: MonetaryTotals(
      totalGravadas: Decimal.parse('500.00'),
      totalIgv: Decimal.parse('90.00'),
      totalValorVenta: Decimal.parse('500.00'),
      totalImpuestos: Decimal.parse('90.00'),
      totalPrecioVenta: Decimal.parse('590.00'),
      importeTotalPagar: Decimal.parse('590.00'),
    ),
    items: [
      CpeLineItem(
        lineNumber: 1,
        description: 'SERVICIO DE CERTIFICACION OSE DIGIFLOW',
        quantity: Decimal.fromInt(1),
        unitValue: Decimal.parse('500.00'),
        unitPrice: Decimal.parse('590.00'),
        lineExtensionAmount: Decimal.parse('500.00'),
        taxableBaseAmount: Decimal.parse('500.00'),
        igvPercentage: Decimal.parse('18.00'),
        igvAmount: Decimal.parse('90.00'),
        totalLineTaxAmount: Decimal.parse('90.00'),
        totalLineAmount: Decimal.parse('590.00'),
      ),
    ],
  );

  final retention = RetentionDocument(
    id: const DocumentId(
      issuerRuc: '20100066603',
      type: CpeDocumentType.comprobanteRetencion,
      series: 'R001',
      number: 15,
    ),
    issuer: _issuer,
    partner: _partner,
    issueDate: DateTime(2026, 11, 4),
    regime: RetentionRegimeCode.tasaTresPorCiento,
    ratePercentage: Decimal.parse('3.00'),
    totalAmountInPen: Decimal.parse('30.00'),
    totalPaidOrCollectedInPen: Decimal.parse('970.00'),
    lines: [
      AgentDocumentLine(
        relatedDocumentType: CpeDocumentType.factura,
        relatedSeriesAndNumber: 'F002-880',
        relatedIssueDate: DateTime(2026, 10, 28),
        relatedTotalAmount: Decimal.parse('1000.00'),
        paymentOrCollectionDate: DateTime(2026, 11, 4),
        paymentAmountBeforeTax: Decimal.parse('1000.00'),
        retainedOrPerceivedAmountInPen: Decimal.parse('30.00'),
        netPaidOrCollectedAmountInPen: Decimal.parse('970.00'),
      ),
    ],
  );

  final invRes = (await syncProvider.sendDocument(invoice)).getOrThrow();
  final retRes = (await syncProvider.sendRetentionOrPerception(retention))
      .getOrThrow();

  print('2. Emisión de Factura (01) y Comprobante de Retención (20):');
  print(
    '   - Factura 01   : ${invRes.documentId} -> ${invRes.cdr?.description}',
  );
  print(
    '   - Retención 20 : ${retRes.documentId} -> ${retRes.cdr?.description}',
  );
  print(
    '   - Cabeceras SOAPAction enviadas: ${simulatedHttp.recordedSoapActions}\n',
  );

  // ---------------------------------------------------------------------------
  // 3. Modo 1 GRE (DigiflowDespatchMode.syncSendBill): CDR directo + caché local
  // ---------------------------------------------------------------------------
  final callsBeforeSyncGre = simulatedHttp.getStatusNetworkCalls;
  final syncGreTicket = (await syncProvider.sendDespatchAdvice(
    _buildDespatchGuide(77),
  )).getOrThrow();
  final syncGreCdr = (await syncProvider.pollTicketUntilDone(
    syncGreTicket.ticket,
  )).getOrThrow();
  final callsAfterSyncGre = simulatedHttp.getStatusNetworkCalls;

  print('3. Guía de Remisión Modo 1 (DigiflowDespatchMode.syncSendBill):');
  print('   - Ticket Sintético : ${syncGreTicket.ticket}');
  print('   - CDR desde caché  : ${syncGreCdr.description}');
  print(
    '   - Llamadas de red a getStatus: ${callsAfterSyncGre - callsBeforeSyncGre} (resuelto en memoria)\n',
  );

  // ---------------------------------------------------------------------------
  // 4. Modo 2 GRE (DigiflowDespatchMode.asyncTicket): envío + consulta getStatus
  // ---------------------------------------------------------------------------
  final asyncProvider = DigiflowProvider(
    config: DigiflowConfig.forEnvironment(
      environment: DigiflowEnvironment.testing,
      username: '20100066603MODDATOS',
      password: 'moddatos',
      certificate: certificate,
      despatchMode: DigiflowDespatchMode.asyncTicket,
    ),
    httpClient: simulatedHttp,
  );

  final asyncGreTicket = (await asyncProvider.sendDespatchAdvice(
    _buildDespatchGuide(78),
  )).getOrThrow();
  final asyncGreCdr = (await asyncProvider.pollTicketUntilDone(
    asyncGreTicket.ticket,
  )).getOrThrow();

  print('4. Guía de Remisión Modo 2 (DigiflowDespatchMode.asyncTicket):');
  print('   - Ticket Asíncrono : ${asyncGreTicket.ticket}');
  print('   - CDR vía getStatus: ${asyncGreCdr.description}');
  print(
    '   - Llamadas de red a getStatus: ${simulatedHttp.getStatusNetworkCalls}\n',
  );

  // ---------------------------------------------------------------------------
  // 5. Consulta histórica de CDR (queryDocumentStatus -> getStatusCdr)
  // ---------------------------------------------------------------------------
  final statusQuery = (await syncProvider.queryDocumentStatus(
    const DocumentStatusQuery(
      issuerRuc: '20100066603',
      documentType: CpeDocumentType.factura,
      series: 'F001',
      number: 250,
    ),
  )).getOrThrow();

  print('5. Consulta Histórica de CDR (queryDocumentStatus -> getStatusCdr):');
  print(
    '   - Estado           : ${statusQuery.status.name} (código ${statusQuery.statusCode})',
  );
  print('   - Mensaje          : ${statusQuery.statusMessage}');
  print('   - Descripción CDR  : ${statusQuery.cdr?.description}');
}
