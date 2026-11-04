import 'dart:convert';
import 'dart:typed_data';

import 'package:sunat_cpe_core/sunat_cpe_core.dart';
import 'package:sunat_cpe_tci/sunat_cpe_tci.dart';

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

/// Cliente HTTP simulado para ejecutar todos los flujos de TCI OSE 100% offline.
final class _SimulatedTciHttpClient implements CpeHttpClient {
  @override
  Future<CpeHttpResponse> send(CpeHttpRequest request) async {
    final body = request.body.toString();

    if (body.contains('<ser:sendBill>')) {
      final isPerception = body.contains('-40-');
      final cdrBase64 = _createMockCdrZipBase64(
        id: isPerception
            ? 'R-20100066603-40-P001-12'
            : 'R-20100066603-01-F001-701',
        referenceId: isPerception ? 'P001-12' : 'F001-701',
        responseCode: '0',
        description: isPerception
            ? 'El Comprobante de Percepcion P001-12 ha sido aceptado por TCI OSE'
            : 'La Factura F001-701 ha sido aceptada por TCI OSE',
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
        '<ticket>TCI-TICKET-GRE-2026-44</ticket>'
        '</br:sendSummaryResponse>'
        '</soapenv:Body>'
        '</soapenv:Envelope>',
      );
    }

    if (body.contains('<ser:getStatus>')) {
      final cdrBase64 = _createMockCdrZipBase64(
        id: 'R-20100066603-09-T001-33',
        referenceId: 'T001-33',
        responseCode: '0',
        description: 'La Guia de Remision T001-33 ha sido aceptada por TCI OSE',
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
}) {
  final cdrXml =
      '<?xml version="1.0" encoding="UTF-8"?>'
      '<ar:ApplicationResponse xmlns:ar="urn:oasis:names:specification:ubl:schema:xsd:ApplicationResponse-2" '
      'xmlns:cac="urn:oasis:names:specification:ubl:schema:xsd:CommonAggregateComponents-2" '
      'xmlns:cbc="urn:oasis:names:specification:ubl:schema:xsd:CommonBasicComponents-2">'
      '<cbc:ID>$id</cbc:ID>'
      '<cbc:ResponseDate>2026-11-04</cbc:ResponseDate>'
      '<cbc:ResponseTime>15:00:00</cbc:ResponseTime>'
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
  legalName: 'AGROINDUSTRIAS DEL NORTE TCI S.A.C.',
  tradeName: 'AGRO TCI',
  address: Address(
    ubigeo: '130101',
    streetLine: 'CARRETERA PANAMERICANA NORTE KM 558',
    district: 'TRUJILLO',
    province: 'TRUJILLO',
    department: 'LA LIBERTAD',
  ),
);

const _customer = CustomerParty(
  documentType: IdentityDocumentType.ruc,
  documentNumber: '20600695771',
  legalName: 'DISTRIBUIDORA MAYORISTA LIMA S.A.C.',
  address: Address(ubigeo: '150101', streetLine: 'AV. ARGENTINA 1820 LIMA'),
);

Future<void> main() async {
  print('===================================================================');
  print('  DEMOSTRACIÓN INTEGRAL: sunat_cpe_tci (TCI OSE SOAP 1.1)');
  print(
    '===================================================================\n',
  );

  final certificate = CpeCertificateCredentials.fromPem(
    privateKeyPem: _demoPrivateKeyPem,
    certificatePem: _demoCertificatePem,
  );

  // ---------------------------------------------------------------------------
  // 1. Configuración por entorno y formateo automático WS-Security
  // ---------------------------------------------------------------------------
  final prodConfig = TciConfig.forEnvironment(
    environment: TciEnvironment.production,
    ruc: '20100066603',
    oseUser: 'TCIUSER01',
    osePassword: 'ProdPassword',
    certificate: certificate,
  );
  final testConfig = TciConfig.forEnvironment(
    environment: TciEnvironment.testing,
    ruc: '20100066603',
    oseUser: 'MODDATOS',
    osePassword: 'moddatos',
    certificate: certificate,
  );

  print('1. Configuración TciConfig.forEnvironment y Credencial WS-Security:');
  print('   - Endpoint Producción     : ${prodConfig.endpointUri}');
  print('   - Endpoint Homologación   : ${testConfig.endpointUri}');
  print(
    '   - formattedWsseUsername   : ${testConfig.formattedWsseUsername} ({RUC}{USUARIO_OSE_TCI})\n',
  );

  final provider = TciProvider(
    config: testConfig,
    httpClient: _SimulatedTciHttpClient(),
  );

  // ---------------------------------------------------------------------------
  // 2. Emisión de Factura (01), Percepción (40) y Guía de Remisión (09)
  // ---------------------------------------------------------------------------
  final invoice = InvoiceDocument(
    id: const DocumentId(
      issuerRuc: '20100066603',
      type: CpeDocumentType.factura,
      series: 'F001',
      number: 701,
    ),
    issuer: _issuer,
    customer: _customer,
    issueDate: DateTime(2026, 11, 4),
    currency: CurrencyCode.pen,
    totals: MonetaryTotals(
      totalGravadas: Decimal.parse('2000.00'),
      totalIgv: Decimal.parse('360.00'),
      totalValorVenta: Decimal.parse('2000.00'),
      totalImpuestos: Decimal.parse('360.00'),
      totalPrecioVenta: Decimal.parse('2360.00'),
      importeTotalPagar: Decimal.parse('2360.00'),
    ),
    items: [
      CpeLineItem(
        lineNumber: 1,
        internalCode: 'AGRO-01',
        description: 'INSUMOS AGRICOLAS CERTIFICADOS',
        quantity: Decimal.fromInt(20),
        unitValue: Decimal.parse('100.00'),
        unitPrice: Decimal.parse('118.00'),
        lineExtensionAmount: Decimal.parse('2000.00'),
        taxableBaseAmount: Decimal.parse('2000.00'),
        igvPercentage: Decimal.parse('18.00'),
        igvAmount: Decimal.parse('360.00'),
        totalLineTaxAmount: Decimal.parse('360.00'),
        totalLineAmount: Decimal.parse('2360.00'),
      ),
    ],
  );

  final perception = PerceptionDocument(
    id: const DocumentId(
      issuerRuc: '20100066603',
      type: CpeDocumentType.comprobantePercepcion,
      series: 'P001',
      number: 12,
    ),
    issuer: _issuer,
    partner: _customer,
    issueDate: DateTime(2026, 11, 4),
    regime: PerceptionRegimeCode.ventaInterna,
    ratePercentage: Decimal.parse('2.00'),
    totalAmountInPen: Decimal.parse('47.20'),
    totalPaidOrCollectedInPen: Decimal.parse('2407.20'),
    lines: [
      AgentDocumentLine(
        relatedDocumentType: CpeDocumentType.factura,
        relatedSeriesAndNumber: 'F001-701',
        relatedIssueDate: DateTime(2026, 11, 4),
        relatedTotalAmount: Decimal.parse('2360.00'),
        paymentOrCollectionDate: DateTime(2026, 11, 4),
        paymentAmountBeforeTax: Decimal.parse('2360.00'),
        retainedOrPerceivedAmountInPen: Decimal.parse('47.20'),
        netPaidOrCollectedAmountInPen: Decimal.parse('2407.20'),
      ),
    ],
  );

  final despatchGuide = DespatchAdviceDocument(
    id: const DocumentId(
      issuerRuc: '20100066603',
      type: CpeDocumentType.guiaRemisionRemitente,
      series: 'T001',
      number: 33,
    ),
    issuer: _issuer,
    recipient: _customer,
    issueDate: DateTime(2026, 11, 4),
    transferReason: DespatchReasonCode.venta,
    transportMode: TransportModeCode.transportePrivado,
    transferStartDate: DateTime(2026, 11, 5),
    grossWeight: Decimal.parse('500.00'),
    originAddress: const Address(
      ubigeo: '130101',
      streetLine: 'PLANTA TRUJILLO KM 558',
    ),
    deliveryAddress: const Address(
      ubigeo: '150101',
      streetLine: 'AV. ARGENTINA 1820 LIMA',
    ),
    vehicles: const [TransportVehicle(plateNumber: 'ABC-789')],
    drivers: const [
      DriverPerson(
        documentNumber: '41424344',
        firstName: 'CARLOS',
        lastName: 'MENDOZA',
        licenseNumber: 'Q41424344',
      ),
    ],
    items: [
      DespatchLineItem(
        lineNumber: 1,
        internalCode: 'AGRO-01',
        description: 'INSUMOS AGRICOLAS CERTIFICADOS',
        quantity: Decimal.fromInt(20),
      ),
    ],
  );

  final invRes = (await provider.sendDocument(invoice)).getOrThrow();
  final perRes = (await provider.sendRetentionOrPerception(perception))
      .getOrThrow();
  final greTicket = (await provider.sendDespatchAdvice(despatchGuide))
      .getOrThrow();
  final greCdr = (await provider.pollTicketUntilDone(greTicket.ticket))
      .getOrThrow();

  print('2. Emisión de Factura (01), Percepción (40) y Guía de Remisión (09):');
  print(
    '   - Factura (01)    : ${invRes.documentId} -> ${invRes.cdr?.description}',
  );
  print(
    '   - Percepción (40) : ${perRes.documentId} -> ${perRes.cdr?.description}',
  );
  print(
    '   - Guía (09)       : Ticket ${greTicket.ticket} -> ${greCdr.description}\n',
  );

  // ---------------------------------------------------------------------------
  // 3. Demostración de TciSoapFaultParser (soap-env:Client.2800 y Client.0151)
  // ---------------------------------------------------------------------------
  const faultParser = TciSoapFaultParser();

  const rejectionFaultXml = '''<?xml version="1.0" encoding="UTF-8"?>
<soap-env:Envelope xmlns:soap-env="http://schemas.xmlsoap.org/soap/envelope/">
  <soap-env:Body>
    <soap-env:Fault>
      <faultcode>soap-env:Client.2800</faultcode>
      <faultstring>El dato ingresado en el tipo de documento de identidad del receptor no esta permitido</faultstring>
      <detail>
        <message>Validacion de negocio TCI OSE</message>
      </detail>
    </soap-env:Fault>
  </soap-env:Body>
</soap-env:Envelope>''';

  const exceptionFaultXml = '''<?xml version="1.0" encoding="UTF-8"?>
<soap-env:Envelope xmlns:soap-env="http://schemas.xmlsoap.org/soap/envelope/">
  <soap-env:Body>
    <soap-env:Fault>
      <faultcode>soap-env:Client.0151</faultcode>
      <faultstring>El nombre del archivo XML no corresponde al archivo ZIP</faultstring>
    </soap-env:Fault>
  </soap-env:Body>
</soap-env:Envelope>''';

  final parsedRejection = faultParser.parseFault(
    CpeHttpResponse(
      statusCode: 500,
      headers: const {},
      bodyBytes: Uint8List.fromList(utf8.encode(rejectionFaultXml)),
    ),
  );
  final parsedException = faultParser.parseFault(
    CpeHttpResponse(
      statusCode: 500,
      headers: const {},
      bodyBytes: Uint8List.fromList(utf8.encode(exceptionFaultXml)),
    ),
  );

  print('3. Análisis de Fallos SOAP con TciSoapFaultParser:');
  print(
    '   - soap-env:Client.2800 -> ${parsedRejection.runtimeType}: '
    'código=${(parsedRejection as SunatRejectionException).sunatCode}, '
    'mensaje="${parsedRejection.message}"',
  );
  print(
    '   - soap-env:Client.0151 -> ${parsedException.runtimeType}: '
    'código=${(parsedException as SunatExceptionError).sunatCode}, '
    'mensaje="${parsedException.message}"',
  );
}
