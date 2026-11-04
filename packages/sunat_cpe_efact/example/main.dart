import 'dart:convert';
import 'dart:typed_data';

import 'package:sunat_cpe_core/sunat_cpe_core.dart';
import 'package:sunat_cpe_efact/sunat_cpe_efact.dart';

/// Llave privada RSA de 1024 bits (PKCS#1 PEM) exclusivamente para demostración offline.
const _demoPrivateKeyPem = '''
-----BEGIN RSA PRIVATE KEY-----
MIICXAIBAAKBgQCn4LPtyLFIBCsIq7t7eKrdlR8GuvodCRQWGfZhqe2oJ1DIVf52
782MvGuMmL1dgghcv1EsDkU0mV1F8+5InPp6cb/tO9kdtW+T7UN1HqOwNC70y9Mu
pQlPkbiSvYA3OZmcTS4uWLXDB5eDtcAMylphY1xmyDjWD/euZtfyFcqV4wIDAQAB
AoGAVsfreyHhss6kyEiuE/eerAioDzycimHlBj/Jg1bqSaB5O/ZoImd4JCZKmlVi
nnHXjMpBVbrSv4wAEWc1aEftmoPSNZXt7eO9qIPLqNLwhDvxlqzVFE2BWw3wIGRs
sU9pBLqPlVEPOTCFJcA20RHSJfDqa2W3CXeOhTPOIuZ8/+ECQQDS1Od76ryyPQC/
nOTug34v5fBalxfRCkuMulaY53nQLLr8cejYE8Qt1Dyn7RpoG6xyOI48GcSr2D12
eLD1dmvJAkEAy9f8B+70YeJeNhE5+oZV6//4pqVnSRwapio2H7EaqJhrd4scEp7s
+U0bRrxIW2t1VpN70AlAONLywfMlOQ3ySwJABz6hpbRvP4CxIeR2SWvjTioMlFBU
1S4RYoiUqTRrDyg6VKplYedr+lcsrmiLW8B3sIUY/h+0jmMj2YpUKlsjYQJAWB3T
mvJWvgGGzESCFaQAfHY4XIFftqDpfC7/GpAKgBrzScfeqMX+ln4YbmlxteMr4/L5
MKLvGiFGQ0UCMDmxJQJBAMooESBt33UYhdQpszaR/gX1ojKXTvs3Xcw/tbf7C1fY
0LUnwA8PAaiAAv2724oM85Kab3lYsjuMNEEI+NJ3xMw=
-----END RSA PRIVATE KEY-----
''';

const _demoCertificatePem = '''
-----BEGIN CERTIFICATE-----
TUlJQ1hEQUNBYWdtQXdJQkFnSUdBWllzR2ZVRU1BMEdDU3FHU0liM0RRRUJCUVVB
-----END CERTIFICATE-----
''';

/// Construye un `<ApplicationResponse>` CDR XML válido de SUNAT/EFACT.
String _buildCdrXml({
  required String referenceId,
  required String description,
}) {
  return '''<?xml version="1.0" encoding="UTF-8"?>
<ar:ApplicationResponse xmlns:ar="urn:oasis:names:specification:ubl:schema:xsd:ApplicationResponse-2"
  xmlns:cac="urn:oasis:names:specification:ubl:schema:xsd:CommonAggregateComponents-2"
  xmlns:cbc="urn:oasis:names:specification:ubl:schema:xsd:CommonBasicComponents-2"
  xmlns:ds="http://www.w3.org/2000/09/xmldsig#">
  <cbc:ID>R-20100066603-$referenceId</cbc:ID>
  <cbc:ResponseDate>2026-11-04</cbc:ResponseDate>
  <cbc:ResponseTime>15:30:00</cbc:ResponseTime>
  <ds:Signature>
    <ds:SignedInfo>
      <ds:Reference>
        <ds:DigestValue>EfactDigest/$referenceId==</ds:DigestValue>
      </ds:Reference>
    </ds:SignedInfo>
  </ds:Signature>
  <cac:DocumentResponse>
    <cac:Response>
      <cbc:ReferenceID>$referenceId</cbc:ReferenceID>
      <cbc:ResponseCode>0</cbc:ResponseCode>
      <cbc:Description>$description</cbc:Description>
    </cac:Response>
  </cac:DocumentResponse>
</ar:ApplicationResponse>''';
}

/// Cliente HTTP simulado 100 % offline que procesa tanto peticiones REST OAuth2
/// (`/oauth/token`, `/v1/document`, `/v1/cdr/{ticket}`) como SOAP 1.1 (`billService`).
final class SimulatedEfactHttpClient implements CpeHttpClient {
  final List<CpeHttpInterceptor> interceptors;
  final Map<String, int> _cdrPollCounts = {};
  int _ticketSequence = 0;

  SimulatedEfactHttpClient({this.interceptors = const []});

  @override
  Future<CpeHttpResponse> send(CpeHttpRequest request) async {
    var effectiveReq = request;
    for (final interceptor in interceptors) {
      effectiveReq = await interceptor.onRequest(effectiveReq);
    }

    final response = await _handleRequest(effectiveReq);

    var effectiveRes = response;
    for (final interceptor in interceptors) {
      effectiveRes = await interceptor.onResponse(effectiveReq, effectiveRes);
    }
    return effectiveRes;
  }

  Future<CpeHttpResponse> _handleRequest(CpeHttpRequest request) async {
    final path = request.uri.path;

    // 1. Endpoint OAuth2 Token (/oauth/token)
    if (path.endsWith('/oauth/token')) {
      return CpeHttpResponse(
        statusCode: 200,
        headers: const {'content-type': 'application/json'},
        bodyBytes: Uint8List.fromList(
          utf8.encode(
            jsonEncode({
              'access_token': 'eyJhbGciOiJSUzI1NiIsInR5cCI6IkpXVCJ9.efact-demo',
              'token_type': 'bearer',
              'expires_in': 3600,
            }),
          ),
        ),
      );
    }

    // 2. Endpoint REST envío multipart (/v1/document)
    if (path.endsWith('/v1/document')) {
      final authHeader = request.headers['Authorization'] ?? '';
      if (!authHeader.startsWith('Bearer ')) {
        return CpeHttpResponse(
          statusCode: 401,
          headers: const {'content-type': 'application/json'},
          bodyBytes: Uint8List.fromList(
            utf8.encode('{"error":"unauthorized"}'),
          ),
        );
      }

      _ticketSequence++;
      final ticketUuid = '550e8400-e29b-41d4-a716-44665544000$_ticketSequence';
      return CpeHttpResponse(
        statusCode: 200,
        headers: const {'content-type': 'application/json'},
        bodyBytes: Uint8List.fromList(
          utf8.encode(jsonEncode({'code': '0', 'description': ticketUuid})),
        ),
      );
    }

    // 3. Endpoint REST consulta de CDR (/v1/cdr/{ticket})
    if (path.contains('/v1/cdr/')) {
      final ticket = path.split('/v1/cdr/').last;
      final attempt = (_cdrPollCounts[ticket] ?? 0) + 1;
      _cdrPollCounts[ticket] = attempt;

      // En el primer intento de un ticket UUID simulamos HTTP 202 (En proceso)
      if (ticket.startsWith('550e8400') && attempt == 1) {
        return CpeHttpResponse(
          statusCode: 202,
          headers: const {'content-type': 'application/json'},
          bodyBytes: Uint8List.fromList(
            utf8.encode(
              jsonEncode({
                'code': '-9998',
                'description':
                    'Documento en proceso de validación en EFACT OSE',
              }),
            ),
          ),
        );
      }

      final cdrXml = _buildCdrXml(
        referenceId: ticket,
        description:
            'El comprobante asociado al ticket $ticket ha sido aceptado por EFACT OSE',
      );
      return CpeHttpResponse(
        statusCode: 200,
        headers: const {'content-type': 'application/xml'},
        bodyBytes: Uint8List.fromList(utf8.encode(cdrXml)),
      );
    }

    // 4. Endpoint SOAP 1.1 billService (/ol-ti-itcpe/billService)
    if (path.endsWith('/billService')) {
      final bodyStr = request.body.toString();

      if (bodyStr.contains('sendBill')) {
        final cdrXml = _buildCdrXml(
          referenceId: 'F001-3',
          description:
              'La Factura numero F001-3, ha sido aceptada (EFACT SOAP)',
        );
        final zipped = const CpeZipCodec().encodeXmlToZip(
          fileNameBase: 'R-20100066603-01-F001-3',
          xmlContent: cdrXml,
        );
        final soapRes =
            '<soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/">'
            '<soapenv:Body>'
            '<br:sendBillResponse xmlns:br="http://service.sunat.gob.pe">'
            '<applicationResponse>${zipped.base64Zip}</applicationResponse>'
            '</br:sendBillResponse>'
            '</soapenv:Body>'
            '</soapenv:Envelope>';
        return CpeHttpResponse(
          statusCode: 200,
          headers: const {'content-type': 'text/xml; charset=utf-8'},
          bodyBytes: Uint8List.fromList(utf8.encode(soapRes)),
        );
      }
    }

    throw StateError('Ruta no reconocida en simulador EFACT: ${request.uri}');
  }

  @override
  void close() {}
}

InvoiceDocument _crearFactura({required int numero, required String desc}) {
  return InvoiceDocument(
    id: DocumentId(
      issuerRuc: '20100066603',
      type: CpeDocumentType.factura,
      series: 'F001',
      number: numero,
    ),
    issueDate: DateTime(2026, 11, 4),
    issuer: const CompanyParty(
      ruc: '20100066603',
      legalName: 'INDUSTRIAS DIGITALES DEL PERU S.A.C.',
      tradeName: 'INDIGITAL PERU',
      address: Address(
        ubigeo: '150101',
        streetLine: 'AV. REPUBLICA DE PANAMA 3055, SAN ISIDRO',
      ),
    ),
    customer: const CustomerParty(
      documentType: IdentityDocumentType.ruc,
      documentNumber: '20600055519',
      legalName: 'CORPORACION CLIENTE S.A.C.',
      address: Address(streetLine: 'AV. JAVIER PRADO ESTE 450, SAN ISIDRO'),
    ),
    currency: CurrencyCode.pen,
    items: [
      CpeLineItem(
        lineNumber: 1,
        internalCode: 'SRV-00$numero',
        unitCode: 'ZZ',
        description: desc,
        quantity: Decimal.one,
        unitValue: Decimal.parse('200.00'),
        unitPrice: Decimal.parse('236.00'),
        lineExtensionAmount: Decimal.parse('200.00'),
        taxableBaseAmount: Decimal.parse('200.00'),
        igvAffectation: IgvAffectationType.gravadoOperacionOnerosa,
        igvPercentage: Decimal.parse('18.00'),
        igvAmount: Decimal.parse('36.00'),
        totalLineTaxAmount: Decimal.parse('36.00'),
        totalLineAmount: Decimal.parse('236.00'),
      ),
    ],
    totals: MonetaryTotals(
      totalGravadas: Decimal.parse('200.00'),
      totalIgv: Decimal.parse('36.00'),
      totalValorVenta: Decimal.parse('200.00'),
      totalImpuestos: Decimal.parse('36.00'),
      totalPrecioVenta: Decimal.parse('236.00'),
      importeTotalPagar: Decimal.parse('236.00'),
    ),
  );
}

Future<void> main() async {
  print('===================================================================');
  print('  DEMO OFFLINE: sunat_cpe_efact (REST JSON, REST XML y SOAP 1.1)');
  print(
    '===================================================================\n',
  );

  // URLs reales documentadas en EfactConfig:
  // - REST Producción : EfactConfig.productionRestUri (https://ose.efact.pe/api-efact-ose)
  // - REST Pruebas    : EfactConfig.testRestUri       (https://ose-gw1.efact.pe:443/api-efact-ose)
  // - SOAP Producción : EfactConfig.productionSoapUri (https://ose.efact.pe/ol-ti-itcpe/billService)
  // - SOAP Pruebas    : EfactConfig.testSoapUri       (https://ose-gw1.efact.pe/ol-ti-itcpe/billService)

  final certificate = CpeCertificateCredentials.fromPem(
    privateKeyPem: _demoPrivateKeyPem,
    certificatePem: _demoCertificatePem,
  );

  // Preparamos el interceptor OAuth2 conectado al cliente simulado:
  final rawAuthTransport = SimulatedEfactHttpClient();
  final oauthInterceptor = EfactOAuth2Interceptor(
    tokenEndpoint: Uri.parse('${EfactConfig.testRestUri}/oauth/token'),
    username: '20100066603',
    password: 'password-hash-efact-demo',
    authHttpClient: rawAuthTransport,
  );
  final restHttpClient = SimulatedEfactHttpClient(
    interceptors: [oauthInterceptor],
  );

  // ---------------------------------------------------------------------------
  // MODO 1: EfactIntegrationMode.restJson (OAuth2 + Multipart JSON + Polling)
  // ---------------------------------------------------------------------------
  print('--- [1] Modo 1: EfactIntegrationMode.restJson (PSE Cloud JSON) ---');
  final restJsonProvider = EfactProvider(
    config: EfactConfig.restJson(
      baseUri: EfactConfig.testRestUri,
      username: '20100066603',
      password: 'password-hash-efact-demo',
      autoPollInRest: true,
      pollingConfig: const PollingConfig(
        initialDelay: Duration(milliseconds: 10),
        maxDelay: Duration(milliseconds: 50),
        maxAttempts: 4,
      ),
    ),
    httpClient: restHttpClient,
  );

  final facturaModo1 = _crearFactura(
    numero: 1,
    desc: 'SERVICIO OSE/PSE EFACT MODO REST JSON',
  );
  final jsonPreview = const EfactJsonMapper().mapDocument(facturaModo1);
  print(
    'Payload EfactJsonMapper generado para ${jsonPreview['id']} (moneda: ${jsonPreview['documentCurrencyCode']})',
  );

  final resModo1 = (await restJsonProvider.sendDocument(facturaModo1))
      .getOrThrow();
  print('Factura ${resModo1.documentId.ublId} -> Estado: ${resModo1.status}');
  print('  Ticket UUID   : ${resModo1.ticket}');
  print('  CDR Mensaje   : ${resModo1.cdr?.description}');
  print('  Descarga PDF  : ${resModo1.pdfDownloadUrl}');
  print('  Descarga XML  : ${resModo1.xmlDownloadUrl}');
  print('  Descarga CDR  : ${resModo1.cdrDownloadUrl}\n');

  // ---------------------------------------------------------------------------
  // MODO 2: EfactIntegrationMode.restXml (Firma X.509 local + Multipart XML)
  // ---------------------------------------------------------------------------
  print(
    '--- [2] Modo 2: EfactIntegrationMode.restXml (Firma Local UBL 2.1) ---',
  );
  final restXmlProvider = EfactProvider(
    config: EfactConfig.restXml(
      baseUri: EfactConfig.testRestUri,
      username: '20100066603',
      password: 'password-hash-efact-demo',
      certificate: certificate,
      autoPollInRest: true,
      pollingConfig: const PollingConfig(
        initialDelay: Duration(milliseconds: 10),
        maxDelay: Duration(milliseconds: 50),
        maxAttempts: 4,
      ),
    ),
    httpClient: restHttpClient,
  );

  final facturaModo2 = _crearFactura(
    numero: 2,
    desc: 'SERVICIO OSE EFACT MODO REST XML FIRMADO LOCALMENTE',
  );
  final resModo2 = (await restXmlProvider.sendDocument(facturaModo2))
      .getOrThrow();
  print('Factura ${resModo2.documentId.ublId} -> Estado: ${resModo2.status}');
  print('  Digest RSA-SHA256 : ${resModo2.digestValue}');
  print(
    '  XML UBL 2.1 firmado (${resModo2.signedXmlContent?.length} bytes) incluye Id="SignSUNAT": '
    '${resModo2.signedXmlContent?.contains('Id="SignSUNAT"')}',
  );
  print('  Contenido QR SUNAT: ${resModo2.qrContent}\n');

  // ---------------------------------------------------------------------------
  // MODO 3: EfactIntegrationMode.soapUbl (SOAP 1.1 billService + WS-Security)
  // ---------------------------------------------------------------------------
  print(
    '--- [3] Modo 3: EfactIntegrationMode.soapUbl (SOAP 1.1 WS-Security) ---',
  );
  final soapProvider = EfactProvider(
    config: EfactConfig.soap(
      endpointUri: EfactConfig.testSoapUri,
      username: '20100066603',
      password: 'password-soap-wsse',
      certificate: certificate,
    ),
    httpClient: SimulatedEfactHttpClient(),
  );

  final facturaModo3 = _crearFactura(
    numero: 3,
    desc: 'SERVICIO OSE EFACT MODO SOAP 1.1 BILLSERVICE',
  );
  final resModo3 = (await soapProvider.sendDocument(facturaModo3)).getOrThrow();
  print('Factura ${resModo3.documentId.ublId} -> Estado: ${resModo3.status}');
  print('  CDR ID          : ${resModo3.cdr?.id}');
  print('  CDR Descripción : ${resModo3.cdr?.description}\n');

  // ---------------------------------------------------------------------------
  // ESCENARIO 4: Resumen Diario (RC), Guía de Remisión (09) y Consulta Estado
  // ---------------------------------------------------------------------------
  print('--- [4] Resumen Diario (RC), Guía de Remisión (09) y Consulta ---');

  final resumenDiario = DailySummaryDocument(
    id: const DocumentId(
      issuerRuc: '20100066603',
      type: CpeDocumentType.resumenDiario,
      series: 'RC-20261104',
      number: 1,
    ),
    issuer: facturaModo1.issuer,
    issueDate: DateTime(2026, 11, 4),
    referenceDate: DateTime(2026, 11, 4),
    lines: [
      DailySummaryLine(
        lineNumber: 1,
        documentType: CpeDocumentType.boleta,
        series: 'B001',
        number: 10,
        status: SummaryLineStatus.adicionar,
        customerDocumentType: IdentityDocumentType.dni,
        customerDocumentNumber: '45678912',
        totalGravadas: Decimal.parse('100.00'),
        totalIgv: Decimal.parse('18.00'),
        totalSaleAmount: Decimal.parse('118.00'),
      ),
    ],
  );

  final ticketRc = (await restXmlProvider.sendDailySummary(resumenDiario))
      .getOrThrow();
  final cdrRc = (await restXmlProvider.pollTicketUntilDone(
    ticketRc.ticket,
    referenceId: resumenDiario.id,
    config: const PollingConfig(
      initialDelay: Duration(milliseconds: 10),
      maxAttempts: 3,
    ),
  )).getOrThrow();
  print(
    'Resumen Diario ${resumenDiario.id.ublId} -> Ticket: ${ticketRc.ticket} -> CDR: [${cdrRc.responseCode}]',
  );

  final guiaRemision = DespatchAdviceDocument(
    id: const DocumentId(
      issuerRuc: '20100066603',
      type: CpeDocumentType.guiaRemisionRemitente,
      series: 'T001',
      number: 5,
    ),
    issuer: facturaModo1.issuer,
    recipient: facturaModo1.customer,
    issueDate: DateTime(2026, 11, 4),
    transferStartDate: DateTime(2026, 11, 5),
    transferReason: DespatchReasonCode.venta,
    transportMode: TransportModeCode.transportePublico,
    grossWeight: Decimal.parse('120.00'),
    weightUnitCode: 'KGM',
    originAddress: const Address(
      ubigeo: '150131',
      streetLine: 'AV. REPUBLICA DE PANAMA 3055, SAN ISIDRO',
    ),
    deliveryAddress: const Address(
      ubigeo: '150131',
      streetLine: 'AV. JAVIER PRADO ESTE 450, SAN ISIDRO',
    ),
    carrier: const CarrierParty(
      ruc: '20555666777',
      legalName: 'TRANSPORTES RAPIDOS PERU S.A.C.',
    ),
    items: [
      DespatchLineItem(
        lineNumber: 1,
        internalCode: 'HW-100',
        unitCode: 'NIU',
        description: 'SWITCH DE RED GESTIONABLE 48 PUERTOS',
        quantity: Decimal.fromInt(4),
      ),
    ],
  );

  final ticketGre = (await restJsonProvider.sendDespatchAdvice(guiaRemision))
      .getOrThrow();
  print(
    'Guía de Remisión ${guiaRemision.id.ublId} -> Ticket: ${ticketGre.ticket}',
  );

  final estadoConsulta = (await restJsonProvider.queryDocumentStatus(
    const DocumentStatusQuery(
      issuerRuc: '20100066603',
      documentType: CpeDocumentType.factura,
      series: 'F001',
      number: 1,
    ),
  )).getOrThrow();
  print(
    'Consulta Estado F001-1 -> ${estadoConsulta.status} (${estadoConsulta.statusMessage})',
  );
  print('  URL CDR: ${estadoConsulta.cdrDownloadUrl}');
}
