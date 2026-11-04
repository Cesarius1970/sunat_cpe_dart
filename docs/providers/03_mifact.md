---
title: "Proveedor 03: Mifact (PSE / OSE)"
aliases:
  - "Mifact"
  - "sunat_cpe_mifact"
tags:
  - sunat
  - cpe
  - proveedor
  - pse
  - ose
  - rest-json
  - mifact
type: provider-spec
package: sunat_cpe_mifact
protocol: REST JSON
status: planned
updated: 2026-11-04
---

# Análisis de Proveedor 03: Mifact (PSE / OSE)

> [!NOTE] Navegación del Vault
> [[README|🏠 Índice Principal]] · **Anterior**: [[providers/02_efact|← Proveedor 02: EFACT]] · **Siguiente**: [[providers/04_bizlinks|Proveedor 04: Bizlinks →]]
> **Enlaces Externos**: [Portal Oficial Mifact](https://mifact.net/) · [Paquete en Monorepo GitHub](https://github.com/Cesarius1970/sunat_cpe_dart/tree/main/packages/sunat_cpe_mifact)

Especificación técnica para el paquete `packages/sunat_cpe_mifact` que implementa el contrato [[core/01_architecture_and_patterns#5. Contrato Principal `OseProvider` y Capacidades Modulares|`OseProvider`]].

---

## 1. Perfil Técnico del Proveedor

- **Rol en SUNAT**: PSE (Proveedor de Servicios Electrónicos) con integración directa a [SUNAT](https://cpe.sunat.gob.pe/) y OSE.
- **Modo de Integración**: **Vía Delegada (JSON REST)**.
- **Generación UBL y Firma**: Ejecutada en el servidor de Mifact (usando el certificado propio del contribuyente subido a Mifact o certificado PSE de Mifact). Pre-validado localmente con [[core/03_validation_and_ubl_signing#1. Motor de Validación Matemática (`CpeMathValidator`)|`CpeMathValidator`]].
- **Protocolo y Transporte**: `HTTPS POST` mediante [[core/01_architecture_and_patterns#6. Capa de Transporte (`CpeHttpClient`)|`CpeHttpClient`]] con payload JSON en mayúsculas (`UPPER_SNAKE_CASE`).
- **Autenticación**: A diferencia de [[providers/01_nubefact|Nubefact]] o [[providers/07_facturaloperu|FacturaloPeru]] que usan cabeceras HTTP, Mifact recibe la credencial **dentro del cuerpo del JSON** mediante la propiedad `"TOKEN"` (contiene un token de pruebas predefinido para beta `gN8zNRBV+/FVxTLwdaZx0w==` y un token único por emisor en producción).

---

## 2. Endpoints Oficiales de Mifact

| Operación | Método | Endpoint (Ruta Relativa sobre Dominio Mifact) | Método en [[core/01_architecture_and_patterns#5. Contrato Principal `OseProvider` y Capacidades Modulares\|`OseProvider`]] |
|-----------|--------|-----------------------------------------------|------------------------|
| Emitir Factura, Boleta, NC, ND | `POST` | `/service.asmx/SendInvoice` (o `/api/SendInvoice`) | `sendDocument` |
| Emitir Guía de Remisión (09/31) | `POST` | `/service.asmx/SendGuide` | `sendDespatchAdvice` |
| Comunicación de Baja (`RA`) | `POST` | `/service.asmx/lowInvoice` | `sendVoidedDocument` |
| Resumen Diario de Boletas (`RC`) | `POST` | `/service.asmx/SendSummary` | `sendDailySummary` |
| Consultar Estado / CDR / PDF | `POST` | `/service.asmx/GetStatus` | `queryDocumentStatus` / `checkTicket` |

---

## 3. Estructura del Payload JSON en Mifact (`SendInvoice`)

> [!NOTE] Convención de Nomenclatura de Mifact
> Todas las llaves del JSON de Mifact utilizan códigos de tres o cuatro letras en **MAYÚSCULAS** inspirados en los campos UBL/SUNAT (`TIP_DOCU`, `NUM_NIF_EMIS`, `MNT_TOT_GRAVADO`, etc.).

```json
{
  "TOKEN": "gN8zNRBV+/FVxTLwdaZx0w==",
  "COD_TIP_NIF_EMIS": "6",
  "NUM_NIF_EMIS": "20100113612",
  "NOM_RZN_SOC_EMIS": "EMPRESA DEMO S.A.C.",
  "NOM_COMER_EMIS": "DEMO",
  "COD_UBI_EMIS": "150101",
  "TXT_DMCL_FISC_EMIS": "AV. DEMO 123 LIMA",
  "COD_TIP_DOCU": "01",
  "NUM_SERIE_CPE": "F001",
  "NUM_CORRE_CPE": "00000001",
  "FEC_EMIS": "2026-10-30",
  "HOR_EMIS": "13:05:00",
  "FEC_VENC": "2026-11-30",
  "COD_MND": "PEN",
  "COD_PRCD_CARGA": "001",
  "COD_TIP_OPE_SUNAT": "0101",
  "COD_TIP_NIF_RECP": "6",
  "NUM_NIF_RECP": "20600695771",
  "NOM_RZN_SOC_RECP": "CLIENTE S.A.C.",
  "TXT_DMCL_FISC_RECP": "AV. CLIENTE 456",
  "MNT_TOT_GRAVADO": "100.00",
  "MNT_TOT_EXONERADO": "0.00",
  "MNT_TOT_INAFECTO": "0.00",
  "MNT_TOT_GRATUITO": "0.00",
  "MNT_TOT_TRIB_IGV": "18.00",
  "MNT_TOT": "118.00",
  "COD_FRM_PAGO": "Contado",
  "ENVIAR_A_SUNAT": "true",
  "ITEMS": [
    {
      "COD_ITEM": "P001",
      "COD_UNID_ITEM": "NIU",
      "CANT_UNID_ITEM": "1.00",
      "VAL_UNIT_ITEM": "100.00",
      "PRC_VTA_UNIT_ITEM": "118.00",
      "VAL_VTA_ITEM": "100.00",
      "MNT_IGV_ITEM": "18.00",
      "POR_IGV_ITEM": "18.00",
      "COD_TIP_AFECT_IGV_ITEM": "10",
      "TXT_DESC_ITEM": "SERVICIO DE CONSULTORIA"
    }
  ]
}
```

### 3.1 Ventaja del Mapeo en Mifact
A diferencia de [[providers/01_nubefact|Nubefact]], **Mifact utiliza exactamente los códigos oficiales de los [[core/02_domain_entities_and_types#2. Catálogos Oficiales SUNAT (Anexo N° 8)|Catálogos SUNAT]]**:
- `COD_TIP_DOCU`: `'01'`, `'03'`, `'07'`, `'08'`.
- `COD_MND`: `'PEN'`, `'USD'`.
- `COD_TIP_AFECT_IGV_ITEM`: `'10'`, `'20'`, `'30'`, `'40'`, etc.
- `COD_TIP_OPE_SUNAT`: `'0101'`, `'1001'`, etc.
- Todos los números y montos se envían serializados como `String` (`"100.00"`), lo cual encaja directamente con `Decimal.toStringAsFixed(2)` del Core.

---

## 4. Estructura de Respuesta y Mapeo de Errores

### 4.1 Respuesta JSON de Mifact

```json
{
  "estado_documento": "102",
  "codigo_hash": "kL9pQ2...",
  "cadena_para_codigo_qr": "20100113612|01|F001|00000001|18.00|118.00|2026-10-30|6|20600695771|kL9pQ2...|",
  "sunat_description": "La Factura numero F001-00000001, ha sido aceptada",
  "pdf_bytes": "JVBERi0xLjQK...",
  "xml_bytes": "PD94bWwgdmVyc2lvbj0iMS4w...",
  "cdr_bytes": "UEsDBBQAAAAI...",
  "url_pdf": "https://...",
  "errors": ""
}
```

### 4.2 Tabla de Estados Internos de Mifact (`estado_documento`)

| `estado_documento` | Significado en Mifact | Mapeo en [[core/01_architecture_and_patterns#3. Modelo de Resultados y Errores (`CpeResult<T>`)\|`sunat_cpe_core`]] |
|--------------------|-----------------------|---------------------------|
| `"101"` | Registrado / En proceso (Pendiente de envío a SUNAT) | `CpeSuccess` -> `CpeProcessStatus.inProcess` |
| `"102"` | **Aceptado por SUNAT** | `CpeSuccess` -> `CpeProcessStatus.accepted` |
| `"103"` | **Aceptado con Observaciones por SUNAT** | `CpeSuccess` -> `CpeProcessStatus.acceptedWithWarnings` |
| `"104"` | **Rechazado por SUNAT** | `CpeFailure(SunatRejectionException)` |
| `"105"` | Anulado (Dado de baja mediante RA/RC) | Estado de consulta `voided` |
| `"100"` o Error | Error de estructura o validación previa en Mifact | `CpeFailure(CpeValidationException)` o `SunatExceptionError` |

---

## 5. Diseño de Clases del Paquete `sunat_cpe_mifact`

```text
packages/sunat_cpe_mifact/
├── lib/
│   ├── sunat_cpe_mifact.dart
│   └── src/
│       ├── mifact_config.dart            # baseUrl, token, sendImmediatelyToSunat, includePdfBytes
│       ├── mifact_provider.dart          # Implementa OseProvider
│       └── mappers/
│           ├── mifact_invoice_mapper.dart  # SalesCpeDocument -> UpperSnakeCase JSON Map
│           ├── mifact_guide_mapper.dart    # DespatchAdviceDocument -> SendGuide JSON Map
│           ├── mifact_summary_mapper.dart  # VoidedDocument / DailySummaryDocument
│           └── mifact_response_mapper.dart # Decodifica estado_documento (101..105) y cdr_bytes Base64
```

---

> [!TIP] Navegación de Proveedores
> - [[README|🏠 Índice Principal]]
> - **Anterior**: [[providers/02_efact|← Proveedor 02: EFACT]]
> - **Siguiente**: [[providers/04_bizlinks|Proveedor 04: Bizlinks →]]
> - **Relacionados (JSON REST)**: [[providers/01_nubefact|01. Nubefact]] · [[providers/07_facturaloperu|07. FacturaloPeru / PRO]]
