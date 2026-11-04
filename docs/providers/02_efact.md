---
title: "Proveedor 02: EFACT (OSE / PSE)"
aliases:
  - "EFACT"
  - "sunat_cpe_efact"
tags:
  - sunat
  - cpe
  - proveedor
  - ose
  - pse
  - oauth2
  - soap
  - efact
type: provider-spec
package: sunat_cpe_efact
protocol: REST OAuth2 + SOAP 1.1
status: planned
updated: 2026-11-04
---

# Análisis de Proveedor 02: EFACT (OSE / PSE)

> [!NOTE] Navegación del Vault
> [[README|🏠 Índice Principal]] · **Anterior**: [[providers/01_nubefact|← Proveedor 01: Nubefact]] · **Siguiente**: [[providers/03_mifact|Proveedor 03: Mifact →]]
> **Enlaces Externos**: [Portal Oficial EFACT](https://www.efact.pe/) · [EFACT OSE](https://ose.efact.pe/) · [Paquete en Monorepo GitHub](https://github.com/Cesarius1970/sunat_cpe/tree/main/packages/sunat_cpe_efact)

Especificación técnica para el paquete `packages/sunat_cpe_efact` que implementa el contrato [[core/01_architecture_and_patterns#5. Contrato Principal `OseProvider` y Capacidades Modulares|`OseProvider`]].

---

## 1. Perfil Técnico del Proveedor

- **Rol en SUNAT**: Uno de los principales OSE (Operador de Servicios Electrónicos) y PSE en Perú por volumen transaccional.
- **Modos de Integración Soportados por `sunat_cpe_efact`**:
  1. **Modo API REST (`api-efact-ose`) (Recomendado)**:
     - Autenticación OAuth2 (`Bearer Token`) mediante interceptor en [[core/01_architecture_and_patterns#6. Capa de Transporte (`CpeHttpClient`)|`CpeHttpClient`]].
     - Envío mediante `multipart/form-data` aceptando **XML UBL 2.1 firmado localmente** (generado con [[core/03_validation_and_ubl_signing#2. Generador XML UBL 2.1 / 2.0 (`UblXmlBuilder`)|`UblXmlBuilder`]] y [[core/03_validation_and_ubl_signing#3. Firmador Digital XAdES-BES en Dart Puro (`XadesBesSigner`)|`XadesBesSigner`]]) o **JSON UBL / CSV** (modo PSE con firma en la nube de EFACT).
     - Flujo **Asíncrono por Ticket UUID**: El POST devuelve HTTP `200` con un `description` que contiene el `Ticket UUID`, seguido de consulta a `/v1/cdr/{ticket}` mediante [[core/01_architecture_and_patterns#Helper de Polling Asíncrono (`PollingConfig`)|`pollTicketUntilDone`]].
  2. **Modo SOAP 1.1 (`efact-ose.pe/ol-ti-itcpe/billService`)**:
     - Compatible con el estándar `billService` de SUNAT (`sendBill`, `sendSummary`, `sendPack`, `getStatus`) heredando de [[core/01_architecture_and_patterns#2. Patrones de Diseño Aplicados|`BaseUblOseProvider`]].
     - Autenticación mediante cabecera WS-Security `<wsse:UsernameToken>`.

---

## 2. Endpoints Oficiales de EFACT

| Entorno | Modalidad | URL Base |
|---------|-----------|----------|
| **Producción** | API REST | `https://ose.efact.pe/api-efact-ose` |
| **Homologación / Test** | API REST | `https://ose-gw1.efact.pe:443/api-efact-ose` |
| **Producción** | SOAP 1.1 | `https://ose.efact.pe/ol-ti-itcpe/billService` |
| **Homologación / Test** | SOAP 1.1 | `https://ose-gw1.efact.pe/ol-ti-itcpe/billService` |

---

## 3. Flujo Detallado: Modo API REST OAuth2

### 3.1 Obtención del Token OAuth2 (`POST /oauth/token`)

EFACT utiliza el esquema `password` grant con credenciales Basic Auth fijas del cliente (`efact-ose-client:secret` -> `Basic ZWZhY3Qtb3NlLWNsaWVudDpzZWNyZXQ=` o según credencial asignada):

```http
POST /api-efact-ose/oauth/token HTTP/1.1
Host: ose.efact.pe
Authorization: Basic ZWZhY3Qtb3NlLWNsaWVudDpzZWNyZXQ=
Content-Type: application/x-www-form-urlencoded

grant_type=password&username=20100066603&password=HASH_SHA256_O_PASSWORD_OSE
```

Respuesta:
```json
{
  "access_token": "eyJhbGciOiJIUzI1NiIsInR5cCI...",
  "token_type": "bearer",
  "expires_in": 43199,
  "scope": "read write"
}
```
> El interceptor `EfactOAuth2Interceptor` almacena el `access_token` en caché de memoria y lo renueva automáticamente 60 segundos antes de que venza `expires_in`.

### 3.2 Envío de Comprobante (`POST /v1/document`)

Recibe un `multipart/form-data` con el campo `file` nombrado `{RUC}-{TIPO}-{SERIE}-{NUMERO}.xml` (o `.json` / `.csv` si se usa EFACT como PSE):

```http
POST /api-efact-ose/v1/document HTTP/1.1
Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI...
Content-Type: multipart/form-data; boundary=---BoundarySunatCpe

-----BoundarySunatCpe
Content-Disposition: form-data; name="file"; filename="20100066603-01-F001-00000001.xml"
Content-Type: application/xml

<?xml version="1.0" encoding="UTF-8"?>
<Invoice ...>...</Invoice>
-----BoundarySunatCpe--
```

Respuesta de recepción (HTTP `200 OK`):
```json
{
  "code": "0",
  "description": "550e8400-e29b-41d4-a716-446655440000"
}
```
Donde `description` es el **Ticket UUID** asignado por EFACT.

### 3.3 Consulta de Ticket / Descarga de CDR, XML y PDF

| Recurso | Endpoint | Código HTTP en Proceso | Código HTTP Finalizado |
|---------|----------|------------------------|------------------------|
| **CDR (XML)** | `GET /v1/cdr/{ticket}` | `202 Accepted` o `412` (`code: -9998` En proceso) | `200 OK` (Retorna XML del CDR, parseado por [[core/03_validation_and_ubl_signing#4. Empaquetado ZIP y Lector de CDR (`CpeZipCodec`)\|`CpeZipCodec.parseCdrFromXmlString`]]) |
| **XML Firmado** | `GET /v1/xml/{ticket}` | `202` / `412` | `200 OK` (Retorna XML UBL 2.1) |
| **PDF Impreso** | `GET /v1/pdf/{ticket}` | `202` / `412` | `200 OK` (`application/pdf`) |

### 3.4 Comportamiento en `sunat_cpe_efact` para `sendDocument`

Dado que la API REST de EFACT devuelve un Ticket UUID en el paso 1:
- **Modo `autoPollInRest: true` (Por defecto en `EfactConfig`)**: `sendDocument()` envía el multipart a `/v1/document`, obtiene el `ticket` e invoca inmediatamente `pollTicketUntilDone(ticket)` (típicamente EFACT responde el CDR en `500ms - 1500ms`), devolviendo un [[core/01_architecture_and_patterns#4. Interfaces de Respuesta Unificadas|`CpeEmissionResponse`]] completo con su `CdrData`.
- **Modo `autoPollInRest: false`**: `sendDocument()` retorna de inmediato `CpeEmissionResponse(status: CpeProcessStatus.inProcess, ticket: uuid)` para que el consumidor consulte luego con `checkTicket(uuid)`.

---

## 4. Flujo Alternativo: Modo SOAP 1.1 (`EfactSoapMode`)

Cuando se configura `EfactConfig.soap(...)`:
- Reutiliza `BaseUblOseProvider` de `sunat_cpe_core`.
- Genera el XML UBL 2.1 con `UblXmlBuilder`, lo firma localmente con `XadesBesSigner` y lo comprime en `.zip` con `CpeZipCodec`.
- Invoca la operación `<ser:sendBill>` enviando `<fileName>20100066603-01-F001-1.zip</fileName>` y `<contentFile>BASE64...</contentFile>`.
- Recibe `<applicationResponse>` de forma **100% síncrona** con el ZIP del CDR `R-20100066603-01-F001-1.zip`.

---

## 5. Diseño de Clases del Paquete `sunat_cpe_efact`

```text
packages/sunat_cpe_efact/
├── lib/
│   ├── sunat_cpe_efact.dart
│   └── src/
│       ├── efact_config.dart             # Modo (restXml, restJson, soapUbl), credenciales, autoPollInRest
│       ├── efact_provider.dart           # Implementa OseProvider
│       ├── auth/
│       │   └── efact_oauth2_interceptor.dart # Gestión de Bearer Token en /oauth/token
│       ├── rest/
│       │   ├── efact_rest_client.dart    # Multipart /v1/document y consultas /v1/cdr/{ticket}
│       │   └── efact_json_mapper.dart    # Mapeo opcional a JSON UBL EFACT
│       └── soap/
│           └── efact_soap_delegate.dart  # Extiende BaseUblOseProvider para billService SOAP
```

---

> [!TIP] Navegación de Proveedores
> - [[README|🏠 Índice Principal]]
> - **Anterior**: [[providers/01_nubefact|← Proveedor 01: Nubefact]]
> - **Siguiente**: [[providers/03_mifact|Proveedor 03: Mifact →]]
