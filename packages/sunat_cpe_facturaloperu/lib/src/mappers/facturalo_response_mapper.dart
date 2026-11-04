import 'dart:convert';
import 'package:sunat_cpe_core/sunat_cpe_core.dart';

/// Maps FacturaloPeru / Facturador PRO JSON responses (`state_type_id` `01..13`, `cdr_response`, `links`) to Core results.
final class FacturaloResponseMapper {
  const FacturaloResponseMapper();

  CpeResult<CpeEmissionResponse> mapEmissionResponse({
    required DocumentId documentId,
    required CpeHttpResponse response,
  }) {
    final decodedResult = _decodeJsonMap(response);
    switch (decodedResult) {
      case CpeFailure<Map<String, dynamic>>(:final error):
        return CpeFailure(error);
      case CpeSuccess<Map<String, dynamic>>(:final data):
        final success = data['success'] == true;
        if (!success) {
          final msg = data['message']?.toString() ?? 'Error en FacturaloPeru API';
          return _buildFailureFromMessage(msg, data);
        }

        final innerData = (data['data'] is Map<String, dynamic>)
            ? data['data'] as Map<String, dynamic>
            : <String, dynamic>{};
        final links = (data['links'] is Map<String, dynamic>)
            ? data['links'] as Map<String, dynamic>
            : <String, dynamic>{};
        final cdrResponse = (innerData['cdr_response'] is Map<String, dynamic>)
            ? innerData['cdr_response'] as Map<String, dynamic>
            : null;

        final stateTypeId = innerData['state_type_id']?.toString() ?? '05';
        final stateDesc = innerData['state_type_description']?.toString() ?? '';
        final externalId = innerData['external_id']?.toString();
        final hash = innerData['hash']?.toString();
        final qr = innerData['qr']?.toString();

        final warnings = <SunatWarning>[];
        if (cdrResponse != null && cdrResponse['notes'] is List) {
          for (final note in cdrResponse['notes'] as List) {
            final noteStr = note.toString().trim();
            if (noteStr.isNotEmpty) {
              warnings.add(SunatWarning(code: '4000', description: noteStr));
            }
          }
        }

        final cdrCode = cdrResponse?['code']?.toString() ?? '0';
        final cdrDesc = cdrResponse?['description']?.toString() ?? stateDesc;

        if (stateTypeId == '09') {
          final parsedCode = int.tryParse(cdrCode) ?? 2000;
          return CpeFailure(
            SunatRejectionException(
              sunatCode: parsedCode,
              message: cdrDesc.isNotEmpty ? cdrDesc : 'Rechazado por SUNAT (state_type_id 09)',
              rawResponse: data,
            ),
          );
        }

        final status = switch (stateTypeId) {
          '01' || '03' || '13' => CpeProcessStatus.inProcess,
          '05' => warnings.isEmpty
              ? CpeProcessStatus.accepted
              : CpeProcessStatus.acceptedWithWarnings,
          '07' => CpeProcessStatus.acceptedWithWarnings,
          '11' => CpeProcessStatus.voided,
          _ => CpeProcessStatus.accepted,
        };

        final cdr = (status == CpeProcessStatus.accepted ||
                status == CpeProcessStatus.acceptedWithWarnings)
            ? CdrData(
                id: innerData['filename']?.toString() ?? 'R-${documentId.fileNameBase}',
                responseCode: cdrCode,
                description: cdrDesc,
                responseDateTime: DateTime.now(),
                digestValue: hash,
                qrContent: qr,
                warnings: List.unmodifiable(warnings),
              )
            : null;

        return CpeSuccess(
          CpeEmissionResponse(
            documentId: documentId,
            status: status,
            cdr: cdr,
            ticket: externalId,
            digestValue: hash,
            qrContent: qr,
            xmlDownloadUrl: links['xml']?.toString(),
            pdfDownloadUrl: links['pdf']?.toString(),
            cdrDownloadUrl: links['cdr']?.toString(),
          ),
        );
    }
  }

  CpeResult<TicketResponse> mapTicketResponse({
    required DocumentId referenceId,
    required CpeHttpResponse response,
  }) {
    final decodedResult = _decodeJsonMap(response);
    switch (decodedResult) {
      case CpeFailure<Map<String, dynamic>>(:final error):
        return CpeFailure(error);
      case CpeSuccess<Map<String, dynamic>>(:final data):
        if (data['success'] != true) {
          final msg = data['message']?.toString() ?? 'Error al registrar ticket en FacturaloPeru';
          return _buildFailureFromMessage(msg, data);
        }
        final innerData = (data['data'] is Map<String, dynamic>)
            ? data['data'] as Map<String, dynamic>
            : <String, dynamic>{};
        final ticket = innerData['ticket']?.toString() ??
            innerData['external_id']?.toString() ??
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

  CpeResult<TicketStatusResponse> mapTicketStatusResponse({
    required String ticket,
    required CpeHttpResponse response,
  }) {
    final decodedResult = _decodeJsonMap(response);
    switch (decodedResult) {
      case CpeFailure<Map<String, dynamic>>(:final error):
        return CpeFailure(error);
      case CpeSuccess<Map<String, dynamic>>(:final data):
        if (data['success'] != true) {
          final msg = data['message']?.toString() ?? 'Error al consultar ticket en FacturaloPeru';
          return CpeSuccess(
            TicketStatusResponse(
              ticket: ticket,
              status: CpeProcessStatus.rejected,
              statusCode: '99',
              statusMessage: msg,
            ),
          );
        }

        final innerData = (data['data'] is Map<String, dynamic>)
            ? data['data'] as Map<String, dynamic>
            : <String, dynamic>{};
        final stateTypeId = innerData['state_type_id']?.toString() ?? '05';
        final cdrResponse = (innerData['cdr_response'] is Map<String, dynamic>)
            ? innerData['cdr_response'] as Map<String, dynamic>
            : null;
        final cdrDesc = cdrResponse?['description']?.toString() ??
            innerData['state_type_description']?.toString() ??
            'Aceptado';

        final status = switch (stateTypeId) {
          '01' || '03' || '13' => CpeProcessStatus.inProcess,
          '05' => CpeProcessStatus.accepted,
          '07' => CpeProcessStatus.acceptedWithWarnings,
          '09' => CpeProcessStatus.rejected,
          _ => CpeProcessStatus.accepted,
        };

        final cdr = (status == CpeProcessStatus.accepted ||
                status == CpeProcessStatus.acceptedWithWarnings)
            ? CdrData(
                id: innerData['filename']?.toString() ?? ticket,
                responseCode: cdrResponse?['code']?.toString() ?? '0',
                description: cdrDesc,
                responseDateTime: DateTime.now(),
              )
            : null;

        return CpeSuccess(
          TicketStatusResponse(
            ticket: ticket,
            status: status,
            cdr: cdr,
            statusCode: stateTypeId,
            statusMessage: cdrDesc,
          ),
        );
    }
  }

  CpeResult<Map<String, dynamic>> _decodeJsonMap(CpeHttpResponse response) {
    if (response.statusCode == 401 || response.statusCode == 403) {
      return CpeFailure(
        OseAuthException(
          message: 'FacturaloPeru Bearer Token unauthorized (HTTP ${response.statusCode})',
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
          message: 'Unexpected FacturaloPeru JSON structure: ${response.bodyAsString}',
          httpStatusCode: response.statusCode,
          rawResponse: response.bodyAsString,
        ),
      );
    } catch (e) {
      return CpeFailure(
        OseTransportException(
          message: 'Invalid JSON from FacturaloPeru (HTTP ${response.statusCode}): $e',
          httpStatusCode: response.statusCode,
          rawResponse: response.bodyAsString,
        ),
      );
    }
  }

  CpeFailure<T> _buildFailureFromMessage<T>(String message, Object raw) {
    final codeMatch = RegExp(r'\b(0[1-9]\d{2}|[1-3]\d{3})\b').firstMatch(message);
    if (codeMatch != null) {
      final code = int.parse(codeMatch.group(1)!);
      if (code >= 100 && code < 2000) {
        return CpeFailure(
          SunatExceptionError(
            sunatCode: code,
            message: message,
            rawResponse: raw,
          ),
        );
      }
      if (code >= 2000 && code < 4000) {
        return CpeFailure(
          SunatRejectionException(
            sunatCode: code,
            message: message,
            rawResponse: raw,
          ),
        );
      }
    }
    return CpeFailure(
      OseTransportException(
        message: message,
        isRetryable: false,
        rawResponse: raw,
      ),
    );
  }
}
