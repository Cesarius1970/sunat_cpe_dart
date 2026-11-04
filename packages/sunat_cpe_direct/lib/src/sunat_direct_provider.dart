import 'package:sunat_cpe_core/sunat_cpe_core.dart';

import 'rest/sunat_direct_gre_rest_client.dart';
import 'rest/sunat_direct_oauth2_interceptor.dart';
import 'soap/sunat_direct_soap_delegate.dart';
import 'sunat_direct_config.dart';

/// Direct SUNAT SOL Provider implementing [OseProvider] with intelligent channel routing:
/// - `soapInvoiceDelegate`: Facturas (01), Boletas (03), Liquidaciones (04), Notas (07/08), RC, RA.
/// - `soapOtrosCpeDelegate`: Retenciones (20), Percepciones (40), Reversiones (RR).
/// - `greRestClient` (or `soapGreDelegate`): Guías de Remisión (09/31) via OAuth2 REST (`arcGreZip` + `hashZip`).
final class SunatDirectProvider with TicketPollingMixin implements OseProvider {
  final SunatDirectConfig config;
  final CpeMathValidator validator;
  final UblXmlBuilder xmlBuilder;
  final XadesBesSigner signer;
  final CpeZipCodec zipCodec;

  late final SunatDirectSoapDelegate _soapInvoiceDelegate;
  late final SunatDirectSoapDelegate _soapOtrosCpeDelegate;
  late final SunatDirectSoapDelegate _soapGreDelegate;
  SunatDirectGreRestClient? _greRestClient;

  /// Tracks which internal channel issued a given ticket (`'rest_gre'`, `'soap_otros'`, `'soap_invoice'`).
  final Map<String, String> _ticketChannelRegistry = {};

  SunatDirectProvider({
    required this.config,
    CpeHttpClient? soapHttpClient,
    CpeHttpClient? restHttpClient,
    CpeMathValidator? validator,
    this.xmlBuilder = const UblXmlBuilder(),
    this.signer = const XadesBesSigner(),
    this.zipCodec = const CpeZipCodec(),
  }) : validator = validator ?? CpeMathValidator() {
    final sharedSoapClient = soapHttpClient ?? DefaultCpeHttpClient();

    _soapInvoiceDelegate = SunatDirectSoapDelegate(
      channelId: 'sunat_direct_soap_factura',
      endpointUri: config.environment.soapInvoiceUri,
      wsseUsername: config.wsseUsername,
      wssePassword: config.claveSol,
      certificate: config.certificate,
      httpClient: sharedSoapClient,
      validator: this.validator,
      xmlBuilder: xmlBuilder,
      signer: signer,
      zipCodec: zipCodec,
    );

    _soapOtrosCpeDelegate = SunatDirectSoapDelegate(
      channelId: 'sunat_direct_soap_otroscpe',
      endpointUri: config.environment.soapOtrosCpeUri,
      wsseUsername: config.wsseUsername,
      wssePassword: config.claveSol,
      certificate: config.certificate,
      httpClient: sharedSoapClient,
      validator: this.validator,
      xmlBuilder: xmlBuilder,
      signer: signer,
      zipCodec: zipCodec,
    );

    _soapGreDelegate = SunatDirectSoapDelegate(
      channelId: 'sunat_direct_soap_gre',
      endpointUri: config.environment.soapGuiaRemisionUri,
      wsseUsername: config.wsseUsername,
      wssePassword: config.claveSol,
      certificate: config.certificate,
      httpClient: sharedSoapClient,
      validator: this.validator,
      xmlBuilder: xmlBuilder,
      signer: signer,
      zipCodec: zipCodec,
    );

    if (config.useRestForGre) {
      final effectiveRestClient =
          restHttpClient ??
          (config.hasRestCredentials
              ? DefaultCpeHttpClient(
                  interceptors: [
                    SunatDirectOAuth2Interceptor(
                      tokenEndpoint: config.environment.restOAuthTokenUri(
                        config.clientId!,
                      ),
                      clientId: config.clientId!,
                      clientSecret: config.clientSecret!,
                      usernameOAuth2: config.wsseUsername,
                      claveSol: config.claveSol,
                    ),
                  ],
                )
              : sharedSoapClient);

      _greRestClient = SunatDirectGreRestClient(
        baseUri: config.environment.restGreBaseUri,
        httpClient: effectiveRestClient,
        zipCodec: zipCodec,
        timeout: config.timeout,
      );
    }
  }

  @override
  String get providerId => 'sunat_direct';

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
  ) => _soapInvoiceDelegate.sendDocument(document);

  @override
  Future<CpeResult<CpeEmissionResponse>> sendRetentionOrPerception(
    AgentCpeDocument document,
  ) => _soapOtrosCpeDelegate.sendRetentionOrPerception(document);

  @override
  Future<CpeResult<TicketResponse>> sendDailySummary(
    DailySummaryDocument summary,
  ) async {
    final res = await _soapInvoiceDelegate.sendDailySummary(summary);
    if (res case CpeSuccess<TicketResponse>(:final data)) {
      _ticketChannelRegistry[data.ticket] = 'soap_invoice';
    }
    return res;
  }

  @override
  Future<CpeResult<TicketResponse>> sendVoidedDocument(
    VoidedDocument voided,
  ) async {
    if (voided.id.type == CpeDocumentType.reversion) {
      final res = await _soapOtrosCpeDelegate.sendVoidedDocument(voided);
      if (res case CpeSuccess<TicketResponse>(:final data)) {
        _ticketChannelRegistry[data.ticket] = 'soap_otros';
      }
      return res;
    }
    final res = await _soapInvoiceDelegate.sendVoidedDocument(voided);
    if (res case CpeSuccess<TicketResponse>(:final data)) {
      _ticketChannelRegistry[data.ticket] = 'soap_invoice';
    }
    return res;
  }

  @override
  Future<CpeResult<TicketResponse>> sendDespatchAdvice(
    DespatchAdviceDocument guide,
  ) async {
    if (!config.useRestForGre || _greRestClient == null) {
      final res = await _soapGreDelegate.sendDespatchAdvice(guide);
      if (res case CpeSuccess<TicketResponse>(:final data)) {
        _ticketChannelRegistry[data.ticket] = 'soap_gre';
      }
      return res;
    }

    final validation = validator.validate(guide);
    if (validation is CpeFailure<void>) {
      return CpeFailure(validation.error);
    }

    if (!config.hasRestCredentials) {
      return const CpeFailure(
        OseAuthException(
          message: 'Se requieren clientId y clientSecret en SunatDirectConfig para enviar Guías de Remisión por la API REST de SUNAT.',
        ),
      );
    }

    try {
      final unsignedXml = xmlBuilder.buildUnsignedXml(guide);
      final signed = signer.signXml(unsignedXml, config.certificate);
      final res = await _greRestClient!.sendDespatchZip(
        documentId: guide.id,
        signedXmlContent: signed.signedXml,
      );
      if (res case CpeSuccess<TicketResponse>(:final data)) {
        _ticketChannelRegistry[data.ticket] = 'rest_gre';
      }
      return res;
    } on CpeException catch (e) {
      return CpeFailure(e);
    } catch (e, st) {
      return CpeFailure(
        OseTransportException(
          message:
              'Error firmando o enviando Guía de Remisión en SunatDirectProvider: $e',
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
  }) {
    final registeredChannel = _ticketChannelRegistry[ticket];
    final refType = referenceId?.type;

    if (registeredChannel == 'rest_gre' ||
        (registeredChannel == null &&
            config.useRestForGre &&
            _greRestClient != null &&
            (refType == CpeDocumentType.guiaRemisionRemitente ||
                refType == CpeDocumentType.guiaRemisionTransportista))) {
      return _greRestClient!.checkGreTicket(ticket);
    }

    if (registeredChannel == 'soap_gre' ||
        (!config.useRestForGre &&
            (refType == CpeDocumentType.guiaRemisionRemitente ||
                refType == CpeDocumentType.guiaRemisionTransportista))) {
      return _soapGreDelegate.checkTicket(ticket, referenceId: referenceId);
    }

    if (registeredChannel == 'soap_otros' ||
        refType == CpeDocumentType.reversion ||
        refType == CpeDocumentType.comprobanteRetencion ||
        refType == CpeDocumentType.comprobantePercepcion) {
      return _soapOtrosCpeDelegate.checkTicket(
        ticket,
        referenceId: referenceId,
      );
    }

    return _soapInvoiceDelegate.checkTicket(ticket, referenceId: referenceId);
  }

  @override
  Future<CpeResult<CpeStatusQueryResponse>> queryDocumentStatus(
    DocumentStatusQuery query,
  ) {
    if (query.documentType == CpeDocumentType.comprobanteRetencion ||
        query.documentType == CpeDocumentType.comprobantePercepcion ||
        query.documentType == CpeDocumentType.reversion) {
      return _soapOtrosCpeDelegate.queryDocumentStatus(query);
    }
    return _soapInvoiceDelegate.queryDocumentStatus(query);
  }
}
