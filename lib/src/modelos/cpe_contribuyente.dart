// Copyright (c) 2026, César A Vergara Buenaventura <cesarvergarab@gmail.com>.
// Todos los derechos reservados. Uso sujeto a la licencia en el archivo LICENSE.

import '../catalogos/cpe_catalogo_06_tipo_documento_identidad.dart';
import 'cpe_direccion.dart';

/// Datos del contribuyente (emisor o receptor) en comprobantes de pago SUNAT.
class CPE_Contribuyente {
  /// Número de documento de identidad (RUC, DNI, etc.).
  final String numeroDocumento;

  /// Tipo de documento de identidad según Catálogo 06 de SUNAT.
  final CPE_Catalogo06_TipoDocumentoIdentidad tipoDocumento;

  /// Razón Social o Nombres y Apellidos completos.
  final String razonSocial;

  /// Nombre comercial (opcional).
  final String? nombreComercial;

  /// Domicilio fiscal o dirección.
  final CPE_Direccion? direccion;

  /// Correo electrónico para notificaciones.
  final String? correoElectronico;

  /// Teléfono de contacto.
  final String? telefono;

  const CPE_Contribuyente({
    required this.numeroDocumento,
    required this.tipoDocumento,
    required this.razonSocial,
    this.nombreComercial,
    this.direccion,
    this.correoElectronico,
    this.telefono,
  });

  /// Constructor de conveniencia para emisor con RUC.
  factory CPE_Contribuyente.emisorRuc({
    required String ruc,
    required String razonSocial,
    String? nombreComercial,
    CPE_Direccion? direccion,
    String? correoElectronico,
  }) {
    return CPE_Contribuyente(
      numeroDocumento: ruc,
      tipoDocumento: CPE_Catalogo06_TipoDocumentoIdentidad.ruc,
      razonSocial: razonSocial,
      nombreComercial: nombreComercial,
      direccion: direccion,
      correoElectronico: correoElectronico,
    );
  }
}
