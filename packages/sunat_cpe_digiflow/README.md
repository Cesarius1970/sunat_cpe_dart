# sunat_cpe_digiflow

Adaptador oficial de **Digiflow (OSE)** para facturación electrónica SUNAT (Perú) en Dart 3 puro, extendiendo `BaseUblOseProvider` de `sunat_cpe_core`.

## Características

- **Cumplimiento Estricto de `SOAPAction` (`urn:sendBill`, `urn:sendSummary`, `urn:getStatus`, `urn:getStatusCdr`)**: Cabeceras y sobre SOAP 1.1 WS-Security específicos para Digiflow OSE.
- **Modo Configurable para Guías de Remisión (`DigiflowDespatchMode`)**: Permite despachar Guías (`09`/`31`) por ticket asíncrono (`urn:sendSummary`) o de forma síncrona (`urn:sendBill`) según el contrato OSE del emisor en Digiflow.
- **Empaquetado ZIP sin Subdirectorios**: Evita la excepción `0151` garantizando coincidencia exacta entre `<fileName>` y la entrada `.xml` interna.
