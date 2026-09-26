// Copyright (c) 2026, César A Vergara Buenaventura <cesarvergarab@gmail.com>.
// Todos los derechos reservados. Uso sujeto a la licencia en el archivo LICENSE.

/// Catálogo N° 01 de SUNAT: Código de Tipo de Documento.
enum CPE_Catalogo01_TipoDocumento {
  factura('01', 'Factura Electrónica', esComprobantePago: true),
  boletaVenta('03', 'Boleta de Venta Electrónica', esComprobantePago: true),
  notaCredito('07', 'Nota de Crédito Electrónica', esComprobantePago: true),
  notaDebito('08', 'Nota de Débito Electrónica', esComprobantePago: true),
  guiaRemisionRemitente(
    '09',
    'Guía de Remisión Remitente',
    esGuiaRemision: true,
  ),
  reciboPorHonorarios('02', 'Recibo por Honorarios Electrónico'),
  polizaAdjudicacion('10', 'Póliza de Adjudicación'),
  ticketCajaRegistradora(
    '12',
    'Ticket o cinta emitido por máquina registradora',
  ),
  documentoBanca(
    '13',
    'Documento emitido por bancos o instituciones financieras',
  ),
  comprobanteRetencion(
    '20',
    'Comprobante de Retención Electrónico',
    esRetencionPercepcion: true,
  ),
  guiaRemisionTransportista(
    '31',
    'Guía de Remisión Transportista',
    esGuiaRemision: true,
  ),
  comprobantePercepcion(
    '40',
    'Comprobante de Percepción Electrónico',
    esRetencionPercepcion: true,
  ),
  comprobantePercepcionVentaInterna(
    '41',
    'Comprobante de Percepción Venta Interna',
    esRetencionPercepcion: true,
  ),
  resumenDiario(
    'RC',
    'Resumen Diario de Boletas y Notas',
    esResumenOComunicacion: true,
  ),
  comunicacionBaja(
    'RA',
    'Comunicación de Baja de Comprobantes',
    esResumenOComunicacion: true,
  ),
  resumenReversion(
    'RR',
    'Resumen de Reversiones de Retenciones/Percepciones',
    esResumenOComunicacion: true,
  );

  final String codigo;
  final String descripcion;
  final bool esComprobantePago;
  final bool esGuiaRemision;
  final bool esRetencionPercepcion;
  final bool esResumenOComunicacion;

  const CPE_Catalogo01_TipoDocumento(
    this.codigo,
    this.descripcion, {
    this.esComprobantePago = false,
    this.esGuiaRemision = false,
    this.esRetencionPercepcion = false,
    this.esResumenOComunicacion = false,
  });

  /// Busca el tipo de documento a partir de su código SUNAT de dos caracteres.
  static CPE_Catalogo01_TipoDocumento? desdeCodigo(String codigo) {
    for (final tipo in values) {
      if (tipo.codigo == codigo) return tipo;
    }
    return null;
  }
}
