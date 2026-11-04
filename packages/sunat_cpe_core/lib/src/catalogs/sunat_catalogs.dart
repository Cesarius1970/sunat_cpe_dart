/// Official SUNAT Catalogs (Anexo N° 8) for Electronic Invoicing (CPE).
library;

/// Catálogo 01: Código de Tipo de Documento.
enum CpeDocumentType {
  factura('01', 'Factura Electrónica'),
  boleta('03', 'Boleta de Venta Electrónica'),
  liquidacionCompra('04', 'Liquidación de Compra Electrónica'),
  notaCredito('07', 'Nota de Crédito Electrónica'),
  notaDebito('08', 'Nota de Débito Electrónica'),
  guiaRemisionRemitente('09', 'Guía de Remisión Remitente'),
  comprobanteRetencion('20', 'Comprobante de Retención Electrónico'),
  guiaRemisionTransportista('31', 'Guía de Remisión Transportista'),
  comprobantePercepcion('40', 'Comprobante de Percepción Electrónico'),
  resumenDiario('RC', 'Resumen Diario de Boletas'),
  comunicacionBaja('RA', 'Comunicación de Baja'),
  reversion('RR', 'Resumen de Reversiones');

  final String code;
  final String description;

  const CpeDocumentType(this.code, this.description);

  static CpeDocumentType? fromCode(String code) {
    for (final value in CpeDocumentType.values) {
      if (value.code == code) return value;
    }
    return null;
  }
}

/// Catálogo 02: Códigos de Tipo de Moneda (ISO 4217).
enum CurrencyCode {
  pen('PEN', 'Soles'),
  usd('USD', 'Dólares Americanos'),
  eur('EUR', 'Euros');

  final String code;
  final String name;

  const CurrencyCode(this.code, this.name);

  static CurrencyCode? fromCode(String code) {
    for (final value in CurrencyCode.values) {
      if (value.code == code) return value;
    }
    return null;
  }
}

/// Catálogo 05: Códigos de Tipos de Tributos.
enum TaxCategoryCode {
  s('S', '1000', 'IGV', 'VAT'),
  sIvap('S', '1016', 'IVAP', 'VAT'),
  e('E', '9997', 'EXO', 'VAT'),
  o('O', '9998', 'INA', 'FRE'),
  z('Z', '9996', 'GRA', 'FRE'),
  g('G', '9995', 'EXP', 'FRE'),
  isc('S', '2000', 'ISC', 'EXC'),
  icbper('S', '7152', 'ICBPER', 'OTH'),
  otros('S', '9999', 'OTROS', 'OTH');

  final String categoryId;
  final String schemeId;
  final String schemeName;
  final String taxTypeCode;

  const TaxCategoryCode(
    this.categoryId,
    this.schemeId,
    this.schemeName,
    this.taxTypeCode,
  );
}

/// Catálogo 06: Códigos de Tipos de Documentos de Identidad.
enum IdentityDocumentType {
  noDomiciliado('0', 'DOC.TRIB.NO.DOM.SIN.RUC'),
  dni('1', 'DNI'),
  carnetExtranjeria('4', 'Carnet de Extranjería'),
  ruc('6', 'RUC'),
  pasaporte('7', 'Pasaporte'),
  cedulaDiplomatica('A', 'Cédula Diplomática'),
  tam('G', 'Tarjeta Andina de Migración');

  final String code;
  final String description;

  const IdentityDocumentType(this.code, this.description);

  static IdentityDocumentType? fromCode(String code) {
    for (final value in IdentityDocumentType.values) {
      if (value.code == code) return value;
    }
    return null;
  }
}

/// Catálogo 07: Códigos de Tipo de Afectación del IGV.
enum IgvAffectationType {
  gravadoOperacionOnerosa('10', TaxCategoryCode.s, isFree: false),
  gravadoRetiroPremio('11', TaxCategoryCode.z, isFree: true),
  gravadoRetiroDonacion('12', TaxCategoryCode.z, isFree: true),
  gravadoRetiro('13', TaxCategoryCode.z, isFree: true),
  gravadoRetiroPublicidad('14', TaxCategoryCode.z, isFree: true),
  gravadoBonificaciones('15', TaxCategoryCode.z, isFree: true),
  gravadoRetiroEntregaTrabajadores('16', TaxCategoryCode.z, isFree: true),
  gravadoIvap('17', TaxCategoryCode.sIvap, isFree: false),
  exoneradoOperacionOnerosa('20', TaxCategoryCode.e, isFree: false),
  exoneradoTransferenciaGratuita('21', TaxCategoryCode.z, isFree: true),
  inafectoOperacionOnerosa('30', TaxCategoryCode.o, isFree: false),
  inafectoRetiroBonificacion('31', TaxCategoryCode.z, isFree: true),
  inafectoRetiro('32', TaxCategoryCode.z, isFree: true),
  inafectoRetiroMuestrasMedicas('33', TaxCategoryCode.z, isFree: true),
  inafectoRetiroConvenioColectivo('34', TaxCategoryCode.z, isFree: true),
  inafectoRetiroPremio('35', TaxCategoryCode.z, isFree: true),
  inafectoRetiroPublicidad('36', TaxCategoryCode.z, isFree: true),
  exportacion('40', TaxCategoryCode.g, isFree: false);

  final String code;
  final TaxCategoryCode taxCategory;
  final bool isFree;

  const IgvAffectationType(
    this.code,
    this.taxCategory, {
    required this.isFree,
  });

  bool get isGravadoOneroso => this == gravadoOperacionOnerosa;
  bool get isIvap => this == gravadoIvap;
  bool get isExoneradoOneroso => this == exoneradoOperacionOnerosa;
  bool get isInafectoOneroso => this == inafectoOperacionOnerosa;
  bool get isExportacion => this == exportacion;

  static IgvAffectationType? fromCode(String code) {
    for (final value in IgvAffectationType.values) {
      if (value.code == code) return value;
    }
    return null;
  }
}

/// Catálogo 09: Códigos de Tipo de Nota de Crédito Electrónica.
enum CreditNoteReasonCode {
  anulacionOperacion('01', 'Anulación de la operación'),
  anulacionErrorRuc('02', 'Anulación por error en el RUC'),
  correccionErrorDescripcion('03', 'Corrección por error en la descripción'),
  descuentoGlobal('04', 'Descuento global'),
  descuentoPorItem('05', 'Descuento por ítem'),
  devolucionTotal('06', 'Devolución total'),
  devolucionPorItem('07', 'Devolución por ítem'),
  bonificacion('08', 'Bonificación'),
  disminucionValor('09', 'Disminución en el valor'),
  otrosConceptos('10', 'Otros Conceptos'),
  ajustesOperacionesExportacion('11', 'Ajustes de operaciones de exportación'),
  ajustesAfectosIvap('12', 'Ajustes afectos al IVAP'),
  correccionMontoNetoPendientePago(
    '13',
    'Corrección del monto neto pendiente de pago y/o fechas de vencimiento',
  );

  final String code;
  final String description;

  const CreditNoteReasonCode(this.code, this.description);
}

/// Catálogo 10: Códigos de Tipo de Nota de Débito Electrónica.
enum DebitNoteReasonCode {
  interesesPorMora('01', 'Intereses por mora'),
  aumentoEnElValor('02', 'Aumento en el valor'),
  penalidadesOtrosConceptos('03', 'Penalidades / otros conceptos'),
  ajustesOperacionesExportacion('10', 'Ajustes de operaciones de exportación'),
  ajustesAfectosIvap('11', 'Ajustes afectos al IVAP');

  final String code;
  final String description;

  const DebitNoteReasonCode(this.code, this.description);
}

/// Catálogo 18: Modalidad de Traslado (Guías de Remisión).
enum TransportModeCode {
  transportePublico('01', 'Transporte público'),
  transportePrivado('02', 'Transporte privado');

  final String code;
  final String description;

  const TransportModeCode(this.code, this.description);
}

/// Catálogo 19: Estado de Ítem en Resumen Diario de Boletas.
enum SummaryLineStatus {
  adicionar('1', 'Adicionar'),
  modificar('2', 'Modificar'),
  anulado('3', 'Anulado');

  final String code;
  final String description;

  const SummaryLineStatus(this.code, this.description);
}

/// Catálogo 20: Motivo de Traslado (Guías de Remisión).
enum DespatchReasonCode {
  venta('01', 'Venta'),
  compra('02', 'Compra'),
  ventaConEntregaATerceros('03', 'Venta con entrega a terceros'),
  trasladoEntreEstablecimientos('04', 'Traslado entre establecimientos de la misma empresa'),
  consignacion('05', 'Consignación'),
  devolucion('06', 'Devolución'),
  recojoBienesTransformados('07', 'Recojo de bienes transformados'),
  importacion('08', 'Importación'),
  exportacion('09', 'Exportación'),
  otros('13', 'Otros'),
  ventaSujetaConfirmacion('14', 'Venta sujeta a confirmación del comprador'),
  trasladoBienesTransformacion('17', 'Traslado de bienes para transformación'),
  trasladoEmisorItinerante('18', 'Traslado emisor itinerante CP');

  final String code;
  final String description;

  const DespatchReasonCode(this.code, this.description);
}

/// Catálogo 22: Régimen de Percepción.
enum PerceptionRegimeCode {
  ventaInterna('01', 'Percepción Venta Interna - Tasa 2%'),
  adquisicionCombustible('02', 'Percepción a la adquisición de combustible - Tasa 1%'),
  tasaEspecial('03', 'Percepción realizada al agente de percepción con tasa especial - Tasa 0.5%');

  final String code;
  final String description;

  const PerceptionRegimeCode(this.code, this.description);
}

/// Catálogo 23: Régimen de Retención.
enum RetentionRegimeCode {
  tasaTresPorCiento('01', 'Tasa 3%'),
  tasaSeisPorCiento('02', 'Tasa 6%');

  final String code;
  final String description;

  const RetentionRegimeCode(this.code, this.description);
}

/// Catálogo 51: Código de Tipo de Operación.
enum OperationType {
  ventaInterna('0101'),
  ventaInternaAnticipos('0102'),
  ventaItinerante('0103'),
  exportacionBienes('0200'),
  exportacionServiciosPais('0201'),
  operacionSujetaDetraccion('1001'),
  operacionSujetaDetraccionRecursosHidrobiologicos('1002'),
  operacionSujetaDetraccionTransportePasajeros('1003'),
  operacionSujetaDetraccionTransporteCarga('1004'),
  operacionSujetaPercepcion('2001'),
  operacionSujetaRetencion('2002');

  final String code;
  const OperationType(this.code);
}
