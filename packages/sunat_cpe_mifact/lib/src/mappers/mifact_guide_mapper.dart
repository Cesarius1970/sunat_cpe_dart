import 'package:sunat_cpe_core/sunat_cpe_core.dart';

import '../mifact_config.dart';
import 'mifact_invoice_mapper.dart';

/// Maps [DespatchAdviceDocument] to Mifact `SendGuide` JSON payload.
final class MifactGuideMapper {
  const MifactGuideMapper();

  Map<String, dynamic> mapGuide(
    DespatchAdviceDocument guide,
    MifactConfig config,
  ) {
    return {
      'TOKEN': config.token,
      'NUM_NIF_EMIS': guide.issuer.ruc,
      'NOM_RZN_SOC_EMIS': guide.issuer.legalName,
      'COD_TIP_DOCU': guide.id.type.code,
      'NUM_SERIE_CPE': guide.id.series,
      'NUM_CORRE_CPE': guide.id.number.toString().padLeft(8, '0'),
      'FEC_EMIS': MifactInvoiceMapper.formatIsoDate(guide.issueDate),
      'COD_MOT_TRASLADO': guide.transferReason.code,
      'MOD_TRASLADO': guide.transportMode.code,
      'FEC_INI_TRASLADO': MifactInvoiceMapper.formatIsoDate(
        guide.transferStartDate,
      ),
      'PESO_BRUTO': guide.grossWeight.toString(),
      'UND_PESO_BRUTO': guide.weightUnitCode,
      'COD_UBI_PARTIDA': guide.originAddress.ubigeo ?? '150101',
      'DIR_PARTIDA': guide.originAddress.streetLine,
      'COD_UBI_LLEGADA': guide.deliveryAddress.ubigeo ?? '150101',
      'DIR_LLEGADA': guide.deliveryAddress.streetLine,
      'COD_TIP_NIF_DEST': guide.recipient.documentType.code,
      'NUM_NIF_DEST': guide.recipient.documentNumber,
      'NOM_RZN_SOC_DEST': guide.recipient.legalName,
      'ENVIAR_A_SUNAT': config.sendImmediatelyToSunat ? 'true' : 'false',
      'ITEMS': guide.items
          .map(
            (i) => {
              'COD_ITEM': i.internalCode ?? 'ITEM-${i.lineNumber}',
              'COD_UNID_ITEM': i.unitCode,
              'CANT_UNID_ITEM': i.quantity.toString(),
              'TXT_DESC_ITEM': i.description,
            },
          )
          .toList(),
    };
  }
}
