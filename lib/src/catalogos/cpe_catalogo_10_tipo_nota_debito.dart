// Copyright (c) 2026, César A Vergara Buenaventura <cesarvergarab@gmail.com>.
// Todos los derechos reservados. Uso sujeto a la licencia en el archivo LICENSE.

/// Catálogo N° 10 de SUNAT: Códigos de Tipo de Nota de Débito Electrónica.
enum CPE_Catalogo10_TipoNotaDebito {
  interesPorMora('01', 'Interés por mora'),
  aumentoEnElValor('02', 'Aumento en el valor'),
  penalidadesOtrosConceptos('03', 'Penalidades/ otros conceptos'),
  ajustesAfectosAlIvAp('11', 'Ajustes afectos al IVAP'),
  ajustesOperacionesExportacion('12', 'Ajustes de operaciones de exportación');

  final String codigo;
  final String descripcion;

  const CPE_Catalogo10_TipoNotaDebito(this.codigo, this.descripcion);

  static CPE_Catalogo10_TipoNotaDebito? desdeCodigo(String codigo) {
    for (final n in values) {
      if (n.codigo == codigo) return n;
    }
    return null;
  }
}
