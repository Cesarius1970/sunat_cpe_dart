// Copyright (c) 2026, César A Vergara Buenaventura <cesarvergarab@gmail.com>.
// Todos los derechos reservados. Uso sujeto a la licencia en el archivo LICENSE.

/// Catálogo N° 06 de SUNAT: Códigos de Tipos de Documentos de Identidad.
enum CPE_Catalogo06_TipoDocumentoIdentidad {
  sinDocumento('0', 'Doc.trib.no.dom.sin.ruc', longitudExacta: null),
  dni('1', 'Documento Nacional de Identidad (DNI)', longitudExacta: 8),
  carnetExtranjeria('4', 'Carnet de Extranjería', longitudExacta: null),
  ruc('6', 'Registro Único de Contribuyentes (RUC)', longitudExacta: 11),
  pasaporte('7', 'Pasaporte', longitudExacta: null),
  cedulaDiplomatica(
    'A',
    'Cédula Diplomática de Identidad',
    longitudExacta: null,
  ),
  docIdentidadPaisResidencia(
    'B',
    'Doc. Identidad País Residencia-No Domiciliado',
    longitudExacta: null,
  ),
  taxIdentificationNumber(
    'C',
    'Tax Identification Number - TIN',
    longitudExacta: null,
  ),
  identificationNumber('D', 'Identification Number - IN', longitudExacta: null),
  tam('E', 'Tarjeta Andina de Migración - TAM', longitudExacta: null),
  permisoTemporalPermanencia(
    'F',
    'Permiso Temporal de Permanencia - PTP',
    longitudExacta: null,
  );

  final String codigo;
  final String descripcion;
  final int? longitudExacta;

  const CPE_Catalogo06_TipoDocumentoIdentidad(
    this.codigo,
    this.descripcion, {
    this.longitudExacta,
  });

  static CPE_Catalogo06_TipoDocumentoIdentidad? desdeCodigo(String codigo) {
    for (final tipo in values) {
      if (tipo.codigo == codigo) return tipo;
    }
    return null;
  }
}
