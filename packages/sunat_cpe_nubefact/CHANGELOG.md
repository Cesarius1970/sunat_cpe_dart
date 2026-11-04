## 0.1.2

- Traducción integral de la documentación (`README.md`, `CHANGELOG.md` y comentarios Dartdoc `///`) al español técnico.
- Implementación de un ejemplo ejecutable multiescenario 100 % offline en `example/main.dart` (Facturas, Boletas, Notas de Crédito, Guías de Remisión, Comunicaciones de Baja con polling automático, consultas de estado y manejo de errores).
- Actualización de la restricción de dependencia `sunat_cpe_core` a `^0.1.2`.

## 0.1.1

- Adición de ejemplo ejecutable del paquete (`example/main.dart`) para alcanzar la puntuación máxima de 160/160 en Pana (pub.dev).
- Actualización de la restricción de dependencia `xml` a `^7.0.0`.

## 0.1.0

- Lanzamiento inicial de `sunat_cpe_nubefact`.
- Implementación de `NubefactProvider` (`OseProvider`) para la API REST JSON v1 de Nubefact.
- Adición de `NubefactCatalogMapper` para traducir los catálogos oficiales de SUNAT a los códigos enteros propietarios de Nubefact.
- Soporte para facturas, boletas, notas de crédito/débito, comunicaciones de baja, guías de remisión (remitente/transportista), retenciones, percepciones y consultas de estado.
