import '../entities/cpe_entities.dart';
import '../results/cpe_responses.dart';
import '../results/cpe_result.dart';

/// Capacidades funcionales soportadas por un adaptador OSE o PSE específico.
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

/// Configuración de retroceso exponencial (exponential backoff) para el sondeo asíncrono de Tickets.
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

/// Contrato unificado implementado por los 9 paquetes de proveedores OSE / PSE.
abstract interface class OseProvider {
  /// Identificador único del proveedor (ej. 'nubefact', 'efact', 'bizlinks').
  String get providerId;

  /// Conjunto de capacidades soportadas por este proveedor.
  Set<ProviderCapability> get capabilities;

  /// Envía un Comprobante de Pago de Venta (01 Factura, 03 Boleta, 04 Liquidación, 07 NC, 08 ND).
  Future<CpeResult<CpeEmissionResponse>> sendDocument(
    SalesCpeDocument document,
  );

  /// Envía un Resumen Diario de Boletas (RC). Retorna un Ticket inmediatamente.
  Future<CpeResult<TicketResponse>> sendDailySummary(
    DailySummaryDocument summary,
  );

  /// Envía una Comunicación de Baja (RA) o Resumen de Reversiones (RR). Retorna un Ticket.
  Future<CpeResult<TicketResponse>> sendVoidedDocument(VoidedDocument voided);

  /// Envía una Guía de Remisión Electrónica (09 Remitente, 31 Transportista).
  Future<CpeResult<TicketResponse>> sendDespatchAdvice(
    DespatchAdviceDocument guide,
  );

  /// Envía un Comprobante de Retención (20) o de Percepción (40).
  Future<CpeResult<CpeEmissionResponse>> sendRetentionOrPerception(
    AgentCpeDocument document,
  );

  /// Consulta una sola vez el estado de un Ticket asíncrono (`98` en proceso, `0` aceptado, `99` rechazado).
  Future<CpeResult<TicketStatusResponse>> checkTicket(
    String ticket, {
    DocumentId? referenceId,
  });

  /// Sondea [checkTicket] aplicando retroceso exponencial hasta que el ticket finalice o agote el tiempo de espera.
  Future<CpeResult<CdrData>> pollTicketUntilDone(
    String ticket, {
    DocumentId? referenceId,
    PollingConfig config = const PollingConfig(),
  });

  /// Consulta el estado y recupera el CDR de un comprobante emitido previamente.
  Future<CpeResult<CpeStatusQueryResponse>> queryDocumentStatus(
    DocumentStatusQuery query,
  );
}

/// Mixin que provee la implementación predeterminada de [OseProvider.pollTicketUntilDone].
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
