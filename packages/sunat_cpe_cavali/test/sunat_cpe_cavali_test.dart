import 'dart:convert';
import 'dart:typed_data';

import 'package:sunat_cpe_cavali/sunat_cpe_cavali.dart';
import 'package:sunat_cpe_core/sunat_cpe_core.dart';
import 'package:test/test.dart';

final class _MockHttpClient implements CpeHttpClient {
  final Future<CpeHttpResponse> Function(CpeHttpRequest request) handler;

  _MockHttpClient(this.handler);

  @override
  Future<CpeHttpResponse> send(CpeHttpRequest request) => handler(request);

  @override
  void close() {}
}

void main() {
  group('CavaliFactrackClient & CavaliOAuth2Interceptor', () {
    test(
      'CavaliFactrackClient registers XML batch and checks conformity status',
      () async {
        final mockHttp = _MockHttpClient((req) async {
          if (req.uri.path.endsWith('/invoice/xml')) {
            return CpeHttpResponse(
              statusCode: 200,
              headers: const {'content-type': 'application/json'},
              bodyBytes: Uint8List.fromList(
                utf8.encode('{"idProceso":"PROC-2026-8899"}'),
              ),
            );
          }
          if (req.uri.path.endsWith('/invoice/status')) {
            return CpeHttpResponse(
              statusCode: 200,
              headers: const {'content-type': 'application/json'},
              bodyBytes: Uint8List.fromList(
                utf8.encode(
                  '{"estadoConformidad":"EXPRESA","anotadaEnCuenta":true,"idProceso":"PROC-2026-8899"}',
                ),
              ),
            );
          }
          throw StateError('Unexpected URI ${req.uri}');
        });

        final client = CavaliFactrackClient(
          baseUri: CavaliConfig.productionFactrackUri,
          httpClient: mockHttp,
        );

        const docId = DocumentId(
          issuerRuc: '20100066603',
          type: CpeDocumentType.factura,
          series: 'F001',
          number: 100,
        );

        final procId = (await client.registerInvoicesForFactoring([
          const CpeEmissionResponse(
            documentId: docId,
            status: CpeProcessStatus.accepted,
            signedXmlContent: '<Invoice/>',
          ),
        ])).getOrThrow();
        expect(procId, 'PROC-2026-8899');

        final status = (await client.checkConformityStatus(docId)).getOrThrow();
        expect(
          status.conformityStatus,
          InvoiceConformityStatus.expressConformity,
        );
        expect(status.isRegisteredInCavali, isTrue);
        expect(status.cavaliProcessId, 'PROC-2026-8899');
      },
    );
  });
}
