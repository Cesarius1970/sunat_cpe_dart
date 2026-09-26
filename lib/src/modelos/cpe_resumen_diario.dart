// Copyright (c) 2026, César A Vergara Buenaventura <cesarvergarab@gmail.com>.
// Todos los derechos reservados. Uso sujeto a la licencia en el archivo LICENSE.

import '../catalogos/cpe_catalogo_01_tipo_documento.dart';
import '../catalogos/cpe_catalogo_02_monedas.dart';
import 'cpe_contribuyente.dart';
import 'cpe_totales.dart';

/// Línea o comprobante consolidado en un Resumen Diario de Boletas y Notas.
class CPE_ItemResumenDiario {
  final int numeroFila;
  final CPE_Catalogo01_TipoDocumento tipoDocumento;
  final String serie;
  final int correlativo;
  final CPE_Contribuyente receptor;
  final CPE_Totales totales;
  final int estadoItem; // 1 = Adición, 2 = Modificación, 3 = Anulación

  const CPE_ItemResumenDiario({
    required this.numeroFila,
    required this.tipoDocumento,
    required this.serie,
    required this.correlativo,
    required this.receptor,
    required this.totales,
    this.estadoItem = 1,
  });
}

/// Resumen Diario de Boletas y Notas Asociadas (UBL SummaryDocuments - Tipo RC).
class CPE_ResumenDiario {
  final int correlativoDelDia; // 1 a 5 dígitos (ej. 1 -> RC-20260926-00001)
  final DateTime fechaEmisionComprobantes;
  final DateTime fechaGeneracionResumen;
  final CPE_Contribuyente emisor;
  final CPE_Catalogo02_Moneda moneda;
  final List<CPE_ItemResumenDiario> comprobantes;

  const CPE_ResumenDiario({
    required this.correlativoDelDia,
    required this.fechaEmisionComprobantes,
    required this.fechaGeneracionResumen,
    required this.emisor,
    required this.moneda,
    required this.comprobantes,
  });

  String get identificadorResumen {
    final y = fechaGeneracionResumen.year.toString().padLeft(4, '0');
    final m = fechaGeneracionResumen.month.toString().padLeft(2, '0');
    final d = fechaGeneracionResumen.day.toString().padLeft(2, '0');
    return 'RC-$y$m$d-${correlativoDelDia.toString().padLeft(5, '0')}';
  }

  String get nombreArchivoSunat =>
      '${emisor.numeroDocumento}-$identificadorResumen';
}
