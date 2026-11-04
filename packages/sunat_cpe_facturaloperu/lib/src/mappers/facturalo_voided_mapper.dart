import 'package:sunat_cpe_core/sunat_cpe_core.dart';

import 'facturalo_document_mapper.dart';

/// Transforma un [VoidedDocument] al formato JSON requerido por `/api/voided` en FacturaloPeru.
final class FacturaloVoidedMapper {
  /// Crea una instancia constante de [FacturaloVoidedMapper].
  const FacturaloVoidedMapper();

  /// Convierte [voided] en el mapa JSON esperado por `/api/voided`.
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
