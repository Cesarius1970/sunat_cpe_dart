## 0.1.2

- Traducción integral de la documentación (`README.md`, `CHANGELOG.md` y comentarios Dartdoc `///`) al español técnico.
- Implementación de un ejemplo ejecutable multiescenario 100 % offline en `example/main.dart` (emisión de Facturas con estados `102`/`103`, Guía de Remisión `09`, Resumen Diario `RC`, Comunicación de Baja `RA`, consulta de ticket/estado y manejo de rechazos `104`).
- Actualización de la restricción de dependencia `sunat_cpe_core` a `^0.1.2`.

## 0.1.1

- Adición de ejemplo ejecutable del paquete (`example/main.dart`) para alcanzar la puntuación máxima de 160/160 en Pana (pub.dev).
- Actualización de la restricción de dependencia `xml` a `^7.0.0`.

## 0.1.0

- Lanzamiento inicial de `sunat_cpe_mifact` implementando `OseProvider` para los endpoints REST JSON de Mifact (`SendInvoice`, `SendGuide`, `lowInvoice`, `SendSummary`, `GetStatus`).
