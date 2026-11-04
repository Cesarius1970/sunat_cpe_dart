import 'package:sunat_cpe_core/sunat_cpe_core.dart';

import '../mifact_config.dart';
import 'mifact_invoice_mapper.dart';

/// Transforma [DailySummaryDocument], [VoidedDocument] y consultas de estado en payloads JSON de Mifact.
final class MifactSummaryMapper {
  /// Crea una instancia constante de [MifactSummaryMapper].
  const MifactSummaryMapper();

  /// Construye el payload JSON `SendSummary` para un Resumen Diario de Boletas (`RC`).
  Map<String, dynamic> mapDailySummary(
    DailySummaryDocument summary,
    MifactConfig config,
  ) {
    return {
      'TOKEN': config.token,
      'NUM_NIF_EMIS': summary.issuer.ruc,
      'NOM_RZN_SOC_EMIS': summary.issuer.legalName,
      'ID_RESUMEN': summary.id.ublId,
      'FEC_EMIS': MifactInvoiceMapper.formatIsoDate(summary.issueDate),
      'FEC_REF': MifactInvoiceMapper.formatIsoDate(summary.referenceDate),
      'ITEMS': summary.lines
          .map(
            (l) => {
              'NUM_LINEA': l.lineNumber,
              'COD_TIP_DOCU': l.documentType.code,
              'NUM_SERIE_CPE': l.series,
              'NUM_CORRE_CPE': l.number.toString(),
              'COD_ESTADO': l.status.code,
              'MNT_TOT': l.totalSaleAmount.toStringAsFixed(2),
              'MNT_TOT_IGV': l.totalIgv.toStringAsFixed(2),
            },
          )
          .toList(),
    };
  }

  /// Construye el payload JSON `lowInvoice` para una Comunicación de Baja (`RA`).
  Map<String, dynamic> mapVoidedDocument(
    VoidedDocument voided,
    MifactConfig config,
  ) {
    return {
      'TOKEN': config.token,
      'NUM_NIF_EMIS': voided.issuer.ruc,
      'NOM_RZN_SOC_EMIS': voided.issuer.legalName,
      'ID_BAJA': voided.id.ublId,
      'FEC_EMIS': MifactInvoiceMapper.formatIsoDate(voided.issueDate),
      'FEC_REF': MifactInvoiceMapper.formatIsoDate(voided.referenceDate),
      'ITEMS': voided.lines
          .map(
            (l) => {
              'NUM_LINEA': l.lineNumber,
              'COD_TIP_DOCU': l.documentType.code,
              'NUM_SERIE_CPE': l.series,
              'NUM_CORRE_CPE': l.number.toString(),
              'TXT_MOTIVO_BAJA': l.voidReason,
            },
          )
          .toList(),
    };
  }

  /// Construye el payload JSON `GetStatus` para consultar el estado de un comprobante.
  Map<String, dynamic> mapStatusQuery(
    DocumentStatusQuery query,
    MifactConfig config,
  ) {
    return {
      'TOKEN': config.token,
      'NUM_NIF_EMIS': query.issuerRuc,
      'COD_TIP_DOCU': query.documentType.code,
      'NUM_SERIE_CPE': query.series,
      'NUM_CORRE_CPE': query.number.toString().padLeft(8, '0'),
    };
  }
}
