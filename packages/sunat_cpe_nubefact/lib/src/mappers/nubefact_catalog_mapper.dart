import 'package:sunat_cpe_core/sunat_cpe_core.dart';

/// Translates official SUNAT Anexo N° 8 catalog enums into Nubefact's proprietary integer codes.
final class NubefactCatalogMapper {
  const NubefactCatalogMapper._();

  /// Translates [CpeDocumentType] to Nubefact `tipo_de_comprobante`:
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
            message: 'Document type ${type.code} is not supported by Nubefact document mapper',
            issues: [
              ValidationIssue(
                field: 'id.type',
                message: 'Unsupported Nubefact document type: ${type.code}',
              ),
            ],
          ),
      };

  /// Translates [CurrencyCode] to Nubefact `moneda`:
  /// - `PEN` -> `1`
  /// - `USD` -> `2`
  /// - `EUR` -> `3`
  static int mapCurrency(CurrencyCode currency) => switch (currency) {
        CurrencyCode.pen => 1,
        CurrencyCode.usd => 2,
        CurrencyCode.eur => 3,
      };

  /// Translates [IdentityDocumentType] to Nubefact `cliente_tipo_de_documento`.
  static String mapIdentityDocumentType(IdentityDocumentType type) => switch (type) {
        IdentityDocumentType.noDomiciliado => '-',
        IdentityDocumentType.dni => '1',
        IdentityDocumentType.carnetExtranjeria => '4',
        IdentityDocumentType.ruc => '6',
        IdentityDocumentType.pasaporte => '7',
        IdentityDocumentType.cedulaDiplomatica => 'A',
        IdentityDocumentType.tam => '0',
      };

  /// Translates [OperationType] (Catálogo 51) to Nubefact `sunat_transaction`.
  static int mapOperationType(OperationType op) => switch (op) {
        OperationType.ventaInterna => 1,
        OperationType.exportacionBienes || OperationType.exportacionServiciosPais => 2,
        OperationType.ventaInternaAnticipos => 4,
        OperationType.operacionSujetaDetraccion => 30,
        OperationType.operacionSujetaDetraccionRecursosHidrobiologicos => 31,
        OperationType.operacionSujetaDetraccionTransportePasajeros => 32,
        OperationType.operacionSujetaDetraccionTransporteCarga => 33,
        OperationType.operacionSujetaPercepcion => 1,
        OperationType.operacionSujetaRetencion => 1,
        OperationType.ventaItinerante => 1,
      };

  /// Translates [IgvAffectationType] (Catálogo 07) to Nubefact `tipo_de_igv` (1..17).
  static int mapIgvAffectation(IgvAffectationType affectation) => switch (affectation) {
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

  /// Translates [CreditNoteReasonCode] (Catálogo 09) to Nubefact `tipo_de_nota_de_credito` (1..13).
  static int mapCreditNoteReason(CreditNoteReasonCode reason) =>
      int.parse(reason.code);

  /// Translates [DebitNoteReasonCode] (Catálogo 10) to Nubefact `tipo_de_nota_de_debito` (1..5).
  static int mapDebitNoteReason(DebitNoteReasonCode reason) => switch (reason) {
        DebitNoteReasonCode.interesesPorMora => 1,
        DebitNoteReasonCode.aumentoEnElValor => 2,
        DebitNoteReasonCode.penalidadesOtrosConceptos => 3,
        DebitNoteReasonCode.ajustesOperacionesExportacion => 4,
        DebitNoteReasonCode.ajustesAfectosIvap => 5,
      };

  /// Formats [DateTime] to Nubefact's preferred `DD-MM-YYYY` format.
  static String formatDate(DateTime date) {
    final d = date.day.toString().padLeft(2, '0');
    final m = date.month.toString().padLeft(2, '0');
    final y = date.year.toString().padLeft(4, '0');
    return '$d-$m-$y';
  }
}
