import '../entities/cpe_entities.dart';
import '../results/cpe_responses.dart';
import '../results/cpe_result.dart';

/// Capabilities supported by a given OSE or PSE adapter.
enum ProviderCapability {
  invoiceAndNotes,
  purchaseSettlement,
  dailySummary,
  voidedDocuments,
  despatchAdvice,
  retentionPerception,
  statusQuery,
  taxpayerLookup,
  cavaliFactoring,
}

/// Exponential backoff configuration for asynchronous Ticket polling.
final class PollingConfig {
  final Duration initialDelay;
  final Duration maxDelay;
  final double backoffMultiplier;
  final int maxAttempts;
  final Duration totalTimeout;

  const PollingConfig({
    this.initialDelay = const Duration(milliseconds: 500),
    this.maxDelay = const Duration(seconds: 10),
    this.backoffMultiplier = 1.5,
    this.maxAttempts = 10,
    this.totalTimeout = const Duration(seconds: 60),
  });
}

/// Unified contract implemented by all 9 OSE / PSE provider packages.
abstract interface class OseProvider {
  /// Unique identifier of the provider (e.g. 'nubefact', 'efact', 'bizlinks').
  String get providerId;

  /// Supported capabilities for this provider.
  Set<ProviderCapability> get capabilities;

  /// Sends a Sales Document (01 Factura, 03 Boleta, 04 Liquidación, 07 NC, 08 ND).
  Future<CpeResult<CpeEmissionResponse>> sendDocument(
    SalesCpeDocument document,
  );

  /// Sends a Daily Summary of Boletas (RC). Returns a Ticket immediately.
  Future<CpeResult<TicketResponse>> sendDailySummary(
    DailySummaryDocument summary,
  );

  /// Sends a Voided Document Communication (RA) or Reversion (RR). Returns a Ticket.
  Future<CpeResult<TicketResponse>> sendVoidedDocument(VoidedDocument voided);

  /// Sends a Despatch Advice / Guía de Remisión (09 Remitente, 31 Transportista).
  Future<CpeResult<TicketResponse>> sendDespatchAdvice(
    DespatchAdviceDocument guide,
  );

  /// Sends a Retention (20) or Perception (40) document.
  Future<CpeResult<CpeEmissionResponse>> sendRetentionOrPerception(
    AgentCpeDocument document,
  );

  /// Checks the status of an asynchronous Ticket once (`98` in process, `0` accepted, `99` rejected).
  Future<CpeResult<TicketStatusResponse>> checkTicket(
    String ticket, {
    DocumentId? referenceId,
  });

  /// Polls [checkTicket] using exponential backoff until the ticket completes or times out.
  Future<CpeResult<CdrData>> pollTicketUntilDone(
    String ticket, {
    DocumentId? referenceId,
    PollingConfig config = const PollingConfig(),
  });

  /// Queries the status and retrieves the CDR of a previously issued document.
  Future<CpeResult<CpeStatusQueryResponse>> queryDocumentStatus(
    DocumentStatusQuery query,
  );
}

/// Mixin providing the default implementation of [OseProvider.pollTicketUntilDone].
base mixin TicketPollingMixin implements OseProvider {
  @override
  Future<CpeResult<CdrData>> pollTicketUntilDone(
    String ticket, {
    DocumentId? referenceId,
    PollingConfig config = const PollingConfig(),
  }) async {
    final stopwatch = Stopwatch()..start();
    var currentDelay = config.initialDelay;

    for (var attempt = 1; attempt <= config.maxAttempts; attempt++) {
      final statusResult = await checkTicket(ticket, referenceId: referenceId);

      switch (statusResult) {
        case CpeFailure<TicketStatusResponse>(:final error):
          return CpeFailure(error);

        case CpeSuccess<TicketStatusResponse>(:final data):
          if (data.status == CpeProcessStatus.accepted ||
              data.status == CpeProcessStatus.acceptedWithWarnings) {
            if (data.cdr != null) {
              return CpeSuccess(data.cdr!);
            }
            return CpeSuccess(
              CdrData(
                id: ticket,
                responseCode: data.statusCode ?? '0',
                description:
                    data.statusMessage ?? 'Ticket procesado correctamente',
                responseDateTime: DateTime.now(),
              ),
            );
          }

          if (data.status == CpeProcessStatus.rejected) {
            final parsedCode = int.tryParse(data.statusCode ?? '') ?? 2000;
            return CpeFailure(
              SunatRejectionException(
                sunatCode: parsedCode,
                message: data.statusMessage ?? 'Ticket rechazado por SUNAT/OSE',
                rejectionCdr: data.cdr,
              ),
            );
          }
      }

      if (attempt == config.maxAttempts ||
          stopwatch.elapsed + currentDelay > config.totalTimeout) {
        break;
      }

      await Future<void>.delayed(currentDelay);
      final nextMs = (currentDelay.inMilliseconds * config.backoffMultiplier)
          .round();
      currentDelay = Duration(
        milliseconds: nextMs.clamp(
          config.initialDelay.inMilliseconds,
          config.maxDelay.inMilliseconds,
        ),
      );
    }

    return CpeFailure(
      OseTransportException(
        message:
            'Polling timeout exceeded for ticket $ticket after ${stopwatch.elapsed.inMilliseconds}ms',
        code: 'TICKET_POLL_TIMEOUT',
        isRetryable: true,
      ),
    );
  }
}
