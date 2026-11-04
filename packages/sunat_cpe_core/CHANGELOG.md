## 0.1.1

- Add executable package example (`example/main.dart`) for pub.dev Pana 160/160 score.
- Upgrade `xml` dependency constraint to `^7.0.0`.

## 0.1.0

- Initial release of `sunat_cpe_core`.
- Add official SUNAT Anexo N° 8 catalogs (`01`, `02`, `05`, `06`, `07`, `09`, `10`, `18`, `19`, `20`, `22`, `23`, `51`).
- Add immutable Dart 3 domain entities for Factura (`01`), Boleta (`03`), Liquidación de Compra (`04`), Nota de Crédito (`07`), Nota de Débito (`08`), Guía de Remisión (`09`, `31`), Retención (`20`), Percepción (`40`), Resumen Diario (`RC`), and Comunicación de Baja (`RA`, `RR`).
- Add `CpeResult<T>` with `.getOrThrow()` and typed SUNAT exception/rejection hierarchy.
- Add `CpeMathValidator`, `UblXmlBuilder`, `XadesBesSigner`, `CpeZipCodec`, `CpeHttpClient`, and `BaseUblOseProvider`.
