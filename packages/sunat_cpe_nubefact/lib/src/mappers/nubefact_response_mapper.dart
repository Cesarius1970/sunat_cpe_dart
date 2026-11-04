import 'dart:convert';
import 'package:sunat_cpe_core/sunat_cpe_core.dart';

/// Maps Nubefact JSON HTTP responses into `sunat_cpe_core` result and response types.
final class NubefactResponseMapper {
  const NubefactResponseMapper._();

  /// Parses an emission response (`generar_comprobante`, `generar_retencion`, `generar_percepcion`).
  static CpeResult<CpeEmissionResponse> parseEmissionResponse({
    required DocumentId documentId,
    required CpeHttpResponse httpResponse,
  }) {
    final decoded = _decodeJsonOrFail(httpResponse);
    if (decoded is CpeFailure<Map<String, Object?>>) {
      return CpeFailure(decoded.error);
    }
    final map = (decoded as CpeSuccess<Map<String, Object?>>).data;

    final error = _extractErrorIfPresent(map, httpResponse);
    if (error != null) {
      return CpeFailure(error);
    }

    final acceptedBySunat = map['aceptada_por_sunat'] == true;
    final sunatCode = _str(map['sunat_responsecode']);
    final sunatDescription = _str(map['sunat_description']);
    final sunatNote = _str(map['sunat_note']);
    final sunatSoapError = _str(map['sunat_soap_error']);

    if (!acceptedBySunat && (sunatCode.isNotEmpty || sunatSoapError.isNotEmpty)) {
      final parsedCode = int.tryParse(sunatCode) ?? _extractNumberFromText(sunatSoapError);
      final msg = sunatDescription.isNotEmpty ? sunatDescription : sunatSoapError;
      if (parsedCode != null && parsedCode >= 100 && parsedCode < 2000) {
        return CpeFailure(
          SunatExceptionError(
            sunatCode: parsedCode,
            message: msg,
            rawResponse: map,
          ),
        );
      }
      return CpeFailure(
        SunatRejectionException(
          sunatCode: parsedCode ?? 2000,
          message: msg.isNotEmpty ? msg : 'Rechazado por SUNAT en Nubefact',
          rawResponse: map,
        ),
      );
    }

    final warnings = <SunatWarning>[];
    if (sunatNote.isNotEmpty) {
      warnings.add(SunatWarning(code: '4000', description: sunatNote));
    }

    final hash = _nullableStr(map['codigo_hash']);
    final qr = _nullableStr(map['cadena_para_codigo_qr']);
    final xmlUrl = _nullableStr(map['enlace_del_xml']);
    final cdrUrl = _nullableStr(map['enlace_del_cdr']);
    final pdfUrl = _nullableStr(map['enlace_del_pdf']);

    final CpeProcessStatus status;
    CdrData? cdr;

    if (acceptedBySunat) {
      status = warnings.isEmpty
          ? CpeProcessStatus.accepted
          : CpeProcessStatus.acceptedWithWarnings;
      cdr = CdrData(
        id: 'R-${documentId.fileNameBase}',
        responseCode: sunatCode.isNotEmpty ? sunatCode : '0',
        description: sunatDescription.isNotEmpty
            ? sunatDescription
            : 'Aceptado por SUNAT vía Nubefact',
        responseDateTime: DateTime.now(),
        digestValue: hash,
        qrContent: qr,
        warnings: List.unmodifiable(warnings),
      );
    } else {
      // Deferred queue in Nubefact
      status = CpeProcessStatus.inProcess;
    }

    return CpeSuccess(
      CpeEmissionResponse(
        documentId: documentId,
        status: status,
        cdr: cdr,
        digestValue: hash,
        qrContent: qr,
        xmlDownloadUrl: xmlUrl,
        cdrDownloadUrl: cdrUrl,
        pdfDownloadUrl: pdfUrl,
      ),
      providerRawMetadata: map,
    );
  }

  /// Parses a Ticket response (`generar_anulacion` or `generar_guia`).
  static CpeResult<TicketResponse> parseTicketResponse({
    required DocumentId referenceId,
    required CpeHttpResponse httpResponse,
  }) {
    final decoded = _decodeJsonOrFail(httpResponse);
    if (decoded is CpeFailure<Map<String, Object?>>) {
      return CpeFailure(decoded.error);
    }
    final map = (decoded as CpeSuccess<Map<String, Object?>>).data;

    final error = _extractErrorIfPresent(map, httpResponse);
    if (error != null) {
      return CpeFailure(error);
    }

    final ticket = _str(map['sunat_ticket_numero']);
    final resolvedTicket = ticket.isNotEmpty ? ticket : referenceId.fileNameBase;

    return CpeSuccess(
      TicketResponse(
        ticket: resolvedTicket,
        referenceId: referenceId,
        receivedAt: DateTime.now(),
      ),
      providerRawMetadata: map,
    );
  }

  /// Parses `checkTicket` response (`consultar_anulacion` or `consultar_guia`).
  static CpeResult<TicketStatusResponse> parseTicketStatusResponse({
    required String ticket,
    required CpeHttpResponse httpResponse,
  }) {
    final decoded = _decodeJsonOrFail(httpResponse);
    if (decoded is CpeFailure<Map<String, Object?>>) {
      return CpeFailure(decoded.error);
    }
    final map = (decoded as CpeSuccess<Map<String, Object?>>).data;

    final error = _extractErrorIfPresent(map, httpResponse);
    if (error != null) {
      return CpeFailure(error);
    }

    final accepted = map['aceptada_por_sunat'] == true;
    final sunatCode = _str(map['sunat_responsecode']);
    final sunatDescription = _str(map['sunat_description']);
    final sunatSoapError = _str(map['sunat_soap_error']);

    if (accepted) {
      final cdr = CdrData(
        id: ticket,
        responseCode: sunatCode.isNotEmpty ? sunatCode : '0',
        description: sunatDescription.isNotEmpty ? sunatDescription : 'Aceptado',
        responseDateTime: DateTime.now(),
        digestValue: _nullableStr(map['codigo_hash']),
      );
      return CpeSuccess(
        TicketStatusResponse(
          ticket: ticket,
          status: CpeProcessStatus.accepted,
          cdr: cdr,
          statusCode: '0',
          statusMessage: cdr.description,
        ),
        providerRawMetadata: map,
      );
    }

    if (sunatCode.isNotEmpty || sunatSoapError.isNotEmpty) {
      return CpeSuccess(
        TicketStatusResponse(
          ticket: ticket,
          status: CpeProcessStatus.rejected,
          statusCode: sunatCode.isNotEmpty ? sunatCode : '2000',
          statusMessage: sunatDescription.isNotEmpty ? sunatDescription : sunatSoapError,
        ),
        providerRawMetadata: map,
      );
    }

    return CpeSuccess(
      TicketStatusResponse(
        ticket: ticket,
        status: CpeProcessStatus.inProcess,
        statusCode: '98',
        statusMessage: 'En proceso en Nubefact/SUNAT',
      ),
      providerRawMetadata: map,
    );
  }

  /// Parses `queryDocumentStatus` response (`consultar_comprobante`).
  static CpeResult<CpeStatusQueryResponse> parseStatusQueryResponse(
    CpeHttpResponse httpResponse,
  ) {
    final decoded = _decodeJsonOrFail(httpResponse);
    if (decoded is CpeFailure<Map<String, Object?>>) {
      return CpeFailure(decoded.error);
    }
    final map = (decoded as CpeSuccess<Map<String, Object?>>).data;

    final error = _extractErrorIfPresent(map, httpResponse);
    if (error != null) {
      return CpeFailure(error);
    }

    final accepted = map['aceptada_por_sunat'] == true;
    final sunatCode = _str(map['sunat_responsecode']);
    final sunatDescription = _str(map['sunat_description']);

    final status = accepted
        ? CpeProcessStatus.accepted
        : (sunatCode.isNotEmpty ? CpeProcessStatus.rejected : CpeProcessStatus.inProcess);

    final cdr = accepted
        ? CdrData(
            id: _str(map['numero']),
            responseCode: sunatCode.isNotEmpty ? sunatCode : '0',
            description: sunatDescription,
            responseDateTime: DateTime.now(),
            digestValue: _nullableStr(map['codigo_hash']),
            qrContent: _nullableStr(map['cadena_para_codigo_qr']),
          )
        : null;

    return CpeSuccess(
      CpeStatusQueryResponse(
        status: status,
        statusCode: sunatCode.isNotEmpty ? sunatCode : (accepted ? '0' : '98'),
        statusMessage: sunatDescription,
        cdr: cdr,
        xmlDownloadUrl: _nullableStr(map['enlace_del_xml']),
        cdrDownloadUrl: _nullableStr(map['enlace_del_cdr']),
        pdfDownloadUrl: _nullableStr(map['enlace_del_pdf']),
      ),
      providerRawMetadata: map,
    );
  }

  static CpeResult<Map<String, Object?>> _decodeJsonOrFail(CpeHttpResponse response) {
    try {
      final raw = json.decode(response.bodyAsString);
      if (raw is Map<String, Object?>) {
        return CpeSuccess(raw);
      }
      return CpeFailure(
        OseTransportException(
          message: 'Expected JSON object from Nubefact, got ${raw.runtimeType}',
          httpStatusCode: response.statusCode,
          rawResponse: response.bodyAsString,
        ),
      );
    } catch (e) {
      return CpeFailure(
        OseTransportException(
          message: 'Invalid JSON response from Nubefact (HTTP ${response.statusCode}): $e',
          httpStatusCode: response.statusCode,
          rawResponse: response.bodyAsString,
        ),
      );
    }
  }

  static CpeException? _extractErrorIfPresent(
    Map<String, Object?> map,
    CpeHttpResponse httpResponse,
  ) {
    final errorsMsg = _str(map['errors']);
    final codigo = int.tryParse(_str(map['codigo']));

    if (errorsMsg.isEmpty && httpResponse.statusCode < 400) {
      return null;
    }

    final message = errorsMsg.isNotEmpty
        ? errorsMsg
        : 'HTTP ${httpResponse.statusCode} error from Nubefact';

    // Nubefact codes 10 and 11 indicate Token or Route authentication failure
    if (codigo == 10 ||
        codigo == 11 ||
        httpResponse.statusCode == 401 ||
        httpResponse.statusCode == 403) {
      return OseAuthException(
        message: message,
        code: codigo?.toString() ?? 'AUTH_ERROR',
        rawResponse: map,
      );
    }

    // Nubefact codes 20..24 indicate payload validation errors
    if (codigo != null && codigo >= 20 && codigo <= 24) {
      return CpeValidationException(
        message: message,
        issues: [
          ValidationIssue(
            field: 'nubefact_code_$codigo',
            message: message,
          ),
        ],
      );
    }

    if (codigo != null && codigo >= 100 && codigo < 2000) {
      return SunatExceptionError(
        sunatCode: codigo,
        message: message,
        rawResponse: map,
      );
    }

    if (codigo != null && codigo >= 2000 && codigo < 4000) {
      return SunatRejectionException(
        sunatCode: codigo,
        message: message,
        rawResponse: map,
      );
    }

    return OseTransportException(
      message: message,
      httpStatusCode: httpResponse.statusCode,
      isRetryable: httpResponse.statusCode >= 500,
      rawResponse: map,
    );
  }

  static int? _extractNumberFromText(String text) {
    final match = RegExp(r'\b(0[1-9]\d{2}|[1-3]\d{3})\b').firstMatch(text);
    return match != null ? int.tryParse(match.group(1)!) : null;
  }

  static String _str(Object? val) => val?.toString().trim() ?? '';

  static String? _nullableStr(Object? val) {
    final s = _str(val);
    return s.isEmpty ? null : s;
  }
}
