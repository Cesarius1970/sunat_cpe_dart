// Copyright (c) 2026, César A Vergara Buenaventura <cesarvergarab@gmail.com>.
// Todos los derechos reservados. Uso sujeto a la licencia en el archivo LICENSE.

/// Catálogo N° 20 de SUNAT: Motivos de Traslado (Guías de Remisión).
enum CPE_Catalogo20_MotivoTraslado {
  venta('01', 'Venta'),
  compra('02', 'Compra'),
  ventaConEntregaATerceros('03', 'Venta con entrega a terceros'),
  trasladoEntreEstablecimientos(
    '04',
    'Traslado entre establecimientos de la misma empresa',
  ),
  consignacion('05', 'Consignación'),
  devolucion('06', 'Devolución'),
  recojoDeBienesTransformados('07', 'Recojo de bienes transformados'),
  importacion('08', 'Importación'),
  exportacion('09', 'Exportación'),
  ventaItinerante('11', 'Venta sujeta a confirmación del comprador'),
  trasladoBienesTransformacion('13', 'Traslado de bienes para transformación'),
  trasladoPorEmisorItinerante('14', 'Traslado por emisor itinerante'),
  trasladoZonaPrimaria('17', 'Traslado a zona primaria'),
  otros('19', 'Otros motivos de traslado');

  final String codigo;
  final String descripcion;

  const CPE_Catalogo20_MotivoTraslado(this.codigo, this.descripcion);

  static CPE_Catalogo20_MotivoTraslado? desdeCodigo(String codigo) {
    for (final m in values) {
      if (m.codigo == codigo) return m;
    }
    return null;
  }
}
