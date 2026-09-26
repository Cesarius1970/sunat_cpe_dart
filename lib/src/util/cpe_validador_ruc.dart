// Copyright (c) 2026, César A Vergara Buenaventura <cesarvergarab@gmail.com>.
// Todos los derechos reservados. Uso sujeto a la licencia en el archivo LICENSE.

/// Validador oficial del Registro Único de Contribuyentes (RUC) de SUNAT mediante Módulo 11.
class CPE_ValidadorRuc {
  static const List<int> _factores = [5, 4, 3, 2, 7, 6, 5, 4, 3, 2];

  /// Valida la estructura y el dígito de control de un número de RUC peruano.
  static bool esValido(String? ruc) {
    if (ruc == null || ruc.length != 11) return false;
    if (!RegExp(r'^[0-9]{11}$').hasMatch(ruc)) return false;

    // Prefijos permitidos por SUNAT (10 = persona natural, 15, 17, 20 = persona jurídica)
    final prefijo = ruc.substring(0, 2);
    if (!const ['10', '15', '17', '20'].contains(prefijo)) {
      return false;
    }

    var suma = 0;
    for (var i = 0; i < 10; i++) {
      suma += int.parse(ruc[i]) * _factores[i];
    }

    final residuo = suma % 11;
    final digitoCalculado = 11 - residuo;

    final digitoEsperado = switch (digitoCalculado) {
      10 => 1,
      11 => 0,
      _ => digitoCalculado,
    };

    return digitoEsperado == int.parse(ruc[10]);
  }
}
