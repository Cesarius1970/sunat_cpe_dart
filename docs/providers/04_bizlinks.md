# Análisis de Proveedor 04: Bizlinks (OSE / PSE)

Especificación técnica para el paquete `packages/sunat_cpe_bizlinks`.

---

## 1. Perfil Técnico del Proveedor

- **Rol en SUNAT**: OSE (Operador de Servicios Electrónicos) y PSE corporativo de alto volumen en Perú.
- **Modo de Integración Principal**: **Vía UBL Nativa (SOAP 1.1 `billService` con WS-Security)**. También cuenta con variante PSE (`Bizlinks Online` por XML/JSON sin firma local), pero su estándar principal como OSE es el servicio SOAP compatible con la especificación técnica de SUNAT OSE.
- **Generación UBL y Firma**: Utiliza el motor nativo de `sunat_cpe_core` (`UblXmlBuilder` + `XadesBesSigner` + `CpeZipCodec`).
- **Autenticación**: Cabecera OASIS WS-Security `<wsse:UsernameToken>` con `Username` (usuario OSE asignado por Bizlinks o `RUC+UsuarioSOL`) y `Password` (`PasswordText`).

---

## 2. Endpoints Oficiales de Bizlinks OSE

| Entorno | Servicio | URL |
|---------|----------|-----|
| **Producción** | SOAP 1.1 OSE | `https://ose.bizlinks.com.pe/ol-ti-itcpe/billService` |
| **Homologación / Pruebas** | SOAP 1.1 OSE | `https://osetesting.bizlinks.com.pe/ol-ti-itcpe/billService` |

---

## 3. Operaciones del Contrato SOAP `billService` en Bizlinks

| Operación SOAP | Método en `OseProvider` | Entrada | Salida | Comportamiento |
|----------------|-------------------------|---------|--------|----------------|
| `sendBill` | `sendDocument`<br>`sendRetentionOrPerception` | `fileName` (`{RUC}-{TIPO}-{SERIE}-{NUM}.zip`)<br>`contentFile` (Base64 ZIP) | `applicationResponse` (Base64 ZIP del CDR `R-*.zip`) | **100% Síncrono** para `01`, `03`, `04`, `07`, `08`, `20`, `40` |
| `sendSummary` | `sendDailySummary`<br>`sendVoidedDocument` | `fileName` (`{RUC}-{RC/RA/RR}-{YYYYMMDD}-{NUM}.zip`)<br>`contentFile` (Base64 ZIP) | `ticket` (`String` numérico/alfanumérico) | **Asíncrono** (Requiere `getStatus`) |
| `sendPack` | Lotes (Opcional) | `fileName` + `contentFile` | `ticket` | **Asíncrono** |
| `getStatus` | `checkTicket` | `ticket` (`String`) | `status` (`statusCode` + `content` Base64 CDR) | Consulta estado de `sendSummary` / `sendPack` |
| `getStatusCdr` | `queryDocumentStatus` | `rucComprobante`, `tipoComprobante`, `serieComprobante`, `numeroComprobante` | `statusCdr` (`statusCode`, `statusMessage`, `content` Base64 CDR) | Recupera CDR de un comprobante previo |

---

## 4. Estructura del Sobre SOAP 1.1 y WS-Security

### 4.1 Petición `sendBill`

```xml
<soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/"
                  xmlns:ser="http://service.sunat.gob.pe"
                  xmlns:wsse="http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-wssecurity-secext-1.0.xsd">
  <soapenv:Header>
    <wsse:Security>
      <wsse:UsernameToken>
        <wsse:Username>20100066603MODDATOS</wsse:Username>
        <wsse:Password Type="http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-username-token-profile-1.0#PasswordText">moddatos</wsse:Password>
      </wsse:UsernameToken>
    </wsse:Security>
  </soapenv:Header>
  <soapenv:Body>
    <ser:sendBill>
      <fileName>20100066603-01-F001-1.zip</fileName>
      <contentFile>UEsDBBQAAAAIA...</contentFile>
    </ser:sendBill>
  </soapenv:Body>
</soapenv:Envelope>
```

### 4.2 Manejo de `<soap:Fault>` y Códigos en Bizlinks

Bizlinks devuelve errores técnicos y de negocio utilizando dos mecanismos que el parser `BizlinksSoapParser` unifica:

1. **Vía `<soapenv:Fault>`**:
   - En algunos casos el código SUNAT viene en `<faultcode>` (ej. `soap-env:Client.2017`) y en otros viene en `<faultstring>` (ej. `"2017"` con el detalle en `<detail><message>...</message></detail>`).
   - El extractor de `sunat_cpe_core` aplica expresión regular para extraer el entero de 4 dígitos (`0100`-`3999`) sin importar si está en `faultcode` o `faultstring`:
     - Si el código es `0100`..`1999` -> `CpeFailure(SunatExceptionError)`.
     - Si el código es `2000`..`3999` -> `CpeFailure(SunatRejectionException)`.
2. **Vía CDR con Código de Rechazo dentro de `<applicationResponse>`**:
   - Cuando el OSE genera un CDR de rechazo firmado, `sendBill` devuelve HTTP `200` con `<applicationResponse>`, pero al abrir el XML `R-*.xml`, `<cbc:ResponseCode>` contiene un valor `>= 2000`.
   - En ese caso, `BaseUblOseProvider` retorna `CpeFailure(SunatRejectionException(sunatCode: code, rejectionCdr: cdrData))` preservando el XML del CDR de rechazo para auditoría contable.

### 4.3 Códigos de `getStatus` para Tickets Asíncronos (`RC`, `RA`, `RR`)

| `<statusCode>` en `getStatus` | Estado en `sunat_cpe_core` | Acción |
|-------------------------------|----------------------------|--------|
| `"0"` o `"0000"` | `CpeProcessStatus.accepted` | Decodifica `<content>` (ZIP CDR) y finaliza polling |
| `"98"` o `"0098"` | `CpeProcessStatus.inProcess` | Continúa polling con `BackoffStrategy` |
| `"99"` o `"0099"` | `CpeProcessStatus.rejected` | Decodifica `<content>` (si trae CDR de error) y retorna `SunatRejectionException` |

---

## 5. Diseño de Clases del Paquete `sunat_cpe_bizlinks`

```text
packages/sunat_cpe_bizlinks/
├── lib/
│   ├── sunat_cpe_bizlinks.dart
│   └── src/
│       ├── bizlinks_config.dart          # environment (prod/test), username, password, certificateCredentials
│       ├── bizlinks_provider.dart        # Extiende BaseUblOseProvider e implementa OseProvider
│       └── soap/
│           └── bizlinks_soap_fault_parser.dart # Reglas específicas de extracción de Faults de Bizlinks
```
