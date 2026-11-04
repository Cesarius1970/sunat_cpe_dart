import 'dart:convert';
import 'package:sunat_cpe_core/sunat_cpe_core.dart';
import 'facturalo_config.dart';
import 'mappers/facturalo_dispatch_mapper.dart';
import 'mappers/facturalo_document_mapper.dart';
import 'mappers/facturalo_response_mapper.dart';
import 'mappers/facturalo_summary_mapper.dart';
import 'mappers/facturalo_voided_mapper.dart';

/// Taxpayer information returned by `/api/service/ruc/{ruc}` or `/api/service/dni/{dni}`.
final class FacturaloTaxpayerInfo {
  final String documentNumber;
  final String nameOrLegalName;
  final String? status;
  final String? condition;
  final String? address;
  final String? ubigeo;

  const FacturaloTaxpayerInfo({
    required this.documentNumber,
    required this.nameOrLegalName,
    this.status,
    this.condition,
    this.address,
    this.ubigeo,
  });
}

/// FacturaloPeru / Facturador PRO (Smart / APIPeru) Provider implementing [OseProvider].
final class FacturaloProvider with TicketPollingMixin implements OseProvider {
  final FacturaloConfig config;
  final CpeHttpClient httpClient;
  final CpeMathValidator validator;
  final FacturaloDocumentMapper documentMapper;
  final FacturaloSummaryMapper summaryMapper;
  final FacturaloVoidedMapper voidedMapper;
  final FacturaloDispatchMapper dispatchMapper;
  final FacturaloResponseMapper responseMapper;

  FacturaloProvider({
    required this.config,
    CpeHttpClient? httpClient,
    CpeMathValidator? validator,
    this.documentMapper = const FacturaloDocumentMapper(),
    this.summaryMapper = const FacturaloSummaryMapper(),
    this.voidedMapper = const FacturaloVoidedMapper(),
    this.dispatchMapper = const FacturaloDispatchMapper(),
    this.responseMapper = const FacturaloResponseMapper(),
  })  : httpClient = httpClient ?? DefaultCpeHttpClient(),
        validator = validator ?? CpeMathValidator();

  @override
  String get providerId => 'facturaloperu';

  @override
  Set<ProviderCapability> get capabilities => const {
        ProviderCapability.invoiceAndNotes,
        ProviderCapability.dailySummary,
        ProviderCapability.voidedDocuments,
        ProviderCapability.despatchAdvice,
        ProviderCapability.retentionPerception,
        ProviderCapability.statusQuery,
        ProviderCapability.taxpayerLookup,
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
      final payload = documentMapper.mapSalesDocument(document, config);
      final response = await _postJson('/api/documents', payload);
      return responseMapper.mapEmissionResponse(
        documentId: document.id,
        response: response,
      );
    } on CpeException catch (e) {
      return CpeFailure(e);
    } catch (e, st) {
      return CpeFailure(
        OseTransportException(
          message: 'Unexpected error in FacturaloPeru /api/documents: $e',
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
      final payload = documentMapper.mapAgentDocument(document);
      final response = await _postJson('/api/retentions', payload);
      return responseMapper.mapEmissionResponse(
        documentId: document.id,
        response: response,
      );
    } on CpeException catch (e) {
      return CpeFailure(e);
    } catch (e, st) {
      return CpeFailure(
        OseTransportException(
          message: 'Unexpected error in FacturaloPeru /api/retentions: $e',
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
      final payload = summaryMapper.mapDailySummary(summary);
      final response = await _postJson('/api/summaries', payload);
      return responseMapper.mapTicketResponse(
        referenceId: summary.id,
        response: response,
      );
    } on CpeException catch (e) {
      return CpeFailure(e);
    } catch (e, st) {
      return CpeFailure(
        OseTransportException(
          message: 'Unexpected error in FacturaloPeru /api/summaries: $e',
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
      final payload = voidedMapper.mapVoidedDocument(voided);
      final response = await _postJson('/api/voided', payload);
      return responseMapper.mapTicketResponse(
        referenceId: voided.id,
        response: response,
      );
    } on CpeException catch (e) {
      return CpeFailure(e);
    } catch (e, st) {
      return CpeFailure(
        OseTransportException(
          message: 'Unexpected error in FacturaloPeru /api/voided: $e',
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
      final payload = dispatchMapper.mapDespatchAdvice(guide);
      final response = await _postJson('/api/dispatches', payload);
      return responseMapper.mapTicketResponse(
        referenceId: guide.id,
        response: response,
      );
    } on CpeException catch (e) {
      return CpeFailure(e);
    } catch (e, st) {
      return CpeFailure(
        OseTransportException(
          message: 'Unexpected error in FacturaloPeru /api/dispatches: $e',
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
      final endpoint = switch (referenceId?.type) {
        CpeDocumentType.comunicacionBaja ||
        CpeDocumentType.reversion =>
          '/api/voided/status',
        CpeDocumentType.guiaRemisionRemitente ||
        CpeDocumentType.guiaRemisionTransportista =>
          '/api/dispatches/status',
        _ => '/api/summaries/status',
      };
      final response = await _postJson(endpoint, {
        'ticket': ticket,
        'external_id': ticket,
      });
      return responseMapper.mapTicketStatusResponse(
        ticket: ticket,
        response: response,
      );
    } on CpeException catch (e) {
      return CpeFailure(e);
    } catch (e, st) {
      return CpeFailure(
        OseTransportException(
          message: 'Unexpected error checking ticket in FacturaloPeru: $e',
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
      final response = await _postJson('/api/documents/status', {
        'serie_documento': query.series,
        'numero_documento': query.number.toString(),
        'codigo_tipo_documento': query.documentType.code,
      });
      final mapped = responseMapper.mapTicketStatusResponse(
        ticket: '${query.series}-${query.number}',
        response: response,
      );
      return switch (mapped) {
        CpeFailure<TicketStatusResponse>(:final error) => CpeFailure(error),
        CpeSuccess<TicketStatusResponse>(:final data) => CpeSuccess(
            CpeStatusQueryResponse(
              status: data.status,
              statusCode: data.statusCode ?? '05',
              statusMessage: data.statusMessage ?? '',
              cdr: data.cdr,
            ),
          ),
      };
    } on CpeException catch (e) {
      return CpeFailure(e);
    } catch (e, st) {
      return CpeFailure(
        OseTransportException(
          message: 'Unexpected error in FacturaloPeru queryDocumentStatus: $e',
          rawResponse: e,
          stackTrace: st,
        ),
      );
    }
  }

  /// Auxiliary RUC/DNI lookup (`/api/service/ruc/{number}` or `/api/service/dni/{number}`).
  Future<CpeResult<FacturaloTaxpayerInfo>> lookupTaxpayer({
    required String documentNumber,
    bool isRuc = true,
  }) async {
    try {
      final typeSegment = isRuc ? 'ruc' : 'dni';
      final baseStr = config.baseUri.toString().replaceAll(RegExp(r'/+$'), '');
      final response = await httpClient.send(
        CpeHttpRequest(
          method: 'GET',
          uri: Uri.parse('$baseStr/api/service/$typeSegment/$documentNumber'),
          headers: {
            'Authorization': 'Bearer ${config.apiToken}',
            'Accept': 'application/json',
          },
          timeout: config.timeout,
        ),
      );
      final decoded = jsonDecode(response.bodyAsString) as Map<String, dynamic>;
      if (decoded['success'] != true) {
        return CpeFailure(
          OseTransportException(
            message: decoded['message']?.toString() ?? 'Taxpayer not found',
            isRetryable: false,
            rawResponse: decoded,
          ),
        );
      }
      final data = (decoded['data'] is Map<String, dynamic>)
          ? decoded['data'] as Map<String, dynamic>
          : decoded;
      return CpeSuccess(
        FacturaloTaxpayerInfo(
          documentNumber: documentNumber,
          nameOrLegalName: data['name']?.toString() ??
              data['nombre_o_razon_social']?.toString() ??
              '',
          status: data['state']?.toString() ?? data['estado']?.toString(),
          condition:
              data['condition']?.toString() ?? data['condicion']?.toString(),
          address: data['address']?.toString() ?? data['direccion']?.toString(),
          ubigeo: data['ubigeo']?.toString(),
        ),
      );
    } on CpeException catch (e) {
      return CpeFailure(e);
    } catch (e, st) {
      return CpeFailure(
        OseTransportException(
          message: 'Error looking up taxpayer in FacturaloPeru: $e',
          rawResponse: e,
          stackTrace: st,
        ),
      );
    }
  }

  Future<CpeHttpResponse> _postJson(
    String path,
    Map<String, dynamic> payload,
  ) {
    final baseStr = config.baseUri.toString().replaceAll(RegExp(r'/+$'), '');
    final cleanPath = path.startsWith('/') ? path : '/$path';
    return httpClient.send(
      CpeHttpRequest(
        method: 'POST',
        uri: Uri.parse('$baseStr$cleanPath'),
        headers: {
          'Authorization': 'Bearer ${config.apiToken}',
          'Content-Type': 'application/json; charset=utf-8',
          'Accept': 'application/json',
        },
        body: jsonEncode(payload),
        timeout: config.timeout,
      ),
    );
  }
}
