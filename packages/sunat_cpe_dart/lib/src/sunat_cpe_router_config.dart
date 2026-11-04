import 'package:sunat_cpe_core/sunat_cpe_core.dart';

/// Routing and contingency policy configuration for `SunatCpeRouter`.
final class SunatCpeRouterConfig {
  /// Default provider used whenever a document type is not explicitly mapped
  /// in [routesByDocumentType].
  final OseProvider primaryProvider;

  /// Optional per-document-type routing table (e.g., routing Facturas `01` to
  /// an OSE/PSE while routing Despatch Advices `09`/`31` to `SunatDirectProvider`).
  final Map<CpeDocumentType, OseProvider> routesByDocumentType;

  /// Optional contingency provider triggered ONLY on transport errors
  /// ([OseTransportException]) or technical SUNAT/OSE exceptions
  /// ([SunatExceptionError], codes `0100–1999` where the document was NOT registered).
  ///
  /// Never triggered on [CpeValidationException] or [SunatRejectionException] (`2000–3999`).
  final OseProvider? fallbackProvider;

  /// Whether [SunatExceptionError] (`0100–1999`) should trigger [fallbackProvider]
  /// in addition to [OseTransportException]. Defaults to `true`.
  final bool enableFallbackOnSunatExceptions;

  /// Whether returned tickets in [TicketResponse.ticket] should be prefixed
  /// with `{providerId}:{ticket}` in addition to being tracked in memory.
  /// Defaults to `false`.
  final bool prefixTicketsWithProviderId;

  const SunatCpeRouterConfig({
    required this.primaryProvider,
    this.routesByDocumentType = const {},
    this.fallbackProvider,
    this.enableFallbackOnSunatExceptions = true,
    this.prefixTicketsWithProviderId = false,
  });
}
