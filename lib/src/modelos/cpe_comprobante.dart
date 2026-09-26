// Copyright (c) 2026, César A Vergara Buenaventura <cesarvergarab@gmail.com>.
// Todos los derechos reservados. Uso sujeto a la licencia en el archivo LICENSE.

import '../catalogos/cpe_catalogo_01_tipo_documento.dart';
import '../catalogos/cpe_catalogo_02_monedas.dart';
import 'cpe_contribuyente.dart';
import 'cpe_totales.dart';
import 'cpe_item.dart';

/// Clase base abstracta para todos los Comprobantes de Pago Electrónicos (CPE) de SUNAT.
abstract class CPE_Comprobante {
  /// Tipo de documento según Catálogo 01 de SUNAT.
  CPE_Catalogo01_TipoDocumento get tipoDocumento;

  /// Serie del comprobante (ej. 'F001', 'B001', 'FC01', 'T001').
  final String serie;

  /// Correlativo numérico del comprobante (1 a 8 dígitos).
  final int correlativo;

  /// Fecha de emisión del comprobante (AAAA-MM-DD).
  final DateTime fechaEmision;

  /// Hora de emisión del comprobante.
  final String? horaEmision;

  /// Contribuyente emisor del comprobante.
  final CPE_Contribuyente emisor;

  /// Contribuyente receptor del comprobante.
  final CPE_Contribuyente receptor;

  /// Moneda en la que se emite la operación.
  final CPE_Catalogo02_Moneda moneda;

  /// Ítems o líneas de detalle del comprobante.
  final List<CPE_Item> items;

  /// Totales y tributos calculados del comprobante.
  final CPE_Totales totales;

  /// Observaciones o notas adicionales del comprobante.
  final String? observaciones;

  const CPE_Comprobante({
    required this.serie,
    required this.correlativo,
    required this.fechaEmision,
    required this.emisor,
    required this.receptor,
    required this.moneda,
    required this.items,
    required this.totales,
    this.horaEmision,
    this.observaciones,
  });

  /// Identificador compuesto oficial del comprobante (ej. `'F001-00000001'`).
  String get identificadorComprobante =>
      '$serie-${correlativo.toString().padLeft(8, '0')}';

  /// Nombre del archivo XML o ZIP requerido por SUNAT:
  /// Formato: `{RUC}-{TIPO_DOC}-{SERIE}-{CORRELATIVO}`
  String get nombreArchivoSunat =>
      '${emisor.numeroDocumento}-${tipoDocumento.codigo}-$serie-${correlativo.toString().padLeft(8, '0')}';

  /// Fecha formateada como AAAA-MM-DD para nodos UBL `cbc:IssueDate`.
  String get fechaEmisionFormatoUbl {
    final y = fechaEmision.year.toString().padLeft(4, '0');
    final m = fechaEmision.month.toString().padLeft(2, '0');
    final d = fechaEmision.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }
}
