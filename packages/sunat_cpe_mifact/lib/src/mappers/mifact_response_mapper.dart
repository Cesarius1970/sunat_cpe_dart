import 'dart:convert';

import 'package:sunat_cpe_core/sunat_cpe_core.dart';

/// Transforma las respuestas JSON de Mifact (`estado_documento` `101..105`, `cdr_bytes`, `errors`) en resultados del Core.
final class MifactResponseMapper {
  /// Codificador/decodificador para desempaquetar el CDR desde `cdr_bytes` en Base64.
  final CpeZipCodec zipCodec;

  /// Crea una instancia constante de [MifactResponseMapper].
  const MifactResponseMapper({this.zipCodec = const CpeZipCodec()});

  /// Convierte la respuesta HTTP de `SendInvoice` en un [CpeResult] de [CpeEmissionResponse].
  CpeResult<CpeEmissionResponse> mapEmissionResponse({
    required DocumentId documentId,
    required CpeHttpResponse response,
  }) {
    final decodedResult = _decodeJsonMap(response);
    switch (decodedResult) {
      case CpeFailure<Map<String, dynamic>>(:final error):
        return CpeFailure(error);
      case CpeSuccess<Map<String, dynamic>>(:final data):
        final estado = data['estado_documento']?.toString().trim() ?? '';
        final errors = data['errors']?.toString().trim() ?? '';
        final sunatDesc = data['sunat_description']?.toString().trim() ?? '';
        final hash = data['codigo_hash']?.toString().trim();
        final qr = data['cadena_para_codigo_qr']?.toString().trim();
        final urlPdf = data['url_pdf']?.toString().trim();
        final cdrBase64 = data['cdr_bytes']?.toString().trim();
        final xmlBase64 = data['xml_bytes']?.toString().trim();
        final ticket = data['ticket']?.toString().trim();

        String? signedXml;
        if (xmlBase64 != null && xmlBase64.isNotEmpty) {
          try {
            signedXml = utf8.decode(
              base64.decode(xmlBase64),
              allowMalformed: true,
            );
          } catch (_) {}
        }

        CdrData? cdr;
        if (cdrBase64 != null && cdrBase64.isNotEmpty) {
          try {
            cdr = zipCodec.parseCdrFromBase64Zip(cdrBase64);
          } catch (_) {}
        }

        if (estado == '104' ||
            (errors.isNotEmpty && estado != '102' && estado != '103')) {
          final msg = errors.isNotEmpty ? errors : sunatDesc;
          final codeMatch = RegExp(r'\b([2-3]\d{3})\b').firstMatch(msg);
          final sunatCode = codeMatch != null
              ? int.parse(codeMatch.group(1)!)
              : 2000;
          return CpeFailure(
            SunatRejectionException(
              sunatCode: sunatCode,
              message: msg.isNotEmpty
                  ? msg
                  : 'Rechazado en Mifact (estado $estado)',
              rejectionCdr: cdr,
              rawResponse: data,
            ),
          );
        }

        if (estado == '100') {
          return CpeFailure(
            CpeValidationException(
              message: errors.isNotEmpty
                  ? errors
                  : 'Error de validación en Mifact (100)',
              issues: [
                if (errors.isNotEmpty)
                  ValidationIssue(field: 'mifact', message: errors),
              ],
            ),
          );
        }

        final status = switch (estado) {
          '101' => CpeProcessStatus.inProcess,
          '102' => CpeProcessStatus.accepted,
          '103' => CpeProcessStatus.acceptedWithWarnings,
          '105' => CpeProcessStatus.voided,
          _ => CpeProcessStatus.accepted,
        };

        final effectiveCdr =
            cdr ??
            (status == CpeProcessStatus.accepted ||
                    status == CpeProcessStatus.acceptedWithWarnings
                ? CdrData(
                    id: 'R-${documentId.fileNameBase}',
                    responseCode: '0',
                    description: sunatDesc.isNotEmpty
                        ? sunatDesc
                        : 'Aceptado por SUNAT (Mifact $estado)',
                    responseDateTime: DateTime.now(),
                    digestValue: hash,
                    qrContent: qr,
                  )
                : null);

        return CpeSuccess(
          CpeEmissionResponse(
            documentId: documentId,
            status: status,
            cdr: effectiveCdr,
            ticket: ticket,
            signedXmlContent: signedXml,
            digestValue: hash,
            qrContent: qr,
            pdfDownloadUrl: urlPdf,
          ),
        );
    }
  }

  /// Convierte la respuesta HTTP de `SendSummary`, `lowInvoice` o `SendGuide` en un [TicketResponse].
  CpeResult<TicketResponse> mapTicketResponse({
    required DocumentId referenceId,
    required CpeHttpResponse response,
  }) {
    final decodedResult = _decodeJsonMap(response);
    switch (decodedResult) {
      case CpeFailure<Map<String, dynamic>>(:final error):
        return CpeFailure(error);
      case CpeSuccess<Map<String, dynamic>>(:final data):
        final errors = data['errors']?.toString().trim() ?? '';
        final estado = data['estado_documento']?.toString().trim() ?? '';
        if (estado == '100' || estado == '104' || errors.isNotEmpty) {
          return CpeFailure(
            OseTransportException(
              message: errors.isNotEmpty ? errors : 'Error en Mifact ($estado)',
              rawResponse: data,
            ),
          );
        }
        final ticket =
            data['ticket']?.toString().trim() ??
            data['num_ticket']?.toString().trim() ??
            referenceId.ublId;
        return CpeSuccess(
          TicketResponse(
            ticket: ticket,
            referenceId: referenceId,
            receivedAt: DateTime.now(),
          ),
        );
    }
  }

  /// Convierte la respuesta HTTP de `GetStatus` en un [CpeStatusQueryResponse].
  CpeResult<CpeStatusQueryResponse> mapStatusQueryResponse(
    CpeHttpResponse response,
  ) {
    final decodedResult = _decodeJsonMap(response);
    switch (decodedResult) {
      case CpeFailure<Map<String, dynamic>>(:final error):
        return CpeFailure(error);
      case CpeSuccess<Map<String, dynamic>>(:final data):
        final estado = data['estado_documento']?.toString().trim() ?? '102';
        final sunatDesc = data['sunat_description']?.toString().trim() ?? '';
        final urlPdf = data['url_pdf']?.toString().trim();
        final cdrBase64 = data['cdr_bytes']?.toString().trim();

        CdrData? cdr;
        if (cdrBase64 != null && cdrBase64.isNotEmpty) {
          try {
            cdr = zipCodec.parseCdrFromBase64Zip(cdrBase64);
          } catch (_) {}
        }

        final status = switch (estado) {
          '101' => CpeProcessStatus.inProcess,
          '102' => CpeProcessStatus.accepted,
          '103' => CpeProcessStatus.acceptedWithWarnings,
          '104' => CpeProcessStatus.rejected,
          '105' => CpeProcessStatus.voided,
          _ => CpeProcessStatus.accepted,
        };

        return CpeSuccess(
          CpeStatusQueryResponse(
            status: status,
            statusCode: estado,
            statusMessage: sunatDesc,
            cdr: cdr,
            pdfDownloadUrl: urlPdf,
          ),
        );
    }
  }

  CpeResult<Map<String, dynamic>> _decodeJsonMap(CpeHttpResponse response) {
    if (response.statusCode == 401 || response.statusCode == 403) {
      return CpeFailure(
        OseAuthException(
          message: 'Mifact authentication failed (HTTP ${response.statusCode})',
          rawResponse: response.bodyAsString,
        ),
      );
    }
    try {
      final decoded = jsonDecode(response.bodyAsString);
      if (decoded is Map<String, dynamic>) {
        return CpeSuccess(decoded);
      }
      return CpeFailure(
        OseTransportException(
          message: 'Unexpected Mifact JSON structure: ${response.bodyAsString}',
          httpStatusCode: response.statusCode,
          rawResponse: response.bodyAsString,
        ),
      );
    } catch (e) {
      return CpeFailure(
        OseTransportException(
          message: 'Invalid JSON from Mifact (HTTP ${response.statusCode}): $e',
          httpStatusCode: response.statusCode,
          rawResponse: response.bodyAsString,
        ),
      );
    }
  }
}
