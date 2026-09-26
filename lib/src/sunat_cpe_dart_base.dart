// Copyright (c) 2026, César A Vergara Buenaventura <cesarvergarab@gmail.com>.
// Todos los derechos reservados. Uso sujeto a la licencia en el archivo LICENSE.

import 'package:decimal/decimal.dart';

/// Catálogo 01 de SUNAT: Código de Tipo de Documento del CPE.
enum CPE_TipoDocumento {
  /// Factura Electrónica (Código '01').
  factura('01', 'Factura'),

  /// Boleta de Venta Electrónica (Código '03').
  boleta('03', 'Boleta de Venta'),

  /// Nota de Crédito Electrónica (Código '07').
  notaCredito('07', 'Nota de Crédito'),

  /// Nota de Débito Electrónica (Código '08').
  notaDebito('08', 'Nota de Débito'),

  /// Guía de Remisión Remitente (Código '09').
  guiaRemisionRemitente('09', 'Guía de Remisión Remitente');

  /// Código oficial asignado por SUNAT.
  final String codigoSunat;

  /// Descripción legible del tipo de documento.
  final String descripcion;

  const CPE_TipoDocumento(this.codigoSunat, this.descripcion);
}

/// Representa un valor monetario exacto dentro de un comprobante electrónico SUNAT.
///
/// **Regla de Negocio:**
/// De acuerdo con la normativa técnica de SUNAT (UBL 2.1) y las buenas prácticas
/// contables, queda prohibido el uso de tipos de coma flotante (`double`) debido a
/// los errores de redondeo inherentes al estándar IEEE 754. Se emplea [Decimal]
/// para garantizar consistencia absoluta en céntimos y totales.
class CPE_Monto {
  /// Valor numérico de alta precisión.
  final Decimal valor;

  /// Código de moneda según Catálogo 02 de SUNAT (ej. 'PEN', 'USD').
  final String moneda;

  /// Constructor principal que recibe un [Decimal] exacto y la moneda (por defecto 'PEN').
  const CPE_Monto(this.valor, {this.moneda = 'PEN'});

  /// Constructor alternativo a partir de una cadena numérica (ej. `"123.45"`).
  factory CPE_Monto.desdeTexto(String valorTexto, {String moneda = 'PEN'}) {
    return CPE_Monto(Decimal.parse(valorTexto), moneda: moneda);
  }

  /// Constructor a partir de centavos enteros (ej. `12345` centavos = `123.45`).
  factory CPE_Monto.desdeCentavos(int centavos, {String moneda = 'PEN'}) {
    final valorDecimal = (Decimal.fromInt(centavos) / Decimal.fromInt(100))
        .toDecimal();
    return CPE_Monto(valorDecimal, moneda: moneda);
  }

  /// Suma dos importes validando que pertenezcan a la misma divisa.
  CPE_Monto operator +(CPE_Monto otro) {
    _validarMismaMoneda(otro);
    return CPE_Monto(valor + otro.valor, moneda: moneda);
  }

  /// Resta dos importes validando que pertenezcan a la misma divisa.
  CPE_Monto operator -(CPE_Monto otro) {
    _validarMismaMoneda(otro);
    return CPE_Monto(valor - otro.valor, moneda: moneda);
  }

  /// Multiplica el importe por una cantidad o factor [Decimal].
  CPE_Monto multiplicarPor(Decimal factor) {
    return CPE_Monto(valor * factor, moneda: moneda);
  }

  /// Valida que la moneda coincida para operaciones aritméticas.
  void _validarMismaMoneda(CPE_Monto otro) {
    if (moneda != otro.moneda) {
      throw ArgumentError(
        'No se pueden operar importes con distinta moneda: $moneda vs ${otro.moneda}',
      );
    }
  }

  /// Formatea el importe con dos decimales para nodos UBL estándar
  /// (ej. `cbc:PayableAmount`, `cbc:TaxAmount`, `cbc:LineExtensionAmount`).
  String aFormatoUbl() {
    final scale = valor.scale;
    if (scale <= 2) {
      return valor.toStringAsFixed(2);
    }
    // Redondeo estándar bancario / comercial a 2 decimales
    return valor.toStringAsFixed(2);
  }

  /// Formatea el precio unitario con la escala requerida por SUNAT (hasta 10 decimales en `cbc:PriceAmount`).
  String aFormatoPrecioUnitario({int decimales = 2}) {
    return valor.toStringAsFixed(decimales);
  }

  @override
  String toString() => '$moneda ${aFormatoUbl()}';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CPE_Monto &&
          runtimeType == other.runtimeType &&
          valor == other.valor &&
          moneda == other.moneda;

  @override
  int get hashCode => valor.hashCode ^ moneda.hashCode;
}

/// Función auxiliar para calcular el Impuesto General a las Ventas (IGV).
///
/// Por defecto aplica la tasa general del 18% ([tasaPorcentaje] = 18).
/// Emplea aritmética [Decimal] pura para evitar descalces de céntimos en SUNAT.
CPE_Monto cpe_calcular_igv(CPE_Monto baseImponible, {Decimal? tasaPorcentaje}) {
  final tasa = tasaPorcentaje ?? Decimal.fromInt(18);
  final factor = (tasa / Decimal.fromInt(100)).toDecimal();
  final montoIgv = baseImponible.valor * factor;
  return CPE_Monto(montoIgv, moneda: baseImponible.moneda);
}
