# sunat_cpe_sovos

Adaptador oficial de **Sovos / Paperless (OSE / PSE)** para facturación electrónica SUNAT (Perú) en Dart 3 puro, implementando los contratos de `sunat_cpe_core`.

## Características

- **SOAP 1.1 `billService` con WS-Security**: Emisión de CPE con firma XAdES-BES local (`SovosIntegrationMode.oseUblSigned`) o modo de firma HSM en servidor (`SovosIntegrationMode.pseCloudSign`).
- **Idempotencia y Recuperación Automática de CDR (`autoRecoverCdrOnDuplicate`)**: Si un reintento de red recibe error de comprobante previamente declarado (`1033` / `2017`), consulta automáticamente `getStatusCdr` y retorna el CDR original como `CpeSuccess`.
- **Inyección de Campos de Impresión Paperless (`SovosUblExtensionBuilder`)**: Permite inyectar `customPrintFields` en un nodo `<ext:UBLExtension>` dedicado sin romper la firma digital XAdES-BES.
