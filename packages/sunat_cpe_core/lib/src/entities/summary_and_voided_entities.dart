part of 'cpe_entities.dart';

/// Resumen Diario de Boletas de Venta y Notas Electrónicas (RC).
final class DailySummaryDocument extends CpeDocument {
  /// Date when the summarized Boletas/Notes were originally issued (`ReferenceDate`).
  final DateTime referenceDate;
  final List<DailySummaryLine> lines;

  const DailySummaryDocument({
    required super.id,
    required super.issuer,
    required super.issueDate,
    super.issueTime,
    required this.referenceDate,
    required this.lines,
  });
}

/// Individual line inside a `DailySummaryDocument` (`sac:SummaryDocumentsLine`).
final class DailySummaryLine {
  final int lineNumber;
  final CpeDocumentType documentType; // 03, 07, 08
  final String series;
  final int number;
  final SummaryLineStatus status; // 1=Add, 2=Modify, 3=Void
  final IdentityDocumentType? customerDocumentType;
  final String? customerDocumentNumber;
  final DocumentReference?
  affectedDocument; // Required when documentType is 07 or 08
  final CurrencyCode currency;

  final Decimal totalGravadas;
  final Decimal totalExoneradas;
  final Decimal totalInafectas;
  final Decimal totalGratuitas;
  final Decimal totalOtrosCargos;

  final Decimal totalIgv;
  final Decimal totalIsc;
  final Decimal totalIcbper;
  final Decimal totalOtrosTributos;
  final Decimal totalSaleAmount;

  static final Decimal _zero = Decimal.zero;

  DailySummaryLine({
    required this.lineNumber,
    required this.documentType,
    required this.series,
    required this.number,
    required this.status,
    this.customerDocumentType,
    this.customerDocumentNumber,
    this.affectedDocument,
    this.currency = CurrencyCode.pen,
    Decimal? totalGravadas,
    Decimal? totalExoneradas,
    Decimal? totalInafectas,
    Decimal? totalGratuitas,
    Decimal? totalOtrosCargos,
    Decimal? totalIgv,
    Decimal? totalIsc,
    Decimal? totalIcbper,
    Decimal? totalOtrosTributos,
    required this.totalSaleAmount,
  }) : totalGravadas = totalGravadas ?? _zero,
       totalExoneradas = totalExoneradas ?? _zero,
       totalInafectas = totalInafectas ?? _zero,
       totalGratuitas = totalGratuitas ?? _zero,
       totalOtrosCargos = totalOtrosCargos ?? _zero,
       totalIgv = totalIgv ?? _zero,
       totalIsc = totalIsc ?? _zero,
       totalIcbper = totalIcbper ?? _zero,
       totalOtrosTributos = totalOtrosTributos ?? _zero;
}

/// Comunicación de Baja (RA) o Resumen de Reversiones (RR).
final class VoidedDocument extends CpeDocument {
  /// Date when the voided documents were originally issued (`ReferenceDate`).
  final DateTime referenceDate;
  final List<VoidedLine> lines;

  const VoidedDocument({
    required super.id,
    required super.issuer,
    required super.issueDate,
    super.issueTime,
    required this.referenceDate,
    required this.lines,
  });
}

/// Line item inside a `VoidedDocument` (`sac:VoidedDocumentsLine`).
final class VoidedLine {
  final int lineNumber;
  final CpeDocumentType documentType;
  final String series;
  final int number;
  final String voidReason;

  const VoidedLine({
    required this.lineNumber,
    required this.documentType,
    required this.series,
    required this.number,
    required this.voidReason,
  });
}
