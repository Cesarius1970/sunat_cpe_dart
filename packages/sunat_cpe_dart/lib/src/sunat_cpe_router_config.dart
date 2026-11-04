import 'package:sunat_cpe_core/sunat_cpe_core.dart';

/// Configuración de políticas de enrutamiento y contingencia para `SunatCpeRouter`.
final class SunatCpeRouterConfig {
  /// Proveedor predeterminado utilizado siempre que un tipo de comprobante no esté
  /// asignado explícitamente en [routesByDocumentType].
  final OseProvider primaryProvider;

  /// Tabla opcional de enrutamiento por tipo de comprobante (p. ej., dirigir Facturas `01`
  /// a un OSE/PSE mientras se envían Guías de Remisión `09`/`31` a `SunatDirectProvider`).
  final Map<CpeDocumentType, OseProvider> routesByDocumentType;

  /// Proveedor opcional de contingencia activado ÚNICAMENTE ante errores de transporte
  /// ([OseTransportException]) o excepciones técnicas de SUNAT/OSE
  /// ([SunatExceptionError], códigos `0100–1999` donde el comprobante NO fue registrado).
  ///
  /// Nunca se activa ante [CpeValidationException] ni [SunatRejectionException] (`2000–3999`).
  final OseProvider? fallbackProvider;

  /// Indica si [SunatExceptionError] (`0100–1999`) debe activar [fallbackProvider]
  /// además de [OseTransportException]. Su valor por defecto es `true`.
  final bool enableFallbackOnSunatExceptions;

  /// Indica si los tickets devueltos en [TicketResponse.ticket] deben llevar el prefijo
  /// `{providerId}:{ticket}` además de registrarse en memoria.
  /// Su valor por defecto es `false`.
  final bool prefixTicketsWithProviderId;

  /// Crea una configuración inmutable para [SunatCpeRouter].
  const SunatCpeRouterConfig({
    required this.primaryProvider,
    this.routesByDocumentType = const {},
    this.fallbackProvider,
    this.enableFallbackOnSunatExceptions = true,
    this.prefixTicketsWithProviderId = false,
  });
}
