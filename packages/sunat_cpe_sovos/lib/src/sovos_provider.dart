import 'package:sunat_cpe_core/sunat_cpe_core.dart';
import 'soap/sovos_soap_delegate.dart';
import 'sovos_config.dart';
import 'ubl/sovos_ubl_extension_builder.dart';

/// Sovos / Paperless OSE & PSE Provider implementing [OseProvider] with idempotent CDR recovery.
final class SovosProvider with TicketPollingMixin implements OseProvider {
  final SovosConfig config;
  final SovosSoapDelegate _delegate;

  SovosProvider({
    required this.config,
    CpeHttpClient? httpClient,
    CpeMathValidator? validator,
    UblXmlBuilder xmlBuilder = const UblXmlBuilder(),
    SovosUblExtensionBuilder extensionBuilder = const SovosUblExtensionBuilder(),
    XadesBesSigner signer = const XadesBesSigner(),
    CpeZipCodec zipCodec = const CpeZipCodec(),
  }) : _delegate = SovosSoapDelegate(
          endpointUri: config.endpointUri,
          wsseUsername: config.username,
          wssePassword: config.password,
          certificate: config.certificate,
          httpClient: httpClient,
          validator: validator,
          xmlBuilder: xmlBuilder,
          extensionBuilder: extensionBuilder,
          customPrintFields: config.customPrintFields,
          signer: signer,
          zipCodec: zipCodec,
        );

  @override
  String get providerId => 'sovos';

  @override
  Set<ProviderCapability> get capabilities => _delegate.capabilities;

  @override
  Future<CpeResult<CpeEmissionResponse>> sendDocument(
    SalesCpeDocument document,
  ) async {
    final result = await _delegate.sendDocument(document);
    if (!config.autoRecoverCdrOnDuplicate || result is CpeSuccess<CpeEmissionResponse>) {
      return result;
    }

    final err = (result as CpeFailure<CpeEmissionResponse>).error;
    if (_isDuplicateSubmissionError(err)) {
      final recovered = await queryDocumentStatus(
        DocumentStatusQuery(
          issuerRuc: document.issuer.ruc,
          documentType: document.id.type,
          series: document.id.series,
          number: document.id.number,
        ),
      );
      if (recovered case CpeSuccess<CpeStatusQueryResponse>(:final data)) {
        if (data.cdr != null && data.cdr!.isAccepted) {
          return CpeSuccess(
            CpeEmissionResponse(
              documentId: document.id,
              status: data.cdr!.warnings.isEmpty
                  ? CpeProcessStatus.accepted
                  : CpeProcessStatus.acceptedWithWarnings,
              cdr: data.cdr,
              digestValue: data.cdr!.digestValue,
              qrContent: BaseUblOseProvider.buildStandardSunatQr(
                document: document,
                igvAmount: document.totals.totalIgv,
                totalAmount: document.totals.importeTotalPagar,
                customer: document.customer,
                digestValue: data.cdr!.digestValue ?? '',
              ),
            ),
          );
        }
      }
    }

    return result;
  }

  @override
  Future<CpeResult<CpeEmissionResponse>> sendRetentionOrPerception(
    AgentCpeDocument document,
  ) =>
      _delegate.sendRetentionOrPerception(document);

  @override
  Future<CpeResult<TicketResponse>> sendDailySummary(
    DailySummaryDocument summary,
  ) =>
      _delegate.sendDailySummary(summary);

  @override
  Future<CpeResult<TicketResponse>> sendVoidedDocument(
    VoidedDocument voided,
  ) =>
      _delegate.sendVoidedDocument(voided);

  @override
  Future<CpeResult<TicketResponse>> sendDespatchAdvice(
    DespatchAdviceDocument guide,
  ) =>
      _delegate.sendDespatchAdvice(guide);

  @override
  Future<CpeResult<TicketStatusResponse>> checkTicket(
    String ticket, {
    DocumentId? referenceId,
  }) =>
      _delegate.checkTicket(ticket, referenceId: referenceId);

  @override
  Future<CpeResult<CpeStatusQueryResponse>> queryDocumentStatus(
    DocumentStatusQuery query,
  ) =>
      _delegate.queryDocumentStatus(query);

  static bool _isDuplicateSubmissionError(CpeException error) {
    return switch (error) {
      SunatExceptionError(:final sunatCode) =>
        sunatCode == 1033 || sunatCode == 2017,
      SunatRejectionException(:final sunatCode) =>
        sunatCode == 1033 || sunatCode == 2017,
      _ => false,
    };
  }
}
