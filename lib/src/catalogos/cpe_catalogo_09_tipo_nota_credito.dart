// Copyright (c) 2026, César A Vergara Buenaventura <cesarvergarab@gmail.com>.
// Todos los derechos reservados. Uso sujeto a la licencia en el archivo LICENSE.

/// Catálogo N° 09 de SUNAT: Códigos de Tipo de Nota de Crédito Electrónica.
enum CPE_Catalogo09_TipoNotaCredito {
  anulacionDeLaOperacion('01', 'Anulación de la operación'),
  anulacionPorErrorEnRuc('02', 'Anulación por error en el RUC'),
  correccionPorErrorEnDescripcion(
    '03',
    'Corrección por error en la descripción',
  ),
  descuentoGlobal('04', 'Descuento global'),
  descuentoPorItem('05', 'Descuento por ítem'),
  devolucionTotal('06', 'Devolución total'),
  devolucionPorItem('07', 'Devolución por ítem'),
  bonificacion('08', 'Bonificación'),
  disminucionEnElValor('09', 'Disminución en el valor'),
  otrosConceptos('10', 'Otros Conceptos'),
  ajustesAfectosAlIvAp('11', 'Ajustes afectos al IVAP'),
  ajustesOperacionesExportacion('12', 'Ajustes de operaciones de exportación'),
  ajustesAfectosAlIcbper('13', 'Ajustes - montos y/o fechas de pago');

  final String codigo;
  final String descripcion;

  const CPE_Catalogo09_TipoNotaCredito(this.codigo, this.descripcion);

  static CPE_Catalogo09_TipoNotaCredito? desdeCodigo(String codigo) {
    for (final n in values) {
      if (n.codigo == codigo) return n;
    }
    return null;
  }
}
