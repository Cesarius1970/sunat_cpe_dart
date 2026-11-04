part of 'cpe_entities.dart';

/// Clase base sellada para comprobantes de venta (01 Factura, 03 Boleta, 04 Liquidación, 07 NC, 08 ND).
sealed class SalesCpeDocument extends CpeDocument {
  final CustomerParty customer;
  final CurrencyCode currency;
  final Decimal? exchangeRate;
  final DateTime? dueDate;
  final MonetaryTotals totals;
  final List<CpeLineItem> items;
  final List<DocumentReference> relatedGuides;
  final String? purchaseOrder;
  final List<String> observations;

  const SalesCpeDocument({
    required super.id,
    required super.issuer,
    required super.issueDate,
    super.issueTime,
    required this.customer,
    required this.currency,
    this.exchangeRate,
    this.dueDate,
    required this.totals,
    required this.items,
    this.relatedGuides = const [],
    this.purchaseOrder,
    this.observations = const [],
  });
}

/// Factura Electrónica (01) y Boleta de Venta Electrónica (03).
final class InvoiceDocument extends SalesCpeDocument {
  final OperationType operationType;
  final PaymentTerms paymentTerms;
  final DetractionInfo? detraction;
  final RetentionSummary? retention;
  final PerceptionSummary? perception;
  final List<PrepaidPayment> advances;

  const InvoiceDocument({
    required super.id,
    required super.issuer,
    required super.issueDate,
    super.issueTime,
    required super.customer,
    required super.currency,
    super.exchangeRate,
    super.dueDate,
    required super.totals,
    required super.items,
    super.relatedGuides,
    super.purchaseOrder,
    super.observations,
    this.operationType = OperationType.ventaInterna,
    this.paymentTerms = const CashPaymentTerms(),
    this.detraction,
    this.retention,
    this.perception,
    this.advances = const [],
  });
}

/// Nota de Crédito Electrónica (07).
final class CreditNoteDocument extends SalesCpeDocument {
  final CreditNoteReasonCode reasonCode;
  final String reasonDescription;
  final DocumentReference affectedDocument;
  final PaymentTerms? updatedPaymentTerms;

  const CreditNoteDocument({
    required super.id,
    required super.issuer,
    required super.issueDate,
    super.issueTime,
    required super.customer,
    required super.currency,
    super.exchangeRate,
    super.dueDate,
    required super.totals,
    required super.items,
    super.relatedGuides,
    super.purchaseOrder,
    super.observations,
    required this.reasonCode,
    required this.reasonDescription,
    required this.affectedDocument,
    this.updatedPaymentTerms,
  });
}

/// Nota de Débito Electrónica (08).
final class DebitNoteDocument extends SalesCpeDocument {
  final DebitNoteReasonCode reasonCode;
  final String reasonDescription;
  final DocumentReference affectedDocument;

  const DebitNoteDocument({
    required super.id,
    required super.issuer,
    required super.issueDate,
    super.issueTime,
    required super.customer,
    required super.currency,
    super.exchangeRate,
    super.dueDate,
    required super.totals,
    required super.items,
    super.relatedGuides,
    super.purchaseOrder,
    super.observations,
    required this.reasonCode,
    required this.reasonDescription,
    required this.affectedDocument,
  });
}

/// Liquidación de Compra Electrónica (04).
final class PurchaseSettlementDocument extends SalesCpeDocument {
  final Address operationLocation;

  const PurchaseSettlementDocument({
    required super.id,
    required super.issuer,
    required super.issueDate,
    super.issueTime,
    required super.customer,
    required super.currency,
    super.exchangeRate,
    super.dueDate,
    required super.totals,
    required super.items,
    super.relatedGuides,
    super.purchaseOrder,
    super.observations,
    required this.operationLocation,
  });
}

/// Totales monetarios de traspaso directo (strict passthrough) para comprobantes de venta UBL 2.1.
final class MonetaryTotals {
  final Decimal totalGravadas;
  final Decimal totalExoneradas;
  final Decimal totalInafectas;
  final Decimal totalExportacion;
  final Decimal totalGratuitas;
  final Decimal totalIvapBase;

  final Decimal totalIgv;
  final Decimal totalIvap;
  final Decimal totalIsc;
  final Decimal totalIcbper;
  final Decimal totalOtrosTributos;
  final Decimal totalImpuestosGratuitas;

  final Decimal totalDescuentosLinea;
  final Decimal descuentoGlobalAfectaBase;
  final Decimal descuentoGlobalNoAfectaBase;
  final Decimal totalOtrosCargos;
  final Decimal totalAnticipos;
  final Decimal redondeo;

  final Decimal totalValorVenta;
  final Decimal totalImpuestos;
  final Decimal totalPrecioVenta;
  final Decimal importeTotalPagar;
  final String? amountInWords;

  static final Decimal _zero = Decimal.zero;

  MonetaryTotals({
    Decimal? totalGravadas,
    Decimal? totalExoneradas,
    Decimal? totalInafectas,
    Decimal? totalExportacion,
    Decimal? totalGratuitas,
    Decimal? totalIvapBase,
    Decimal? totalIgv,
    Decimal? totalIvap,
    Decimal? totalIsc,
    Decimal? totalIcbper,
    Decimal? totalOtrosTributos,
    Decimal? totalImpuestosGratuitas,
    Decimal? totalDescuentosLinea,
    Decimal? descuentoGlobalAfectaBase,
    Decimal? descuentoGlobalNoAfectaBase,
    Decimal? totalOtrosCargos,
    Decimal? totalAnticipos,
    Decimal? redondeo,
    required this.totalValorVenta,
    required this.totalImpuestos,
    required this.totalPrecioVenta,
    required this.importeTotalPagar,
    this.amountInWords,
  }) : totalGravadas = totalGravadas ?? _zero,
       totalExoneradas = totalExoneradas ?? _zero,
       totalInafectas = totalInafectas ?? _zero,
       totalExportacion = totalExportacion ?? _zero,
       totalGratuitas = totalGratuitas ?? _zero,
       totalIvapBase = totalIvapBase ?? _zero,
       totalIgv = totalIgv ?? _zero,
       totalIvap = totalIvap ?? _zero,
       totalIsc = totalIsc ?? _zero,
       totalIcbper = totalIcbper ?? _zero,
       totalOtrosTributos = totalOtrosTributos ?? _zero,
       totalImpuestosGratuitas = totalImpuestosGratuitas ?? _zero,
       totalDescuentosLinea = totalDescuentosLinea ?? _zero,
       descuentoGlobalAfectaBase = descuentoGlobalAfectaBase ?? _zero,
       descuentoGlobalNoAfectaBase = descuentoGlobalNoAfectaBase ?? _zero,
       totalOtrosCargos = totalOtrosCargos ?? _zero,
       totalAnticipos = totalAnticipos ?? _zero,
       redondeo = redondeo ?? _zero;
}

/// Ítem de detalle de traspaso directo (strict passthrough) para comprobantes de venta UBL 2.1.
final class CpeLineItem {
  final int lineNumber;
  final String? internalCode;
  final String? sunatProductCode;
  final String? gtinCode;
  final String unitCode;
  final String description;
  final Decimal quantity;

  final Decimal unitValue;
  final Decimal unitPrice;
  final bool isReferencePrice;

  final Decimal lineExtensionAmount;
  final Decimal taxableBaseAmount;

  final IgvAffectationType igvAffectation;
  final Decimal igvPercentage;
  final Decimal igvAmount;

  final String? iscSystemCode;
  final Decimal? iscPercentage;
  final Decimal? iscAmount;

  final int? icbperQuantity;
  final Decimal? icbperUnitTax;
  final Decimal? icbperAmount;

  final AllowanceCharge? discount;
  final AllowanceCharge? charge;

  final Decimal totalLineTaxAmount;
  final Decimal totalLineAmount;

  const CpeLineItem({
    required this.lineNumber,
    this.internalCode,
    this.sunatProductCode,
    this.gtinCode,
    this.unitCode = 'NIU',
    required this.description,
    required this.quantity,
    required this.unitValue,
    required this.unitPrice,
    this.isReferencePrice = false,
    required this.lineExtensionAmount,
    required this.taxableBaseAmount,
    this.igvAffectation = IgvAffectationType.gravadoOperacionOnerosa,
    required this.igvPercentage,
    required this.igvAmount,
    this.iscSystemCode,
    this.iscPercentage,
    this.iscAmount,
    this.icbperQuantity,
    this.icbperUnitTax,
    this.icbperAmount,
    this.discount,
    this.charge,
    required this.totalLineTaxAmount,
    required this.totalLineAmount,
  });
}

/// Condiciones de pago de la operación (Contado vs Crédito según RS 000193-2020/SUNAT).
sealed class PaymentTerms {
  const PaymentTerms();
}

final class CashPaymentTerms extends PaymentTerms {
  const CashPaymentTerms();
}

final class CreditPaymentTerms extends PaymentTerms {
  final Decimal netPendingAmount;
  final List<PaymentInstallment> installments;

  const CreditPaymentTerms({
    required this.netPendingAmount,
    required this.installments,
  });
}

final class PaymentInstallment {
  final int number;
  final Decimal amount;
  final DateTime dueDate;

  const PaymentInstallment({
    required this.number,
    required this.amount,
    required this.dueDate,
  });

  String get formattedQuotaId => 'Cuota${number.toString().padLeft(3, '0')}';
}

/// Información de detracción SPOT (Catálogos 54 y 59).
final class DetractionInfo {
  final String code;
  final String paymentMethodCode;
  final String bankAccountNumber;
  final Decimal percentage;
  final Decimal amountInPen;
  final Decimal? amountInDocumentCurrency;

  const DetractionInfo({
    required this.code,
    this.paymentMethodCode = '001',
    required this.bankAccountNumber,
    required this.percentage,
    required this.amountInPen,
    this.amountInDocumentCurrency,
  });
}

/// Resumen de Retención del IGV dentro de una Factura (Código '62').
final class RetentionSummary {
  final Decimal baseAmount;
  final Decimal percentage;
  final Decimal amount;

  const RetentionSummary({
    required this.baseAmount,
    required this.percentage,
    required this.amount,
  });
}

/// Resumen de Percepción dentro de una Factura o Boleta.
final class PerceptionSummary {
  final String regimeCode;
  final Decimal baseAmount;
  final Decimal percentage;
  final Decimal amount;
  final Decimal totalWithPerception;

  const PerceptionSummary({
    this.regimeCode = '51',
    required this.baseAmount,
    required this.percentage,
    required this.amount,
    required this.totalWithPerception,
  });
}

/// Deducción por pago anticipado (Anticipo).
final class PrepaidPayment {
  final CpeDocumentType documentType;
  final String seriesAndNumber;
  final String issuerRuc;
  final Decimal prepaidAmount;
  final DateTime? paymentDate;

  const PrepaidPayment({
    required this.documentType,
    required this.seriesAndNumber,
    required this.issuerRuc,
    required this.prepaidAmount,
    this.paymentDate,
  });
}
