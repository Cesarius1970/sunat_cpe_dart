// Copyright (c) 2026, César A Vergara Buenaventura <cesarvergarab@gmail.com>.
// Todos los derechos reservados. Uso sujeto a la licencia en el archivo LICENSE.

/// Domicilio fiscal o dirección de un contribuyente según catálogo de SUNAT.
class CPE_Direccion {
  /// Código de ubigeo (6 dígitos, ej. '150101' para Lima).
  final String? ubigeo;

  /// Dirección completa (avenida, calle, número, etc.).
  final String direccion;

  /// Urbanización o zona.
  final String? urbanizacion;

  /// Nombre del departamento.
  final String? departamento;

  /// Nombre de la provincia.
  final String? provincia;

  /// Nombre del distrito.
  final String? distrito;

  /// Código de país (ISO 3166-1 alfa-2, por defecto 'PE').
  final String codigoPais;

  const CPE_Direccion({
    required this.direccion,
    this.ubigeo,
    this.urbanizacion,
    this.departamento,
    this.provincia,
    this.distrito,
    this.codigoPais = 'PE',
  });
}
