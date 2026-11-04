# sunat_cpe_facturaloperu

Adaptador oficial de **FacturaloPeru / Facturador PRO (PRO X, PRO 4, PRO 5, Smart, APIPeru)** para facturación electrónica SUNAT (Perú) en Dart 3 puro, implementando los contratos de `sunat_cpe_core`.

## Características

- **Endpoints Semánticos RESTful**: Soporte completo para `/api/documents`, `/api/summaries`, `/api/voided`, `/api/dispatches`, `/api/retentions` y consulta auxiliar de RUC/DNI (`/api/service/ruc/{numero}`).
- **Autenticación `Bearer Token`**: Integración con el esquema estándar de tokens por empresa/tenant de Facturador PRO.
- **Mapeo de Estados (`state_type_id` `01..13`)**: Traduce respuestas anidadas (`data.state_type_id`, `cdr_response`, `links.xml/pdf/cdr`) a `CpeResult<CpeEmissionResponse>`.
