## 0.1.2

- Traducción integral de la documentación API (`Dartdoc`), `README.md` y `CHANGELOG.md` al español técnico.
- Ampliación de `example/main.dart` con escenarios ejecutables 100% offline: configuración por entorno, firma XAdES-BES de Factura (`01`), Resumen Diario (`RC`), Comunicación de Baja (`RA`) con sondeo de ticket, Guía de Remisión (`09`) y diagnóstico de fallos SOAP (`BizlinksSoapFaultParser`).
- Actualización de dependencia `sunat_cpe_core` a `^0.1.2`.

## 0.1.1

- Adición de ejemplo ejecutable (`example/main.dart`) para alcanzar la puntuación máxima (160/160) en pub.dev Pana.
- Actualización de la restricción de dependencia `xml` a `^7.0.0`.

## 0.1.0

- Lanzamiento inicial de `sunat_cpe_bizlinks` implementando el contrato `OseProvider` sobre el servicio SOAP 1.1 `billService` de Bizlinks con seguridad WS-Security.
