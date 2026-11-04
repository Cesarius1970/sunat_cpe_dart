import 'package:sunat_cpe_core/sunat_cpe_core.dart';

import 'sunat_cpe_router_config.dart';
import 'sunat_provider_descriptor.dart';
import 'sunat_provider_factory.dart';

/// Orquestador y enrutador inteligente de CPE que implementa [OseProvider].
///
/// Permite discernir dinámicamente entre la emisión directa a SUNAT (`sunat_cpe_direct`)
/// y cualquiera de los 9 adaptadores OSE/PSE (`nubefact`, `efact`, `mifact`, `bizlinks`,
/// `digiflow`, `sovos`, `facturaloperu`, `tci`, `cavali`) con:
/// - Enrutamiento por [CpeDocumentType] ([SunatCpeRouterConfig.routesByDocumentType]).
/// - Conmutación por error contablemente segura ([SunatCpeRouterConfig.fallbackProvider])
///   restringida estrictamente a [OseTransportException] y [SunatExceptionError].
/// - Rastreo automático del proveedor de origen de cada ticket para [checkTicket] y [pollTicketUntilDone].
final class SunatCpeRouter with TicketPollingMixin implements OseProvider {
  /// Configuración de enrutamiento y contingencia del router.
  final SunatCpeRouterConfig config;

  /// Registro en memoria que asocia los tickets asíncronos emitidos con la
  /// instancia exacta de [OseProvider] que los generó.
  final Map<String, OseProvider> _ticketProviderRegistry = {};

  /// Crea un [SunatCpeRouter] a partir de su configuración [config].
  SunatCpeRouter({required this.config});

  /// Constructor abreviado que recibe instancias de proveedores directamente.
  SunatCpeRouter.simple({
    required OseProvider primaryProvider,
    Map<CpeDocumentType, OseProvider> routesByDocumentType = const {},
    OseProvider? fallbackProvider,
    bool enableFallbackOnSunatExceptions = true,
    bool prefixTicketsWithProviderId = false,
  }) : config = SunatCpeRouterConfig(
         primaryProvider: primaryProvider,
         routesByDocumentType: routesByDocumentType,
         fallbackProvider: fallbackProvider,
         enableFallbackOnSunatExceptions: enableFallbackOnSunatExceptions,
         prefixTicketsWithProviderId: prefixTicketsWithProviderId,
       );

  /// Constructor de fábrica declarativo que construye los proveedores a partir de [SunatProviderDescriptor]s.
  factory SunatCpeRouter.fromDescriptors({
    required SunatProviderDescriptor primaryDescriptor,
    Map<CpeDocumentType, SunatProviderDescriptor>
        routeDescriptorsByDocumentType =
        const {},
    SunatProviderDescriptor? fallbackDescriptor,
    bool enableFallbackOnSunatExceptions = true,
    bool prefixTicketsWithProviderId = false,
  }) {
    final primary = SunatProviderFactory.create(primaryDescriptor);
    final routes = <CpeDocumentType, OseProvider>{
      for (final entry in routeDescriptorsByDocumentType.entries)
        entry.key: SunatProviderFactory.create(entry.value),
    };
    final fallback = fallbackDescriptor != null
        ? SunatProviderFactory.create(fallbackDescriptor)
        : null;

    return SunatCpeRouter(
      config: SunatCpeRouterConfig(
        primaryProvider: primary,
        routesByDocumentType: routes,
        fallbackProvider: fallback,
        enableFallbackOnSunatExceptions: enableFallbackOnSunatExceptions,
        prefixTicketsWithProviderId: prefixTicketsWithProviderId,
      ),
    );
  }

  @override
  String get providerId => 'router(${config.primaryProvider.providerId})';

  @override
  Set<ProviderCapability> get capabilities {
    final merged = <ProviderCapability>{...config.primaryProvider.capabilities};
    for (final provider in config.routesByDocumentType.values) {
      merged.addAll(provider.capabilities);
    }
    if (config.fallbackProvider != null) {
      merged.addAll(config.fallbackProvider!.capabilities);
    }
    return Set.unmodifiable(merged);
  }

  /// Resuelve el [OseProvider] objetivo para un [documentType] determinado.
  OseProvider resolveProviderForDocumentType(CpeDocumentType? documentType) {
    if (documentType != null) {
      final specific = config.routesByDocumentType[documentType];
      if (specific != null) {
        return specific;
      }
    }
    return config.primaryProvider;
  }

  /// Devuelve el proveedor registrado para [ticket], si se encuentra en el registro.
  OseProvider? getRegisteredProviderForTicket(String ticket) =>
      _ticketProviderRegistry[ticket];

  @override
  Future<CpeResult<CpeEmissionResponse>> sendDocument(
    SalesCpeDocument document,
  ) {
    final target = resolveProviderForDocumentType(document.id.type);
    return _executeWithFallback<CpeEmissionResponse>(
      target: target,
      action: (provider) => provider.sendDocument(document),
    );
  }

  @override
  Future<CpeResult<TicketResponse>> sendDailySummary(
    DailySummaryDocument summary,
  ) {
    final target = resolveProviderForDocumentType(
      CpeDocumentType.resumenDiario,
    );
    return _executeTicketOperationWithFallback(
      target: target,
      action: (provider) => provider.sendDailySummary(summary),
    );
  }

  @override
  Future<CpeResult<TicketResponse>> sendVoidedDocument(VoidedDocument voided) {
    final target = resolveProviderForDocumentType(voided.id.type);
    return _executeTicketOperationWithFallback(
      target: target,
      action: (provider) => provider.sendVoidedDocument(voided),
    );
  }

  @override
  Future<CpeResult<TicketResponse>> sendDespatchAdvice(
    DespatchAdviceDocument guide,
  ) {
    final target = resolveProviderForDocumentType(guide.id.type);
    return _executeTicketOperationWithFallback(
      target: target,
      action: (provider) => provider.sendDespatchAdvice(guide),
    );
  }

  @override
  Future<CpeResult<CpeEmissionResponse>> sendRetentionOrPerception(
    AgentCpeDocument document,
  ) {
    final target = resolveProviderForDocumentType(document.id.type);
    return _executeWithFallback<CpeEmissionResponse>(
      target: target,
      action: (provider) => provider.sendRetentionOrPerception(document),
    );
  }

  @override
  Future<CpeResult<TicketStatusResponse>> checkTicket(
    String ticket, {
    DocumentId? referenceId,
    String? providerIdOverride,
  }) {
    final (targetProvider, rawTicket) = _resolveTicketTarget(
      ticket,
      referenceId: referenceId,
      providerIdOverride: providerIdOverride,
    );
    return _executeWithFallback<TicketStatusResponse>(
      target: targetProvider,
      action: (provider) =>
          provider.checkTicket(rawTicket, referenceId: referenceId),
    );
  }

  @override
  Future<CpeResult<CpeStatusQueryResponse>> queryDocumentStatus(
    DocumentStatusQuery query,
  ) {
    final target = resolveProviderForDocumentType(query.documentType);
    return _executeWithFallback<CpeStatusQueryResponse>(
      target: target,
      action: (provider) => provider.queryDocumentStatus(query),
    );
  }

  /// Determina si [error] es seguro para activar el proveedor de contingencia.
  ///
  /// Regla de seguridad contable:
  /// - ÚNICAMENTE [OseTransportException] y (cuando está habilitado) [SunatExceptionError] (`0100–1999`)
  ///   garantizan que el comprobante NO fue registrado por SUNAT ni por el OSE.
  /// - [CpeValidationException], [SunatRejectionException] (`2000–3999`) y
  ///   [OseAuthException] NUNCA activan el proveedor de contingencia.
  bool _shouldTriggerFallback(CpeException error) {
    return switch (error) {
      OseTransportException() => true,
      SunatExceptionError() => config.enableFallbackOnSunatExceptions,
      CpeValidationException() => false,
      SunatRejectionException() => false,
      OseAuthException() => false,
    };
  }

  Future<CpeResult<T>> _executeWithFallback<T>({
    required OseProvider target,
    required Future<CpeResult<T>> Function(OseProvider provider) action,
  }) async {
    final primaryResult = await action(target);

    switch (primaryResult) {
      case CpeSuccess<T>(:final data, :final providerRawMetadata):
        return CpeSuccess<T>(
          data,
          providerRawMetadata: {
            ...providerRawMetadata,
            'routedProviderId': target.providerId,
            'usedFallback': false,
          },
        );

      case CpeFailure<T>(:final error):
        final fallback = config.fallbackProvider;
        if (fallback != null &&
            !identical(fallback, target) &&
            _shouldTriggerFallback(error)) {
          final fallbackResult = await action(fallback);
          return switch (fallbackResult) {
            CpeSuccess<T>(:final data, :final providerRawMetadata) =>
              CpeSuccess<T>(
                data,
                providerRawMetadata: {
                  ...providerRawMetadata,
                  'routedProviderId': fallback.providerId,
                  'usedFallback': true,
                  'primaryProviderId': target.providerId,
                  'primaryFailureCode': error.code,
                },
              ),
            CpeFailure<T>() => fallbackResult,
          };
        }
        return primaryResult;
    }
  }

  Future<CpeResult<TicketResponse>> _executeTicketOperationWithFallback({
    required OseProvider target,
    required Future<CpeResult<TicketResponse>> Function(OseProvider provider)
    action,
  }) async {
    final result = await _executeWithFallback<TicketResponse>(
      target: target,
      action: action,
    );

    if (result case CpeSuccess<TicketResponse>(
      :final data,
      :final providerRawMetadata,
    )) {
      final winningProviderId =
          providerRawMetadata['routedProviderId'] as String?;
      final winningProvider = _findProviderById(winningProviderId) ?? target;

      _ticketProviderRegistry[data.ticket] = winningProvider;

      if (config.prefixTicketsWithProviderId) {
        final prefixedTicket = '${winningProvider.providerId}:${data.ticket}';
        _ticketProviderRegistry[prefixedTicket] = winningProvider;
        return CpeSuccess<TicketResponse>(
          TicketResponse(
            ticket: prefixedTicket,
            referenceId: data.referenceId,
            receivedAt: data.receivedAt,
            signedXmlContent: data.signedXmlContent,
          ),
          providerRawMetadata: providerRawMetadata,
        );
      }
    }

    return result;
  }

  (OseProvider, String) _resolveTicketTarget(
    String ticket, {
    DocumentId? referenceId,
    String? providerIdOverride,
  }) {
    // 1. Check if ticket has an explicit `{providerId}:{rawTicket}` prefix
    final colonIndex = ticket.indexOf(':');
    if (colonIndex > 0) {
      final prefix = ticket.substring(0, colonIndex);
      final rawTicket = ticket.substring(colonIndex + 1);
      final byPrefix = _findProviderById(prefix);
      if (byPrefix != null) {
        return (byPrefix, rawTicket);
      }
    }

    // 2. Check explicit providerIdOverride
    if (providerIdOverride != null) {
      final byOverride = _findProviderById(providerIdOverride);
      if (byOverride != null) {
        return (byOverride, ticket);
      }
    }

    // 3. Check in-memory ticket registry
    final registered = _ticketProviderRegistry[ticket];
    if (registered != null) {
      return (registered, ticket);
    }

    // 4. Fallback to referenceId document type route or primaryProvider
    return (resolveProviderForDocumentType(referenceId?.type), ticket);
  }

  OseProvider? _findProviderById(String? providerId) {
    if (providerId == null) return null;
    if (config.primaryProvider.providerId == providerId) {
      return config.primaryProvider;
    }
    for (final provider in config.routesByDocumentType.values) {
      if (provider.providerId == providerId) {
        return provider;
      }
    }
    if (config.fallbackProvider?.providerId == providerId) {
      return config.fallbackProvider;
    }
    return null;
  }
}
