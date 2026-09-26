// Copyright (c) 2026, César A Vergara Buenaventura <cesarvergarab@gmail.com>.
// Todos los derechos reservados. Uso sujeto a la licencia en el archivo LICENSE.

import '../catalogos/cpe_catalogo_01_tipo_documento.dart';
import '../catalogos/cpe_catalogo_10_tipo_nota_debito.dart';
import 'cpe_comprobante.dart';

/// Nota de Débito Electrónica (Tipo de Documento 08 de SUNAT).
class CPE_NotaDebito extends CPE_Comprobante {
  @override
  CPE_Catalogo01_TipoDocumento get tipoDocumento =>
      CPE_Catalogo01_TipoDocumento.notaDebito;

  /// Motivo o tipo de nota de débito según Catálogo 10 de SUNAT.
  final CPE_Catalogo10_TipoNotaDebito tipoNotaDebito;

  /// Sustento del motivo por el cual se emite la nota.
  final String sustentoMotivo;

  /// Tipo de documento que se modifica o afecta.
  final CPE_Catalogo01_TipoDocumento tipoDocumentoAfectado;

  /// Serie y número del documento afectado (ej. 'F001-00000045').
  final String numeroDocumentoAfectado;

  const CPE_NotaDebito({
    required super.serie,
    required super.correlativo,
    required super.fechaEmision,
    required super.emisor,
    required super.receptor,
    required super.moneda,
    required super.items,
    required super.totales,
    required this.tipoNotaDebito,
    required this.sustentoMotivo,
    required this.tipoDocumentoAfectado,
    required this.numeroDocumentoAfectado,
    super.horaEmision,
    super.observaciones,
  });
}
