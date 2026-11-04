# sunat_cpe_mifact

Adaptador oficial de **Mifact (PSE / OSE)** para facturación electrónica SUNAT (Perú) en Dart 3 puro, implementando los contratos de `sunat_cpe_core`.

## Características

- **Mapeo JSON `UPPER_SNAKE_CASE`**: Transforma las entidades de `sunat_cpe_core` al formato propietario de Mifact (`SendInvoice`, `SendGuide`, `lowInvoice`, `SendSummary`, `GetStatus`) con inyección de `"TOKEN"` en el cuerpo JSON.
- **Códigos SUNAT Directos**: Mantiene la precisión de `Decimal` y los códigos de los Catálogos Oficiales SUNAT.
- **Decodificación de Estados (`101` a `105`) y CDR Base64**: Interpreta `estado_documento`, extrae `cdr_bytes`, `xml_bytes`, `codigo_hash` y `cadena_para_codigo_qr`.
