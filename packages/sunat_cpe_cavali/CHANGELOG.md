## 0.1.2

- Traducción completa de la documentación API (`dartdoc`), `README.md` y metadatos del paquete al español técnico.
- Ampliación de `example/main.dart` con el ciclo de vida completo en dos partes: validación OSE SOAP 1.1 en Gosocket (Factura al crédito con cuotas, Resumen Diario y consulta CDR) y Factoring Electrónico en Cavali Factrack v2 REST OAuth2 (`registerInvoicesForFactoring` y `checkConformityStatus`).
- Actualización de la restricción de dependencia a `sunat_cpe_core: ^0.1.2`.

## 0.1.1

- Adición de ejemplo ejecutable (`example/main.dart`) para alcanzar la puntuación máxima de 160/160 en Pana (`pub.dev`).
- Actualización de la restricción de dependencia `xml` a `^7.0.0`.

## 0.1.0

- Lanzamiento inicial de `sunat_cpe_cavali` implementando `OseProvider` (Gosocket/Carvajal SOAP 1.1) y `CavaliFactoringCapability` (Cavali Factrack REST OAuth2).
