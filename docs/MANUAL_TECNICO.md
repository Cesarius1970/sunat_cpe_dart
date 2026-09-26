# Manual Técnico: sunat_cpe_dart

**Librería Dart para Comprobantes de Pago Electrónico (CPE) SUNAT - Estándar UBL 2.1**  
**Autor y Titular de Derechos:** César A Vergara Buenaventura (<cesarvergarab@gmail.com>)  
**Licencia:** MIT (ver archivo `LICENSE`)  
**Versión:** 0.1.0  
**Fecha de actualización:** 2026-09-26  

---

## 1. Introducción y Objetivos de la Librería

`sunat_cpe_dart` es una biblioteca desarrollada en Dart diseñada para la construcción, cálculo fiscal, validación y estructuración de Comprobantes de Pago Electrónico (CPE) conforme a los marcos normativos emitidos por la Superintendencia Nacional de Aduanas y de Administración Tributaria (**SUNAT**, Perú) y al estándar internacional **UBL 2.1** (OASIS Universal Business Language, ISO/IEC 19845:2015).

El objetivo primordial es dotar al ecosistema Dart y Flutter de una herramienta robusta, matemáticamente exacta, estrictamente tipada y documentada en idioma español para emitir:
- Facturas Electrónicas (Tipo 01)
- Boletas de Venta Electrónicas (Tipo 03)
- Notas de Crédito Electrónicas (Tipo 07)
- Notas de Débito Electrónicas (Tipo 08)
- Guías de Remisión Remitente / Transportista (Tipos 09 y 31)

---

## 2. Fundamentación Técnica: Representación Monetaria y Rechazo de Punto Flotante

### 2.1. Problema del Punto Flotante (IEEE 754) en la Facturación Electrónica
En lenguajes de programación como Dart, el tipo `double` implementa la norma IEEE 754 para números en coma flotante binaria de 64 bits. Esta representación no puede modelar de forma exacta la mayoría de fracciones decimales en base 10 (por ejemplo, `0.1` o `0.2` poseen representaciones periódicas infinitas en base 2).

```dart
// En coma flotante nativa:
print(0.1 + 0.2); // Imprime: 0.30000000000000004
```

### 2.2. Normativa SUNAT y Códigos de Rechazo UBL
De acuerdo con las especificaciones de validación técnica de comprobantes electrónicos (RS N.° 097-2012/SUNAT, RS N.° 340-2017/SUNAT y sus Anexos I, IV y V):
1. **Regla de Cuadre de Totales:** La suma de los importes de venta (`LineExtensionAmount`) debe coincidir exactamente con las bases imponibles declaradas en los totales tributarios (`TaxableAmount`).
2. **Liquidación del IGV:** El importe del IGV (`TaxAmount`) debe calcularse aplicando el 18% a la base gravada, con redondeo estándar a 2 decimales.
3. **Discrepancia de Centavos:** Si el algoritmo produce una diferencia de tan solo `0.01` respecto a la fórmula validada por el validador XML de SUNAT o un OSE (Operador de Servicios Electrónicos), el comprobante es **RECHAZADO** con excepciones formales:
   - **Error 2017:** *El valor de venta de la operación debe ser igual a la suma de los valores de venta por ítem*.
   - **Error 2019:** *El importe total de la operación es diferente a la suma de los tributos más el valor de venta*.
   - **Error 2021:** *El importe del IGV es incorrecto en el ítem o total*.

### 2.3. Dictamen y Regla del Proyecto
**Se prohíbe el uso de `double` para almacenamiento o cálculo de importes monetarios.**  
Se adopta la clase `Decimal` (paquete `decimal`), garantizando cálculo aritmético exacto en base 10 con precisión arbitraria, eliminando cualquier riesgo de inconsistencia fiscal.

---

## 3. Estructura y Organización del Código

```text
sunat_cpe_dart/
├── AUTHORS                      # Registro formal de autoría
├── LICENSE                      # Licencia MIT de César A Vergara Buenaventura
├── README.md                    # Descripción de bienvenida e instalación
├── CHANGELOG.md                 # Registro de versiones y cambios
├── analysis_options.yaml        # Reglas de linting estándar de Dart
├── pubspec.yaml                 # Manifiesto pub con metadatos oficiales
├── docs/                        # Documentación técnica del proyecto
│   ├── MANUAL_TECNICO.md        # Este manual técnico
│   ├── REGLAS_PROYECTO.md       # Reglas de gobernanza, git y código
│   └── prompts/                 # Histórico cronológico de prompts
│       └── HISTORICO_PROMPTS.md # Bitácora numerada de interacciones
├── example/                     # Ejemplos ejecutables de uso
│   └── sunat_cpe_dart_example.dart
├── lib/                         # Código fuente de la biblioteca
│   ├── sunat_cpe_dart.dart      # Punto de entrada público (exportaciones)
│   └── src/                     # Implementación interna modular
│       └── sunat_cpe_dart_base.dart # Clases base CPE, importes e impuestos
└── test/                        # Batería de pruebas unitarias
    └── sunat_cpe_dart_test.dart
```

---

## 4. Convenciones de Nomenclatura e Idioma

1. **Idioma:** Todo el código interno, identificadores de dominio, excepciones, comentarios y documentación técnica se escriben en **idioma español**.
2. **Prefijo `CPE_` para Objetos/Tipos:**
   - Clases de modelo y entidades: `CPE_Monto`, `CPE_Factura`, `CPE_Item`, `CPE_Emisor`, etc.
   - Enumeraciones: `CPE_TipoDocumento`, `CPE_Moneda`, `CPE_TipoAfectacionIgv`.
3. **Prefijo `cpe_` para Funciones y Métodos Libres:**
   - Algoritmos y cálculos: `cpe_calcular_igv()`, `cpe_redondear_moneda()`.
4. **Interoperabilidad con la API SUNAT / Nombres UBL:**
   - Los nombres de nodos XML o esquemas JSON requeridos estrictamente por los Web Services de SUNAT (ej. `cbc:PayableAmount`, `cac:TaxTotal`, `ublVersionID`, etc.) se preservan intactos en los componentes de serialización para asegurar cumplimiento del estándar.

---

## 5. Descripción de Algoritmos Implementados

### 5.1. Clase `CPE_Monto` (`lib/src/sunat_cpe_dart_base.dart`)
Representa una magnitud monetaria exacta con su código de divisa ISO 4217 (Catálogo 02 de SUNAT).

#### Algoritmo de Creación Segura:
- `CPE_Monto(Decimal valor, {String moneda = 'PEN'})`: Instancia directa con valor exacto.
- `CPE_Monto.desdeTexto(String valorTexto)`: Convierte cadenas representativas como `"1500.50"` a `Decimal.parse()`.
- `CPE_Monto.desdeCentavos(int centavos)`: Divide enteros en céntimos entre `100` en espacio decimal puro, ideal para bases de datos transaccionales.

#### Algoritmo de Operación Monetaria:
- Los operadores `+` y `-` verifican primero que ambas instancias compartan el mismo código de divisa (`moneda == otro.moneda`). En caso de discrepancia, lanzan `ArgumentError` inmediato, previniendo mezcla no intencional de Soles (`PEN`) y Dólares (`USD`).

#### Algoritmo de Formateo UBL:
- `aFormatoUbl()`: Emite una cadena numérica formateada con exactamente 2 decimales (`toStringAsFixed(2)`), lista para etiquetas XML como `<cbc:PayableAmount>`.
- `aFormatoPrecioUnitario({int decimales = 2})`: Permite formatear precios unitarios con la precisión configurada (hasta 10 decimales según Catálogo SUNAT para ítems al por mayor o combustible).

### 5.2. Función `cpe_calcular_igv`
```dart
CPE_Monto cpe_calcular_igv(
  CPE_Monto baseImponible, {
  Decimal? tasaPorcentaje,
})
```
- **Entrada:** `baseImponible` (`CPE_Monto`) y tasa opcional (por defecto `18%`).
- **Proceso:** Convierte la tasa a factor decimal (`18 / 100 = 0.18`), efectúa el producto `base * factor` en álgebra `Decimal` y retorna un nuevo `CPE_Monto` con la misma divisa.
- **Resultado:** Cero distorsión por aproximación de punto flotante.

---

## 6. Procedimientos de Validación y Calidad

Para asegurar que todo el código cumpla con los estándares del equipo de Dart y Flutter:

```bash
# 1. Análisis estático de código (cero errores o advertencias)
dart analyze

# 2. Ejecución de la suite completa de pruebas
dart test

# 3. Formateo de código según Effective Dart
dart format .
```

---

## 7. Mantenimiento y Ciclo de Vida del Manual
Este manual debe actualizarse obligatoriamente en cada interacción donde se añadan nuevos tipos de comprobantes, algoritmos de cálculo impositivo (ISC, Detracciones, Percepciones), esquemas de firma digital XMLDSig o comunicación con el API REST/SOAP de SUNAT.
