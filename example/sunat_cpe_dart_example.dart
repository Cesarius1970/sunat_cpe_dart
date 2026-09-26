// Copyright (c) 2026, César A Vergara Buenaventura <cesarvergarab@gmail.com>.
// Todos los derechos reservados. Uso sujeto a la licencia en el archivo LICENSE.

import 'package:sunat_cpe_dart/sunat_cpe_dart.dart';

void main() {
  // Ejemplo de creación de importe con precisión decimal pura (sin punto flotante)
  final baseImponible = CPE_Monto.desdeTexto('1500.00');
  final igv = cpe_calcular_igv(baseImponible);
  final totalPagar = baseImponible + igv;

  print('Tipo CPE: ${CPE_TipoDocumento.factura.descripcion}');
  print('Base Imponible: $baseImponible');
  print('IGV (18%): $igv');
  print('Total a Pagar: $totalPagar');
  print('Total UBL: ${totalPagar.aFormatoUbl()}');
}
