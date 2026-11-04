import 'dart:convert';
import 'dart:typed_data';

import 'package:sunat_cpe_cavali/sunat_cpe_cavali.dart';
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

/// Genera un archivo CDR `.zip` codificado en Base64 para simular respuestas SOAP.
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
  <cbc:ResponseTime>15:30:00</cbc:ResponseTime>
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

/// Cliente HTTP simulado para el servicio OSE SOAP 1.1 de Gosocket / Carvajal.
final class _SimulatedGosocketSoapHttpClient implements CpeHttpClient {
  @override
  Future<CpeHttpResponse> send(CpeHttpRequest request) async {
    final body = request.body.toString();

    if (body.contains('<ser:sendBill>')) {
      final cdrB64 = _buildMockCdrBase64(
        id: '20100066603-01-F001-450',
        responseCode: '0',
        description: 'La Factura Comercial al Credito F001-450 ha sido aceptada por Gosocket OSE',
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
        '<ticket>GOSOCKET-TCK-20261104-001</ticket>'
        '</br:sendSummaryResponse>',
      );
    }

    if (body.contains('<ser:getStatus>')) {
      final cdrB64 = _buildMockCdrBase64(
        id: '20100066603-RC-20261104-1',
        responseCode: '0',
        description: 'El Resumen Diario RC-20261104-1 ha sido aceptado',
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

    if (body.contains('<ser:getStatusCdr>')) {
      final cdrB64 = _buildMockCdrBase64(
        id: '20100066603-01-F001-450',
        responseCode: '0',
        description: 'Constancia de Recepcion recuperada de Gosocket OSE',
      );
      return _soapResponse(
        '<br:getStatusCdrResponse xmlns:br="http://service.sunat.gob.pe">'
        '<statusCdr>'
        '<statusCode>0004</statusCode>'
        '<statusMessage>La constancia existe</statusMessage>'
        '<content>$cdrB64</content>'
        '</statusCdr>'
        '</br:getStatusCdrResponse>',
      );
    }

    throw StateError('Operación SOAP no simulada');
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

/// Transporte HTTP simulado para Cavali Factrack v2 REST OAuth2 (incluyendo `/oauth/token`).
final class _SimulatedFactrackRawTransport implements CpeHttpClient {
  int _statusCheckCount = 0;

  @override
  Future<CpeHttpResponse> send(CpeHttpRequest request) async {
    final path = request.uri.path;

    // Endpoint de autenticación OAuth2 client_credentials
    if (path.endsWith('/oauth/token')) {
      return _jsonResponse(200, {
        'access_token':
            'eyJhbGciOiJSUzI1NiIsInR5cCI6IkpXVCJ9.cavali_factrack_v2',
        'token_type': 'Bearer',
        'expires_in': 3600,
      });
    }

    // Registro de lote de facturas negociables (POST /invoice/xml)
    if (path.endsWith('/invoice/xml')) {
      final auth = request.headers['Authorization'];
      final apiKey = request.headers['x-api-key'];
      print('   [Factrack HTTP] POST /invoice/xml');
      print('   [Factrack HTTP] Header Authorization: $auth');
      print('   [Factrack HTTP] Header x-api-key: $apiKey');

      return _jsonResponse(200, {
        'idProceso': 'CAVALI-LOTE-2026-9081',
        'mensaje':
            'Lote de Facturas Negociables recibido para anotación en cuenta',
      });
    }

    // Consulta de estado de conformidad (POST /invoice/status)
    if (path.endsWith('/invoice/status')) {
      _statusCheckCount++;
      if (_statusCheckCount == 1) {
        return _jsonResponse(200, {
          'idProceso': 'CAVALI-LOTE-2026-9081',
          'estadoConformidad': 'PENDIENTE',
          'anotadaEnCuenta': false,
        });
      }
      return _jsonResponse(200, {
        'idProceso': 'CAVALI-LOTE-2026-9081',
        'estadoConformidad': 'EXPRESA',
        'anotadaEnCuenta': true,
        'fechaConformidad': '2026-11-06T11:20:00',
      });
    }

    return _jsonResponse(404, {'error': 'Ruta Factrack no encontrada: $path'});
  }

  CpeHttpResponse _jsonResponse(int statusCode, Map<String, dynamic> body) {
    return CpeHttpResponse(
      statusCode: statusCode,
      headers: const {'content-type': 'application/json; charset=utf-8'},
      bodyBytes: Uint8List.fromList(utf8.encode(jsonEncode(body))),
    );
  }

  @override
  void close() {}
}

/// Cliente HTTP con soporte de interceptores para ejecutar `CavaliOAuth2Interceptor` offline.
final class _InterceptedSimulatedHttpClient implements CpeHttpClient {
  final CpeHttpClient inner;
  final List<CpeHttpInterceptor> interceptors;

  const _InterceptedSimulatedHttpClient({
    required this.inner,
    required this.interceptors,
  });

  @override
  Future<CpeHttpResponse> send(CpeHttpRequest request) async {
    var currentReq = request;
    for (final interceptor in interceptors) {
      currentReq = await interceptor.onRequest(currentReq);
    }
    var response = await inner.send(currentReq);
    for (final interceptor in interceptors) {
      response = await interceptor.onResponse(currentReq, response);
    }
    return response;
  }

  @override
  void close() => inner.close();
}

Future<void> main() async {
  print('===================================================================');
  print(' DEMO OFFLINE: sunat_cpe_cavali (OSE Gosocket + Cavali Factrack v2)');
  print(
    '===================================================================\n',
  );

  final certificate = CpeCertificateCredentials.fromPem(
    privateKeyPem: _demoPrivateKeyPem,
    certificatePem: _demoCertificatePem,
  );

  final config = CavaliConfig(
    oseSoapEndpoint: CavaliConfig.testingOseSoapUri,
    wsseUsername: '20100066603MODDATOS',
    wssePassword: 'moddatos',
    certificate: certificate,
    factrackBaseUri: CavaliConfig.testingFactrackUri,
    factrackClientId: 'cavali-client-id-demo',
    factrackClientSecret: 'cavali-client-secret-demo',
    factrackApiKey: 'CAVALI-API-KEY-998877',
  );

  final rawFactrackTransport = _SimulatedFactrackRawTransport();
  final oauthInterceptor = CavaliOAuth2Interceptor(
    tokenEndpoint: Uri.parse('${config.factrackBaseUri}/oauth/token'),
    clientId: config.factrackClientId!,
    clientSecret: config.factrackClientSecret!,
    apiKey: config.factrackApiKey,
    authHttpClient: rawFactrackTransport,
  );

  final provider = CavaliProvider(
    config: config,
    oseHttpClient: _SimulatedGosocketSoapHttpClient(),
    factrackHttpClient: _InterceptedSimulatedHttpClient(
      inner: rawFactrackTransport,
      interceptors: [oauthInterceptor],
    ),
  );

  const issuer = CompanyParty(
    ruc: '20100066603',
    legalName: 'TEXTILES EXPORTADORES DEL SUR S.A.C.',
    address: Address(ubigeo: '150101', streetLine: 'AV. INDUSTRIAL 890, LIMA'),
  );

  // ===========================================================================
  // PARTE 1: Validación OSE Gosocket SOAP 1.1
  // ===========================================================================
  print(
    '--- PARTE 1: Validación OSE Gosocket / Carvajal (SOAP 1.1 UBL 2.1) ---',
  );

  // 1.1 Emisión de Factura Comercial (01) al crédito con cuotas (CreditPaymentTerms)
  final creditInvoice = InvoiceDocument(
    id: const DocumentId(
      issuerRuc: '20100066603',
      type: CpeDocumentType.factura,
      series: 'F001',
      number: 450,
    ),
    issueDate: DateTime(2026, 11, 4),
    dueDate: DateTime(2027, 1, 4),
    issuer: issuer,
    customer: const CustomerParty(
      documentType: IdentityDocumentType.ruc,
      documentNumber: '20555123456',
      legalName: 'DISTRIBUIDORA NACIONAL DE MODA S.A.',
      address: Address(
        ubigeo: '150131',
        streetLine: 'AV. RIVERA NAVARRETE 750',
      ),
    ),
    currency: CurrencyCode.pen,
    paymentTerms: CreditPaymentTerms(
      netPendingAmount: Decimal.parse('11800.00'),
      installments: [
        PaymentInstallment(
          number: 1,
          amount: Decimal.parse('5900.00'),
          dueDate: DateTime(2026, 12, 4),
        ),
        PaymentInstallment(
          number: 2,
          amount: Decimal.parse('5900.00'),
          dueDate: DateTime(2027, 1, 4),
        ),
      ],
    ),
    items: [
      CpeLineItem(
        lineNumber: 1,
        internalCode: 'TEX-ALG-01',
        unitCode: 'NIU',
        description: 'LOTE DE PRENDAS DE ALGODON PIMA EXPORTACION',
        quantity: Decimal.fromInt(100),
        unitValue: Decimal.parse('100.00'),
        unitPrice: Decimal.parse('118.00'),
        lineExtensionAmount: Decimal.parse('10000.00'),
        taxableBaseAmount: Decimal.parse('10000.00'),
        igvAffectation: IgvAffectationType.gravadoOperacionOnerosa,
        igvPercentage: Decimal.parse('18.00'),
        igvAmount: Decimal.parse('1800.00'),
        totalLineTaxAmount: Decimal.parse('1800.00'),
        totalLineAmount: Decimal.parse('11800.00'),
      ),
    ],
    totals: MonetaryTotals(
      totalGravadas: Decimal.parse('10000.00'),
      totalIgv: Decimal.parse('1800.00'),
      totalValorVenta: Decimal.parse('10000.00'),
      totalImpuestos: Decimal.parse('1800.00'),
      totalPrecioVenta: Decimal.parse('11800.00'),
      importeTotalPagar: Decimal.parse('11800.00'),
    ),
  );

  final emissionResponse = (await provider.sendDocument(creditInvoice))
      .getOrThrow();
  print('1.1 Factura al Crédito emitida: ${emissionResponse.documentId}');
  print('    -> Estado OSE: ${emissionResponse.status.name}');
  print('    -> Respuesta CDR: ${emissionResponse.cdr?.description}');
  print('    -> DigestValue XAdES-BES: ${emissionResponse.digestValue}');

  // 1.2 Emisión de Resumen Diario (RC) y verificación de Ticket
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
        totalGravadas: Decimal.parse('200.00'),
        totalIgv: Decimal.parse('36.00'),
        totalSaleAmount: Decimal.parse('236.00'),
      ),
    ],
  );
  final summaryTicket = (await provider.sendDailySummary(summary)).getOrThrow();
  final summaryStatus = (await provider.checkTicket(summaryTicket.ticket))
      .getOrThrow();
  print(
    '1.2 Resumen Diario (RC) -> Ticket: ${summaryTicket.ticket} '
    '| Estado: ${summaryStatus.status.name} (${summaryStatus.statusMessage})',
  );

  // 1.3 Consulta de CDR (queryDocumentStatus)
  final cdrQuery = (await provider.queryDocumentStatus(
    const DocumentStatusQuery(
      issuerRuc: '20100066603',
      documentType: CpeDocumentType.factura,
      series: 'F001',
      number: 450,
    ),
  )).getOrThrow();
  print(
    '1.3 Consulta de CDR (getStatusCdr) -> Código: ${cdrQuery.statusCode} '
    '| Mensaje: ${cdrQuery.statusMessage}\n',
  );

  // ===========================================================================
  // PARTE 2: Factoring Electrónico en Cavali Factrack v2 REST OAuth2
  // ===========================================================================
  print(
    '--- PARTE 2: Factoring Electrónico en Cavali Factrack v2 (REST OAuth2) ---',
  );

  // 2.1 Registro de lote de facturas negociables (registerInvoicesForFactoring)
  // El interceptor CavaliOAuth2Interceptor obtiene automáticamente el Bearer Token y añade x-api-key
  final processId = (await provider.registerInvoicesForFactoring([
    emissionResponse,
  ])).getOrThrow();
  print('2.1 Lote registrado en Cavali Factrack -> idProceso: $processId');

  // 2.2 Seguimiento del estado de conformidad / anotación en cuenta (plazo 8 días DU 013-2020)
  final initialConformity = (await provider.checkConformityStatus(
    creditInvoice.id,
  )).getOrThrow();
  print(
    '2.2 Consulta Día 1 -> Estado Conformidad: ${initialConformity.conformityStatus.name} '
    '| Anotada en Cuenta: ${initialConformity.isRegisteredInCavali}',
  );

  final finalConformity = (await provider.checkConformityStatus(
    creditInvoice.id,
  )).getOrThrow();
  print(
    '2.3 Consulta Día 3 -> Estado Conformidad: ${finalConformity.conformityStatus.name} '
    '| Anotada en Cuenta: ${finalConformity.isRegisteredInCavali} '
    '| Fecha Conformidad: ${finalConformity.conformityDate}',
  );
}
