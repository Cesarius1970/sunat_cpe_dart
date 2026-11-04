import 'dart:convert';
import 'dart:typed_data';
import 'package:sunat_cpe_core/sunat_cpe_core.dart';
import 'package:sunat_cpe_direct/sunat_cpe_direct.dart';
import 'package:test/test.dart';

final class _MockHttpClient implements CpeHttpClient {
  final Future<CpeHttpResponse> Function(CpeHttpRequest request) handler;

  _MockHttpClient(this.handler);

  @override
  Future<CpeHttpResponse> send(CpeHttpRequest request) => handler(request);

  @override
  void close() {}
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
      address: Address(
        ubigeo: '150101',
        streetLine: 'AV. CENTRAL 123',
      ),
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
  group('SunatDirectConfig & Certificate Security Rules', () {
    test('allows automatic mock RSA certificate in SunatDirectEnvironment.beta', () {
      final config = SunatDirectConfig.beta();
      expect(config.environment, SunatDirectEnvironment.beta);
      expect(config.wsseUsername, '20100066603MODDATOS');
      expect(config.isMockCertificate, isTrue);
    });

    test('forbids missing or mock certificate in homologacion and produccion', () {
      expect(
        () => SunatDirectConfig(
          ruc: '20100066603',
          usuarioSol: 'USER',
          claveSol: 'PASS',
          environment: SunatDirectEnvironment.produccion,
        ),
        throwsArgumentError,
      );

      expect(
        () => SunatDirectConfig(
          ruc: '20100066603',
          usuarioSol: 'USER',
          claveSol: 'PASS',
          environment: SunatDirectEnvironment.homologacion,
          certificate: SunatDirectMockCertificateFactory.createBetaMockCertificate(),
          isMockCertificate: true,
        ),
        throwsArgumentError,
      );
    });
  });

  group('SunatDirectProvider Intelligent Routing (REST GRE + Ticket Registry)', () {
    test('routes DespatchAdvice (09) to REST API with arcGreZip and SHA-256 hashZip', () async {
      Map<String, dynamic>? capturedPayload;

      final restMock = _MockHttpClient((req) async {
        if (req.uri.path.endsWith('/comprobantes/20100066603-09-T001-1')) {
          capturedPayload = jsonDecode(req.body as String) as Map<String, dynamic>;
          return CpeHttpResponse(
            statusCode: 200,
            headers: const {'content-type': 'application/json'},
            bodyBytes: Uint8List.fromList(
              utf8.encode('{"numTicket":"gre-ticket-9988","fecRecepcion":"2026-11-04T14:50:00"}'),
            ),
          );
        }
        if (req.uri.path.endsWith('/comprobantes/envios/gre-ticket-9988')) {
          return CpeHttpResponse(
            statusCode: 200,
            headers: const {'content-type': 'application/json'},
            bodyBytes: Uint8List.fromList(
              utf8.encode('{"codRespuesta":"0","indCdrGenerado":"1"}'),
            ),
          );
        }
        throw StateError('Unexpected REST URI: ${req.uri}');
      });

      final provider = SunatDirectProvider(
        config: SunatDirectConfig.beta(
          clientId: 'client-id-sunat',
          clientSecret: 'client-secret-sunat',
        ),
        restHttpClient: restMock,
      );

      final ticketRes = (await provider.sendDespatchAdvice(_sampleGuide())).getOrThrow();
      expect(ticketRes.ticket, 'gre-ticket-9988');

      final archivo = capturedPayload?['archivo'] as Map<String, dynamic>;
      expect(archivo['nomArchivo'], '20100066603-09-T001-1.zip');
      expect((archivo['arcGreZip'] as String).isNotEmpty, isTrue);
      expect((archivo['hashZip'] as String).length, 64); // 64-char SHA-256 hex

      // Verify checkTicket routes automatically to REST GRE using the ticket registry
      final statusRes = (await provider.checkTicket('gre-ticket-9988')).getOrThrow();
      expect(statusRes.status, CpeProcessStatus.accepted);
    });
  });
}
