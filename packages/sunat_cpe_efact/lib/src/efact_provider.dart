import 'dart:convert';
import 'package:sunat_cpe_core/sunat_cpe_core.dart';
import 'auth/efact_oauth2_interceptor.dart';
import 'efact_config.dart';
import 'rest/efact_json_mapper.dart';
import 'rest/efact_rest_client.dart';
import 'soap/efact_soap_delegate.dart';

/// EFACT OSE / PSE Provider supporting REST OAuth2 (XML/JSON) and SOAP 1.1 (`billService`).
final class EfactProvider with TicketPollingMixin implements OseProvider {
  final EfactConfig config;
  final CpeMathValidator validator;
  final UblXmlBuilder xmlBuilder;
  final XadesBesSigner signer;
  final CpeZipCodec zipCodec;
  final EfactJsonMapper jsonMapper;

  late final CpeHttpClient _httpClient;
  EfactRestClient? _restClient;
  EfactSoapDelegate? _soapDelegate;

  EfactProvider({
    required this.config,
    CpeHttpClient? httpClient,
    CpeMathValidator? validator,
    this.xmlBuilder = const UblXmlBuilder(),
    this.signer = const XadesBesSigner(),
    this.zipCodec = const CpeZipCodec(),
    this.jsonMapper = const EfactJsonMapper(),
  }) : validator = validator ?? CpeMathValidator() {
    if (config.mode == EfactIntegrationMode.soapUbl) {
      final cert = config.certificate;
      if (cert == null) {
        throw ArgumentError('EfactConfig.certificate is required for EfactIntegrationMode.soapUbl');
      }
      _httpClient = httpClient ?? DefaultCpeHttpClient();
      _soapDelegate = EfactSoapDelegate(
        endpointUri: config.baseUri,
        wsseUsername: config.username,
        wssePassword: config.password,
        certificate: cert,
        httpClient: _httpClient,
        validator: this.validator,
        xmlBuilder: xmlBuilder,
        signer: signer,
        zipCodec: zipCodec,
      );
    } else {
      if (config.mode == EfactIntegrationMode.restXml && config.certificate == null) {
        throw ArgumentError('EfactConfig.certificate is required for EfactIntegrationMode.restXml');
      }
      final baseStr = config.baseUri.toString().replaceAll(RegExp(r'/+$'), '');
      final tokenUri = Uri.parse('$baseStr/oauth/token');
      _httpClient = httpClient ??
          DefaultCpeHttpClient(
            interceptors: [
              EfactOAuth2Interceptor(
                tokenEndpoint: tokenUri,
                username: config.username,
                password: config.password,
                clientId: config.oauthClientId,
                clientSecret: config.oauthClientSecret,
              ),
            ],
          );
      _restClient = EfactRestClient(
        baseUri: config.baseUri,
        httpClient: _httpClient,
        zipCodec: zipCodec,
        timeout: config.timeout,
      );
    }
  }

  @override
  String get providerId => 'efact';

  @override
  Set<ProviderCapability> get capabilities => const {
        ProviderCapability.invoiceAndNotes,
        ProviderCapability.purchaseSettlement,
        ProviderCapability.dailySummary,
        ProviderCapability.voidedDocuments,
        ProviderCapability.despatchAdvice,
        ProviderCapability.retentionPerception,
        ProviderCapability.statusQuery,
      };

  @override
  Future<CpeResult<CpeEmissionResponse>> sendDocument(
    SalesCpeDocument document,
  ) {
    if (_soapDelegate != null) {
      return _soapDelegate!.sendDocument(document);
    }
    return _sendRestEmission(
      document,
      igvAmountForQr: document.totals.totalIgv,
      totalAmountForQr: document.totals.importeTotalPagar,
      customerForQr: document.customer,
    );
  }

  @override
  Future<CpeResult<CpeEmissionResponse>> sendRetentionOrPerception(
    AgentCpeDocument document,
  ) {
    if (_soapDelegate != null) {
      return _soapDelegate!.sendRetentionOrPerception(document);
    }
    return _sendRestEmission(
      document,
      igvAmountForQr: Decimal.zero,
      totalAmountForQr: document.totalAmountInPen,
      customerForQr: document.partner,
    );
  }

  @override
  Future<CpeResult<TicketResponse>> sendDailySummary(
    DailySummaryDocument summary,
  ) {
    if (_soapDelegate != null) {
      return _soapDelegate!.sendDailySummary(summary);
    }
    return _sendRestAsyncDocument(summary);
  }

  @override
  Future<CpeResult<TicketResponse>> sendVoidedDocument(
    VoidedDocument voided,
  ) {
    if (_soapDelegate != null) {
      return _soapDelegate!.sendVoidedDocument(voided);
    }
    return _sendRestAsyncDocument(voided);
  }

  @override
  Future<CpeResult<TicketResponse>> sendDespatchAdvice(
    DespatchAdviceDocument guide,
  ) {
    if (_soapDelegate != null) {
      return _soapDelegate!.sendDespatchAdvice(guide);
    }
    return _sendRestAsyncDocument(guide);
  }

  @override
  Future<CpeResult<TicketStatusResponse>> checkTicket(
    String ticket, {
    DocumentId? referenceId,
  }) {
    if (_soapDelegate != null) {
      return _soapDelegate!.checkTicket(ticket, referenceId: referenceId);
    }
    return _restClient!.fetchTicketCdr(ticket);
  }

  @override
  Future<CpeResult<CpeStatusQueryResponse>> queryDocumentStatus(
    DocumentStatusQuery query,
  ) async {
    if (_soapDelegate != null) {
      return _soapDelegate!.queryDocumentStatus(query);
    }
    final ticketIdentifier =
        '${query.issuerRuc}-${query.documentType.code}-${query.series}-${query.number}';
    final ticketResult = await _restClient!.fetchTicketCdr(ticketIdentifier);

    return switch (ticketResult) {
      CpeFailure<TicketStatusResponse>(:final error) => CpeFailure(error),
      CpeSuccess<TicketStatusResponse>(:final data) => CpeSuccess(
          CpeStatusQueryResponse(
            status: data.status,
            statusCode: data.statusCode ?? '0',
            statusMessage: data.statusMessage ?? '',
            cdr: data.cdr,
            cdrDownloadUrl: _restClient!.cdrDownloadUrl(ticketIdentifier),
            xmlDownloadUrl: _restClient!.xmlDownloadUrl(ticketIdentifier),
            pdfDownloadUrl: _restClient!.pdfDownloadUrl(ticketIdentifier),
          ),
        ),
    };
  }

  Future<CpeResult<CpeEmissionResponse>> _sendRestEmission(
    CpeDocument document, {
    required Decimal igvAmountForQr,
    required Decimal totalAmountForQr,
    required CustomerParty customerForQr,
  }) async {
    final validation = validator.validate(document);
    if (validation is CpeFailure<void>) {
      return CpeFailure(validation.error);
    }

    try {
      final prepared = _prepareMultipartPayload(document);
      final ticketRes = await _restClient!.submitMultipartDocument(
        fileName: prepared.fileName,
        contentType: prepared.contentType,
        fileContent: prepared.content,
      );

      switch (ticketRes) {
        case CpeFailure<String>(:final error):
          return CpeFailure(error);

        case CpeSuccess<String>(:final data):
          final ticket = data;
          if (!config.autoPollInRest) {
            return CpeSuccess(
              CpeEmissionResponse(
                documentId: document.id,
                status: CpeProcessStatus.inProcess,
                ticket: ticket,
                signedXmlContent: prepared.signedXml,
                digestValue: prepared.digestValue,
                cdrDownloadUrl: _restClient!.cdrDownloadUrl(ticket),
                xmlDownloadUrl: _restClient!.xmlDownloadUrl(ticket),
                pdfDownloadUrl: _restClient!.pdfDownloadUrl(ticket),
              ),
            );
          }

          final cdrResult = await pollTicketUntilDone(
            ticket,
            referenceId: document.id,
            config: config.pollingConfig,
          );

          return switch (cdrResult) {
            CpeFailure<CdrData>(:final error) => CpeFailure(error),
            CpeSuccess<CdrData>(:final data) => CpeSuccess(
                CpeEmissionResponse(
                  documentId: document.id,
                  status: data.warnings.isEmpty
                      ? CpeProcessStatus.accepted
                      : CpeProcessStatus.acceptedWithWarnings,
                  cdr: data,
                  ticket: ticket,
                  signedXmlContent: prepared.signedXml,
                  digestValue: prepared.digestValue ?? data.digestValue,
                  qrContent: BaseUblOseProvider.buildStandardSunatQr(
                    document: document,
                    igvAmount: igvAmountForQr,
                    totalAmount: totalAmountForQr,
                    customer: customerForQr,
                    digestValue: prepared.digestValue ?? data.digestValue ?? '',
                  ),
                  cdrDownloadUrl: _restClient!.cdrDownloadUrl(ticket),
                  xmlDownloadUrl: _restClient!.xmlDownloadUrl(ticket),
                  pdfDownloadUrl: _restClient!.pdfDownloadUrl(ticket),
                ),
              ),
          };
      }
    } on CpeException catch (e) {
      return CpeFailure(e);
    } catch (e, st) {
      return CpeFailure(
        OseTransportException(
          message: 'Unexpected error in EFACT REST sendDocument: $e',
          rawResponse: e,
          stackTrace: st,
        ),
      );
    }
  }

  Future<CpeResult<TicketResponse>> _sendRestAsyncDocument(
    CpeDocument document,
  ) async {
    final validation = validator.validate(document);
    if (validation is CpeFailure<void>) {
      return CpeFailure(validation.error);
    }

    try {
      final prepared = _prepareMultipartPayload(document);
      final ticketRes = await _restClient!.submitMultipartDocument(
        fileName: prepared.fileName,
        contentType: prepared.contentType,
        fileContent: prepared.content,
      );

      return switch (ticketRes) {
        CpeFailure<String>(:final error) => CpeFailure(error),
        CpeSuccess<String>(:final data) => CpeSuccess(
            TicketResponse(
              ticket: data,
              referenceId: document.id,
              receivedAt: DateTime.now(),
              signedXmlContent: prepared.signedXml,
            ),
          ),
      };
    } on CpeException catch (e) {
      return CpeFailure(e);
    } catch (e, st) {
      return CpeFailure(
        OseTransportException(
          message: 'Unexpected error in EFACT REST async submission: $e',
          rawResponse: e,
          stackTrace: st,
        ),
      );
    }
  }

  ({
    String fileName,
    String contentType,
    String content,
    String? signedXml,
    String? digestValue,
  }) _prepareMultipartPayload(CpeDocument document) {
    if (config.mode == EfactIntegrationMode.restXml) {
      final unsignedXml = xmlBuilder.buildUnsignedXml(document);
      final signed = signer.signXml(unsignedXml, config.certificate!);
      return (
        fileName: '${document.id.fileNameBase}.xml',
        contentType: 'application/xml',
        content: signed.signedXml,
        signedXml: signed.signedXml,
        digestValue: signed.digestValue,
      );
    } else {
      final jsonPayload = jsonMapper.mapDocument(document);
      return (
        fileName: '${document.id.fileNameBase}.json',
        contentType: 'application/json',
        content: jsonEncode(jsonPayload),
        signedXml: null,
        digestValue: null,
      );
    }
  }
}
