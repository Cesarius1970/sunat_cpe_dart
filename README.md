# sunat_cpe_dart

Librería Dart para la construcción, cálculo fiscal, validación y emisión de Comprobantes de Pago Electrónico (CPE) regulados por **SUNAT** (Perú) bajo el estándar **UBL 2.1**.

## Características

- **Cero errores de punto flotante:** Cálculos monetarios e impositivos realizados estrictamente con aritmética decimal exacta (`Decimal`), eliminando rechazos SUNAT por descuadre de céntimos.
- **Nomenclatura oficial:** Tipado con prefijo `CPE_` y catálogos estandarizados de SUNAT (Catálogo 01 de tipos de documento, Catálogo 02 de monedas, etc.).
- **Compatibilidad UBL 2.1:** Formateo nativo para nodos de importes y precios unitarios.
- **Documentación técnica y reglas:** Manual técnico y bitácora de desarrollo incluidos en el directorio `docs/`.

## Instalación

Agrega la dependencia en tu archivo `pubspec.yaml`:

```yaml
dependencies:
  sunat_cpe_dart:
    git:
      url: https://github.com/cesarvergarab/sunat_cpe_dart.git
```

O instala localmente:

```bash
dart pub get
```

## Ejemplo de Uso

```dart
import 'package:sunat_cpe_dart/sunat_cpe_dart.dart';

void main() {
  // Base imponible exacta sin punto flotante
  final baseImponible = CPE_Monto.desdeTexto('1000.00');

  // Cálculo de IGV (18%)
  final igv = cpe_calcular_igv(baseImponible);

  // Total a pagar
  final total = baseImponible + igv;

  print('Tipo CPE: ${CPE_TipoDocumento.factura.descripcion}');
  print('Base Imponible: ${baseImponible.aFormatoUbl()}'); // 1000.00
  print('IGV: ${igv.aFormatoUbl()}');                     // 180.00
  print('Total a pagar: ${total.aFormatoUbl()}');         // 1180.00
}
```

## Documentación

- [Manual Técnico](docs/MANUAL_TECNICO.md)
- [Reglas de Proyecto](docs/REGLAS_PROYECTO.md)
- [Histórico de Prompts](docs/prompts/HISTORICO_PROMPTS.md)

## Licencia y Copyright

Copyright (c) 2026 César A Vergara Buenaventura <cesarvergarab@gmail.com>.  
Distribuido bajo Licencia MIT. Consulta el archivo [LICENSE](LICENSE) para más detalles.
