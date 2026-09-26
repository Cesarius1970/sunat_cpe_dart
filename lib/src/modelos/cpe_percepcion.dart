// Copyright (c) 2026, César A Vergara Buenaventura <cesarvergarab@gmail.com>.
// Todos los derechos reservados. Uso sujeto a la licencia en el archivo LICENSE.

import 'package:decimal/decimal.dart';

import '../catalogos/cpe_catalogo_01_tipo_documento.dart';
import '../sunat_cpe_dart_base.dart';
import 'cpe_contribuyente.dart';

/// Documento relacionado o cobrado en un Comprobante de Percepción.
class CPE_DocumentoPercibido {
  final CPE_Catalogo01_TipoDocumento tipoDocumento;
  final String serie;
  final int correlativo;
  final DateTime fechaEmision;
  final CPE_Monto totalDocumento;
  final DateTime fechaCobro;
  final int numeroCobro;
  final CPE_Monto importeCobroSinPercepcion;
  final CPE_Monto importePercibido;
  final CPE_Monto importeTotalCobrado;

  const CPE_DocumentoPercibido({
    required this.tipoDocumento,
    required this.serie,
    required this.correlativo,
    required this.fechaEmision,
    required this.totalDocumento,
    required this.fechaCobro,
    required this.numeroCobro,
    required this.importeCobroSinPercepcion,
    required this.importePercibido,
    required this.importeTotalCobrado,
  });
}

/// Comprobante de Percepción Electrónica (Tipo 40 de SUNAT).
class CPE_Percepcion {
  final String serie;
  final int correlativo;
  final DateTime fechaEmision;
  final CPE_Contribuyente agentePercepcion;
  final CPE_Contribuyente cliente;
  final String regimenPercepcion; // Catálogo 22 (ej. '01' Tasa 2%, '02' Tasa 1%, '03' Tasa 0.5%)
  final Decimal tasaPorcentaje;
  final CPE_Monto totalPercibido;
  final CPE_Monto totalCobrado;
  final List<CPE_DocumentoPercibido> documentos;
  final String? observaciones;

  const CPE_Percepcion({
    required this.serie,
    required this.correlativo,
    required this.fechaEmision,
    required this.agentePercepcion,
    required this.cliente,
    required this.regimenPercepcion,
    required this.tasaPorcentaje,
    required this.totalPercibido,
    required this.totalCobrado,
    required this.documentos,
    this.observaciones,
  });

  CPE_Catalogo01_TipoDocumento get tipoDocumento =>
      CPE_Catalogo01_TipoDocumento.comprobantePercepcion;

  String get identificadorComprobante =>
      '$serie-${correlativo.toString().padLeft(8, '0')}';

  String get nombreArchivoSunat =>
      '${agentePercepcion.numeroDocumento}-${tipoDocumento.codigo}-$serie-${correlativo.toString().padLeft(8, '0')}';
}
