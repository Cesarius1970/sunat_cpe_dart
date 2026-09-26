// Copyright (c) 2026, César A Vergara Buenaventura <cesarvergarab@gmail.com>.
// Todos los derechos reservados. Uso sujeto a la licencia en el archivo LICENSE.

/// Catálogo N° 51 / 17 de SUNAT: Códigos de Tipo de Operación.
enum CPE_Catalogo17_TipoOperacion {
  ventaInterna('0101', 'Venta interna'),
  exportacion('0200', 'Exportación de bienes'),
  noDomiciliados('0300', 'Operaciones con no domiciliados'),
  ventaInternaAnticipos('0102', 'Venta interna - Anticipos'),
  ventaItinerante('0103', 'Venta itinerante'),
  facturaGuia('0104', 'Factura guía'),
  ventaArrozPilado('0105', 'Venta arroz pilado'),
  facturaComprobantePercepcion('0106', 'Factura - Comprobante de Percepción'),
  trasladoBienesVenta('0108', 'Traslado de bienes para venta'),
  exportacionServicios('0201', 'Exportación de servicios');

  final String codigo;
  final String descripcion;

  const CPE_Catalogo17_TipoOperacion(this.codigo, this.descripcion);

  static CPE_Catalogo17_TipoOperacion? desdeCodigo(String codigo) {
    for (final op in values) {
      if (op.codigo == codigo) return op;
    }
    return null;
  }
}
