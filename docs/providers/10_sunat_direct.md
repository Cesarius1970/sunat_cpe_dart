---
title: "Proveedor 10: SUNAT Directo (SOAP billService + REST GRE OAuth2)"
aliases:
  - "SUNAT Directo"
  - "sunat_cpe_direct"
  - "sunat_cpe_dart"
tags:
  - sunat
  - cpe
  - proveedor
  - directo
  - soap
  - oauth2
  - gre
  - ubl21
type: provider-spec
package: sunat_cpe_direct
protocol: SOAP 1.1 WS-Security + REST OAuth2 GRE
status: active
updated: 2026-11-04
---

# Análisis de Proveedor 10: SUNAT Directo (`sunat_cpe_direct`)

> [!NOTE] Navegación del Vault
> [[README|🏠 Índice Principal]] · **Anterior**: [[providers/09_cavali_gosocket|← Proveedor 09: Cavali / Gosocket]] · **Orquestador**: [[core/04_main_router_and_orchestration|04. Router Principal (`sunat_cpe_dart`) →]]
> **Base Core**: [[core/01_architecture_and_patterns#2. Patrones de Diseño Aplicados|`BaseUblOseProvider`]] · [[core/03_validation_and_ubl_signing|Motor UBL 2.1 y Firma XAdES-BES]]
> **Enlaces Externos**: [Portal Oficial SUNAT CPE](https://cpe.sunat.gob.pe/) · [Paquete en Monorepo GitHub](https://github.com/Cesarius1970/sunat_cpe_dart/tree/main/packages/sunat_cpe_direct)

Especificación técnica para el paquete `packages/sunat_cpe_direct` que integra las capacidades de emisión directa a los servidores de SUNAT (provenientes de `sunat_cpe_dart`) sobre la arquitectura unificada de [[core/01_architecture_and_patterns#5. Contrato Principal `OseProvider` y Capacidades Modulares|`sunat_cpe_core`]].

---

## 1. Perfil Técnico del Canal Directo SUNAT

A diferencia de un OSE o PSE que centraliza todos los tipos de comprobantes en un único endpoint, la conexión directa a **SUNAT Operaciones en Línea (SOL)** requiere **enrutamiento multiprotocolo según el tipo de CPE**:

1. **Canal SOAP Facturación (`e-factura` / `ol-ti-itcpfegem`)**:
   - Atiende Facturas (`01`), Boletas (`03`), Liquidaciones de Compra (`04`), Notas de Crédito (`07`), Notas de Débito (`08`), Resumen Diario (`RC`) y Comunicación de Baja (`RA`).
   - Autenticación vía cabecera OASIS WS-Security `<wsse:UsernameToken>` con `Username = {RUC}{USUARIO_SOL}` y `Password = {CLAVE_SOL}`.
2. **Canal SOAP Otros CPE (`ol-ti-itemision-otroscpe-gem`)**:
   - Atiende Comprobantes de Retención (`20`), Comprobantes de Percepción (`40`) y Resumen de Reversiones (`RR`).
   - Utiliza un endpoint SOAP independiente en SUNAT pero la misma estructura WS-Security.
3. **Canal API REST OAuth2 para Guías de Remisión (`api-cpe.sunat.gob.pe` / `api-seguridad.sunat.gob.pe`)**:
   - Obligatorio en SUNAT para Guías de Remisión Electrónicas Remitente (`09`) y Transportista (`31`) bajo UBL 2.1.
   - Autenticación OAuth2 (`grant_type=password`, `scope=https://api-cpe.sunat.gob.pe`, `client_id`, `client_secret`, `username={RUC}{USUARIO_SOL}`, `password={CLAVE_SOL}`).
   - Envío del archivo `.zip` codificado en Base64 (`arcGreZip`) acompañado de su **hash SHA-256 del binario ZIP en hexadecimal** (`hashZip`), retornando un `numTicket` asíncrono.

---

## 2. Matriz Oficial de Endpoints Directos SUNAT (`SunatDirectEnvironment`)

| Canal | `beta` (Pruebas) | `homologacion` (SQA) | `produccion` (Real) |
|-------|------------------|----------------------|---------------------|
| **SOAP Factura / Notas / RC / RA** | `https://e-beta.sunat.gob.pe/ol-ti-itcpfegem-beta/billService` | `https://www.sunat.gob.pe/ol-ti-itcpgem-sqa/billService` | `https://e-factura.sunat.gob.pe/ol-ti-itcpfegem/billService` |
| **SOAP Retención / Percepción / RR** | `https://e-beta.sunat.gob.pe/ol-ti-itemision-otroscpe-gem-beta/billService` | `https://www.sunat.gob.pe/ol-ti-itemision-otroscpe-gem-sqa/billService` | `https://e-factura.sunat.gob.pe/ol-ti-itemision-otroscpe-gem/billService` |
| **SOAP Guía Remisión (Fallback)** | `https://e-beta.sunat.gob.pe/ol-ti-itemision-guia-gem-beta/billService` | `https://www.sunat.gob.pe/ol-ti-itemision-guia-gem-sqa/billService` | `https://e-guiaremision.sunat.gob.pe/ol-ti-itemision-guia-gem/billService` |
| **REST OAuth2 Token** | `https://api-seguridad.sunat.gob.pe/v1/clientessol/{clientId}/oauth2/token` | `https://api-seguridad.sunat.gob.pe/v1/clientessol/{clientId}/oauth2/token` | `https://api-seguridad.sunat.gob.pe/v1/clientessol/{clientId}/oauth2/token` |
| **REST API GRE Base** | `https://api-cpe.sunat.gob.pe/v1/contribuyente/gem` | `https://api-cpe.sunat.gob.pe/v1/contribuyente/gem` | `https://api-cpe.sunat.gob.pe/v1/contribuyente/gem` |

---

## 3. Regla de Seguridad de Certificado Digital (Real vs Mock en `beta`)

Siguiendo la regla de seguridad de `sunat_cpe_dart`:
- En `SunatDirectEnvironment.produccion` y `SunatDirectEnvironment.homologacion`, es **estrictamente obligatorio** proveer un `CpeCertificateCredentials` real (sin el flag `useBetaMockCertificate`). Si se intenta usar un certificado mock fuera de `beta`, `SunatDirectConfig` lanza `ArgumentError` de inmediato.
- En `SunatDirectEnvironment.beta`, si no se proporciona un certificado X.509 real (o se usa `SunatDirectConfig.beta(...)`), `SunatDirectMockCertificateFactory` genera un par RSA determinístico de pruebas para firmar el XML UBL 2.1 con [[core/03_validation_and_ubl_signing#3. Firmador Digital XAdES-BES en Dart Puro (`XadesBesSigner`)|`XadesBesSigner`]].

---

## 4. Flujo API REST OAuth2 para Guías de Remisión (`SunatDirectGreRestClient`)

### 4.1 Envío de Guía (`POST /v1/contribuyente/gem/comprobantes/{RUC}-{09/31}-{SERIE}-{NUMERO}`)

```json
{
  "archivo": {
    "nomArchivo": "20100066603-09-T001-1.zip",
    "arcGreZip": "UEsDBBQAAAAIA...",
    "hashZip": "e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855"
  }
}
```

Respuesta (`HTTP 200 OK`):
```json
{
  "numTicket": "c4ca4238-a0b9-2382-0dcc-509a6f75849b",
  "fecRecepcion": "2026-11-04T14:30:00"
}
```

### 4.2 Consulta de Ticket GRE (`GET /v1/contribuyente/gem/comprobantes/envios/{numTicket}`)

| `codRespuesta` | Significado en SUNAT REST | Mapeo a `TicketStatusResponse` |
|----------------|---------------------------|--------------------------------|
| `"98"` | En proceso | `CpeProcessStatus.inProcess` |
| `"0"` | Aceptado (incluye `arcCdr` Base64 ZIP) | `CpeProcessStatus.accepted` / `acceptedWithWarnings` + `CdrData` |
| `"99"` | Procesado con errores (`error.numError`, `error.desError`, y opcional `arcCdr`) | `CpeProcessStatus.rejected` |

---

## 5. Diseño de Clases del Paquete `sunat_cpe_direct`

```text
packages/sunat_cpe_direct/
├── lib/
│   ├── sunat_cpe_direct.dart
│   └── src/
│       ├── sunat_direct_config.dart       # SunatDirectEnvironment (beta, homologacion, produccion), credenciales SOL y OAuth2 GRE
│       ├── sunat_direct_provider.dart     # Implementa OseProvider enrutando entre SOAP Factura, SOAP OtrosCPE y REST GRE
│       ├── rest/
│       │   ├── sunat_direct_oauth2_interceptor.dart # Token OAuth2 en api-seguridad.sunat.gob.pe
│       │   └── sunat_direct_gre_rest_client.dart    # Envío ZIP + SHA-256 y consulta de envios/{ticket}
│       └── soap/
│           └── sunat_direct_soap_delegate.dart      # Extiende BaseUblOseProvider para endpoints SOAP de SUNAT
```

---

> [!TIP] Navegación
> - [[README|🏠 Índice Principal]]
> - **Anterior**: [[providers/09_cavali_gosocket|← Proveedor 09: Cavali / Gosocket]]
> - **Siguiente**: [[core/04_main_router_and_orchestration|04. Router Principal (`sunat_cpe_dart`) →]]
