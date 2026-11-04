## 0.1.2

- Traducción integral de la documentación API (`Dartdoc`), `README.md` y `CHANGELOG.md` al español técnico.
- Ampliación de `example/main.dart` con escenarios ejecutables 100% offline: sobre SOAP 1.1 con `mustUnderstand="1"`, emisión de Factura (`01`) y Comprobante de Retención (`20`), ambos modos de Guía de Remisión (`DigiflowDespatchMode.syncSendBill` y `asyncTicket`) y consulta histórica de CDR (`getStatusCdr`).
- Actualización de dependencia `sunat_cpe_core` a `^0.1.2`.

## 0.1.1

- Adición de ejemplo ejecutable (`example/main.dart`) para alcanzar la puntuación máxima (160/160) en pub.dev Pana.
- Actualización de la restricción de dependencia `xml` a `^7.0.0`.

## 0.1.0

- Lanzamiento inicial de `sunat_cpe_digiflow` implementando el contrato `OseProvider` sobre el servicio SOAP 1.1 `billService` de Digiflow OSE.
