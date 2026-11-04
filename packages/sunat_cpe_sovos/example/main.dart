import 'dart:convert';
import 'dart:typed_data';

import 'package:sunat_cpe_core/sunat_cpe_core.dart';
import 'package:sunat_cpe_sovos/sunat_cpe_sovos.dart';

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

/// Cliente HTTP simulado para probar Sovos / Paperless OSE y recuperación idempotente offline.
final class _SimulatedSovosHttpClient implements CpeHttpClient {
  bool simulateDuplicateFaultOnSendBill = false;
  int getStatusCdrCalls = 0;

  @override
  Future<CpeHttpResponse> send(CpeHttpRequest request) async {
    final body = request.body.toString();

    if (body.contains('<ser:sendBill>')) {
      if (simulateDuplicateFaultOnSendBill) {
        return _xmlResponse('''<?xml version="1.0" encoding="UTF-8"?>
<soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/">
  <soapenv:Body>
    <soapenv:Fault>
      <faultcode>soap-env:Client.2017</faultcode>
      <faultstring>El comprobante F001-502 ya fue registrado previamente en Sovos OSE</faultstring>
    </soapenv:Fault>
  </soapenv:Body>
</soapenv:Envelope>''', statusCode: 500);
      }

      final cdrBase64 = _createMockCdrZipBase64(
        id: 'R-20100066603-01-F001-501',
        referenceId: 'F001-501',
        responseCode: '0',
        description:
            'La Factura F001-501 ha sido aceptada por Sovos Paperless OSE',
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

    if (body.contains('<ser:getStatusCdr>')) {
      getStatusCdrCalls++;
      final cdrBase64 = _createMockCdrZipBase64(
        id: 'R-20100066603-01-F001-502',
        referenceId: 'F001-502',
        responseCode: '0',
        description: 'La Factura F001-502 ha sido aceptada (CDR recuperado idempotentemente)',
      );
      return _xmlResponse(
        '<soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/">'
        '<soapenv:Body>'
        '<br:getStatusCdrResponse xmlns:br="http://service.sunat.gob.pe">'
        '<statusCdr>'
        '<statusCode>0004</statusCode>'
        '<statusMessage>La constancia de recepcion existe</statusMessage>'
        '<content>$cdrBase64</content>'
        '</statusCdr>'
        '</br:getStatusCdrResponse>'
        '</soapenv:Body>'
        '</soapenv:Envelope>',
      );
    }

    if (body.contains('<ser:sendSummary>')) {
      final isRa = body.contains('RA-');
      final ticket = isRa ? 'SOVOS-RA-2026-9002' : 'SOVOS-RC-2026-9001';
      return _xmlResponse(
        '<soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/">'
        '<soapenv:Body>'
        '<br:sendSummaryResponse xmlns:br="http://service.sunat.gob.pe">'
        '<ticket>$ticket</ticket>'
        '</br:sendSummaryResponse>'
        '</soapenv:Body>'
        '</soapenv:Envelope>',
      );
    }

    if (body.contains('<ser:getStatus>')) {
      final cdrBase64 = _createMockCdrZipBase64(
        id: 'R-20100066603-RC-20261104-1',
        referenceId: 'RC-20261104-1',
        responseCode: '0',
        description: 'Resumen procesado y aceptado en Sovos OSE',
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
      '<cbc:ResponseTime>12:00:00</cbc:ResponseTime>'
      '<cbc:DigestValue>SovosOriginalDigestHashBase64==</cbc:DigestValue>'
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
  legalName: 'RETAIL PERUANO SOVOS S.A.C.',
  tradeName: 'RETAIL PERU',
  address: Address(
    ubigeo: '150101',
    streetLine: 'JR. DE LA UNION 850',
    district: 'LIMA',
    province: 'LIMA',
    department: 'LIMA',
  ),
);

const _customer = CustomerParty(
  documentType: IdentityDocumentType.ruc,
  documentNumber: '20600695771',
  legalName: 'COMERCIALIZADORA ANDINA S.A.C.',
  address: Address(ubigeo: '150101', streetLine: 'AV. TACNA 450 LIMA'),
);

InvoiceDocument _buildInvoice(int number) {
  return InvoiceDocument(
    id: DocumentId(
      issuerRuc: '20100066603',
      type: CpeDocumentType.factura,
      series: 'F001',
      number: number,
    ),
    issuer: _issuer,
    customer: _customer,
    issueDate: DateTime(2026, 11, 4),
    currency: CurrencyCode.pen,
    totals: MonetaryTotals(
      totalGravadas: Decimal.parse('200.00'),
      totalIgv: Decimal.parse('36.00'),
      totalValorVenta: Decimal.parse('200.00'),
      totalImpuestos: Decimal.parse('36.00'),
      totalPrecioVenta: Decimal.parse('236.00'),
      importeTotalPagar: Decimal.parse('236.00'),
    ),
    items: [
      CpeLineItem(
        lineNumber: 1,
        internalCode: 'ART-10',
        description: 'TERMINAL PUNTO DE VENTA POS INALAMBRICO',
        quantity: Decimal.fromInt(1),
        unitValue: Decimal.parse('200.00'),
        unitPrice: Decimal.parse('236.00'),
        lineExtensionAmount: Decimal.parse('200.00'),
        taxableBaseAmount: Decimal.parse('200.00'),
        igvPercentage: Decimal.parse('18.00'),
        igvAmount: Decimal.parse('36.00'),
        totalLineTaxAmount: Decimal.parse('36.00'),
        totalLineAmount: Decimal.parse('236.00'),
      ),
    ],
  );
}

Future<void> main() async {
  print('===================================================================');
  print('  DEMOSTRACIÓN INTEGRAL: sunat_cpe_sovos (Sovos / Paperless OSE)');
  print(
    '===================================================================\n',
  );

  final certificate = CpeCertificateCredentials.fromPem(
    privateKeyPem: _demoPrivateKeyPem,
    certificatePem: _demoCertificatePem,
  );

  // ---------------------------------------------------------------------------
  // 1. Configuración SovosConfig con customPrintFields y SovosUblExtensionBuilder
  // ---------------------------------------------------------------------------
  const printFields = {'VENDEDOR': 'JUAN PEREZ', 'SUCURSAL': 'LIMA CENTRO'};

  final configOseSigned = SovosConfig(
    endpointUri: SovosConfig.certificationEndpoint,
    username: '20100066603MODDATOS',
    password: 'moddatos',
    certificate: certificate,
    mode: SovosIntegrationMode.oseUblSigned,
    autoRecoverCdrOnDuplicate: true,
    customPrintFields: printFields,
  );

  final unsignedInvoiceXml = const UblXmlBuilder().buildUnsignedXml(
    _buildInvoice(500),
  );
  final enrichedXml = const SovosUblExtensionBuilder().injectCustomPrintFields(
    unsignedInvoiceXml,
    configOseSigned.customPrintFields,
  );

  print('1. Configuración SovosConfig y SovosUblExtensionBuilder:');
  print('   - Endpoint Producción    : ${SovosConfig.productionEndpoint}');
  print('   - Endpoint Certificación : ${SovosConfig.certificationEndpoint}');
  print('   - Campos Personalizados  : ${configOseSigned.customPrintFields}');
  print(
    '   - XML contiene <SovosCustomPrintFields>: ${enrichedXml.contains('<SovosCustomPrintFields>')}',
  );
  print(
    '   - XML contiene VENDEDOR=JUAN PEREZ     : ${enrichedXml.contains('<Field name="VENDEDOR">JUAN PEREZ</Field>')}\n',
  );

  // ---------------------------------------------------------------------------
  // 2. Emisión de Factura (01) en modos oseUblSigned y pseCloudSign
  // ---------------------------------------------------------------------------
  final simulatedHttp = _SimulatedSovosHttpClient();

  final oseProvider = SovosProvider(
    config: configOseSigned,
    httpClient: simulatedHttp,
  );
  final pseProvider = SovosProvider(
    config: SovosConfig(
      endpointUri: SovosConfig.certificationEndpoint,
      username: '20100066603PSEUSER',
      password: 'psepassword',
      certificate: certificate,
      mode: SovosIntegrationMode.pseCloudSign,
      customPrintFields: printFields,
    ),
    httpClient: simulatedHttp,
  );

  final oseResult = (await oseProvider.sendDocument(_buildInvoice(501)))
      .getOrThrow();
  final pseResult = (await pseProvider.sendDocument(_buildInvoice(501)))
      .getOrThrow();

  print('2. Emisión de Factura (01) en Modos OSE y PSE:');
  print(
    '   - Modo ${configOseSigned.mode.name}: ${oseResult.documentId} -> ${oseResult.cdr?.description}',
  );
  print(
    '   - Modo ${pseProvider.config.mode.name} : ${pseResult.documentId} -> ${pseResult.cdr?.description}\n',
  );

  // ---------------------------------------------------------------------------
  // 3. Recuperación Idempotente Automática de CDR (autoRecoverCdrOnDuplicate)
  // ---------------------------------------------------------------------------
  simulatedHttp.simulateDuplicateFaultOnSendBill = true;
  final duplicateResult = await oseProvider.sendDocument(_buildInvoice(502));
  simulatedHttp.simulateDuplicateFaultOnSendBill = false;

  if (duplicateResult case CpeSuccess<CpeEmissionResponse>(
    :final data,
    :final providerRawMetadata,
  )) {
    print(
      '3. Recuperación Idempotente Automática de CDR ante Duplicado (Fault 2017):',
    );
    print(
      '   - Llamadas automáticas a getStatusCdr : ${simulatedHttp.getStatusCdrCalls}',
    );
    print(
      '   - recoveredFromDuplicate              : ${providerRawMetadata['recoveredFromDuplicate']}',
    );
    print('   - Estado final                        : ${data.status.name}');
    print(
      '   - CDR Recuperado                      : ${data.cdr?.description}',
    );
    print('   - QR Reconstruido                     : ${data.qrContent}\n');
  }

  // ---------------------------------------------------------------------------
  // 4. Resumen Diario (RC) y Comunicación de Baja (RA)
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
        number: 120,
        status: SummaryLineStatus.adicionar,
        customerDocumentType: IdentityDocumentType.dni,
        customerDocumentNumber: '40506070',
        totalGravadas: Decimal.parse('50.00'),
        totalIgv: Decimal.parse('9.00'),
        totalSaleAmount: Decimal.parse('59.00'),
      ),
    ],
  );

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
        number: 499,
        voidReason: 'ANULACION POR DUPLICIDAD DE EMISION',
      ),
    ],
  );

  final rcTicket = (await oseProvider.sendDailySummary(summaryRc)).getOrThrow();
  final rcCdr = (await oseProvider.pollTicketUntilDone(rcTicket.ticket))
      .getOrThrow();

  final raTicket = (await oseProvider.sendVoidedDocument(voidedRa))
      .getOrThrow();
  final raCdr = (await oseProvider.pollTicketUntilDone(raTicket.ticket))
      .getOrThrow();

  print('4. Resumen Diario (RC) y Comunicación de Baja (RA):');
  print(
    '   - Resumen Diario (RC)       : Ticket ${rcTicket.ticket} -> ${rcCdr.description}',
  );
  print(
    '   - Comunicación de Baja (RA) : Ticket ${raTicket.ticket} -> ${raCdr.description}',
  );
}
