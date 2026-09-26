// Copyright (c) 2026, César A Vergara Buenaventura <cesarvergarab@gmail.com>.
// Todos los derechos reservados. Uso sujeto a la licencia en el archivo LICENSE.

import 'package:decimal/decimal.dart';
import 'package:sunat_cpe_dart/sunat_cpe_dart.dart';
import 'package:test/test.dart';

void main() {
  group('Pruebas de CPE_Monto y cálculo monetario exacto', () {
    test('Creación desde texto y centavos', () {
      final montoTexto = CPE_Monto.desdeTexto('100.50');
      final montoCentavos = CPE_Monto.desdeCentavos(10050);

      expect(montoTexto, equals(montoCentavos));
      expect(montoTexto.aFormatoUbl(), equals('100.50'));
    });

    test('Precisión decimal sin errores de punto flotante IEEE 754', () {
      // 0.1 + 0.2 en double produce 0.30000000000000004
      // CPE_Monto debe producir exactamente 0.30
      final m1 = CPE_Monto.desdeTexto('0.10');
      final m2 = CPE_Monto.desdeTexto('0.20');
      final suma = m1 + m2;

      expect(suma.aFormatoUbl(), equals('0.30'));
      expect(suma.valor, equals(Decimal.parse('0.3')));
    });

    test('Cálculo de IGV estándar al 18%', () {
      final base = CPE_Monto.desdeTexto('1000.00');
      final igv = cpe_calcular_igv(base);

      expect(igv.aFormatoUbl(), equals('180.00'));
      expect(igv.moneda, equals('PEN'));
    });

    test('Validación de rechazo al operar distintas monedas', () {
      final enSoles = CPE_Monto.desdeTexto('100.00', moneda: 'PEN');
      final enDolares = CPE_Monto.desdeTexto('100.00', moneda: 'USD');

      expect(() => enSoles + enDolares, throwsArgumentError);
    });
  });

  group('Pruebas de Catálogo 01 - CPE_TipoDocumento', () {
    test('Códigos oficiales SUNAT', () {
      expect(CPE_TipoDocumento.factura.codigoSunat, equals('01'));
      expect(CPE_TipoDocumento.boleta.codigoSunat, equals('03'));
      expect(CPE_TipoDocumento.notaCredito.codigoSunat, equals('07'));
      expect(CPE_TipoDocumento.notaDebito.codigoSunat, equals('08'));
    });
  });
}
