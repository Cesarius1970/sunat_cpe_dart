# Reglas de Desarrollo y Gobernanza del Proyecto

Este documento define los estándares obligatorios para el desarrollo de la librería `sunat_cpe_dart`.

---

## 1. Convención de Git: Commits y Ramas
- **Frecuencia de Commits:** Debe generarse un commit al finalizar cada fase de trabajo o interacción con el agente.
- **Nomenclatura de Commits (Conventional Commits v1.0.0):**
  - Formato: `<tipo>[ámbito opcional]: <descripción concisa>`
  - Tipos válidos:
    - `feat`: Nueva funcionalidad o componente del CPE.
    - `fix`: Corrección de un fallo o cálculo impositivo.
    - `docs`: Modificación o adición de documentación (`MANUAL_TECNICO.md`, `HISTORICO_PROMPTS.md`, README).
    - `refactor`: Cambio de código sin modificar funcionalidad existente.
    - `test`: Adición o ajuste de pruebas unitarias/integración.
    - `chore`: Mantenimiento de configuración, dependencias (`pubspec.yaml`), etc.
- **Nomenclatura de Ramas:**
  - `feature/<nombre-caracteristica>`
  - `fix/<nombre-correccion>`
  - `doc/<nombre-documentacion>`
  - `chore/<tarea>`

---

## 2. Histórico de Prompts e Interacciones
- Carpeta: `doc/prompts/`
- Archivo: `doc/prompts/HISTORICO_PROMPTS.md`
- Debe mantenerse actualizado cronológicamente, numerando cada interacción, guardando el prompt del usuario y el resumen/resultado de la respuesta del asistente.

---

## 3. Idioma y Nomenclatura de Código
- **Idioma principal:** Todo el desarrollo interno, comentarios, documentación técnica y dartdocs deben redactarse en **idioma español**.
- **Nomenclatura de Objetos (Prefijos CPE):**
  - Las clases, tipos, enums y estructuras de datos deben usar el prefijo `CPE_` (ej. `CPE_Factura`, `CPE_Emisor`, `CPE_Item`).
  - Variables, métodos, funciones y archivos de soporte deben emplear el prefijo `cpe_` según corresponda (ej. `cpe_calcular_igv()`, `cpe_factura.dart`).
  - **Excepción mandatoria:** Si un campo, nodo o atributo corresponde estrictamente al estándar UBL (ej. `cbc:PayableAmount`, `cac:TaxTotal`, `ID`, `IssueDate`) o a la API REST/SOAP de SUNAT, no se forzará el prefijo cuando hacerlo colisione, rompa la serialización XML/JSON o degrade la interoperabilidad oficial.

---

## 4. Prohibición de Punto Flotante en Valores Monetarios
- **Regla Estricta:** Queda prohibido el uso de tipos de datos de punto flotante binario (`double` en Dart) para representar, calcular o almacenar importes monetarios, bases imponibles, tributos o totales.
- **Fundamento Técnico SUNAT:**
  - El estándar UBL 2.1 adoptado por SUNAT (Resolución de Superintendencia N.° 097-2012 y N.° 340-2017) exige exactitud a nivel de centavos en totales (`PayableAmount`, `TaxAmount`) y hasta 10 decimales en precios unitarios (`PriceAmount`).
  - Los tipos `double` bajo la especificación IEEE 754 introducen errores residuales de conversión binaria (ej. `0.1 + 0.2 = 0.30000000000000004`), los cuales generan discrepancias en la suma de ítems y liquidación de impuestos.
  - SUNAT rechaza comprobantes con errores de discrepancia tributaria (códigos de error 2017, 2019, 2021).
  - **Solución implementada:** Uso exclusivo de `Decimal` (vía paquete `decimal`) o enteros en submúltiplos fijos (centavos / `BigInt`), con esquemas de redondeo simétrico o bancario según catálogo SUNAT.

---

## 5. Estándares Oficiales Dart y Flutter
- Cumplimiento de **Effective Dart** (Style, Documentation, Usage, Design).
- Verificación continua mediante `dart analyze` sin advertencias (`analysis_options.yaml`).
- Formato automático mediante `dart format`.
- Cobertura de pruebas con `dart test` en `test/`.
- Documentación de API pública con comentarios dartdoc `///`.
- Gestión de autoría y licencias con `LICENSE` y `AUTHORS`.

---

## 6. Repositorio Oficial y Enlace Remoto
- **URL Oficial:** [https://github.com/Cesarius1970/sunat_cpe_dart](https://github.com/Cesarius1970/sunat_cpe_dart)
- **Rama principal:** `main`
- **Control de origen:** El remoto `origin` debe apuntar a `https://github.com/Cesarius1970/sunat_cpe_dart.git`.

