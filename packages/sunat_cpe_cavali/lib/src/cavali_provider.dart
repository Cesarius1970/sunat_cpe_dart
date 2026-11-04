import 'package:sunat_cpe_core/sunat_cpe_core.dart';

import 'cavali_config.dart';
import 'factrack/cavali_factrack_client.dart';
import 'factrack/cavali_oauth2_interceptor.dart';
import 'ose/gosocket_soap_delegate.dart';

/// Proveedor Cavali / Gosocket / Carvajal que implementa tanto [OseProvider]
/// (validación SOAP 1.1 UBL 2.1) como [CavaliFactoringCapability] (Cavali Factrack v2).
final class CavaliProvider
    with TicketPollingMixin
    implements OseProvider, CavaliFactoringCapability {
  /// Configuración de endpoints y credenciales para OSE y Factrack.
  final CavaliConfig config;
  final GosocketSoapDelegate _oseDelegate;
  final CavaliFactrackClient _factrackClient;

  /// Crea una instancia de [CavaliProvider].
  CavaliProvider({
    required this.config,
    CpeHttpClient? oseHttpClient,
    CpeHttpClient? factrackHttpClient,
    CpeMathValidator? validator,
    UblXmlBuilder xmlBuilder = const UblXmlBuilder(),
    XadesBesSigner signer = const XadesBesSigner(),
    CpeZipCodec zipCodec = const CpeZipCodec(),
  }) : _oseDelegate = GosocketSoapDelegate(
         endpointUri: config.oseSoapEndpoint,
         wsseUsername: config.wsseUsername,
         wssePassword: config.wssePassword,
         certificate: config.certificate,
         httpClient: oseHttpClient,
         validator: validator,
         xmlBuilder: xmlBuilder,
         signer: signer,
         zipCodec: zipCodec,
       ),
       _factrackClient = CavaliFactrackClient(
         baseUri: config.factrackBaseUri,
         timeout: config.timeout,
         httpClient:
             factrackHttpClient ??
             DefaultCpeHttpClient(
               interceptors: [
                 if (config.factrackClientId != null &&
                     config.factrackClientSecret != null)
                   CavaliOAuth2Interceptor(
                     tokenEndpoint: Uri.parse(
                       '${config.factrackBaseUri.toString().replaceAll(RegExp(r'/+$'), '')}/oauth/token',
                     ),
                     clientId: config.factrackClientId!,
                     clientSecret: config.factrackClientSecret!,
                     apiKey: config.factrackApiKey,
                   ),
               ],
             ),
       );

  @override
  String get providerId => 'cavali';

  @override
  Set<ProviderCapability> get capabilities => {
    ..._oseDelegate.capabilities,
    ProviderCapability.cavaliFactoring,
  };

  @override
  Future<CpeResult<CpeEmissionResponse>> sendDocument(
    SalesCpeDocument document,
  ) => _oseDelegate.sendDocument(document);

  @override
  Future<CpeResult<CpeEmissionResponse>> sendRetentionOrPerception(
    AgentCpeDocument document,
  ) => _oseDelegate.sendRetentionOrPerception(document);

  @override
  Future<CpeResult<TicketResponse>> sendDailySummary(
    DailySummaryDocument summary,
  ) => _oseDelegate.sendDailySummary(summary);

  @override
  Future<CpeResult<TicketResponse>> sendVoidedDocument(VoidedDocument voided) =>
      _oseDelegate.sendVoidedDocument(voided);

  @override
  Future<CpeResult<TicketResponse>> sendDespatchAdvice(
    DespatchAdviceDocument guide,
  ) => _oseDelegate.sendDespatchAdvice(guide);

  @override
  Future<CpeResult<TicketStatusResponse>> checkTicket(
    String ticket, {
    DocumentId? referenceId,
  }) => _oseDelegate.checkTicket(ticket, referenceId: referenceId);

  @override
  Future<CpeResult<CpeStatusQueryResponse>> queryDocumentStatus(
    DocumentStatusQuery query,
  ) => _oseDelegate.queryDocumentStatus(query);

  @override
  Future<CpeResult<String>> registerInvoicesForFactoring(
    List<CpeEmissionResponse> acceptedInvoices,
  ) => _factrackClient.registerInvoicesForFactoring(acceptedInvoices);

  @override
  Future<CpeResult<CavaliInvoiceStatus>> checkConformityStatus(
    DocumentId documentId,
  ) => _factrackClient.checkConformityStatus(documentId);
}
