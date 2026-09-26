// Copyright (c) 2026, César A Vergara Buenaventura <cesarvergarab@gmail.com>.
// Todos los derechos reservados. Uso sujeto a la licencia en el archivo LICENSE.

/// Catálogo N° 02 de SUNAT: Código de Tipo de Monedas (ISO 4217).
enum CPE_Catalogo02_Moneda {
  sol('PEN', 'Soles', 'S/'),
  dolarEstadounidense('USD', 'Dólares Americanos', r'$'),
  euro('EUR', 'Euros', '€'),
  libraEsterlina('GBP', 'Libras Esterlinas', '£'),
  yenJapones('JPY', 'Yen Japonés', '¥'),
  francoSuizo('CHF', 'Franco Suizo', 'CHF'),
  dolarCanadiense('CAD', 'Dólar Canadiense', r'C$');

  final String codigoIso;
  final String descripcion;
  final String simbolo;

  const CPE_Catalogo02_Moneda(this.codigoIso, this.descripcion, this.simbolo);

  static CPE_Catalogo02_Moneda? desdeCodigo(String codigo) {
    for (final m in values) {
      if (m.codigoIso.toUpperCase() == codigo.toUpperCase()) return m;
    }
    return null;
  }
}
