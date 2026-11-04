import 'dart:convert';
import 'package:sunat_cpe_core/sunat_cpe_core.dart';
import 'mappers/nubefact_request_mapper.dart';
import 'mappers/nubefact_response_mapper.dart';
import 'nubefact_config.dart';

/// Nubefact PSE / OSE implementation of [OseProvider].
final class NubefactProvider with TicketPollingMixin implements OseProvider {
  final NubefactConfig config;
  final CpeHttpClient httpClient;
  final CpeMathValidator validator;
  final NubefactRequestMapper _requestMapper;

  NubefactProvider({
    required this.config,
    CpeHttpClient? httpClient,
    CpeMathValidator? validator,
  })  : httpClient = httpClient ?? DefaultCpeHttpClient(),
        validator = validator ?? CpeMathValidator(),
        _requestMapper = NubefactRequestMapper(config);

  @override
  String get providerId => 'nubefact';

  @override
  Set<ProviderCapability> get capabilities => const {
        ProviderCapability.invoiceAndNotes,
        ProviderCapability.voidedDocuments,
        ProviderCapability.despatchAdvice,
        ProviderCapability.retentionPerception,
        ProviderCapability.statusQuery,
      };

  @override
  Future<CpeResult<CpeEmissionResponse>> sendDocument(
    SalesCpeDocument document,
  ) async {
    final validation = validator.validate(document);
    if (validation is CpeFailure<void>) {
      return CpeFailure(validation.error);
    }

    try {
      final payload = _requestMapper.mapSalesDocument(document);
      final response = await _postJson(payload);
      return NubefactResponseMapper.parseEmissionResponse(
        documentId: document.id,
        httpResponse: response,
      );
    } on CpeException catch (e) {
      return CpeFailure(e);
    } catch (e, st) {
      return CpeFailure(
        OseTransportException(
          message: 'Error sending document to Nubefact: $e',
          rawResponse: e,
          stackTrace: st,
        ),
      );
    }
  }

  @override
  Future<CpeResult<TicketResponse>> sendDailySummary(
    DailySummaryDocument summary,
  ) async {
    final validation = validator.validate(summary);
    if (validation is CpeFailure<void>) {
      return CpeFailure(validation.error);
    }

    final firstLine = summary.lines.first;
    try {
      final payload = _requestMapper.mapVoidedLine(
        VoidedLine(
          lineNumber: firstLine.lineNumber,
          documentType: firstLine.documentType,
          series: firstLine.series,
          number: firstLine.number,
          voidReason: 'RESUMEN DIARIO DE BOLETAS',
        ),
      );
      final response = await _postJson(payload);
      return NubefactResponseMapper.parseTicketResponse(
        referenceId: DocumentId(
          issuerRuc: summary.issuer.ruc,
          type: firstLine.documentType,
          series: firstLine.series,
          number: firstLine.number,
        ),
        httpResponse: response,
      );
    } on CpeException catch (e) {
      return CpeFailure(e);
    } catch (e, st) {
      return CpeFailure(
        OseTransportException(
          message: 'Error sending summary to Nubefact: $e',
          rawResponse: e,
          stackTrace: st,
        ),
      );
    }
  }

  @override
  Future<CpeResult<TicketResponse>> sendVoidedDocument(
    VoidedDocument voided,
  ) async {
    final validation = validator.validate(voided);
    if (validation is CpeFailure<void>) {
      return CpeFailure(validation.error);
    }

    final firstLine = voided.lines.first;
    try {
      final payload = _requestMapper.mapVoidedLine(firstLine);
      final response = await _postJson(payload);
      return NubefactResponseMapper.parseTicketResponse(
        referenceId: DocumentId(
          issuerRuc: voided.issuer.ruc,
          type: firstLine.documentType,
          series: firstLine.series,
          number: firstLine.number,
        ),
        httpResponse: response,
      );
    } on CpeException catch (e) {
      return CpeFailure(e);
    } catch (e, st) {
      return CpeFailure(
        OseTransportException(
          message: 'Error sending voided document to Nubefact: $e',
          rawResponse: e,
          stackTrace: st,
        ),
      );
    }
  }

  @override
  Future<CpeResult<TicketResponse>> sendDespatchAdvice(
    DespatchAdviceDocument guide,
  ) async {
    final validation = validator.validate(guide);
    if (validation is CpeFailure<void>) {
      return CpeFailure(validation.error);
    }

    try {
      final payload = _requestMapper.mapDespatchAdvice(guide);
      final response = await _postJson(payload);
      return NubefactResponseMapper.parseTicketResponse(
        referenceId: guide.id,
        httpResponse: response,
      );
    } on CpeException catch (e) {
      return CpeFailure(e);
    } catch (e, st) {
      return CpeFailure(
        OseTransportException(
          message: 'Error sending despatch advice to Nubefact: $e',
          rawResponse: e,
          stackTrace: st,
        ),
      );
    }
  }

  @override
  Future<CpeResult<CpeEmissionResponse>> sendRetentionOrPerception(
    AgentCpeDocument document,
  ) async {
    final validation = validator.validate(document);
    if (validation is CpeFailure<void>) {
      return CpeFailure(validation.error);
    }

    try {
      final payload = _requestMapper.mapAgentDocument(document);
      final response = await _postJson(payload);
      return NubefactResponseMapper.parseEmissionResponse(
        documentId: document.id,
        httpResponse: response,
      );
    } on CpeException catch (e) {
      return CpeFailure(e);
    } catch (e, st) {
      return CpeFailure(
        OseTransportException(
          message: 'Error sending retention/perception to Nubefact: $e',
          rawResponse: e,
          stackTrace: st,
        ),
      );
    }
  }

  @override
  Future<CpeResult<TicketStatusResponse>> checkTicket(
    String ticket, {
    DocumentId? referenceId,
  }) async {
    if (referenceId == null) {
      return const CpeFailure(
        CpeValidationException(
          message:
              'Nubefact requires referenceId (type, series, number) to query ticket status (consultar_anulacion / consultar_guia)',
          issues: [
            ValidationIssue(
              field: 'referenceId',
              message: 'referenceId is required for Nubefact checkTicket',
            ),
          ],
        ),
      );
    }

    final isGuide = referenceId.type == CpeDocumentType.guiaRemisionRemitente ||
        referenceId.type == CpeDocumentType.guiaRemisionTransportista;

    try {
      final payload = _requestMapper.mapStatusQuery(
        operation: isGuide ? 'consultar_guia' : 'consultar_anulacion',
        documentType: referenceId.type,
        series: referenceId.series,
        number: referenceId.number,
      );
      final response = await _postJson(payload);
      return NubefactResponseMapper.parseTicketStatusResponse(
        ticket: ticket,
        httpResponse: response,
      );
    } on CpeException catch (e) {
      return CpeFailure(e);
    } catch (e, st) {
      return CpeFailure(
        OseTransportException(
          message: 'Error checking ticket on Nubefact: $e',
          rawResponse: e,
          stackTrace: st,
        ),
      );
    }
  }

  @override
  Future<CpeResult<CpeStatusQueryResponse>> queryDocumentStatus(
    DocumentStatusQuery query,
  ) async {
    try {
      final payload = _requestMapper.mapStatusQuery(
        operation: 'consultar_comprobante',
        documentType: query.documentType,
        series: query.series,
        number: query.number,
      );
      final response = await _postJson(payload);
      return NubefactResponseMapper.parseStatusQueryResponse(response);
    } on CpeException catch (e) {
      return CpeFailure(e);
    } catch (e, st) {
      return CpeFailure(
        OseTransportException(
          message: 'Error querying document status on Nubefact: $e',
          rawResponse: e,
          stackTrace: st,
        ),
      );
    }
  }

  Future<CpeHttpResponse> _postJson(Map<String, Object?> payload) {
    return httpClient.send(
      CpeHttpRequest(
        method: 'POST',
        uri: config.routeUri,
        headers: {
          'Authorization': 'Token token="${config.apiToken}"',
          'Content-Type': 'application/json; charset=utf-8',
          'Accept': 'application/json',
        },
        body: json.encode(payload),
      ),
    );
  }
}
