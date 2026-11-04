## 0.1.2

- Traducción completa de la documentación API (`dartdoc`), `README.md` y metadatos del paquete al español técnico.
- Ampliación de `example/main.dart` con los 3 canales oficiales de SUNAT Operaciones en Línea: validación de certificados por entorno (`beta` vs `homologacion`/`produccion`), Canal 1 SOAP `e-factura` (`01`, `07`, `RC`, `RA`), Canal 2 SOAP `otroscpe` (`20`, `40`) y Canal 3 API REST OAuth2 GRE (`09`, `31` con `arcGreZip` y `hashZip` SHA-256).
- Actualización de la restricción de dependencia a `sunat_cpe_core: ^0.1.2`.

## 0.1.1

- Adición de ejemplo ejecutable (`example/main.dart`) para alcanzar la puntuación máxima de 160/160 en Pana (`pub.dev`).
- Actualización de la restricción de dependencia `xml` a `^7.0.0`.

## 0.1.0

- Lanzamiento inicial de `sunat_cpe_direct` implementando `OseProvider` para los canales directos de SUNAT SOL SOAP (`e-factura`, `otroscpe`) y API REST OAuth2 GRE (`api-cpe.sunat.gob.pe`).
