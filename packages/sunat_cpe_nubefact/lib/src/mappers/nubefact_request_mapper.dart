import 'package:sunat_cpe_core/sunat_cpe_core.dart';
import '../nubefact_config.dart';
import 'nubefact_catalog_mapper.dart';

/// Maps `sunat_cpe_core` domain entities into Nubefact REST JSON payloads.
final class NubefactRequestMapper {
  final NubefactConfig config;

  const NubefactRequestMapper(this.config);

  /// Builds payload for `"operacion": "generar_comprobante"`.
  Map<String, Object?> mapSalesDocument(SalesCpeDocument doc) {
    final totals = doc.totals;
    final opType = doc is InvoiceDocument ? doc.operationType : OperationType.ventaInterna;

    var igvRate = Decimal.parse('18.00');
    for (final item in doc.items) {
      if (item.igvPercentage > Decimal.zero) {
        igvRate = item.igvPercentage;
        break;
      }
    }

    final payload = <String, Object?>{
      'operacion': 'generar_comprobante',
      'tipo_de_comprobante': NubefactCatalogMapper.mapDocumentType(doc.id.type),
      'serie': doc.id.series,
      'numero': doc.id.number,
      'sunat_transaction': NubefactCatalogMapper.mapOperationType(opType),
      'cliente_tipo_de_documento':
          NubefactCatalogMapper.mapIdentityDocumentType(doc.customer.documentType),
      'cliente_numero_de_documento': doc.customer.documentNumber,
      'cliente_denominacion': doc.customer.legalName,
      'cliente_direccion': doc.customer.address?.streetLine ?? '',
      'cliente_email': doc.customer.email ?? '',
      'fecha_de_emision': NubefactCatalogMapper.formatDate(doc.issueDate),
      'fecha_de_vencimiento':
          doc.dueDate != null ? NubefactCatalogMapper.formatDate(doc.dueDate!) : '',
      'moneda': NubefactCatalogMapper.mapCurrency(doc.currency),
      'tipo_de_cambio': doc.exchangeRate != null ? doc.exchangeRate.toString() : '',
      'porcentaje_de_igv': _num2(igvRate),
      'descuento_global': _optionalNum2(totals.descuentoGlobalAfectaBase),
      'total_descuento': _optionalNum2(
        totals.totalDescuentosLinea +
            totals.descuentoGlobalAfectaBase +
            totals.descuentoGlobalNoAfectaBase,
      ),
      'total_anticipo': _optionalNum2(totals.totalAnticipos),
      'total_gravada': _optionalNum2(totals.totalGravadas),
      'total_inafecta': _optionalNum2(totals.totalInafectas),
      'total_exonerada': _optionalNum2(totals.totalExoneradas),
      'total_igv': _optionalNum2(totals.totalIgv),
      'total_gratuita': _optionalNum2(totals.totalGratuitas),
      'total_otros_cargos': _optionalNum2(totals.totalOtrosCargos),
      'total_isc': _optionalNum2(totals.totalIsc),
      'total_impuestos_bolsas': _optionalNum2(totals.totalIcbper),
      'total': _num2(totals.importeTotalPagar),
      'observaciones': doc.observations.join(' | '),
      'orden_compra_servicio': doc.purchaseOrder ?? '',
      'enviar_automaticamente_a_la_sunat': config.autoSendToSunat,
      'enviar_automaticamente_al_cliente': config.autoSendToCustomer,
      'formato_de_pdf': config.pdfFormat,
    };

    if (doc is InvoiceDocument) {
      payload['detraccion'] = doc.detraction != null;
      if (doc.detraction != null) {
        payload['detraccion_tipo'] = int.tryParse(doc.detraction!.code) ?? doc.detraction!.code;
        payload['detraccion_total'] = _num2(doc.detraction!.amountInPen);
        payload['detraccion_porcentaje'] = _num2(doc.detraction!.percentage);
        payload['medio_de_pago_detraccion'] =
            int.tryParse(doc.detraction!.paymentMethodCode) ?? 1;
      }

      switch (doc.paymentTerms) {
        case CashPaymentTerms():
          payload['condiciones_de_pago'] = 'CONTADO';
          payload['medio_de_pago'] = 'contado';
        case CreditPaymentTerms(:final installments):
          payload['condiciones_de_pago'] = 'CRÉDITO';
          payload['medio_de_pago'] = 'credito';
          payload['venta_al_credito'] = installments
              .map(
                (q) => <String, Object?>{
                  'cuota': q.number,
                  'fecha_de_pago': NubefactCatalogMapper.formatDate(q.dueDate),
                  'importe': _num2(q.amount),
                },
              )
              .toList();
      }
    } else if (doc is CreditNoteDocument) {
      payload['documento_que_se_modifica_tipo'] =
          NubefactCatalogMapper.mapDocumentType(doc.affectedDocument.documentType);
      payload['documento_que_se_modifica_serie'] = doc.affectedDocument.series;
      payload['documento_que_se_modifica_numero'] = doc.affectedDocument.number;
      payload['tipo_de_nota_de_credito'] =
          NubefactCatalogMapper.mapCreditNoteReason(doc.reasonCode);
      payload['motivo_o_sustento_de_nota'] = doc.reasonDescription;
    } else if (doc is DebitNoteDocument) {
      payload['documento_que_se_modifica_tipo'] =
          NubefactCatalogMapper.mapDocumentType(doc.affectedDocument.documentType);
      payload['documento_que_se_modifica_serie'] = doc.affectedDocument.series;
      payload['documento_que_se_modifica_numero'] = doc.affectedDocument.number;
      payload['tipo_de_nota_de_debito'] =
          NubefactCatalogMapper.mapDebitNoteReason(doc.reasonCode);
      payload['motivo_o_sustento_de_nota'] = doc.reasonDescription;
    }

    if (doc.relatedGuides.isNotEmpty) {
      payload['guias'] = doc.relatedGuides
          .map(
            (g) => <String, Object?>{
              'guia_tipo': NubefactCatalogMapper.mapDocumentType(g.documentType),
              'guia_serie_numero': g.formattedId,
            },
          )
          .toList();
    }

    payload['items'] = doc.items.map(_mapLineItem).toList();
    return payload;
  }

  Map<String, Object?> _mapLineItem(CpeLineItem item) {
    final unitVal = item.igvAffectation.isFree ? item.unitPrice : item.unitValue;
    return <String, Object?>{
      'unidad_de_medida': item.unitCode,
      'codigo': item.internalCode ?? '',
      'codigo_producto_sunat': item.sunatProductCode ?? '',
      'descripcion': item.description,
      'cantidad': double.parse(item.quantity.toString()),
      'valor_unitario': double.parse(unitVal.toString()),
      'precio_unitario': double.parse(item.unitPrice.toString()),
      'descuento': item.discount != null ? _num2(item.discount!.amount) : '',
      'subtotal': _num2(item.lineExtensionAmount),
      'tipo_de_igv': NubefactCatalogMapper.mapIgvAffectation(item.igvAffectation),
      'igv': _num2(item.igvAmount),
      'impuesto_bolsas': item.icbperAmount != null ? _num2(item.icbperAmount!) : '',
      'total': _num2(item.totalLineAmount),
      'anticipo_regularizacion': false,
    };
  }

  /// Builds payload for `"operacion": "generar_anulacion"` from a [VoidedLine].
  Map<String, Object?> mapVoidedLine(VoidedLine line) {
    return <String, Object?>{
      'operacion': 'generar_anulacion',
      'tipo_de_comprobante': NubefactCatalogMapper.mapDocumentType(line.documentType),
      'serie': line.series,
      'numero': line.number,
      'motivo': line.voidReason,
      'codigo_unico': '',
    };
  }

  /// Builds payload for `"operacion": "generar_guia"` from a [DespatchAdviceDocument].
  Map<String, Object?> mapDespatchAdvice(DespatchAdviceDocument guide) {
    final principalDriver = guide.drivers.firstOrNull;
    final principalVehicle = guide.vehicles.firstOrNull;

    return <String, Object?>{
      'operacion': 'generar_guia',
      'tipo_de_comprobante': NubefactCatalogMapper.mapDocumentType(guide.id.type),
      'serie': guide.id.series,
      'numero': guide.id.number,
      'cliente_tipo_de_documento':
          NubefactCatalogMapper.mapIdentityDocumentType(guide.recipient.documentType),
      'cliente_numero_de_documento': guide.recipient.documentNumber,
      'cliente_denominacion': guide.recipient.legalName,
      'cliente_direccion': guide.recipient.address?.streetLine ?? '',
      'fecha_de_emision': NubefactCatalogMapper.formatDate(guide.issueDate),
      'motivo_de_traslado': guide.transferReason.code,
      'peso_bruto_total': double.parse(guide.grossWeight.toString()),
      'peso_bruto_unidad_de_medida': guide.weightUnitCode,
      'numero_de_bultos': guide.packageCount ?? 1,
      'tipo_de_transporte': guide.transportMode.code,
      'fecha_de_inicio_de_traslado':
          NubefactCatalogMapper.formatDate(guide.transferStartDate),
      'transportista_documento_tipo': '6',
      'transportista_documento_numero': guide.carrier?.ruc ?? '',
      'transportista_denominacion': guide.carrier?.legalName ?? '',
      'transportista_placa_numero': principalVehicle?.plateNumber ?? '',
      'conductor_documento_tipo': principalDriver != null
          ? NubefactCatalogMapper.mapIdentityDocumentType(principalDriver.documentType)
          : '',
      'conductor_documento_numero': principalDriver?.documentNumber ?? '',
      'conductor_nombre': principalDriver?.firstName ?? '',
      'conductor_apellidos': principalDriver?.lastName ?? '',
      'conductor_numero_licencia': principalDriver?.licenseNumber ?? '',
      'punto_de_partida_ubigeo': guide.originAddress.ubigeo ?? '',
      'punto_de_partida_direccion': guide.originAddress.streetLine,
      'punto_de_llegada_ubigeo': guide.deliveryAddress.ubigeo ?? '',
      'punto_de_llegada_direccion': guide.deliveryAddress.streetLine,
      'enviar_automaticamente_a_la_sunat': config.autoSendToSunat,
      'enviar_automaticamente_al_cliente': config.autoSendToCustomer,
      'formato_de_pdf': config.pdfFormat,
      'items': guide.items
          .map(
            (i) => <String, Object?>{
              'unidad_de_medida': i.unitCode,
              'codigo': i.internalCode ?? '',
              'descripcion': i.description,
              'cantidad': double.parse(i.quantity.toString()),
            },
          )
          .toList(),
    };
  }

  /// Builds payload for `"operacion": "generar_retencion"` or `"generar_percepcion"`.
  Map<String, Object?> mapAgentDocument(AgentCpeDocument doc) {
    final isRetention = doc is RetentionDocument;
    return <String, Object?>{
      'operacion': isRetention ? 'generar_retencion' : 'generar_percepcion',
      'serie': doc.id.series,
      'numero': doc.id.number,
      'cliente_tipo_de_documento':
          NubefactCatalogMapper.mapIdentityDocumentType(doc.partner.documentType),
      'cliente_numero_de_documento': doc.partner.documentNumber,
      'cliente_denominacion': doc.partner.legalName,
      'cliente_direccion': doc.partner.address?.streetLine ?? '',
      'fecha_de_emision': NubefactCatalogMapper.formatDate(doc.issueDate),
      'moneda': 1,
      if (doc is RetentionDocument) ...{
        'tipo_de_tasa_de_retencion': int.parse(doc.regime.code),
        'total_retenido': _num2(doc.totalAmountInPen),
        'total_pagado': _num2(doc.totalPaidOrCollectedInPen),
      },
      if (doc is PerceptionDocument) ...{
        'tipo_de_tasa_de_percepcion': int.parse(doc.regime.code),
        'total_percibido': _num2(doc.totalAmountInPen),
        'total_cobrado': _num2(doc.totalPaidOrCollectedInPen),
      },
      'enviar_automaticamente_a_la_sunat': config.autoSendToSunat,
      'enviar_automaticamente_al_cliente': config.autoSendToCustomer,
    };
  }

  /// Builds payload for `"operacion": "consultar_comprobante"`, `"consultar_anulacion"`, or `"consultar_guia"`.
  Map<String, Object?> mapStatusQuery({
    required String operation,
    required CpeDocumentType documentType,
    required String series,
    required int number,
  }) {
    return <String, Object?>{
      'operacion': operation,
      'tipo_de_comprobante': NubefactCatalogMapper.mapDocumentType(documentType),
      'serie': series,
      'numero': number,
    };
  }

  static double _num2(Decimal value) => double.parse(value.toStringAsFixed(2));

  static Object _optionalNum2(Decimal value) =>
      value > Decimal.zero ? double.parse(value.toStringAsFixed(2)) : '';
}
