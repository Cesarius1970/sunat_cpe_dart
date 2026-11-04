import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:sunat_cpe_core/sunat_cpe_core.dart';

/// REST client for SUNAT `api-cpe.sunat.gob.pe/v1/contribuyente/gem` (Guías de Remisión 09/31).
final class SunatDirectGreRestClient {
  final Uri baseUri;
  final CpeHttpClient httpClient;
  final CpeZipCodec zipCodec;
  final Duration timeout;

  const SunatDirectGreRestClient({
    required this.baseUri,
    required this.httpClient,
    this.zipCodec = const CpeZipCodec(),
    this.timeout = const Duration(seconds: 30),
  });

  /// Sends a signed GRE `.zip` archive with its SHA-256 hex digest (`arcGreZip` + `hashZip`).
  Future<CpeResult<TicketResponse>> sendDespatchZip({
    required DocumentId documentId,
    required String signedXmlContent,
  }) async {
    try {
      final encodedZip = zipCodec.encodeXmlToZip(
        fileNameBase: documentId.fileNameBase,
        xmlContent: signedXmlContent,
      );
      final hashSha256Hex = sha256.convert(encodedZip.zipBytes).toString();
      final zipFileName = '${documentId.fileNameBase}.zip';

      final baseStr = baseUri.toString().replaceAll(RegExp(r'/+$'), '');
      final urlEnvio = Uri.parse(
        '$baseStr/comprobantes/${documentId.fileNameBase}',
      );

      final payload = {
        'archivo': {
          'nomArchivo': zipFileName,
          'arcGreZip': encodedZip.base64Zip,
          'hashZip': hashSha256Hex,
        },
      };

      final response = await httpClient.send(
        CpeHttpRequest(
          method: 'POST',
          uri: urlEnvio,
          headers: const {
            'Content-Type': 'application/json; charset=utf-8',
            'Accept': 'application/json',
          },
          body: jsonEncode(payload),
          timeout: timeout,
        ),
      );

      if (response.statusCode == 200 || response.statusCode == 202) {
        final data = jsonDecode(response.bodyAsString) as Map<String, dynamic>;
        final numTicket = data['numTicket']?.toString();
        if (numTicket == null || numTicket.isEmpty) {
          return CpeFailure(
            OseTransportException(
              message: 'API REST GRE SUNAT no devolvió numTicket: ${response.bodyAsString}',
              httpStatusCode: response.statusCode,
              rawResponse: data,
            ),
          );
        }
        return CpeSuccess(
          TicketResponse(
            ticket: numTicket,
            referenceId: documentId,
            receivedAt: DateTime.now(),
            signedXmlContent: signedXmlContent,
          ),
        );
      }

      return CpeFailure(
        OseTransportException(
          message: 'Error en API REST GRE SUNAT (HTTP ${response.statusCode}): ${response.bodyAsString}',
          httpStatusCode: response.statusCode,
          rawResponse: response.bodyAsString,
        ),
      );
    } on CpeException catch (e) {
      return CpeFailure(e);
    } catch (e, st) {
      return CpeFailure(
        OseTransportException(
          message: 'Excepción en envío REST GRE SUNAT: $e',
          rawResponse: e,
          stackTrace: st,
        ),
      );
    }
  }

  /// Queries a GRE ticket at `GET /comprobantes/envios/{ticket}`.
  Future<CpeResult<TicketStatusResponse>> checkGreTicket(String ticket) async {
    try {
      final baseStr = baseUri.toString().replaceAll(RegExp(r'/+$'), '');
      final urlConsulta = Uri.parse('$baseStr/comprobantes/envios/$ticket');

      final response = await httpClient.send(
        CpeHttpRequest(
          method: 'GET',
          uri: urlConsulta,
          headers: const {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
          timeout: timeout,
        ),
      );

      if (response.statusCode != 200) {
        return CpeFailure(
          OseTransportException(
            message: 'Error al consultar ticket REST GRE (${response.statusCode}): ${response.bodyAsString}',
            httpStatusCode: response.statusCode,
            rawResponse: response.bodyAsString,
          ),
        );
      }

      final data = jsonDecode(response.bodyAsString) as Map<String, dynamic>;
      final codRespuesta = data['codRespuesta']?.toString() ?? '98';
      final arcCdr = data['arcCdr']?.toString();
      final indCdrGenerado = data['indCdrGenerado']?.toString();

      if (codRespuesta == '98') {
        return CpeSuccess(
          TicketStatusResponse(
            ticket: ticket,
            status: CpeProcessStatus.inProcess,
            statusCode: '98',
            statusMessage: 'En proceso en API REST GRE SUNAT',
          ),
        );
      }

      CdrData? cdr;
      if (arcCdr != null && arcCdr.isNotEmpty) {
        try {
          cdr = zipCodec.parseCdrFromBase64Zip(arcCdr);
        } catch (_) {}
      }

      if (codRespuesta == '0') {
        final status = (cdr?.warnings.isNotEmpty ?? false)
            ? CpeProcessStatus.acceptedWithWarnings
            : CpeProcessStatus.accepted;
        return CpeSuccess(
          TicketStatusResponse(
            ticket: ticket,
            status: status,
            cdr: cdr,
            statusCode: '0',
            statusMessage: cdr?.description ?? 'Guía de Remisión aceptada por SUNAT',
          ),
        );
      }

      final errorObj = data['error'];
      String errorMsg = 'Ticket GRE rechazado (codRespuesta $codRespuesta, indCdr $indCdrGenerado)';
      String statusCode = codRespuesta;
      if (errorObj is Map<String, dynamic>) {
        statusCode = errorObj['numError']?.toString() ?? codRespuesta;
        errorMsg = errorObj['desError']?.toString() ?? errorMsg;
      }

      return CpeSuccess(
        TicketStatusResponse(
          ticket: ticket,
          status: CpeProcessStatus.rejected,
          cdr: cdr,
          statusCode: statusCode,
          statusMessage: errorMsg,
        ),
      );
    } on CpeException catch (e) {
      return CpeFailure(e);
    } catch (e, st) {
      return CpeFailure(
        OseTransportException(
          message: 'Error en consulta de ticket REST GRE SUNAT: $e',
          rawResponse: e,
          stackTrace: st,
        ),
      );
    }
  }
}
