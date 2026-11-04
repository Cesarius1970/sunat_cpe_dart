# sunat_cpe_cavali

Adaptador oficial de **Cavali / Gosocket / Carvajal (OSE + Factoring Factrack)** para facturación electrónica SUNAT (Perú) y Facturas Negociables en Dart 3 puro, implementando `OseProvider` de `sunat_cpe_core` y `CavaliFactoringCapability`.

## Características

- **Validación OSE (Gosocket / Carvajal SOAP 1.1 `billService`)**: Emisión síncrona y asíncrona de CPE UBL 2.1 con firma XAdES-BES local.
- **Integración API REST Cavali Factrack (`CavaliFactoringCapability`)**:
  - Registro de Facturas Comerciales al Crédito (`registerInvoicesForFactoring`) hacia `POST /invoice/xml`.
  - Consulta de estado de Conformidad Expresa, Presunta o Disconformidad (`checkConformityStatus` según DU 013-2020) y Anotación en Cuenta.
- **Interceptor OAuth2 + `x-api-key` (`CavaliOAuth2Interceptor`)**: Renovación automática de tokens `client_credentials` para Factrack v2.
