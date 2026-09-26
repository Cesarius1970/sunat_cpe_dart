// Copyright (c) 2026, César A Vergara Buenaventura <cesarvergarab@gmail.com>.
// Todos los derechos reservados. Uso sujeto a la licencia en el archivo LICENSE.

import '../catalogos/cpe_catalogo_01_tipo_documento.dart';
import 'cpe_contribuyente.dart';

/// Ítem de comprobante dado de baja.
class CPE_ItemComunicacionBaja {
  final int numeroFila;
  final CPE_Catalogo01_TipoDocumento tipoDocumento;
  final String serie;
  final int correlativo;
  final String motivoBaja;

  const CPE_ItemComunicacionBaja({
    required this.numeroFila,
    required this.tipoDocumento,
    required this.serie,
    required this.correlativo,
    required this.motivoBaja,
  });
}

/// Comunicación de Baja de Facturas, Notas y Guías (UBL VoidedDocuments - Tipo RA).
class CPE_ComunicacionBaja {
  final int correlativoDelDia; // 1 a 5 dígitos (ej. 1 -> RA-20260926-00001)
  final DateTime fechaEmisionComprobantes;
  final DateTime fechaGeneracionBaja;
  final CPE_Contribuyente emisor;
  final List<CPE_ItemComunicacionBaja> comprobantesBaja;

  const CPE_ComunicacionBaja({
    required this.correlativoDelDia,
    required this.fechaEmisionComprobantes,
    required this.fechaGeneracionBaja,
    required this.emisor,
    required this.comprobantesBaja,
  });

  String get identificadorBaja {
    final y = fechaGeneracionBaja.year.toString().padLeft(4, '0');
    final m = fechaGeneracionBaja.month.toString().padLeft(2, '0');
    final d = fechaGeneracionBaja.day.toString().padLeft(2, '0');
    return 'RA-$y$m$d-${correlativoDelDia.toString().padLeft(5, '0')}';
  }

  String get nombreArchivoSunat =>
      '${emisor.numeroDocumento}-$identificadorBaja';
}
