import 'package:sunat_cpe_core/sunat_cpe_core.dart';

import 'facturalo_document_mapper.dart';

/// Maps [VoidedDocument] to FacturaloPeru `/api/voided` JSON.
final class FacturaloVoidedMapper {
  const FacturaloVoidedMapper();

  Map<String, dynamic> mapVoidedDocument(VoidedDocument voided) {
    return {
      'fecha_de_emision_de_documentos': FacturaloDocumentMapper.formatIsoDate(
        voided.referenceDate,
      ),
      'documentos': voided.lines
          .map(
            (l) => {
              'serie_documento': l.series,
              'numero_documento': l.number.toString(),
              'codigo_tipo_documento': l.documentType.code,
              'motivo_anulacion': l.voidReason,
            },
          )
          .toList(),
    };
  }
}
