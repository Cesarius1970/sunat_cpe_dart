// Copyright (c) 2026, César A Vergara Buenaventura <cesarvergarab@gmail.com>.
// Todos los derechos reservados. Uso sujeto a la licencia en el archivo LICENSE.

/// Catálogo N° 18 de SUNAT: Modalidad de Traslado (Guías de Remisión).
enum CPE_Catalogo18_ModalidadTraslado {
  transportePublico('01', 'Transporte público'),
  transportePrivado('02', 'Transporte privado');

  final String codigo;
  final String descripcion;

  const CPE_Catalogo18_ModalidadTraslado(this.codigo, this.descripcion);

  static CPE_Catalogo18_ModalidadTraslado? desdeCodigo(String codigo) {
    for (final m in values) {
      if (m.codigo == codigo) return m;
    }
    return null;
  }
}
