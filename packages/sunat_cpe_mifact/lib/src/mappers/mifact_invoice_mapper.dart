import 'package:sunat_cpe_core/sunat_cpe_core.dart';

import '../mifact_config.dart';

/// Transforma entidades [SalesCpeDocument] y [AgentCpeDocument] a payloads JSON `UPPER_SNAKE_CASE` de Mifact.
final class MifactInvoiceMapper {
  /// Crea una instancia constante de [MifactInvoiceMapper].
  const MifactInvoiceMapper();

  /// Construye el payload JSON para Facturas (`01`), Boletas (`03`), Notas de Crédito (`07`) y Notas de Débito (`08`).
  Map<String, dynamic> mapSalesDocument(
    SalesCpeDocument doc,
    MifactConfig config,
  ) {
    final map = <String, dynamic>{
      'TOKEN': config.token,
      'COD_TIP_NIF_EMIS': '6',
      'NUM_NIF_EMIS': doc.issuer.ruc,
      'NOM_RZN_SOC_EMIS': doc.issuer.legalName,
      if (doc.issuer.tradeName != null) 'NOM_COMER_EMIS': doc.issuer.tradeName,
      if (doc.issuer.address.ubigeo != null)
        'COD_UBI_EMIS': doc.issuer.address.ubigeo,
      'TXT_DMCL_FISC_EMIS': doc.issuer.address.streetLine,
      'COD_TIP_DOCU': doc.id.type.code,
      'NUM_SERIE_CPE': doc.id.series,
      'NUM_CORRE_CPE': doc.id.number.toString().padLeft(8, '0'),
      'FEC_EMIS': formatIsoDate(doc.issueDate),
      'HOR_EMIS': doc.issueTime ?? '12:00:00',
      if (doc.dueDate != null) 'FEC_VENC': formatIsoDate(doc.dueDate!),
      'COD_MND': doc.currency.code,
      'COD_PRCD_CARGA': '001',
      'COD_TIP_NIF_RECP': doc.customer.documentType.code,
      'NUM_NIF_RECP': doc.customer.documentNumber,
      'NOM_RZN_SOC_RECP': doc.customer.legalName,
      if (doc.customer.address != null)
        'TXT_DMCL_FISC_RECP': doc.customer.address!.streetLine,
      'MNT_TOT_GRAVADO': doc.totals.totalGravadas.toStringAsFixed(2),
      'MNT_TOT_EXONERADO': doc.totals.totalExoneradas.toStringAsFixed(2),
      'MNT_TOT_INAFECTO': doc.totals.totalInafectas.toStringAsFixed(2),
      'MNT_TOT_EXPORTACION': doc.totals.totalExportacion.toStringAsFixed(2),
      'MNT_TOT_GRATUITO': doc.totals.totalGratuitas.toStringAsFixed(2),
      'MNT_TOT_TRIB_IGV': doc.totals.totalIgv.toStringAsFixed(2),
      'MNT_TOT_TRIB_ISC': doc.totals.totalIsc.toStringAsFixed(2),
      'MNT_TOT_TRIB_ICBPER': doc.totals.totalIcbper.toStringAsFixed(2),
      'MNT_TOT': doc.totals.importeTotalPagar.toStringAsFixed(2),
      'ENVIAR_A_SUNAT': config.sendImmediatelyToSunat ? 'true' : 'false',
      'ITEMS': doc.items
          .map(
            (item) => {
              'COD_ITEM': item.internalCode ?? 'ITEM-${item.lineNumber}',
              'COD_UNID_ITEM': item.unitCode,
              'CANT_UNID_ITEM': item.quantity.toStringAsFixed(2),
              'VAL_UNIT_ITEM': item.unitValue.toString(),
              'PRC_VTA_UNIT_ITEM': item.unitPrice.toString(),
              'VAL_VTA_ITEM': item.lineExtensionAmount.toStringAsFixed(2),
              'MNT_IGV_ITEM': item.igvAmount.toStringAsFixed(2),
              'POR_IGV_ITEM': item.igvPercentage.toStringAsFixed(2),
              'COD_TIP_AFECT_IGV_ITEM': item.igvAffectation.code,
              'TXT_DESC_ITEM': item.description,
            },
          )
          .toList(),
    };

    if (doc is InvoiceDocument) {
      map['COD_TIP_OPE_SUNAT'] = doc.operationType.code;
      switch (doc.paymentTerms) {
        case CashPaymentTerms():
          map['COD_FRM_PAGO'] = 'Contado';
        case final CreditPaymentTerms credit:
          map['COD_FRM_PAGO'] = 'Credito';
          map['MNT_PEND_PAGO'] = credit.netPendingAmount.toStringAsFixed(2);
          map['CUOTAS'] = credit.installments
              .map(
                (c) => {
                  'NUM_CUOTA': c.formattedQuotaId,
                  'MNT_CUOTA': c.amount.toStringAsFixed(2),
                  'FEC_VENC_CUOTA': formatIsoDate(c.dueDate),
                },
              )
              .toList();
      }
    } else if (doc is CreditNoteDocument) {
      map['COD_TIP_NC'] = doc.reasonCode.code;
      map['TXT_SUST_NC'] = doc.reasonDescription;
      map['COD_TIP_DOCU_REF'] = doc.affectedDocument.documentType.code;
      map['NUM_SERIE_CPE_REF'] = doc.affectedDocument.series;
      map['NUM_CORRE_CPE_REF'] = doc.affectedDocument.number.toString().padLeft(
        8,
        '0',
      );
    } else if (doc is DebitNoteDocument) {
      map['COD_TIP_ND'] = doc.reasonCode.code;
      map['TXT_SUST_ND'] = doc.reasonDescription;
      map['COD_TIP_DOCU_REF'] = doc.affectedDocument.documentType.code;
      map['NUM_SERIE_CPE_REF'] = doc.affectedDocument.series;
      map['NUM_CORRE_CPE_REF'] = doc.affectedDocument.number.toString().padLeft(
        8,
        '0',
      );
    }

    return map;
  }

  /// Construye el payload JSON para Comprobantes de Retención (`20`) y Percepción (`40`).
  Map<String, dynamic> mapAgentDocument(
    AgentCpeDocument doc,
    MifactConfig config,
  ) {
    final (regimeCode, ratePercent) = switch (doc) {
      final RetentionDocument ret => (ret.regime.code, ret.ratePercentage),
      final PerceptionDocument per => (per.regime.code, per.ratePercentage),
    };
    return {
      'TOKEN': config.token,
      'NUM_NIF_EMIS': doc.issuer.ruc,
      'NOM_RZN_SOC_EMIS': doc.issuer.legalName,
      'COD_TIP_DOCU': doc.id.type.code,
      'NUM_SERIE_CPE': doc.id.series,
      'NUM_CORRE_CPE': doc.id.number.toString().padLeft(8, '0'),
      'FEC_EMIS': formatIsoDate(doc.issueDate),
      'COD_TIP_NIF_RECP': doc.partner.documentType.code,
      'NUM_NIF_RECP': doc.partner.documentNumber,
      'NOM_RZN_SOC_RECP': doc.partner.legalName,
      'COD_REGIMEN': regimeCode,
      'TASA_PORC': ratePercent.toStringAsFixed(2),
      'MNT_TOT_RET_PER': doc.totalAmountInPen.toStringAsFixed(2),
      'MNT_TOT_PAG_COB': doc.totalPaidOrCollectedInPen.toStringAsFixed(2),
      'ENVIAR_A_SUNAT': config.sendImmediatelyToSunat ? 'true' : 'false',
    };
  }

  /// Formatea un [DateTime] al estándar ISO `YYYY-MM-DD` requerido por Mifact.
  static String formatIsoDate(DateTime dt) {
    final y = dt.year.toString().padLeft(4, '0');
    final m = dt.month.toString().padLeft(2, '0');
    final d = dt.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }
}
