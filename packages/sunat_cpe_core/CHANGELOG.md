## 0.1.2

- Traducción integral al español de toda la documentación de la API (`///` Dartdoc), `README.md` y registro de cambios.
- Ampliación de la guía arquitectónica sobre validación matemática *Strict Passthrough*, generación UBL 2.1/2.0, firma XAdES-BES y manejo de errores con `CpeResult<T>`.
- Incorporación de ejemplo completo y ejecutable 100 % offline (`example/main.dart`) con 6 escenarios prácticos que cubren todos los tipos de comprobantes electrónicos de SUNAT, validación aritmética, firma criptográfica RSA-SHA256 y empaquetado ZIP/CDR.

## 0.1.1

- Adición de ejemplo ejecutable del paquete (`example/main.dart`) para alcanzar la puntuación máxima de 160/160 en el análisis Pana de pub.dev.
- Actualización de la restricción de dependencia de `xml` a `^7.0.0`.

## 0.1.0

- Lanzamiento inicial de `sunat_cpe_core`.
- Incorporación de los catálogos oficiales del Anexo N° 8 de SUNAT (`01`, `02`, `05`, `06`, `07`, `09`, `10`, `18`, `19`, `20`, `22`, `23`, `51`).
- Incorporación de entidades de dominio inmutables en Dart 3 para Factura (`01`), Boleta de Venta (`03`), Liquidación de Compra (`04`), Nota de Crédito (`07`), Nota de Débito (`08`), Guía de Remisión (`09`, `31`), Comprobante de Retención (`20`), Comprobante de Percepción (`40`), Resumen Diario (`RC`) y Comunicación de Baja (`RA`, `RR`).
- Incorporación de `CpeResult<T>` con `.getOrThrow()` y jerarquía tipada de excepciones y rechazos de SUNAT/OSE.
- Incorporación de `CpeMathValidator`, `UblXmlBuilder`, `XadesBesSigner`, `CpeZipCodec`, `CpeHttpClient` y `BaseUblOseProvider`.
