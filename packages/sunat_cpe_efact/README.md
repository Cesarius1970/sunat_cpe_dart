# sunat_cpe_efact

Adaptador oficial de **EFACT (OSE / PSE)** para facturación electrónica SUNAT (Perú) en Dart 3 puro, implementando los contratos de `sunat_cpe_core`.

## Características

- **Modo REST OAuth2 XML (`EfactIntegrationMode.restXml`)**: Genera XML UBL 2.1, firma localmente con XAdES-BES, envía por `multipart/form-data` a `/v1/document` y descarga el CDR en `/v1/cdr/{ticket}` (con `autoPollInRest` configurable).
- **Modo REST OAuth2 JSON (`EfactIntegrationMode.restJson`)**: Transforma las entidades del Core a JSON UBL EFACT para firma en la nube (PSE).
- **Modo SOAP 1.1 (`EfactIntegrationMode.soapUbl`)**: Integración directa con `billService` de EFACT (`sendBill`, `sendSummary`, `getStatus`, `getStatusCdr`) con cabecera WS-Security.
- **Interceptor OAuth2 (`EfactOAuth2Interceptor`)**: Renovación automática de tokens `Bearer` contra `/oauth/token`.
