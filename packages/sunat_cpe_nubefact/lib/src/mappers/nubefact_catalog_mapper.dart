import 'package:sunat_cpe_core/sunat_cpe_core.dart';

/// Traduce los catálogos oficiales del Anexo N° 8 de SUNAT a los códigos enteros propietarios de Nubefact.
final class NubefactCatalogMapper {
  const NubefactCatalogMapper._();

  /// Traduce [CpeDocumentType] al campo `tipo_de_comprobante` de Nubefact:
  /// - `01` Factura -> `1`
  /// - `03` Boleta -> `2`
  /// - `07` Nota de Crédito -> `3`
  /// - `08` Nota de Débito -> `4`
  /// - `09` Guía de Remisión Remitente -> `7`
  /// - `31` Guía de Remisión Transportista -> `8`
  static int mapDocumentType(CpeDocumentType type) => switch (type) {
    CpeDocumentType.factura => 1,
    CpeDocumentType.boleta => 2,
    CpeDocumentType.notaCredito => 3,
    CpeDocumentType.notaDebito => 4,
    CpeDocumentType.guiaRemisionRemitente => 7,
    CpeDocumentType.guiaRemisionTransportista => 8,
    _ => throw CpeValidationException(
      message:
          'Document type ${type.code} is not supported by Nubefact document mapper',
      issues: [
        ValidationIssue(
          field: 'id.type',
          message: 'Unsupported Nubefact document type: ${type.code}',
        ),
      ],
    ),
  };

  /// Traduce [CurrencyCode] al campo `moneda` de Nubefact:
  /// - `PEN` -> `1`
  /// - `USD` -> `2`
  /// - `EUR` -> `3`
  static int mapCurrency(CurrencyCode currency) => switch (currency) {
    CurrencyCode.pen => 1,
    CurrencyCode.usd => 2,
    CurrencyCode.eur => 3,
  };

  /// Traduce [IdentityDocumentType] al campo `cliente_tipo_de_documento` de Nubefact.
  static String mapIdentityDocumentType(IdentityDocumentType type) =>
      switch (type) {
        IdentityDocumentType.noDomiciliado => '-',
        IdentityDocumentType.dni => '1',
        IdentityDocumentType.carnetExtranjeria => '4',
        IdentityDocumentType.ruc => '6',
        IdentityDocumentType.pasaporte => '7',
        IdentityDocumentType.cedulaDiplomatica => 'A',
        IdentityDocumentType.tam => '0',
      };

  /// Traduce [OperationType] (Catálogo 51) al campo `sunat_transaction` de Nubefact.
  static int mapOperationType(OperationType op) => switch (op) {
    OperationType.ventaInterna => 1,
    OperationType.exportacionBienes ||
    OperationType.exportacionServiciosPais => 2,
    OperationType.ventaInternaAnticipos => 4,
    OperationType.operacionSujetaDetraccion => 30,
    OperationType.operacionSujetaDetraccionRecursosHidrobiologicos => 31,
    OperationType.operacionSujetaDetraccionTransportePasajeros => 32,
    OperationType.operacionSujetaDetraccionTransporteCarga => 33,
    OperationType.operacionSujetaPercepcion => 1,
    OperationType.operacionSujetaRetencion => 1,
    OperationType.ventaItinerante => 1,
  };

  /// Traduce [IgvAffectationType] (Catálogo 07) al campo `tipo_de_igv` de Nubefact (`1..17`).
  static int mapIgvAffectation(IgvAffectationType affectation) =>
      switch (affectation) {
        IgvAffectationType.gravadoOperacionOnerosa => 1,
        IgvAffectationType.gravadoRetiroPremio => 2,
        IgvAffectationType.gravadoRetiroDonacion => 3,
        IgvAffectationType.gravadoRetiro => 4,
        IgvAffectationType.gravadoRetiroPublicidad => 5,
        IgvAffectationType.gravadoBonificaciones => 6,
        IgvAffectationType.gravadoRetiroEntregaTrabajadores => 7,
        IgvAffectationType.exoneradoOperacionOnerosa => 8,
        IgvAffectationType.inafectoOperacionOnerosa => 9,
        IgvAffectationType.inafectoRetiroBonificacion => 10,
        IgvAffectationType.inafectoRetiro => 11,
        IgvAffectationType.inafectoRetiroMuestrasMedicas => 12,
        IgvAffectationType.inafectoRetiroConvenioColectivo => 13,
        IgvAffectationType.inafectoRetiroPremio => 14,
        IgvAffectationType.inafectoRetiroPublicidad => 15,
        IgvAffectationType.exportacion => 16,
        IgvAffectationType.exoneradoTransferenciaGratuita => 17,
        IgvAffectationType.gravadoIvap => 17,
      };

  /// Traduce [CreditNoteReasonCode] (Catálogo 09) al campo `tipo_de_nota_de_credito` de Nubefact (`1..13`).
  static int mapCreditNoteReason(CreditNoteReasonCode reason) =>
      int.parse(reason.code);

  /// Traduce [DebitNoteReasonCode] (Catálogo 10) al campo `tipo_de_nota_de_debito` de Nubefact (`1..5`).
  static int mapDebitNoteReason(DebitNoteReasonCode reason) => switch (reason) {
    DebitNoteReasonCode.interesesPorMora => 1,
    DebitNoteReasonCode.aumentoEnElValor => 2,
    DebitNoteReasonCode.penalidadesOtrosConceptos => 3,
    DebitNoteReasonCode.ajustesOperacionesExportacion => 4,
    DebitNoteReasonCode.ajustesAfectosIvap => 5,
  };

  /// Formatea un [DateTime] al formato `DD-MM-YYYY` requerido por Nubefact.
  static String formatDate(DateTime date) {
    final d = date.day.toString().padLeft(2, '0');
    final m = date.month.toString().padLeft(2, '0');
    final y = date.year.toString().padLeft(4, '0');
    return '$d-$m-$y';
  }
}
