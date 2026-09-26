// Copyright (c) 2026, César A Vergara Buenaventura <cesarvergarab@gmail.com>.
// Todos los derechos reservados. Uso sujeto a la licencia en el archivo LICENSE.

import 'package:decimal/decimal.dart';

import '../catalogos/cpe_catalogo_07_afectacion_igv.dart';
import '../sunat_cpe_dart_base.dart';

/// Detalle o ítem individual de una línea de comprobante de pago SUNAT.
class CPE_Item {
  /// Número de orden del ítem (1, 2, 3...).
  final int numeroLinea;

  /// Código interno del producto o servicio.
  final String codigo;

  /// Código de producto según catálogo estándar de la ONU (UNSPSC, opcional).
  final String? codigoSunat;

  /// Descripción detallada del bien o servicio prestado.
  final String descripcion;

  /// Código de unidad de medida comercial según Catálogo 03 (ej. 'NIU' unidad, 'KGM' kilogramos).
  final String unidadMedida;

  /// Cantidad física facturada.
  final Decimal cantidad;

  /// Valor unitario de venta (sin impuestos).
  final CPE_Monto valorUnitario;

  /// Precio unitario de venta comercial (incluye IGV y tributos aplicables).
  final CPE_Monto precioUnitario;

  /// Tipo de afectación al IGV según Catálogo 07.
  final CPE_Catalogo07_AfectacionIgv tipoAfectacionIgv;

  /// Valor de venta de la línea (Base imponible de la línea: `cantidad * valorUnitario`).
  final CPE_Monto valorVenta;

  /// Monto de IGV correspondiente a la línea.
  final CPE_Monto igv;

  /// Porcentaje de IGV aplicado (por defecto 18%).
  final Decimal porcentajeIgv;

  /// Monto de ISC si aplica.
  final CPE_Monto? isc;

  /// Impuesto a las bolsas plásticas (ICBPER) si aplica.
  final CPE_Monto? icbper;

  const CPE_Item({
    required this.numeroLinea,
    required this.codigo,
    required this.descripcion,
    required this.cantidad,
    required this.valorUnitario,
    required this.precioUnitario,
    required this.tipoAfectacionIgv,
    required this.valorVenta,
    required this.igv,
    required this.porcentajeIgv,
    this.unidadMedida = 'NIU',
    this.codigoSunat,
    this.isc,
    this.icbper,
  });

  /// Constructor de cálculo automático a partir de valor unitario sin IGV y cantidad.
  factory CPE_Item.calcularDesdeValorUnitario({
    required int numeroLinea,
    required String codigo,
    required String descripcion,
    required Decimal cantidad,
    required CPE_Monto valorUnitario,
    CPE_Catalogo07_AfectacionIgv afectacion =
        CPE_Catalogo07_AfectacionIgv.gravadoOperacionOnerosa,
    Decimal? porcentajeIgv,
    String unidadMedida = 'NIU',
    String? codigoSunat,
  }) {
    final porcentaje = porcentajeIgv ?? Decimal.fromInt(18);
    final valorVentaCalculado = valorUnitario.multiplicarPor(cantidad);

    CPE_Monto igvCalculado;
    CPE_Monto precioUnitarioCalculado;

    if (afectacion.esGravado && afectacion.esOneroso) {
      final factorIgv = (porcentaje / Decimal.fromInt(100)).toDecimal();
      igvCalculado = CPE_Monto(
        valorVentaCalculado.valor * factorIgv,
        moneda: valorUnitario.moneda,
      );
      final precioConIgv = valorUnitario.valor * (Decimal.one + factorIgv);
      precioUnitarioCalculado = CPE_Monto(
        precioConIgv,
        moneda: valorUnitario.moneda,
      );
    } else {
      igvCalculado = CPE_Monto(Decimal.zero, moneda: valorUnitario.moneda);
      precioUnitarioCalculado = valorUnitario;
    }

    return CPE_Item(
      numeroLinea: numeroLinea,
      codigo: codigo,
      descripcion: descripcion,
      cantidad: cantidad,
      valorUnitario: valorUnitario,
      precioUnitario: precioUnitarioCalculado,
      tipoAfectacionIgv: afectacion,
      valorVenta: valorVentaCalculado,
      igv: igvCalculado,
      porcentajeIgv: porcentaje,
      unidadMedida: unidadMedida,
      codigoSunat: codigoSunat,
    );
  }
}
