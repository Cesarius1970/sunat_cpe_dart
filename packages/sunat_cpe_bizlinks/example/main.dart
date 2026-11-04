import 'dart:convert';
import 'dart:typed_data';

import 'package:sunat_cpe_bizlinks/sunat_cpe_bizlinks.dart';
import 'package:sunat_cpe_core/sunat_cpe_core.dart';

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

/// Cliente HTTP simulado para ejecutar todos los escenarios de Bizlinks OSE 100% offline.
final class _SimulatedBizlinksHttpClient implements CpeHttpClient {
  int _ticketPollCount = 0;

  @override
  Future<CpeHttpResponse> send(CpeHttpRequest request) async {
    final body = request.body.toString();

    if (body.contains('<ser:sendBill>') || body.contains('<ser:sendPack>')) {
      final isPack = body.contains('<ser:sendPack>');
      final cdrBase64 = _createMockCdrZipBase64(
        id: 'R-20100066603-01-F001-101',
        referenceId: 'F001-101',
        responseCode: '0',
        description: isPack
            ? 'La Guia de Remision T001-1 ha sido aceptada por Bizlinks OSE'
            : 'La Factura numero F001-101, ha sido aceptada por Bizlinks OSE',
        notes: const ['4252 - Observacion informativa no bloqueante'],
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

    if (body.contains('<ser:sendSummary>')) {
      final isRa = body.contains('RA-');
      final isGre = body.contains('-09-');
      final ticketId = isGre
          ? 'BIZ-TICKET-GRE-2026-003'
          : (isRa ? 'BIZ-TICKET-RA-2026-002' : 'BIZ-TICKET-RC-2026-001');
      return _xmlResponse(
        '<soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/">'
        '<soapenv:Body>'
        '<br:sendSummaryResponse xmlns:br="http://service.sunat.gob.pe">'
        '<ticket>$ticketId</ticket>'
        '</br:sendSummaryResponse>'
        '</soapenv:Body>'
        '</soapenv:Envelope>',
      );
    }

    if (body.contains('<ser:getStatus>')) {
      _ticketPollCount++;
      // Simula estado 98 (En proceso) en el primer intento y 0 (Aceptado) en el siguiente
      if (_ticketPollCount % 2 == 1) {
        return _xmlResponse(
          '<soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/">'
          '<soapenv:Body>'
          '<br:getStatusResponse xmlns:br="http://service.sunat.gob.pe">'
          '<status><statusCode>98</statusCode></status>'
          '</br:getStatusResponse>'
          '</soapenv:Body>'
          '</soapenv:Envelope>',
        );
      }

      final cdrBase64 = _createMockCdrZipBase64(
        id: 'R-20100066603-RC-20261104-1',
        referenceId: 'RC-20261104-1',
        responseCode: '0',
        description:
            'Ticket procesado y aceptado correctamente en Bizlinks OSE',
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
  List<String> notes = const [],
}) {
  final notesXml = notes.map((n) => '<cbc:Note>$n</cbc:Note>').join();
  final cdrXml =
      '<?xml version="1.0" encoding="UTF-8"?>'
      '<ar:ApplicationResponse xmlns:ar="urn:oasis:names:specification:ubl:schema:xsd:ApplicationResponse-2" '
      'xmlns:cac="urn:oasis:names:specification:ubl:schema:xsd:CommonAggregateComponents-2" '
      'xmlns:cbc="urn:oasis:names:specification:ubl:schema:xsd:CommonBasicComponents-2">'
      '<cbc:ID>$id</cbc:ID>'
      '<cbc:ResponseDate>2026-11-04</cbc:ResponseDate>'
      '<cbc:ResponseTime>10:15:00</cbc:ResponseTime>'
      '$notesXml'
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
  legalName: 'CORPORACION INDUSTRIAL PERU S.A.C.',
  tradeName: 'CORP PERU',
  address: Address(
    ubigeo: '150101',
    streetLine: 'AV. JAVIER PRADO ESTE 2450',
    district: 'SAN BORJA',
    province: 'LIMA',
    department: 'LIMA',
  ),
);

const _customer = CustomerParty(
  documentType: IdentityDocumentType.ruc,
  documentNumber: '20600695771',
  legalName: 'IMPORTACIONES TECNOLOGICAS S.A.C.',
  address: Address(ubigeo: '150122', streetLine: 'CALLE ALCANFORES 410'),
);

Future<void> main() async {
  print('===================================================================');
  print('  DEMOSTRACIÓN INTEGRAL: sunat_cpe_bizlinks (SOAP 1.1 WS-Security)');
  print(
    '===================================================================\n',
  );

  final certificate = CpeCertificateCredentials.fromPem(
    privateKeyPem: _demoPrivateKeyPem,
    certificatePem: _demoCertificatePem,
  );

  // ---------------------------------------------------------------------------
  // 1. Configuración por entorno (Producción y Homologación)
  // ---------------------------------------------------------------------------
  final prodConfig = BizlinksConfig.forEnvironment(
    environment: BizlinksEnvironment.production,
    username: '20100066603BIZUSER',
    password: 'SecretProdPassword',
    certificate: certificate,
  );
  final testConfig = BizlinksConfig.forEnvironment(
    environment: BizlinksEnvironment.testing,
    username: '20100066603MODDATOS',
    password: 'moddatos',
    certificate: certificate,
  );

  print('1. Configuración por Entorno (BizlinksConfig.forEnvironment):');
  print('   - Endpoint Producción   : ${prodConfig.endpointUri}');
  print('   - Endpoint Homologación : ${testConfig.endpointUri}\n');

  final provider = BizlinksProvider(
    config: testConfig,
    httpClient: _SimulatedBizlinksHttpClient(),
  );

  // ---------------------------------------------------------------------------
  // 2. Emisión de Factura (01) firmada con XAdES-BES (sendDocument -> sendBill)
  // ---------------------------------------------------------------------------
  final invoice = InvoiceDocument(
    id: const DocumentId(
      issuerRuc: '20100066603',
      type: CpeDocumentType.factura,
      series: 'F001',
      number: 101,
    ),
    issuer: _issuer,
    customer: _customer,
    issueDate: DateTime(2026, 11, 4),
    issueTime: '10:15:00',
    currency: CurrencyCode.pen,
    totals: MonetaryTotals(
      totalGravadas: Decimal.parse('1000.00'),
      totalIgv: Decimal.parse('180.00'),
      totalValorVenta: Decimal.parse('1000.00'),
      totalImpuestos: Decimal.parse('180.00'),
      totalPrecioVenta: Decimal.parse('1180.00'),
      importeTotalPagar: Decimal.parse('1180.00'),
      amountInWords: 'SON MIL CIENTO OCHENTA Y 00/100 SOLES',
    ),
    items: [
      CpeLineItem(
        lineNumber: 1,
        internalCode: 'LIC-BIZ-01',
        description: 'SERVICIO DE INTERCAMBIO ELECTRONICO OSE ANUAL',
        quantity: Decimal.fromInt(1),
        unitValue: Decimal.parse('1000.00'),
        unitPrice: Decimal.parse('1180.00'),
        lineExtensionAmount: Decimal.parse('1000.00'),
        taxableBaseAmount: Decimal.parse('1000.00'),
        igvPercentage: Decimal.parse('18.00'),
        igvAmount: Decimal.parse('180.00'),
        totalLineTaxAmount: Decimal.parse('180.00'),
        totalLineAmount: Decimal.parse('1180.00'),
      ),
    ],
  );

  final invoiceResponse = (await provider.sendDocument(invoice)).getOrThrow();
  print('2. Emisión de Factura Electrónica (01) -> SOAP sendBill:');
  print('   - Comprobante : ${invoiceResponse.documentId}');
  print('   - Estado      : ${invoiceResponse.status.name}');
  print('   - Hash (XAdES): ${invoiceResponse.digestValue}');
  print('   - CDR Mensaje : ${invoiceResponse.cdr?.description}');
  print('   - Advertencias: ${invoiceResponse.cdr?.warnings.join(', ')}');
  print('   - Cadena QR   : ${invoiceResponse.qrContent}\n');

  // ---------------------------------------------------------------------------
  // 3. Resumen Diario (RC) y Comunicación de Baja (RA) con pollTicketUntilDone
  // ---------------------------------------------------------------------------
  final summaryRc = DailySummaryDocument(
    id: const DocumentId(
      issuerRuc: '20100066603',
      type: CpeDocumentType.resumenDiario,
      series: 'RC-20261104',
      number: 1,
    ),
    issuer: _issuer,
    issueDate: DateTime(2026, 11, 4),
    referenceDate: DateTime(2026, 11, 3),
    lines: [
      DailySummaryLine(
        lineNumber: 1,
        documentType: CpeDocumentType.boleta,
        series: 'B001',
        number: 55,
        status: SummaryLineStatus.adicionar,
        customerDocumentType: IdentityDocumentType.dni,
        customerDocumentNumber: '44556677',
        totalGravadas: Decimal.parse('100.00'),
        totalIgv: Decimal.parse('18.00'),
        totalSaleAmount: Decimal.parse('118.00'),
      ),
    ],
  );

  final rcTicket = (await provider.sendDailySummary(summaryRc)).getOrThrow();
  final rcCdr = (await provider.pollTicketUntilDone(
    rcTicket.ticket,
    config: const PollingConfig(initialDelay: Duration(milliseconds: 5)),
  )).getOrThrow();

  final voidedRa = VoidedDocument(
    id: const DocumentId(
      issuerRuc: '20100066603',
      type: CpeDocumentType.comunicacionBaja,
      series: 'RA-20261104',
      number: 1,
    ),
    issuer: _issuer,
    issueDate: DateTime(2026, 11, 4),
    referenceDate: DateTime(2026, 11, 3),
    lines: const [
      VoidedLine(
        lineNumber: 1,
        documentType: CpeDocumentType.factura,
        series: 'F001',
        number: 99,
        voidReason: 'ERROR EN RUC DEL ADQUIRENTE',
      ),
    ],
  );

  final raTicket = (await provider.sendVoidedDocument(voidedRa)).getOrThrow();
  final raCdr = (await provider.pollTicketUntilDone(
    raTicket.ticket,
    config: const PollingConfig(initialDelay: Duration(milliseconds: 5)),
  )).getOrThrow();

  print(
    '3. Resumen Diario (RC) y Comunicación de Baja (RA) -> sendSummary + getStatus:',
  );
  print('   - Ticket RC : ${rcTicket.ticket} -> CDR: ${rcCdr.description}');
  print('   - Ticket RA : ${raTicket.ticket} -> CDR: ${raCdr.description}\n');

  // ---------------------------------------------------------------------------
  // 4. Emisión de Guía de Remisión Remitente (09) (sendDespatchAdvice / sendPack)
  // ---------------------------------------------------------------------------
  final despatchGuide = DespatchAdviceDocument(
    id: const DocumentId(
      issuerRuc: '20100066603',
      type: CpeDocumentType.guiaRemisionRemitente,
      series: 'T001',
      number: 1,
    ),
    issuer: _issuer,
    recipient: _customer,
    issueDate: DateTime(2026, 11, 4),
    transferReason: DespatchReasonCode.venta,
    transportMode: TransportModeCode.transportePublico,
    transferStartDate: DateTime(2026, 11, 5),
    grossWeight: Decimal.parse('150.50'),
    originAddress: const Address(
      ubigeo: '150101',
      streetLine: 'ALMACEN CENTRAL LIMA',
    ),
    deliveryAddress: const Address(
      ubigeo: '150122',
      streetLine: 'CALLE ALCANFORES 410 MIRAFLORES',
    ),
    carrier: const CarrierParty(
      ruc: '20555444333',
      legalName: 'TRANSPORTES RAPIDOS DEL PERU S.A.C.',
      mtcRegistrationNumber: '15443322CNG',
    ),
    items: [
      DespatchLineItem(
        lineNumber: 1,
        internalCode: 'EQ-SRV-01',
        description: 'SERVIDOR RACK 2U',
        quantity: Decimal.fromInt(3),
      ),
    ],
  );

  final greTicket = (await provider.sendDespatchAdvice(despatchGuide))
      .getOrThrow();
  final greCdr = (await provider.pollTicketUntilDone(
    greTicket.ticket,
    config: const PollingConfig(initialDelay: Duration(milliseconds: 5)),
  )).getOrThrow();

  print('4. Emisión de Guía de Remisión Remitente (09):');
  print('   - Guía Remisión : ${despatchGuide.id}');
  print('   - Ticket GRE    : ${greTicket.ticket}');
  print(
    '   - Respuesta CDR : [${greCdr.responseCode}] ${greCdr.description}\n',
  );

  // ---------------------------------------------------------------------------
  // 5. Demostración de BizlinksSoapFaultParser (Excepción Técnica vs Rechazo)
  // ---------------------------------------------------------------------------
  const faultParser = BizlinksSoapFaultParser();

  const technicalFaultXml = '''<?xml version="1.0" encoding="UTF-8"?>
<soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/">
  <soapenv:Body>
    <soapenv:Fault>
      <faultcode>soap-env:Client.0151</faultcode>
      <faultstring>El nombre del archivo XML no corresponde al archivo ZIP</faultstring>
    </soapenv:Fault>
  </soapenv:Body>
</soapenv:Envelope>''';

  const rejectionFaultXml = '''<?xml version="1.0" encoding="UTF-8"?>
<soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/">
  <soapenv:Body>
    <soapenv:Fault>
      <faultcode>soapenv:Client</faultcode>
      <faultstring>2017</faultstring>
      <detail>
        <message>El comprobante F001-101 ya fue informado anteriormente a Bizlinks OSE</message>
      </detail>
    </soapenv:Fault>
  </soapenv:Body>
</soapenv:Envelope>''';

  final parsedTech = faultParser.parseFault(
    CpeHttpResponse(
      statusCode: 500,
      headers: const {},
      bodyBytes: Uint8List.fromList(utf8.encode(technicalFaultXml)),
    ),
  );
  final parsedRej = faultParser.parseFault(
    CpeHttpResponse(
      statusCode: 500,
      headers: const {},
      bodyBytes: Uint8List.fromList(utf8.encode(rejectionFaultXml)),
    ),
  );

  print('5. Diagnóstico de Fallos SOAP con BizlinksSoapFaultParser:');
  print(
    '   - Client.0151 -> ${parsedTech.runtimeType}: '
    'código=${(parsedTech as SunatExceptionError).sunatCode}, '
    'mensaje="${parsedTech.message}"',
  );
  print(
    '   - faultstring=2017 + <detail><message> -> ${parsedRej.runtimeType}: '
    'código=${(parsedRej as SunatRejectionException).sunatCode}, '
    'mensaje="${parsedRej.message}"',
  );
}
