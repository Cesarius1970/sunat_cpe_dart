import 'dart:convert';
import 'dart:typed_data';
import 'package:archive/archive.dart';
import 'package:pointycastle/export.dart';
import 'package:sunat_cpe_core/sunat_cpe_core.dart';
import 'package:test/test.dart';

final class _FakeHttpClient implements CpeHttpClient {
  final Future<CpeHttpResponse> Function(CpeHttpRequest request) handler;

  _FakeHttpClient(this.handler);

  @override
  Future<CpeHttpResponse> send(CpeHttpRequest request) => handler(request);

  @override
  void close() {}
}

final class _TestUblOseProvider extends BaseUblOseProvider {
  _TestUblOseProvider({
    required super.endpointUri,
    required super.wsseUsername,
    required super.wssePassword,
    required super.certificate,
    required super.httpClient,
  });

  @override
  String get providerId => 'test_ose';
}

CpeCertificateCredentials _generateTestCertificate() {
  final keyParams = RSAKeyGeneratorParameters(BigInt.parse('65537'), 1024, 12);
  final secureRandom = FortunaRandom();
  secureRandom.seed(KeyParameter(Uint8List.fromList(List.generate(32, (i) => i + 1))));

  final generator = RSAKeyGenerator()
    ..init(ParametersWithRandom(keyParams, secureRandom));
  final pair = generator.generateKeyPair();

  return CpeCertificateCredentials(
    privateKey: pair.privateKey,
    base64X509Certificate: base64.encode(utf8.encode('FAKE-X509-CERT-DER-BYTES')),
  );
}

InvoiceDocument _buildValidInvoice({
  PaymentTerms paymentTerms = const CashPaymentTerms(),
  DetractionInfo? detraction,
  Decimal? overrideTotalIgv,
}) {
  const issuer = CompanyParty(
    ruc: '20100066603',
    legalName: 'EMPRESA EMISORA S.A.C.',
    tradeName: 'EMISORA',
    address: Address(
      ubigeo: '150101',
      streetLine: 'AV. AREQUIPA 1234',
      establishmentCode: '0000',
    ),
  );

  const customer = CustomerParty(
    documentType: IdentityDocumentType.ruc,
    documentNumber: '20600695771',
    legalName: 'CLIENTE CORPORATIVO S.A.C.',
    address: Address(
      ubigeo: '150122',
      streetLine: 'CALLE LIBERTAD 116',
    ),
  );

  final item = CpeLineItem(
    lineNumber: 1,
    internalCode: 'SRV-001',
    sunatProductCode: '80101500',
    unitCode: 'ZZ',
    description: 'CONSULTORIA DE ARQUITECTURA DE SOFTWARE',
    quantity: Decimal.fromInt(2),
    unitValue: Decimal.parse('500.00'),
    unitPrice: Decimal.parse('590.00'),
    lineExtensionAmount: Decimal.parse('1000.00'),
    taxableBaseAmount: Decimal.parse('1000.00'),
    igvAffectation: IgvAffectationType.gravadoOperacionOnerosa,
    igvPercentage: Decimal.parse('18.00'),
    igvAmount: Decimal.parse('180.00'),
    totalLineTaxAmount: Decimal.parse('180.00'),
    totalLineAmount: Decimal.parse('1180.00'),
  );

  final igv = overrideTotalIgv ?? Decimal.parse('180.00');

  return InvoiceDocument(
    id: const DocumentId(
      issuerRuc: '20100066603',
      type: CpeDocumentType.factura,
      series: 'F001',
      number: 42,
    ),
    issuer: issuer,
    customer: customer,
    issueDate: DateTime(2026, 10, 30),
    issueTime: '13:30:00',
    currency: CurrencyCode.pen,
    operationType: detraction != null
        ? OperationType.operacionSujetaDetraccion
        : OperationType.ventaInterna,
    paymentTerms: paymentTerms,
    detraction: detraction,
    totals: MonetaryTotals(
      totalGravadas: Decimal.parse('1000.00'),
      totalIgv: igv,
      totalValorVenta: Decimal.parse('1000.00'),
      totalImpuestos: igv,
      totalPrecioVenta: Decimal.parse('1180.00'),
      importeTotalPagar: Decimal.parse('1180.00'),
      amountInWords: 'SON MIL CIENTO OCHENTA CON 00/100 SOLES',
    ),
    items: [item],
  );
}

String _buildSampleCdrBase64Zip({
  required String responseCode,
  required String description,
  List<String> notes = const [],
}) {
  final notesXml = notes.map((n) => '<cbc:Note>$n</cbc:Note>').join();
  final cdrXml = '<?xml version="1.0" encoding="UTF-8"?>'
      '<ar:ApplicationResponse xmlns:ar="urn:oasis:names:specification:ubl:schema:xsd:ApplicationResponse-2" '
      'xmlns:cac="urn:oasis:names:specification:ubl:schema:xsd:CommonAggregateComponents-2" '
      'xmlns:cbc="urn:oasis:names:specification:ubl:schema:xsd:CommonBasicComponents-2">'
      '<cbc:ID>R-20100066603-01-F001-42</cbc:ID>'
      '<cbc:ResponseDate>2026-10-30</cbc:ResponseDate>'
      '<cbc:ResponseTime>13:30:05</cbc:ResponseTime>'
      '$notesXml'
      '<cac:DocumentResponse>'
      '<cac:Response>'
      '<cbc:ReferenceID>F001-42</cbc:ReferenceID>'
      '<cbc:ResponseCode>$responseCode</cbc:ResponseCode>'
      '<cbc:Description>$description</cbc:Description>'
      '</cac:Response>'
      '</cac:DocumentResponse>'
      '</ar:ApplicationResponse>';

  final xmlBytes = utf8.encode(cdrXml);
  final archive = Archive()
    ..addFile(ArchiveFile('R-20100066603-01-F001-42.xml', xmlBytes.length, xmlBytes));
  return base64.encode(ZipEncoder().encode(archive));
}

void main() {
  group('CpeMathValidator (Strict Passthrough Business Logic)', () {
    final validator = CpeMathValidator();

    test('accepts mathematically consistent InvoiceDocument', () {
      final invoice = _buildValidInvoice();
      final result = validator.validate(invoice);
      expect(result.isSuccess, isTrue);
    });

    test('fails when header totalIgv does not match sum of line IGV amounts', () {
      final brokenInvoice = _buildValidInvoice(
        overrideTotalIgv: Decimal.parse('150.00'),
      );
      final result = validator.validate(brokenInvoice);
      expect(result.isFailure, isTrue);
      expect(
        () => result.getOrThrow(),
        throwsA(
          isA<CpeValidationException>().having(
            (e) => e.issues.any((i) => i.field == 'totals.totalIgv'),
            'contains totals.totalIgv issue',
            isTrue,
          ),
        ),
      );
    });

    test(
      'enforces SUNAT RS 000193-2020 rule: credit netPendingAmount must deduct detraction from payable total',
      () {
        final detraction = DetractionInfo(
          code: '022',
          bankAccountNumber: '00-000-123456',
          percentage: Decimal.parse('12.00'),
          amountInPen: Decimal.parse('141.60'),
        );

        // Wrong credit terms: installments sum to full 1180.00 instead of deducting 141.60 detraction (1038.40)
        final wrongCreditInvoice = _buildValidInvoice(
          detraction: detraction,
          paymentTerms: CreditPaymentTerms(
            netPendingAmount: Decimal.parse('1180.00'),
            installments: [
              PaymentInstallment(
                number: 1,
                amount: Decimal.parse('1180.00'),
                dueDate: DateTime(2026, 11, 30),
              ),
            ],
          ),
        );

        final wrongResult = validator.validate(wrongCreditInvoice);
        expect(wrongResult.isFailure, isTrue);

        // Correct credit terms: netPendingAmount = 1180.00 - 141.60 = 1038.40
        final validCreditInvoice = _buildValidInvoice(
          detraction: detraction,
          paymentTerms: CreditPaymentTerms(
            netPendingAmount: Decimal.parse('1038.40'),
            installments: [
              PaymentInstallment(
                number: 1,
                amount: Decimal.parse('1038.40'),
                dueDate: DateTime(2026, 11, 30),
              ),
            ],
          ),
        );

        expect(validator.validate(validCreditInvoice).isSuccess, isTrue);
      },
    );
  });

  group('UblXmlBuilder & XadesBesSigner (Pure Dart UBL 2.1 + RSA-SHA256)', () {
    late CpeCertificateCredentials cert;

    setUpAll(() {
      cert = _generateTestCertificate();
    });

    test('generates UBL 2.1 XML and injects verifiable RSA-SHA256 signature', () {
      const builder = UblXmlBuilder();
      const signer = XadesBesSigner();
      final invoice = _buildValidInvoice();

      final unsignedXml = builder.buildUnsignedXml(invoice);
      expect(unsignedXml, contains('<cbc:UBLVersionID>2.1</cbc:UBLVersionID>'));
      expect(unsignedXml, contains('<cbc:ID>F001-42</cbc:ID>'));

      final signed = signer.signXml(unsignedXml, cert);
      expect(signed.digestValue, isNotEmpty);
      expect(signed.signatureValue, isNotEmpty);
      expect(signed.signedXml, contains('Id="SignSUNAT"'));
      expect(signed.signedXml, contains('<ds:DigestValue>${signed.digestValue}</ds:DigestValue>'));
    });
  });

  group('BaseUblOseProvider & TicketPollingMixin End-to-End Pipeline', () {
    late CpeCertificateCredentials cert;

    setUpAll(() {
      cert = _generateTestCertificate();
    });

    test('sendDocument signs, zips, sends SOAP sendBill, and parses CDR with warnings', () async {
      final cdrBase64 = _buildSampleCdrBase64Zip(
        responseCode: '0',
        description: 'La Factura numero F001-42, ha sido aceptada',
        notes: ['4252 - El ubigeo del cliente es referencial'],
      );

      final client = _FakeHttpClient((req) async {
        expect(req.headers['SOAPAction'], '"urn:sendBill"');
        expect(req.body.toString(), contains('<fileName>20100066603-01-F001-42.zip</fileName>'));

        return CpeHttpResponse(
          statusCode: 200,
          headers: const {'content-type': 'text/xml'},
          bodyBytes: Uint8List.fromList(
            utf8.encode(
              '<soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/">'
              '<soapenv:Body>'
              '<br:sendBillResponse xmlns:br="http://service.sunat.gob.pe">'
              '<applicationResponse>$cdrBase64</applicationResponse>'
              '</br:sendBillResponse>'
              '</soapenv:Body>'
              '</soapenv:Envelope>',
            ),
          ),
        );
      });

      final provider = _TestUblOseProvider(
        endpointUri: Uri.parse('https://ose.example.pe/ol-ti-itcpe/billService'),
        wsseUsername: '20100066603MODDATOS',
        wssePassword: 'moddatos',
        certificate: cert,
        httpClient: client,
      );

      final result = await provider.sendDocument(_buildValidInvoice());
      final response = result.getOrThrow();

      expect(response.status, CpeProcessStatus.acceptedWithWarnings);
      expect(response.cdr?.responseCode, '0');
      expect(response.cdr?.warnings.single.code, '4252');
      expect(response.qrContent, startsWith('20100066603|01|F001|42|180.00|1180.00|2026-10-30|6|20600695771|'));
    });

    test('distinguishes SUNAT Exception (0100-1999) from Rejection (2000-3999) on SOAP Fault', () async {
      var faultCodeToReturn = 'soap-env:Client.0151';
      var faultMsgToReturn = 'El nombre del archivo XML es incorrecto';

      final client = _FakeHttpClient((_) async {
        return CpeHttpResponse(
          statusCode: 500,
          headers: const {'content-type': 'text/xml'},
          bodyBytes: Uint8List.fromList(
            utf8.encode(
              '<soap-env:Envelope xmlns:soap-env="http://schemas.xmlsoap.org/soap/envelope/">'
              '<soap-env:Body>'
              '<soap-env:Fault>'
              '<faultcode>$faultCodeToReturn</faultcode>'
              '<faultstring>$faultMsgToReturn</faultstring>'
              '</soap-env:Fault>'
              '</soap-env:Body>'
              '</soap-env:Envelope>',
            ),
          ),
        );
      });

      final provider = _TestUblOseProvider(
        endpointUri: Uri.parse('https://ose.example.pe/ol-ti-itcpe/billService'),
        wsseUsername: '20100066603MODDATOS',
        wssePassword: 'moddatos',
        certificate: cert,
        httpClient: client,
      );

      // 1. Code 0151 must map to SunatExceptionError (retriable with same correlative)
      final exResult = await provider.sendDocument(_buildValidInvoice());
      expect(exResult.errorOrNull, isA<SunatExceptionError>());
      expect((exResult.errorOrNull as SunatExceptionError).sunatCode, 151);

      // 2. Code 2017 must map to SunatRejectionException (definitive business rejection)
      faultCodeToReturn = 'soap-env:Client.2017';
      faultMsgToReturn = 'El RUC del receptor no esta activo';
      final rejResult = await provider.sendDocument(_buildValidInvoice());
      expect(rejResult.errorOrNull, isA<SunatRejectionException>());
      expect((rejResult.errorOrNull as SunatRejectionException).sunatCode, 2017);
    });

    test('pollTicketUntilDone retries while statusCode is 98 and resolves when statusCode is 0', () async {
      var pollCount = 0;
      final cdrBase64 = _buildSampleCdrBase64Zip(
        responseCode: '0',
        description: 'El Resumen Diario RC-20261030-1 ha sido aceptado',
      );

      final client = _FakeHttpClient((_) async {
        pollCount++;
        final isReady = pollCount >= 3;
        final statusCode = isReady ? '0' : '98';
        final contentNode = isReady ? '<content>$cdrBase64</content>' : '';

        return CpeHttpResponse(
          statusCode: 200,
          headers: const {'content-type': 'text/xml'},
          bodyBytes: Uint8List.fromList(
            utf8.encode(
              '<soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/">'
              '<soapenv:Body>'
              '<ns2:getStatusResponse xmlns:ns2="http://service.sunat.gob.pe">'
              '<status>'
              '<statusCode>$statusCode</statusCode>'
              '$contentNode'
              '</status>'
              '</ns2:getStatusResponse>'
              '</soapenv:Body>'
              '</soapenv:Envelope>',
            ),
          ),
        );
      });

      final provider = _TestUblOseProvider(
        endpointUri: Uri.parse('https://ose.example.pe/ol-ti-itcpe/billService'),
        wsseUsername: '20100066603MODDATOS',
        wssePassword: 'moddatos',
        certificate: cert,
        httpClient: client,
      );

      final pollResult = await provider.pollTicketUntilDone(
        'TICKET-2026-999',
        config: const PollingConfig(
          initialDelay: Duration(milliseconds: 5),
          maxDelay: Duration(milliseconds: 20),
          maxAttempts: 5,
        ),
      );

      final cdr = pollResult.getOrThrow();
      expect(pollCount, 3);
      expect(cdr.isAccepted, isTrue);
      expect(cdr.description, contains('RC-20261030-1'));
    });
  });
}
