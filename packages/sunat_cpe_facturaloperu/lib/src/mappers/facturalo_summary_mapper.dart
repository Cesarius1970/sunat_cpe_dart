import 'package:sunat_cpe_core/sunat_cpe_core.dart';

import 'facturalo_document_mapper.dart';

/// Maps [DailySummaryDocument] to FacturaloPeru `/api/summaries` JSON.
final class FacturaloSummaryMapper {
  const FacturaloSummaryMapper();

  Map<String, dynamic> mapDailySummary(DailySummaryDocument summary) {
    return {
      'fecha_de_emision_de_documentos': FacturaloDocumentMapper.formatIsoDate(
        summary.referenceDate,
      ),
      'codigo_tipo_proceso': '1',
      'documentos': summary.lines
          .map(
            (l) => {
              'serie_documento': l.series,
              'numero_documento': l.number.toString(),
              'codigo_tipo_documento': l.documentType.code,
              'codigo_tipo_estado': l.status.code,
              'total_venta': double.parse(l.totalSaleAmount.toString()),
              'total_igv': double.parse(l.totalIgv.toString()),
            },
          )
          .toList(),
    };
  }
}
