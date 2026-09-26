// Copyright (c) 2026, César A Vergara Buenaventura <cesarvergarab@gmail.com>.
// Todos los derechos reservados. Uso sujeto a la licencia en el archivo LICENSE.

import 'package:decimal/decimal.dart';

import '../catalogos/cpe_catalogo_01_tipo_documento.dart';
import '../sunat_cpe_dart_base.dart';
import 'cpe_contribuyente.dart';

/// Documento relacionado o pagado en un Comprobante de Retención.
class CPE_DocumentoRetenido {
  final CPE_Catalogo01_TipoDocumento tipoDocumento;
  final String serie;
  final int correlativo;
  final DateTime fechaEmision;
  final CPE_Monto totalDocumento;
  final DateTime fechaPago;
  final int numeroPago;
  final CPE_Monto importePagoSinRetencion;
  final CPE_Monto importeRetenido;
  final CPE_Monto importeNetoPagado;

  const CPE_DocumentoRetenido({
    required this.tipoDocumento,
    required this.serie,
    required this.correlativo,
    required this.fechaEmision,
    required this.totalDocumento,
    required this.fechaPago,
    required this.numeroPago,
    required this.importePagoSinRetencion,
    required this.importeRetenido,
    required this.importeNetoPagado,
  });
}

/// Comprobante de Retención Electrónica (Tipo 20 de SUNAT).
class CPE_Retencion {
  final String serie;
  final int correlativo;
  final DateTime fechaEmision;
  final CPE_Contribuyente agenteRetencion;
  final CPE_Contribuyente proveedor;
  final String regimenRetencion; // Catálogo 23 (ej. '01' Tasa 3%)
  final Decimal tasaPorcentaje;
  final CPE_Monto totalRetenido;
  final CPE_Monto totalPagado;
  final List<CPE_DocumentoRetenido> documentos;
  final String? observaciones;

  const CPE_Retencion({
    required this.serie,
    required this.correlativo,
    required this.fechaEmision,
    required this.agenteRetencion,
    required this.proveedor,
    required this.regimenRetencion,
    required this.tasaPorcentaje,
    required this.totalRetenido,
    required this.totalPagado,
    required this.documentos,
    this.observaciones,
  });

  CPE_Catalogo01_TipoDocumento get tipoDocumento =>
      CPE_Catalogo01_TipoDocumento.comprobanteRetencion;

  String get identificadorComprobante =>
      '$serie-${correlativo.toString().padLeft(8, '0')}';

  String get nombreArchivoSunat =>
      '${agenteRetencion.numeroDocumento}-${tipoDocumento.codigo}-$serie-${correlativo.toString().padLeft(8, '0')}';
}
