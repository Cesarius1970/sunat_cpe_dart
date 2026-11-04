## 0.1.2

- Traducción integral de la documentación API (`Dartdoc`), `README.md` y `CHANGELOG.md` al español técnico.
- Inclusión del metadato `providerRawMetadata['recoveredFromDuplicate'] = true` en `SovosProvider.sendDocument` cuando recupera automáticamente el CDR original tras un error de duplicado (`1033` / `2017`).
- Ampliación de `example/main.dart` con escenarios ejecutables 100% offline: `SovosUblExtensionBuilder` con `customPrintFields`, emisión en modos `oseUblSigned` y `pseCloudSign`, recuperación idempotente de CDR ante duplicados y envío de Resumen Diario (`RC`) / Comunicación de Baja (`RA`).
- Actualización de dependencia `sunat_cpe_core` a `^0.1.2`.

## 0.1.1

- Adición de ejemplo ejecutable (`example/main.dart`) para alcanzar la puntuación máxima (160/160) en pub.dev Pana.
- Actualización de la restricción de dependencia `xml` a `^7.0.0`.

## 0.1.0

- Lanzamiento inicial de `sunat_cpe_sovos` con soporte para el servicio SOAP 1.1 de Sovos / Paperless OSE, extensiones UBL de impresión personalizada y recuperación idempotente de CDR ante envíos duplicados.
