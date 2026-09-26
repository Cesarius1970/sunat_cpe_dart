// Copyright (c) 2026, César A Vergara Buenaventura <cesarvergarab@gmail.com>.
// Todos los derechos reservados. Uso sujeto a la licencia en el archivo LICENSE.

import 'package:decimal/decimal.dart';

import '../sunat_cpe_dart_base.dart';
import 'cpe_item.dart';

/// Agrupación de bases imponibles, tributos y totales finales de un comprobante.
class CPE_Totales {
  /// Total valor de venta operaciones gravadas.
  final CPE_Monto totalGravado;

  /// Total valor de venta operaciones inafectas.
  final CPE_Monto totalInafecto;

  /// Total valor de venta operaciones exoneradas.
  final CPE_Monto totalExonerado;

  /// Total valor de venta operaciones de exportación.
  final CPE_Monto totalExportacion;

  /// Total valor de venta operaciones gratuitas.
  final CPE_Monto totalGratuito;

  /// Sumatoria total de IGV liquidado.
  final CPE_Monto totalIgv;

  /// Sumatoria total de ISC si aplica.
  final CPE_Monto totalIsc;

  /// Sumatoria total de otros tributos si aplica.
  final CPE_Monto totalOtrosTributos;

  /// Total cargos o recargos al comprobante.
  final CPE_Monto totalCargos;

  /// Total descuentos globales aplicados.
  final CPE_Monto totalDescuentos;

  /// Importe total a pagar (Importe final del comprobante).
  final CPE_Monto importeTotalPagar;

  const CPE_Totales({
    required this.totalGravado,
    required this.totalInafecto,
    required this.totalExonerado,
    required this.totalExportacion,
    required this.totalGratuito,
    required this.totalIgv,
    required this.totalIsc,
    required this.totalOtrosTributos,
    required this.totalCargos,
    required this.totalDescuentos,
    required this.importeTotalPagar,
  });

  /// Calcula automáticamente los totales a partir de una lista de ítems.
  factory CPE_Totales.calcularDesdeItems(
    List<CPE_Item> items, {
    String moneda = 'PEN',
  }) {
    var gravado = Decimal.zero;
    var inafecto = Decimal.zero;
    var exonerado = Decimal.zero;
    var exportacion = Decimal.zero;
    var gratuito = Decimal.zero;
    var sumIgv = Decimal.zero;
    var sumIsc = Decimal.zero;

    for (final it in items) {
      if (it.tipoAfectacionIgv.esGravado && it.tipoAfectacionIgv.esOneroso) {
        gravado += it.valorVenta.valor;
        sumIgv += it.igv.valor;
      } else if (it.tipoAfectacionIgv.esExonerado) {
        exonerado += it.valorVenta.valor;
      } else if (it.tipoAfectacionIgv.esInafecto) {
        inafecto += it.valorVenta.valor;
      } else if (it.tipoAfectacionIgv.esExportacion) {
        exportacion += it.valorVenta.valor;
      } else {
        gratuito += it.valorVenta.valor;
      }

      if (it.isc != null) {
        sumIsc += it.isc!.valor;
      }
    }

    final totalPagar =
        gravado + inafecto + exonerado + exportacion + sumIgv + sumIsc;

    return CPE_Totales(
      totalGravado: CPE_Monto(gravado, moneda: moneda),
      totalInafecto: CPE_Monto(inafecto, moneda: moneda),
      totalExonerado: CPE_Monto(exonerado, moneda: moneda),
      totalExportacion: CPE_Monto(exportacion, moneda: moneda),
      totalGratuito: CPE_Monto(gratuito, moneda: moneda),
      totalIgv: CPE_Monto(sumIgv, moneda: moneda),
      totalIsc: CPE_Monto(sumIsc, moneda: moneda),
      totalOtrosTributos: CPE_Monto(Decimal.zero, moneda: moneda),
      totalCargos: CPE_Monto(Decimal.zero, moneda: moneda),
      totalDescuentos: CPE_Monto(Decimal.zero, moneda: moneda),
      importeTotalPagar: CPE_Monto(totalPagar, moneda: moneda),
    );
  }
}
