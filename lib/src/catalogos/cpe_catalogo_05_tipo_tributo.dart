// Copyright (c) 2026, César A Vergara Buenaventura <cesarvergarab@gmail.com>.
// Todos los derechos reservados. Uso sujeto a la licencia en el archivo LICENSE.

/// Catálogo N° 05 de SUNAT: Códigos de Tipos de Tributos.
enum CPE_Catalogo05_TipoTributo {
  igv('1000', 'IGV', 'Impuesto General a las Ventas', 'VAT'),
  ivap('1016', 'IVAP', 'Impuesto a la Venta de Arroz Pilado', 'VAT'),
  isc('2000', 'ISC', 'Impuesto Selectivo al Consumo', 'EXC'),
  exportacion('9995', 'EXP', 'Exportación', 'FRE'),
  gratuito('9996', 'GRA', 'Gratuito', 'FRE'),
  exonerado('9997', 'EXO', 'Exonerado', 'VAT'),
  inafecto('9998', 'INA', 'Inafecto', 'FRE'),
  otrosTributos('9999', 'OTROS', 'Otros conceptos de pago', 'OTH');

  final String codigoSunat;
  final String nombreCorto;
  final String descripcion;
  final String codigoInternacionalUnece;

  const CPE_Catalogo05_TipoTributo(
    this.codigoSunat,
    this.nombreCorto,
    this.descripcion,
    this.codigoInternacionalUnece,
  );

  static CPE_Catalogo05_TipoTributo? desdeCodigo(String codigo) {
    for (final t in values) {
      if (t.codigoSunat == codigo) return t;
    }
    return null;
  }
}
