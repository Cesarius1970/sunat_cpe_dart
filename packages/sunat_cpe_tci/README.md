# sunat_cpe_tci

Adaptador oficial de **TCI - Transporte Confidencial de Información / Efacturación (OSE / PSE)** para facturación electrónica SUNAT (Perú) en Dart 3 puro, extendiendo `BaseUblOseProvider` de `sunat_cpe_core`.

## Características

- **SOAP 1.1 `billService` con WS-Security Estricto**: Formato de credencial `{RUC}{USUARIO_OSE_TCI}` y atributo explícito `PasswordText`.
- **Soporte Agroindustrial y Logístico**: Cobertura completa para Liquidación de Compra (`04`), Guías de Remisión Remitente (`09`) y Transportista (`31`), Facturas (`01`), Boletas (`03`), Notas (`07`/`08`), Retenciones (`20`) y Percepciones (`40`).
- **Parser Especializado de `<soap-env:Fault>` (`TciSoapFaultParser`)**: Extrae códigos `Client.XXXX` y `Server.XXXX` retornados por TCI OSE.
