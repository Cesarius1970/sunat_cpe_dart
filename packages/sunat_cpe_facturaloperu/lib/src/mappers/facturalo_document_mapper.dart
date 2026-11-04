import 'package:sunat_cpe_core/sunat_cpe_core.dart';
import '../facturalo_config.dart';

/// Maps [SalesCpeDocument] and [AgentCpeDocument] to FacturaloPeru `/api/documents` and `/api/retentions` JSON.
final class FacturaloDocumentMapper {
  const FacturaloDocumentMapper();

  Map<String, dynamic> mapSalesDocument(
    SalesCpeDocument doc,
    FacturaloConfig config,
  ) {
    final numeroStr = (config.allowServerAutoIncrement && doc.id.number <= 0)
        ? '#'
        : doc.id.number.toString();

    final map = <String, dynamic>{
      'serie_documento': doc.id.series,
      'numero_documento': numeroStr,
      'fecha_de_emision': formatIsoDate(doc.issueDate),
      'hora_de_emision': doc.issueTime ?? '12:00:00',
      'codigo_tipo_documento': doc.id.type.code,
      'codigo_tipo_moneda': doc.currency.code,
      if (doc.dueDate != null)
        'fecha_de_vencimiento': formatIsoDate(doc.dueDate!),
      if (doc.purchaseOrder != null)
        'numero_orden_de_compra': doc.purchaseOrder,
      'datos_del_cliente_o_receptor': {
        'codigo_tipo_documento_identidad': doc.customer.documentType.code,
        'numero_documento': doc.customer.documentNumber,
        'apellidos_y_nombres_o_razon_social': doc.customer.legalName,
        'codigo_pais': doc.customer.address?.countryCode ?? 'PE',
        if (doc.customer.address?.ubigeo != null)
          'ubigeo': doc.customer.address!.ubigeo,
        if (doc.customer.address != null)
          'direccion': doc.customer.address!.streetLine,
        if (doc.customer.email != null)
          'correo_electronico': doc.customer.email,
        if (doc.customer.phone != null) 'telefono': doc.customer.phone,
      },
      'totales': {
        'total_exportacion': _toDouble(doc.totals.totalExportacion),
        'total_operaciones_gravadas': _toDouble(doc.totals.totalGravadas),
        'total_operaciones_inafectas': _toDouble(doc.totals.totalInafectas),
        'total_operaciones_exoneradas': _toDouble(doc.totals.totalExoneradas),
        'total_operaciones_gratuitas': _toDouble(doc.totals.totalGratuitas),
        'total_igv': _toDouble(doc.totals.totalIgv),
        'total_isc': _toDouble(doc.totals.totalIsc),
        'total_impuestos_bolsas_plasticas': _toDouble(doc.totals.totalIcbper),
        'total_impuestos': _toDouble(doc.totals.totalImpuestos),
        'total_valor': _toDouble(doc.totals.totalValorVenta),
        'total_venta': _toDouble(doc.totals.importeTotalPagar),
      },
      'items': doc.items
          .map(
            (item) => {
              'codigo_interno': item.internalCode ?? 'ITEM-${item.lineNumber}',
              'descripcion': item.description,
              if (item.sunatProductCode != null)
                'codigo_producto_sunat': item.sunatProductCode,
              'unidad_de_medida': item.unitCode,
              'cantidad': _toDouble(item.quantity),
              'valor_unitario': _toDouble(item.unitValue),
              'codigo_tipo_precio': item.isReferencePrice ? '02' : '01',
              'precio_unitario': _toDouble(item.unitPrice),
              'codigo_tipo_afectacion_igv': item.igvAffectation.code,
              'total_base_igv': _toDouble(item.taxableBaseAmount),
              'porcentaje_igv': _toDouble(item.igvPercentage),
              'total_igv': _toDouble(item.igvAmount),
              'total_impuestos': _toDouble(item.totalLineTaxAmount),
              'total_valor_item': _toDouble(item.lineExtensionAmount),
              'total_item': _toDouble(item.totalLineAmount),
            },
          )
          .toList(),
      'acciones': {
        'enviar_email': config.sendEmail,
        'formato_pdf': config.pdfFormat,
      },
    };

    if (doc is InvoiceDocument) {
      map['codigo_tipo_operacion'] = doc.operationType.code;
      switch (doc.paymentTerms) {
        case CashPaymentTerms():
          map['codigo_condicion_de_pago'] = '01';
        case final CreditPaymentTerms credit:
          map['codigo_condicion_de_pago'] = '02';
          map['cuotas'] = credit.installments
              .map(
                (c) => {
                  'fecha': formatIsoDate(c.dueDate),
                  'codigo_tipo_moneda': doc.currency.code,
                  'monto': _toDouble(c.amount),
                },
              )
              .toList();
      }
    } else if (doc is CreditNoteDocument) {
      map['codigo_tipo_nota'] = doc.reasonCode.code;
      map['motivo_o_sustento_de_nota'] = doc.reasonDescription;
      map['documento_afectado'] = {
        'serie_documento': doc.affectedDocument.series,
        'numero_documento': doc.affectedDocument.number.toString(),
        'codigo_tipo_documento': doc.affectedDocument.documentType.code,
      };
    } else if (doc is DebitNoteDocument) {
      map['codigo_tipo_nota'] = doc.reasonCode.code;
      map['motivo_o_sustento_de_nota'] = doc.reasonDescription;
      map['documento_afectado'] = {
        'serie_documento': doc.affectedDocument.series,
        'numero_documento': doc.affectedDocument.number.toString(),
        'codigo_tipo_documento': doc.affectedDocument.documentType.code,
      };
    }

    return map;
  }

  Map<String, dynamic> mapAgentDocument(AgentCpeDocument doc) {
    final (regimeCode, ratePercent) = switch (doc) {
      final RetentionDocument ret => (ret.regime.code, ret.ratePercentage),
      final PerceptionDocument per => (per.regime.code, per.ratePercentage),
    };
    return {
      'serie_documento': doc.id.series,
      'numero_documento': doc.id.number.toString(),
      'fecha_de_emision': formatIsoDate(doc.issueDate),
      'hora_de_emision': doc.issueTime ?? '12:00:00',
      'codigo_tipo_documento': doc.id.type.code,
      'codigo_regimen': regimeCode,
      'tasa': _toDouble(ratePercent),
      'total_retencion_percepcion': _toDouble(doc.totalAmountInPen),
      'total_pagado_cobrado': _toDouble(doc.totalPaidOrCollectedInPen),
      'datos_del_proveedor_o_cliente': {
        'codigo_tipo_documento_identidad': doc.partner.documentType.code,
        'numero_documento': doc.partner.documentNumber,
        'apellidos_y_nombres_o_razon_social': doc.partner.legalName,
      },
    };
  }

  static double _toDouble(Decimal value) => double.parse(value.toString());

  static String formatIsoDate(DateTime dt) {
    final y = dt.year.toString().padLeft(4, '0');
    final m = dt.month.toString().padLeft(2, '0');
    final d = dt.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }
}
