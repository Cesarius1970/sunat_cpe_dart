# sunat_cpe_direct

Adaptador oficial de **Envío Directo a SUNAT Operaciones en Línea (SOL)** para facturación electrónica SUNAT (Perú) en Dart 3 puro, integrando la lógica de `sunat_cpe_dart` sobre los contratos de `sunat_cpe_core`.

## Características

- **Enrutamiento Multiprotocolo Inteligente hacia SUNAT**:
  - **SOAP `e-factura` (`urlSoapFactura`)**: Facturas (`01`), Boletas (`03`), Liquidaciones de Compra (`04`), Notas de Crédito/Débito (`07`/`08`), Resumen Diario (`RC`) y Comunicación de Baja (`RA`).
  - **SOAP `otroscpe` (`urlSoapOtrosCpe`)**: Comprobantes de Retención (`20`), Percepción (`40`) y Resumen de Reversiones (`RR`).
  - **API REST OAuth2 GRE (`api-cpe.sunat.gob.pe` + `api-seguridad.sunat.gob.pe`)**: Guías de Remisión Remitente (`09`) y Transportista (`31`) enviando `arcGreZip` (Base64) y `hashZip` (SHA-256 hexadecimal del binario ZIP).
- **Seguridad de Certificado Digital (`beta` vs `homologacion` / `produccion`)**: Permite certificados RSA simulados únicamente en `SunatDirectEnvironment.beta` y exige certificados X.509 reales en Homologación y Producción.
