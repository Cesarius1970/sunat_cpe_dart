---
title: "Proveedor 05: Digiflow (OSE)"
aliases:
  - "Digiflow"
  - "sunat_cpe_digiflow"
tags:
  - sunat
  - cpe
  - proveedor
  - ose
  - soap
  - ubl21
  - digiflow
type: provider-spec
package: sunat_cpe_digiflow
protocol: SOAP 1.1 WS-Security + REST GRE
status: planned
updated: 2026-11-04
---

# Análisis de Proveedor 05: Digiflow (OSE)

> [!NOTE] Navegación del Vault
> [[README|🏠 Índice Principal]] · **Anterior**: [[providers/04_bizlinks|← Proveedor 04: Bizlinks]] · **Siguiente**: [[providers/06_sovos_paperless|Proveedor 06: Sovos / Paperless →]]
> **Base Core**: [[core/01_architecture_and_patterns#2. Patrones de Diseño Aplicados|`BaseUblOseProvider`]] · [[core/03_validation_and_ubl_signing|Motor UBL 2.1 y Firma XAdES-BES]]
> **Enlaces Externos**: [Portal Oficial Digiflow](https://www.digiflow.pe/) · [Paquete en Monorepo GitHub](https://github.com/Cesarius1970/sunat_cpe_dart/tree/main/packages/sunat_cpe_digiflow)

Especificación técnica para el paquete `packages/sunat_cpe_digiflow` que extiende [`BaseUblOseProvider`](../../packages/sunat_cpe_core/lib/src/providers/base_ubl_ose_provider.dart) e implementa [[core/01_architecture_and_patterns#5. Contrato Principal `OseProvider` y Capacidades Modulares|`OseProvider`]].

---

## 1. Perfil Técnico del Proveedor

- **Rol en SUNAT**: Primer OSE (Operador de Servicios Electrónicos) autorizado en el Perú (vinculado a la Cámara de Comercio de Lima / Certicom), especializado en validación OSE pura de alto rendimiento.
- **Modo de Integración**: **Vía UBL Nativa (SOAP 1.1 WS-Security + REST para GRE)**.
- **Generación UBL y Firma**: Requiere que el emisor genere el XML UBL 2.1 ([[core/03_validation_and_ubl_signing#2. Generador XML UBL 2.1 / 2.0 (`UblXmlBuilder`)|`UblXmlBuilder`]]), lo firme digitalmente con su certificado X.509 ([[core/03_validation_and_ubl_signing#3. Firmador Digital XAdES-BES en Dart Puro (`XadesBesSigner`)|`XadesBesSigner`]]) y lo empaquete en `.zip` ([[core/03_validation_and_ubl_signing#4. Empaquetado ZIP y Lector de CDR (`CpeZipCodec`)|`CpeZipCodec`]]).
- **Autenticación**:
  - **SOAP `billService`**: Cabecera OASIS WS-Security `<wsse:UsernameToken>` con usuario `{RUC}{USUARIO_SOL_O_DIGIFLOW}` y contraseña en texto plano (`PasswordText`).
  - **Guías de Remisión (GRE)**: Soporta tanto validación por `sendBill` / `sendSummary` OSE como el flujo API REST GRE OAuth2.

---

## 2. Endpoints Oficiales de Digiflow OSE

| Entorno | Servicio | URL |
|---------|----------|-----|
| **Producción** | SOAP 1.1 OSE | `https://ose.digiflow.pe/ol-ti-itcpe/billService` |
| **Homologación / Test** | SOAP 1.1 OSE | `https://osetest.digiflow.pe/ol-ti-itcpe/billService` |

---

## 3. Reglas y Particularidades Técnicas de Digiflow

1. **Estricto Cumplimiento de Namespace SOAP y `SOAPAction`**:
   - Digiflow valida la presencia del header HTTP `SOAPAction`:
     - `SOAPAction: "urn:sendBill"`
     - `SOAPAction: "urn:sendSummary"`
     - `SOAPAction: "urn:sendPack"`
     - `SOAPAction: "urn:getStatus"`
     - `SOAPAction: "urn:getStatusCdr"`
2. **Validación Estricta del Nombre del Archivo Interno del ZIP**:
   - Si el `<fileName>` del SOAP es `20100066603-01-F001-00000001.zip`, la entrada dentro del archivo comprimido **debe llamarse exactamente** `20100066603-01-F001-00000001.xml` (sin rutas relativas como `./` ni subcarpetas). Si no coinciden carácter por carácter, Digiflow devuelve Excepción `0151` ("El nombre del archivo XML no corresponde al nombre del archivo ZIP" -> mapeado a [[core/01_architecture_and_patterns#Jerarquía de Excepciones (`CpeException`)|`SunatExceptionError`]]).
3. **Guías de Remisión (`09` y `31`) en Digiflow**:
   - A partir de las actualizaciones de SUNAT para GRE UBL 2.1 ([[core/02_domain_entities_and_types#4.5 Resúmenes, Bajas, Guías de Remisión, Retenciones y Percepciones|`DespatchAdviceDocument`]]), Digiflow valida el hash SHA-256 y retorna dentro del CDR (`<cbc:DocumentDescription>` o `<cac:Response>`) el enlace QR de verificación SUNAT para la guía.
   - `sunat_cpe_digiflow` soporta envío de Guías (`09`/`31`) tanto de forma síncrona vía `sendBill` (cuando el contrato OSE de Digiflow del cliente lo habilita así) como asíncrona por Ticket.

---

## 4. Mapeo de Operaciones en `sunat_cpe_digiflow`

| Método de [[core/01_architecture_and_patterns#5. Contrato Principal `OseProvider` y Capacidades Modulares\|`OseProvider`]] | Operación Digiflow | Detalle de Implementación |
|-------------------------|--------------------|---------------------------|
| `sendDocument` (`01`, `03`, `04`, `07`, `08`) | `urn:sendBill` | Genera UBL 2.1 -> Firma XAdES-BES -> ZIP -> Recibe CDR `R-*.zip` síncrono |
| `sendRetentionOrPerception` (`20`, `40`) | `urn:sendBill` | Genera UBL 2.0 -> Firma XAdES-BES -> ZIP -> Recibe CDR `R-*.zip` síncrono |
| `sendDailySummary` (`RC`) | `urn:sendSummary` | Genera SummaryDocuments UBL 2.0 -> Firma -> ZIP -> Recibe `<ticket>` |
| `sendVoidedDocument` (`RA`, `RR`) | `urn:sendSummary` | Genera VoidedDocuments UBL 2.0 -> Firma -> ZIP -> Recibe `<ticket>` |
| `sendDespatchAdvice` (`09`, `31`) | `urn:sendBill` o `urn:sendSummary` | Configurable en `DigiflowConfig.despatchMode` (Síncrono o Ticket) |
| `checkTicket` | `urn:getStatus` | Consulta `<ticket>` y parsea `statusCode` (`0`, `98`, `99`) |
| `queryDocumentStatus` | `urn:getStatusCdr` | Consulta por `rucComprobante`, `tipoComprobante`, `serieComprobante`, `numeroComprobante` |

---

## 5. Diseño de Clases del Paquete `sunat_cpe_digiflow`

```text
packages/sunat_cpe_digiflow/
├── lib/
│   ├── sunat_cpe_digiflow.dart
│   └── src/
│       ├── digiflow_config.dart          # environment, username, password, certificateCredentials, despatchMode
│       ├── digiflow_provider.dart        # Extiende BaseUblOseProvider con inyección de headers SOAPAction
│       └── soap/
│           └── digiflow_soap_envelope.dart # Construcción de sobre SOAP con namespaces específicos Digiflow
```

---

> [!TIP] Navegación de Proveedores
> - [[README|🏠 Índice Principal]]
> - **Anterior**: [[providers/04_bizlinks|← Proveedor 04: Bizlinks]]
> - **Siguiente**: [[providers/06_sovos_paperless|Proveedor 06: Sovos / Paperless →]]
> - **Relacionados (SOAP UBL)**: [[providers/04_bizlinks|04. Bizlinks]] · [[providers/08_tci|08. TCI]]
