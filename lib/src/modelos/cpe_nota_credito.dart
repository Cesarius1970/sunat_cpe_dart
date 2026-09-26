// Copyright (c) 2026, César A Vergara Buenaventura <cesarvergarab@gmail.com>.
// Todos los derechos reservados. Uso sujeto a la licencia en el archivo LICENSE.

import '../catalogos/cpe_catalogo_01_tipo_documento.dart';
import '../catalogos/cpe_catalogo_09_tipo_nota_credito.dart';
import 'cpe_comprobante.dart';

/// Nota de Crédito Electrónica (Tipo de Documento 07 de SUNAT).
class CPE_NotaCredito extends CPE_Comprobante {
  @override
  CPE_Catalogo01_TipoDocumento get tipoDocumento =>
      CPE_Catalogo01_TipoDocumento.notaCredito;

  /// Motivo o tipo de nota de crédito según Catálogo 09 de SUNAT.
  final CPE_Catalogo09_TipoNotaCredito tipoNotaCredito;

  /// Descripción o sustento del motivo por el cual se emite la nota.
  final String sustentoMotivo;

  /// Tipo de documento que se modifica o afecta (ej. Factura '01' o Boleta '03').
  final CPE_Catalogo01_TipoDocumento tipoDocumentoAfectado;

  /// Serie y número del documento afectado (ej. 'F001-00000045').
  final String numeroDocumentoAfectado;

  const CPE_NotaCredito({
    required super.serie,
    required super.correlativo,
    required super.fechaEmision,
    required super.emisor,
    required super.receptor,
    required super.moneda,
    required super.items,
    required super.totales,
    required this.tipoNotaCredito,
    required this.sustentoMotivo,
    required this.tipoDocumentoAfectado,
    required this.numeroDocumentoAfectado,
    super.horaEmision,
    super.observaciones,
  });
}
