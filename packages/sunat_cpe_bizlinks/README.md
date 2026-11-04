# sunat_cpe_bizlinks

Adaptador oficial de **Bizlinks (OSE / PSE)** para facturación electrónica SUNAT (Perú) en Dart 3 puro, extendiendo `BaseUblOseProvider` de `sunat_cpe_core`.

## Características

- **SOAP 1.1 `billService` con WS-Security**: Soporte completo para `sendBill`, `sendSummary`, `getStatus` y `getStatusCdr`.
- **Generación UBL 2.1 y Firma XAdES-BES Local**: Construye el XML UBL 2.1, firma con certificado X.509 RSA-SHA256 y comprime en `.zip` según el estándar OSE de Bizlinks.
- **Parser Especializado de `<soapenv:Fault>` (`BizlinksSoapFaultParser`)**: Extrae códigos SUNAT (`0100..3999`) tanto desde `<faultcode>` (`Client.2017`) como desde `<faultstring>` y `<detail><message>`.
