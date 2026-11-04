import 'package:decimal/decimal.dart';

import '../catalogs/sunat_catalogs.dart';
import '../entities/cpe_entities.dart';
import '../results/cpe_result.dart';

/// Validador de reglas matemáticas y de negocio de traspaso directo (strict passthrough) para CPE SUNAT.
///
/// No muta ni recalcula montos faltantes; verifica que los importes proporcionados por el llamador
/// cumplan las ecuaciones UBL 2.1 de SUNAT dentro de las tolerancias de redondeo permitidas.
final class CpeMathValidator {
  /// Tolerancia predeterminada para sumatorias directas (subtotales de línea hacia totales de cabecera).
  final Decimal sumTolerance;

  /// Tolerancia predeterminada para cálculos de impuestos porcentuales (SUNAT permite hasta ±1.00 por línea).
  final Decimal taxCalculationTolerance;

  static final Decimal _hundred = Decimal.fromInt(100);
  static final RegExp _rucRegex = RegExp(r'^(10|15|17|20)\d{9}$');

  CpeMathValidator({Decimal? sumTolerance, Decimal? taxCalculationTolerance})
    : sumTolerance = sumTolerance ?? Decimal.parse('0.02'),
      taxCalculationTolerance =
          taxCalculationTolerance ?? Decimal.parse('1.00');

  /// Valida cualquier [CpeDocument] y retorna un [CpeResult<void>].
  CpeResult<void> validate(CpeDocument document) {
    final issues = <ValidationIssue>[];

    if (!_rucRegex.hasMatch(document.issuer.ruc)) {
      issues.add(
        ValidationIssue(
          field: 'issuer.ruc',
          message: 'Invalid 11-digit SUNAT RUC: ${document.issuer.ruc}',
        ),
      );
    }

    if (document.id.issuerRuc != document.issuer.ruc) {
      issues.add(
        ValidationIssue(
          field: 'id.issuerRuc',
          message:
              'DocumentId RUC (${document.id.issuerRuc}) does not match issuer RUC (${document.issuer.ruc})',
        ),
      );
    }

    if (document.id.number <= 0) {
      issues.add(
        ValidationIssue(
          field: 'id.number',
          message: 'Correlative number must be positive: ${document.id.number}',
        ),
      );
    }

    switch (document) {
      case SalesCpeDocument():
        _validateSalesDocument(document, issues);
      case DailySummaryDocument():
        _validateDailySummary(document, issues);
      case VoidedDocument():
        _validateVoidedDocument(document, issues);
      case DespatchAdviceDocument():
        _validateDespatchAdvice(document, issues);
      case AgentCpeDocument():
        _validateAgentDocument(document, issues);
    }

    if (issues.isNotEmpty) {
      return CpeFailure(
        CpeValidationException(
          message:
              'Document ${document.id.fileNameBase} failed validation (${issues.length} issues)',
          issues: List.unmodifiable(issues),
        ),
      );
    }
    return const CpeSuccess(null);
  }

  void _validateSalesDocument(
    SalesCpeDocument doc,
    List<ValidationIssue> issues,
  ) {
    if (doc.items.isEmpty) {
      issues.add(
        const ValidationIssue(
          field: 'items',
          message: 'Sales document must contain at least 1 line item',
        ),
      );
      return;
    }

    if (doc.id.type == CpeDocumentType.factura &&
        doc.customer.documentType != IdentityDocumentType.ruc &&
        doc is InvoiceDocument &&
        doc.operationType != OperationType.exportacionBienes &&
        doc.operationType != OperationType.exportacionServiciosPais) {
      issues.add(
        const ValidationIssue(
          field: 'customer.documentType',
          message: 'Domestic Factura (01) requires customer IdentityDocumentType.ruc (6)',
        ),
      );
    }

    var sumGravadas = Decimal.zero;
    var sumExoneradas = Decimal.zero;
    var sumInafectas = Decimal.zero;
    var sumExportacion = Decimal.zero;
    var sumGratuitas = Decimal.zero;
    var sumIvapBase = Decimal.zero;

    var sumIgv = Decimal.zero;
    var sumIvap = Decimal.zero;
    var sumIsc = Decimal.zero;
    var sumIcbper = Decimal.zero;
    var sumFreeTaxes = Decimal.zero;

    for (final item in doc.items) {
      _validateLineItem(item, issues);

      final affectation = item.igvAffectation;
      if (affectation.isFree) {
        sumGratuitas += item.lineExtensionAmount;
        sumFreeTaxes += item.igvAmount;
      } else if (affectation.isGravadoOneroso) {
        sumGravadas += item.lineExtensionAmount;
        sumIgv += item.igvAmount;
      } else if (affectation.isIvap) {
        sumIvapBase += item.lineExtensionAmount;
        sumIvap += item.igvAmount;
      } else if (affectation.isExoneradoOneroso) {
        sumExoneradas += item.lineExtensionAmount;
      } else if (affectation.isInafectoOneroso) {
        sumInafectas += item.lineExtensionAmount;
      } else if (affectation.isExportacion) {
        sumExportacion += item.lineExtensionAmount;
      }

      if (item.iscAmount != null) {
        sumIsc += item.iscAmount!;
      }
      if (item.icbperAmount != null) {
        sumIcbper += item.icbperAmount!;
      }
    }

    final totals = doc.totals;

    // Expected gravadas considering global base-reducing discounts and advances
    final expectedGravadas =
        sumGravadas - totals.descuentoGlobalAfectaBase - totals.totalAnticipos;
    if (sumGravadas > Decimal.zero &&
        !_withinTolerance(
          totals.totalGravadas,
          expectedGravadas,
          sumTolerance,
        )) {
      issues.add(
        ValidationIssue(
          field: 'totals.totalGravadas',
          message:
              'Expected $expectedGravadas from line sum ($sumGravadas) minus global discounts/advances, but got ${totals.totalGravadas}',
        ),
      );
    }

    if (!_withinTolerance(
      totals.totalExoneradas,
      sumExoneradas,
      sumTolerance,
    )) {
      issues.add(
        ValidationIssue(
          field: 'totals.totalExoneradas',
          message:
              'Expected $sumExoneradas from line items, but got ${totals.totalExoneradas}',
        ),
      );
    }

    if (!_withinTolerance(totals.totalInafectas, sumInafectas, sumTolerance)) {
      issues.add(
        ValidationIssue(
          field: 'totals.totalInafectas',
          message:
              'Expected $sumInafectas from line items, but got ${totals.totalInafectas}',
        ),
      );
    }

    if (!_withinTolerance(
      totals.totalExportacion,
      sumExportacion,
      sumTolerance,
    )) {
      issues.add(
        ValidationIssue(
          field: 'totals.totalExportacion',
          message:
              'Expected $sumExportacion from line items, but got ${totals.totalExportacion}',
        ),
      );
    }

    if (!_withinTolerance(totals.totalGratuitas, sumGratuitas, sumTolerance)) {
      issues.add(
        ValidationIssue(
          field: 'totals.totalGratuitas',
          message:
              'Expected $sumGratuitas from free line items, but got ${totals.totalGratuitas}',
        ),
      );
    }

    if (!_withinTolerance(totals.totalIvapBase, sumIvapBase, sumTolerance)) {
      issues.add(
        ValidationIssue(
          field: 'totals.totalIvapBase',
          message:
              'Expected $sumIvapBase from IVAP line items, but got ${totals.totalIvapBase}',
        ),
      );
    }

    if (!_withinTolerance(totals.totalIvap, sumIvap, sumTolerance)) {
      issues.add(
        ValidationIssue(
          field: 'totals.totalIvap',
          message:
              'Expected $sumIvap from IVAP line items, but got ${totals.totalIvap}',
        ),
      );
    }

    if (!_withinTolerance(totals.totalIsc, sumIsc, sumTolerance)) {
      issues.add(
        ValidationIssue(
          field: 'totals.totalIsc',
          message:
              'Expected $sumIsc from line items, but got ${totals.totalIsc}',
        ),
      );
    }

    if (!_withinTolerance(totals.totalIcbper, sumIcbper, sumTolerance)) {
      issues.add(
        ValidationIssue(
          field: 'totals.totalIcbper',
          message:
              'Expected $sumIcbper from line items, but got ${totals.totalIcbper}',
        ),
      );
    }

    if (totals.descuentoGlobalAfectaBase == Decimal.zero &&
        totals.totalAnticipos == Decimal.zero &&
        !_withinTolerance(totals.totalIgv, sumIgv, sumTolerance)) {
      issues.add(
        ValidationIssue(
          field: 'totals.totalIgv',
          message:
              'Expected $sumIgv from line items, but got ${totals.totalIgv}',
        ),
      );
    }

    if (!_withinTolerance(
      totals.totalImpuestosGratuitas,
      sumFreeTaxes,
      sumTolerance,
    )) {
      issues.add(
        ValidationIssue(
          field: 'totals.totalImpuestosGratuitas',
          message:
              'Expected $sumFreeTaxes from free items IGV, but got ${totals.totalImpuestosGratuitas}',
        ),
      );
    }

    // Header total equations
    final expectedValorVenta =
        totals.totalGravadas +
        totals.totalExoneradas +
        totals.totalInafectas +
        totals.totalExportacion +
        totals.totalIvapBase;
    if (!_withinTolerance(
      totals.totalValorVenta,
      expectedValorVenta,
      sumTolerance,
    )) {
      issues.add(
        ValidationIssue(
          field: 'totals.totalValorVenta',
          message:
              'totalValorVenta (${totals.totalValorVenta}) must equal sum of bases ($expectedValorVenta)',
        ),
      );
    }

    final expectedTotalImpuestos =
        totals.totalIgv +
        totals.totalIvap +
        totals.totalIsc +
        totals.totalIcbper +
        totals.totalOtrosTributos;
    if (!_withinTolerance(
      totals.totalImpuestos,
      expectedTotalImpuestos,
      sumTolerance,
    )) {
      issues.add(
        ValidationIssue(
          field: 'totals.totalImpuestos',
          message:
              'totalImpuestos (${totals.totalImpuestos}) must equal IGV+IVAP+ISC+ICBPER+Otros ($expectedTotalImpuestos)',
        ),
      );
    }

    final expectedPrecioVenta = totals.totalValorVenta + totals.totalImpuestos;
    if (!_withinTolerance(
      totals.totalPrecioVenta,
      expectedPrecioVenta,
      sumTolerance,
    )) {
      issues.add(
        ValidationIssue(
          field: 'totals.totalPrecioVenta',
          message:
              'totalPrecioVenta (${totals.totalPrecioVenta}) must equal totalValorVenta + totalImpuestos ($expectedPrecioVenta)',
        ),
      );
    }

    final expectedPayable =
        totals.totalPrecioVenta -
        totals.descuentoGlobalNoAfectaBase +
        totals.totalOtrosCargos -
        totals.totalAnticipos +
        totals.redondeo;
    if (!_withinTolerance(
      totals.importeTotalPagar,
      expectedPayable,
      sumTolerance,
    )) {
      issues.add(
        ValidationIssue(
          field: 'totals.importeTotalPagar',
          message:
              'importeTotalPagar (${totals.importeTotalPagar}) does not match expected payable ($expectedPayable)',
        ),
      );
    }

    if (doc is InvoiceDocument) {
      _validatePaymentTerms(doc, issues);
    }
  }

  void _validateLineItem(CpeLineItem item, List<ValidationIssue> issues) {
    if (item.quantity <= Decimal.zero) {
      issues.add(
        ValidationIssue(
          field: 'quantity',
          lineNumber: item.lineNumber,
          message: 'Quantity must be greater than zero',
        ),
      );
    }

    final discountAmount = item.discount?.amount ?? Decimal.zero;

    if (item.igvAffectation.isFree) {
      if (!item.isReferencePrice) {
        issues.add(
          ValidationIssue(
            field: 'isReferencePrice',
            lineNumber: item.lineNumber,
            message:
                'Free item (${item.igvAffectation.code}) must have isReferencePrice = true',
          ),
        );
      }
      if (item.unitValue != Decimal.zero) {
        issues.add(
          ValidationIssue(
            field: 'unitValue',
            lineNumber: item.lineNumber,
            message: 'Free item must have unitValue == 0.00',
          ),
        );
      }
      final expectedRefExtension =
          (item.quantity * item.unitPrice) - discountAmount;
      if (!_withinTolerance(
        item.lineExtensionAmount,
        expectedRefExtension,
        sumTolerance,
      )) {
        issues.add(
          ValidationIssue(
            field: 'lineExtensionAmount',
            lineNumber: item.lineNumber,
            message:
                'Free item lineExtensionAmount (${item.lineExtensionAmount}) does not match quantity * unitPrice ($expectedRefExtension)',
          ),
        );
      }
      return;
    }

    // Onerous operation
    final expectedExtension = (item.quantity * item.unitValue) - discountAmount;
    if (!_withinTolerance(
      item.lineExtensionAmount,
      expectedExtension,
      sumTolerance,
    )) {
      issues.add(
        ValidationIssue(
          field: 'lineExtensionAmount',
          lineNumber: item.lineNumber,
          message:
              'lineExtensionAmount (${item.lineExtensionAmount}) does not match (quantity * unitValue) - discount ($expectedExtension)',
        ),
      );
    }

    final isc = item.iscAmount ?? Decimal.zero;
    final icbper = item.icbperAmount ?? Decimal.zero;

    if (item.icbperQuantity != null && item.icbperUnitTax != null) {
      final expectedIcbper =
          Decimal.fromInt(item.icbperQuantity!) * item.icbperUnitTax!;
      if (!_withinTolerance(icbper, expectedIcbper, sumTolerance)) {
        issues.add(
          ValidationIssue(
            field: 'icbperAmount',
            lineNumber: item.lineNumber,
            message:
                'icbperAmount ($icbper) does not match quantity * unitTax ($expectedIcbper)',
          ),
        );
      }
    }

    if (item.igvAffectation.isGravadoOneroso || item.igvAffectation.isIvap) {
      final igvRate = (item.igvPercentage / _hundred).toDecimal(
        scaleOnInfinitePrecision: 10,
      );
      final expectedIgv = (item.taxableBaseAmount + isc) * igvRate;
      if (!_withinTolerance(
        item.igvAmount,
        expectedIgv,
        taxCalculationTolerance,
      )) {
        issues.add(
          ValidationIssue(
            field: 'igvAmount',
            lineNumber: item.lineNumber,
            message:
                'igvAmount (${item.igvAmount}) deviates from expected base * rate ($expectedIgv) beyond tolerance',
          ),
        );
      }
    } else {
      if (item.igvAmount != Decimal.zero) {
        issues.add(
          ValidationIssue(
            field: 'igvAmount',
            lineNumber: item.lineNumber,
            message:
                'Exempt/Unaffected/Export item (${item.igvAffectation.code}) must have igvAmount == 0.00',
          ),
        );
      }
    }

    final expectedLineTaxes = item.igvAmount + isc + icbper;
    if (!_withinTolerance(
      item.totalLineTaxAmount,
      expectedLineTaxes,
      sumTolerance,
    )) {
      issues.add(
        ValidationIssue(
          field: 'totalLineTaxAmount',
          lineNumber: item.lineNumber,
          message:
              'totalLineTaxAmount (${item.totalLineTaxAmount}) must equal igv + isc + icbper ($expectedLineTaxes)',
        ),
      );
    }

    final expectedTotalLine = item.lineExtensionAmount + expectedLineTaxes;
    if (!_withinTolerance(
      item.totalLineAmount,
      expectedTotalLine,
      sumTolerance,
    )) {
      issues.add(
        ValidationIssue(
          field: 'totalLineAmount',
          lineNumber: item.lineNumber,
          message:
              'totalLineAmount (${item.totalLineAmount}) must equal lineExtensionAmount + totalLineTaxAmount ($expectedTotalLine)',
        ),
      );
    }
  }

  void _validatePaymentTerms(
    InvoiceDocument doc,
    List<ValidationIssue> issues,
  ) {
    final terms = doc.paymentTerms;
    if (terms is CreditPaymentTerms) {
      if (terms.installments.isEmpty) {
        issues.add(
          const ValidationIssue(
            field: 'paymentTerms.installments',
            message: 'Credit payment terms require at least 1 installment (Cuota001)',
          ),
        );
        return;
      }

      var installmentSum = Decimal.zero;
      for (final quota in terms.installments) {
        installmentSum += quota.amount;
      }

      if (!_withinTolerance(
        installmentSum,
        terms.netPendingAmount,
        sumTolerance,
      )) {
        issues.add(
          ValidationIssue(
            field: 'paymentTerms.netPendingAmount',
            message:
                'Sum of credit installments ($installmentSum) must equal netPendingAmount (${terms.netPendingAmount})',
          ),
        );
      }

      final detractionDeduction = doc.detraction != null
          ? (doc.detraction!.amountInDocumentCurrency ??
                (doc.currency == CurrencyCode.pen
                    ? doc.detraction!.amountInPen
                    : Decimal.zero))
          : Decimal.zero;
      final retentionDeduction = doc.retention?.amount ?? Decimal.zero;

      if (detractionDeduction > Decimal.zero ||
          retentionDeduction > Decimal.zero) {
        final expectedNetPending =
            doc.totals.importeTotalPagar -
            detractionDeduction -
            retentionDeduction;
        if (expectedNetPending > Decimal.zero &&
            !_withinTolerance(
              terms.netPendingAmount,
              expectedNetPending,
              taxCalculationTolerance,
            )) {
          issues.add(
            ValidationIssue(
              field: 'paymentTerms.netPendingAmount',
              message:
                  'Per SUNAT RS 000193-2020, netPendingAmount (${terms.netPendingAmount}) must deduct detraction ($detractionDeduction) and retention ($retentionDeduction) from importeTotalPagar (${doc.totals.importeTotalPagar})',
            ),
          );
        }
      }
    }
  }

  void _validateDailySummary(
    DailySummaryDocument doc,
    List<ValidationIssue> issues,
  ) {
    if (doc.lines.isEmpty) {
      issues.add(
        const ValidationIssue(
          field: 'lines',
          message: 'DailySummaryDocument must contain at least 1 line',
        ),
      );
    }
  }

  void _validateVoidedDocument(
    VoidedDocument doc,
    List<ValidationIssue> issues,
  ) {
    if (doc.lines.isEmpty) {
      issues.add(
        const ValidationIssue(
          field: 'lines',
          message: 'VoidedDocument must contain at least 1 voided line',
        ),
      );
    }
    for (final line in doc.lines) {
      if (line.voidReason.trim().length < 3) {
        issues.add(
          ValidationIssue(
            field: 'voidReason',
            lineNumber: line.lineNumber,
            message: 'Void reason must be at least 3 characters',
          ),
        );
      }
    }
  }

  void _validateDespatchAdvice(
    DespatchAdviceDocument doc,
    List<ValidationIssue> issues,
  ) {
    if (doc.items.isEmpty) {
      issues.add(
        const ValidationIssue(
          field: 'items',
          message: 'DespatchAdviceDocument must contain at least 1 item',
        ),
      );
    }
    if (doc.grossWeight <= Decimal.zero) {
      issues.add(
        const ValidationIssue(
          field: 'grossWeight',
          message: 'Gross weight must be greater than zero',
        ),
      );
    }
  }

  void _validateAgentDocument(
    AgentCpeDocument doc,
    List<ValidationIssue> issues,
  ) {
    if (doc.lines.isEmpty) {
      issues.add(
        const ValidationIssue(
          field: 'lines',
          message: 'Retention/Perception document must contain at least 1 line',
        ),
      );
    }
    var sumRetainedOrPerceived = Decimal.zero;
    for (final line in doc.lines) {
      sumRetainedOrPerceived += line.retainedOrPerceivedAmountInPen;
    }
    if (!_withinTolerance(
      doc.totalAmountInPen,
      sumRetainedOrPerceived,
      sumTolerance,
    )) {
      issues.add(
        ValidationIssue(
          field: 'totalAmountInPen',
          message:
              'totalAmountInPen (${doc.totalAmountInPen}) must equal sum of lines ($sumRetainedOrPerceived)',
        ),
      );
    }
  }

  static bool _withinTolerance(
    Decimal actual,
    Decimal expected,
    Decimal tolerance,
  ) {
    final diff = (actual - expected).abs();
    return diff <= tolerance;
  }
}
