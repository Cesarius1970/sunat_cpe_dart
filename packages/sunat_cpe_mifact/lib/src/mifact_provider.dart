import 'dart:convert';

import 'package:sunat_cpe_core/sunat_cpe_core.dart';

import 'mappers/mifact_guide_mapper.dart';
import 'mappers/mifact_invoice_mapper.dart';
import 'mappers/mifact_response_mapper.dart';
import 'mappers/mifact_summary_mapper.dart';
import 'mifact_config.dart';

/// Proveedor PSE / OSE de Mifact que implementa [OseProvider].
final class MifactProvider with TicketPollingMixin implements OseProvider {
  /// Configuración activa de Mifact (URI base, token y opciones de envío).
  final MifactConfig config;

  /// Cliente HTTP inyectable para las peticiones POST JSON.
  final CpeHttpClient httpClient;

  /// Validador aritmético y normativo previo al envío.
  final CpeMathValidator validator;

  /// Mapeador de comprobantes de venta y retención/percepción a `UPPER_SNAKE_CASE`.
  final MifactInvoiceMapper invoiceMapper;

  /// Mapeador de guías de remisión al formato `SendGuide`.
  final MifactGuideMapper guideMapper;

  /// Mapeador de resúmenes diarios, bajas y consultas de estado.
  final MifactSummaryMapper summaryMapper;

  /// Mapeador de respuestas JSON de Mifact (`estado_documento` `100..105`) a resultados del Core.
  final MifactResponseMapper responseMapper;

  /// Crea una instancia de [MifactProvider] con su configuración y dependencias opcionales.
  MifactProvider({
    required this.config,
    CpeHttpClient? httpClient,
    CpeMathValidator? validator,
    this.invoiceMapper = const MifactInvoiceMapper(),
    this.guideMapper = const MifactGuideMapper(),
    this.summaryMapper = const MifactSummaryMapper(),
    this.responseMapper = const MifactResponseMapper(),
  }) : httpClient = httpClient ?? DefaultCpeHttpClient(),
       validator = validator ?? CpeMathValidator();

  @override
  String get providerId => 'mifact';

  @override
  Set<ProviderCapability> get capabilities => const {
    ProviderCapability.invoiceAndNotes,
    ProviderCapability.dailySummary,
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
      final payload = invoiceMapper.mapSalesDocument(document, config);
      final response = await _postJson('/service.asmx/SendInvoice', payload);
      return responseMapper.mapEmissionResponse(
        documentId: document.id,
        response: response,
      );
    } on CpeException catch (e) {
      return CpeFailure(e);
    } catch (e, st) {
      return CpeFailure(
        OseTransportException(
          message: 'Unexpected error in Mifact SendInvoice: $e',
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
      final payload = invoiceMapper.mapAgentDocument(document, config);
      final response = await _postJson('/service.asmx/SendInvoice', payload);
      return responseMapper.mapEmissionResponse(
        documentId: document.id,
        response: response,
      );
    } on CpeException catch (e) {
      return CpeFailure(e);
    } catch (e, st) {
      return CpeFailure(
        OseTransportException(
          message: 'Unexpected error in Mifact retention/perception: $e',
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
    try {
      final payload = summaryMapper.mapDailySummary(summary, config);
      final response = await _postJson('/service.asmx/SendSummary', payload);
      return responseMapper.mapTicketResponse(
        referenceId: summary.id,
        response: response,
      );
    } on CpeException catch (e) {
      return CpeFailure(e);
    } catch (e, st) {
      return CpeFailure(
        OseTransportException(
          message: 'Unexpected error in Mifact SendSummary: $e',
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
    try {
      final payload = summaryMapper.mapVoidedDocument(voided, config);
      final response = await _postJson('/service.asmx/lowInvoice', payload);
      return responseMapper.mapTicketResponse(
        referenceId: voided.id,
        response: response,
      );
    } on CpeException catch (e) {
      return CpeFailure(e);
    } catch (e, st) {
      return CpeFailure(
        OseTransportException(
          message: 'Unexpected error in Mifact lowInvoice: $e',
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
      final payload = guideMapper.mapGuide(guide, config);
      final response = await _postJson('/service.asmx/SendGuide', payload);
      return responseMapper.mapTicketResponse(
        referenceId: guide.id,
        response: response,
      );
    } on CpeException catch (e) {
      return CpeFailure(e);
    } catch (e, st) {
      return CpeFailure(
        OseTransportException(
          message: 'Unexpected error in Mifact SendGuide: $e',
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
    try {
      final payload = <String, dynamic>{
        'TOKEN': config.token,
        'TICKET': ticket,
        if (referenceId != null) ...{
          'NUM_NIF_EMIS': referenceId.issuerRuc,
          'COD_TIP_DOCU': referenceId.type.code,
          'NUM_SERIE_CPE': referenceId.series,
          'NUM_CORRE_CPE': referenceId.number.toString().padLeft(8, '0'),
        },
      };
      final response = await _postJson('/service.asmx/GetStatus', payload);
      final queryRes = responseMapper.mapStatusQueryResponse(response);
      return switch (queryRes) {
        CpeFailure<CpeStatusQueryResponse>(:final error) => CpeFailure(error),
        CpeSuccess<CpeStatusQueryResponse>(:final data) => CpeSuccess(
          TicketStatusResponse(
            ticket: ticket,
            status: data.status,
            cdr: data.cdr,
            statusCode: data.statusCode,
            statusMessage: data.statusMessage,
          ),
        ),
      };
    } on CpeException catch (e) {
      return CpeFailure(e);
    } catch (e, st) {
      return CpeFailure(
        OseTransportException(
          message: 'Unexpected error checking ticket in Mifact: $e',
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
      final payload = summaryMapper.mapStatusQuery(query, config);
      final response = await _postJson('/service.asmx/GetStatus', payload);
      return responseMapper.mapStatusQueryResponse(response);
    } on CpeException catch (e) {
      return CpeFailure(e);
    } catch (e, st) {
      return CpeFailure(
        OseTransportException(
          message: 'Unexpected error in Mifact GetStatus: $e',
          rawResponse: e,
          stackTrace: st,
        ),
      );
    }
  }

  Future<CpeHttpResponse> _postJson(String path, Map<String, dynamic> payload) {
    final baseStr = config.baseUri.toString().replaceAll(RegExp(r'/+$'), '');
    final cleanPath = path.startsWith('/') ? path : '/$path';
    return httpClient.send(
      CpeHttpRequest(
        method: 'POST',
        uri: Uri.parse('$baseStr$cleanPath'),
        headers: const {
          'Content-Type': 'application/json; charset=utf-8',
          'Accept': 'application/json',
        },
        body: jsonEncode(payload),
        timeout: config.timeout,
      ),
    );
  }
}
