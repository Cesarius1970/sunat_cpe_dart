import 'package:sunat_cpe_core/sunat_cpe_core.dart';

/// Transforma las entidades [CpeDocument] del Core al formato JSON UBL de EFACT para el modo PSE con firma en la nube.
final class EfactJsonMapper {
  /// Crea una instancia constante de [EfactJsonMapper].
  const EfactJsonMapper();

  /// Convierte un [CpeDocument] en un mapa JSON compatible con el endpoint REST de EFACT.
  Map<String, dynamic> mapDocument(CpeDocument document) {
    final issueDate = _formatIsoDate(document.issueDate);
    return switch (document) {
      final SalesCpeDocument sales => _mapSalesDocument(sales, issueDate),
      final DailySummaryDocument summary => _mapDailySummary(
        summary,
        issueDate,
      ),
      final VoidedDocument voided => _mapVoidedDocument(voided, issueDate),
      final DespatchAdviceDocument guide => _mapDespatchAdvice(
        guide,
        issueDate,
      ),
      final AgentCpeDocument agent => _mapAgentDocument(agent, issueDate),
    };
  }

  Map<String, dynamic> _mapSalesDocument(
    SalesCpeDocument doc,
    String issueDate,
  ) {
    final map = <String, dynamic>{
      'ublVersion': '2.1',
      'customizationId': '2.0',
      'id': doc.id.ublId,
      'documentTypeCode': doc.id.type.code,
      'issueDate': issueDate,
      'documentCurrencyCode': doc.currency.code,
      'supplier': {
        'ruc': doc.issuer.ruc,
        'legalName': doc.issuer.legalName,
        if (doc.issuer.tradeName != null) 'tradeName': doc.issuer.tradeName,
        'establishmentCode': doc.issuer.address.establishmentCode,
      },
      'customer': {
        'documentTypeCode': doc.customer.documentType.code,
        'documentNumber': doc.customer.documentNumber,
        'legalName': doc.customer.legalName,
      },
      'totals': {
        'gravadas': doc.totals.totalGravadas.toStringAsFixed(2),
        'exoneradas': doc.totals.totalExoneradas.toStringAsFixed(2),
        'inafectas': doc.totals.totalInafectas.toStringAsFixed(2),
        'exportacion': doc.totals.totalExportacion.toStringAsFixed(2),
        'gratuitas': doc.totals.totalGratuitas.toStringAsFixed(2),
        'igv': doc.totals.totalIgv.toStringAsFixed(2),
        'isc': doc.totals.totalIsc.toStringAsFixed(2),
        'icbper': doc.totals.totalIcbper.toStringAsFixed(2),
        'totalImpuestos': doc.totals.totalImpuestos.toStringAsFixed(2),
        'totalValorVenta': doc.totals.totalValorVenta.toStringAsFixed(2),
        'totalPrecioVenta': doc.totals.totalPrecioVenta.toStringAsFixed(2),
        'importeTotalPagar': doc.totals.importeTotalPagar.toStringAsFixed(2),
      },
      'items': doc.items
          .map(
            (item) => {
              'id': item.lineNumber,
              'unitCode': item.unitCode,
              'quantity': item.quantity.toString(),
              'description': item.description,
              'valorUnitario': item.unitValue.toString(),
              'precioUnitario': item.unitPrice.toString(),
              'valorVentaLinea': item.lineExtensionAmount.toStringAsFixed(2),
              'affectationType': item.igvAffectation.code,
              'igvAmount': item.igvAmount.toStringAsFixed(2),
              'totalLineTaxes': item.totalLineTaxAmount.toStringAsFixed(2),
            },
          )
          .toList(),
    };

    if (doc is InvoiceDocument) {
      map['operationTypeCode'] = doc.operationType.code;
      map['paymentTerms'] = switch (doc.paymentTerms) {
        CashPaymentTerms() => {'type': 'Contado'},
        final CreditPaymentTerms credit => {
          'type': 'Credito',
          'netPendingAmount': credit.netPendingAmount.toStringAsFixed(2),
          'installments': credit.installments
              .map(
                (c) => {
                  'number': c.number,
                  'amount': c.amount.toStringAsFixed(2),
                  'dueDate': _formatIsoDate(c.dueDate),
                },
              )
              .toList(),
        },
      };
    } else if (doc is CreditNoteDocument) {
      map['noteReasonCode'] = doc.reasonCode.code;
      map['noteReasonDescription'] = doc.reasonDescription;
      map['affectedDocumentId'] = doc.affectedDocument.formattedId;
    } else if (doc is DebitNoteDocument) {
      map['noteReasonCode'] = doc.reasonCode.code;
      map['noteReasonDescription'] = doc.reasonDescription;
      map['affectedDocumentId'] = doc.affectedDocument.formattedId;
    }

    return map;
  }

  Map<String, dynamic> _mapDailySummary(
    DailySummaryDocument summary,
    String issueDate,
  ) {
    return {
      'ublVersion': '2.0',
      'id': summary.id.ublId,
      'documentTypeCode': 'RC',
      'issueDate': issueDate,
      'referenceDate': _formatIsoDate(summary.referenceDate),
      'supplierRuc': summary.issuer.ruc,
      'lines': summary.lines
          .map(
            (l) => {
              'lineNumber': l.lineNumber,
              'documentTypeCode': l.documentType.code,
              'documentId': '${l.series}-${l.number}',
              'statusCode': l.status.code,
              'totalAmount': l.totalSaleAmount.toStringAsFixed(2),
              'igvAmount': l.totalIgv.toStringAsFixed(2),
            },
          )
          .toList(),
    };
  }

  Map<String, dynamic> _mapVoidedDocument(
    VoidedDocument voided,
    String issueDate,
  ) {
    return {
      'ublVersion': '2.0',
      'id': voided.id.ublId,
      'documentTypeCode': voided.id.type.code,
      'issueDate': issueDate,
      'referenceDate': _formatIsoDate(voided.referenceDate),
      'supplierRuc': voided.issuer.ruc,
      'lines': voided.lines
          .map(
            (l) => {
              'lineNumber': l.lineNumber,
              'documentTypeCode': l.documentType.code,
              'series': l.series,
              'number': l.number,
              'voidReason': l.voidReason,
            },
          )
          .toList(),
    };
  }

  Map<String, dynamic> _mapDespatchAdvice(
    DespatchAdviceDocument guide,
    String issueDate,
  ) {
    return {
      'ublVersion': '2.1',
      'id': guide.id.ublId,
      'documentTypeCode': guide.id.type.code,
      'issueDate': issueDate,
      'transferReasonCode': guide.transferReason.code,
      'transportModalityCode': guide.transportMode.code,
      'transferStartDate': _formatIsoDate(guide.transferStartDate),
      'grossWeight': guide.grossWeight.toString(),
      'weightUnitCode': guide.weightUnitCode,
      'originUbigeo': guide.originAddress.ubigeo,
      'destinationUbigeo': guide.deliveryAddress.ubigeo,
    };
  }

  Map<String, dynamic> _mapAgentDocument(
    AgentCpeDocument agent,
    String issueDate,
  ) {
    final (regimeCode, ratePercent) = switch (agent) {
      final RetentionDocument ret => (ret.regime.code, ret.ratePercentage),
      final PerceptionDocument per => (per.regime.code, per.ratePercentage),
    };
    return {
      'ublVersion': '2.0',
      'id': agent.id.ublId,
      'documentTypeCode': agent.id.type.code,
      'issueDate': issueDate,
      'supplierRuc': agent.issuer.ruc,
      'partnerDocumentNumber': agent.partner.documentNumber,
      'regimeCode': regimeCode,
      'ratePercent': ratePercent.toString(),
      'totalAmountInPen': agent.totalAmountInPen.toStringAsFixed(2),
    };
  }

  static String _formatIsoDate(DateTime dt) {
    final y = dt.year.toString().padLeft(4, '0');
    final m = dt.month.toString().padLeft(2, '0');
    final d = dt.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }
}
