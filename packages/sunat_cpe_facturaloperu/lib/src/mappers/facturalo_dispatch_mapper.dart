import 'package:sunat_cpe_core/sunat_cpe_core.dart';
import 'facturalo_document_mapper.dart';

/// Maps [DespatchAdviceDocument] to FacturaloPeru `/api/dispatches` JSON.
final class FacturaloDispatchMapper {
  const FacturaloDispatchMapper();

  Map<String, dynamic> mapDespatchAdvice(DespatchAdviceDocument guide) {
    return {
      'serie_documento': guide.id.series,
      'numero_documento': guide.id.number.toString(),
      'fecha_de_emision': FacturaloDocumentMapper.formatIsoDate(guide.issueDate),
      'hora_de_emision': guide.issueTime ?? '12:00:00',
      'codigo_tipo_documento': guide.id.type.code,
      'codigo_modo_transporte': guide.transportMode.code,
      'codigo_motivo_traslado': guide.transferReason.code,
      'descripcion_motivo_traslado':
          guide.transferDescription ?? guide.transferReason.description,
      'fecha_de_traslado':
          FacturaloDocumentMapper.formatIsoDate(guide.transferStartDate),
      'unidad_peso_total': guide.weightUnitCode,
      'peso_total': double.parse(guide.grossWeight.toString()),
      'direccion_partida': {
        'ubigeo': guide.originAddress.ubigeo ?? '150101',
        'direccion': guide.originAddress.streetLine,
      },
      'direccion_llegada': {
        'ubigeo': guide.deliveryAddress.ubigeo ?? '150101',
        'direccion': guide.deliveryAddress.streetLine,
      },
      'datos_del_cliente_o_receptor': {
        'codigo_tipo_documento_identidad': guide.recipient.documentType.code,
        'numero_documento': guide.recipient.documentNumber,
        'apellidos_y_nombres_o_razon_social': guide.recipient.legalName,
      },
      'items': guide.items
          .map(
            (i) => {
              'codigo_interno': i.internalCode ?? 'ITEM-${i.lineNumber}',
              'descripcion': i.description,
              'unidad_de_medida': i.unitCode,
              'cantidad': double.parse(i.quantity.toString()),
            },
          )
          .toList(),
    };
  }
}
