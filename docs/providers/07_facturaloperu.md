---
title: "Proveedor 07: FacturaloPeru / Facturador PRO (Smart / APIPeru)"
aliases:
  - "FacturaloPeru"
  - "Facturador PRO"
  - "APIPeru"
  - "sunat_cpe_facturaloperu"
tags:
  - sunat
  - cpe
  - proveedor
  - pse
  - ose
  - rest-json
  - facturaloperu
type: provider-spec
package: sunat_cpe_facturaloperu
protocol: REST JSON Bearer
status: planned
updated: 2026-11-04
---

# Análisis de Proveedor 07: FacturaloPeru / Facturador PRO (Smart / APIPeru)

> [!NOTE] Navegación del Vault
> [[README|🏠 Índice Principal]] · **Anterior**: [[providers/06_sovos_paperless|← Proveedor 06: Sovos / Paperless]] · **Siguiente**: [[providers/08_tci|Proveedor 08: TCI / Efacturación →]]
> **Enlaces Externos**: [Portal FacturaloPeru](https://facturaloperu.com/) · [APIPeru](https://apiperu.dev/) · [Paquete en Monorepo GitHub](https://github.com/Cesarius1970/sunat_cpe/tree/main/packages/sunat_cpe_facturaloperu)

Especificación técnica para el paquete `packages/sunat_cpe_facturaloperu` que implementa [[core/01_architecture_and_patterns#5. Contrato Principal `OseProvider` y Capacidades Modulares|`OseProvider`]].

---

## 1. Perfil Técnico del Proveedor

- **Rol en el Ecosistema Peruano**: Familia de plataformas PSE / Facturadores basados en el estándar de API REST de **FacturaloPeru / Facturador PRO (PRO X, PRO 4, PRO 5, Smart, APIPeru)**. Es la arquitectura de API JSON más extendida en el mercado peruano para software a medida, casas de software y ERPs cloud/multi-tenant.
- **Modo de Integración**: **Vía Delegada (JSON REST Anidado Semántico)**.
- **Generación UBL y Firma**: Ejecutada en el servidor del Facturador (el cual a su vez despacha a SUNAT directo o al OSE configurado para el tenant). Validado previamente en local por [[core/03_validation_and_ubl_signing#1. Motor de Validación Matemática (`CpeMathValidator`)|`CpeMathValidator`]].
- **Protocolo y Transporte**: `HTTPS POST` mediante [[core/01_architecture_and_patterns#6. Capa de Transporte (`CpeHttpClient`)|`CpeHttpClient`]] sobre endpoints RESTful semánticos (`/api/documents`, `/api/voided`, `/api/summaries`, `/api/dispatches`, `/api/retentions`).
- **Autenticación**: Header estándar Bearer Token:
  ```http
  Authorization: Bearer 8f9d2a1b3c4e5f6a7b8c9d0e1f2a3b4c5d6e7f8a...
  Content-Type: application/json
  Accept: application/json
  ```

---

## 2. Mapa de Endpoints REST (`FacturaloPeru / PRO`)

| Operación | Método HTTP | Ruta del Endpoint | Método en [[core/01_architecture_and_patterns#5. Contrato Principal `OseProvider` y Capacidades Modulares\|`OseProvider`]] |
|-----------|-------------|-------------------|-------------------------|
| Emitir Factura (`01`), Boleta (`03`), NC (`07`), ND (`08`) | `POST` | `/api/documents` | `sendDocument` |
| Enviar Documento en Cola a SUNAT/OSE | `POST` | `/api/documents/send` | Interno / `queryDocumentStatus` |
| Emitir Resumen Diario de Boletas (`RC`) | `POST` | `/api/summaries` | `sendDailySummary` |
| Consultar Ticket de Resumen Diario (`RC`) | `POST` | `/api/summaries/status` | `checkTicket` |
| Emitir Comunicación de Baja (`RA`) | `POST` | `/api/voided` | `sendVoidedDocument` |
| Consultar Ticket de Comunicación de Baja (`RA`) | `POST` | `/api/voided/status` | `checkTicket` |
| Emitir Guía de Remisión (`09` / `31`) | `POST` | `/api/dispatches` | `sendDespatchAdvice` |
| Consultar Ticket de Guía de Remisión | `POST` | `/api/dispatches/status` | `checkTicket` |
| Emitir Comprobante de Retención (`20`) | `POST` | `/api/retentions` | `sendRetentionOrPerception` |
| Consulta de RUC / DNI (Servicio Auxiliar) | `GET` | `/api/service/ruc/{ruc}` o `/dni/{dni}` | Capacidad `ProviderCapability.taxpayerLookup` |

---

## 3. Estructura del Payload JSON Anidado (`POST /api/documents`)

A diferencia de [[providers/01_nubefact|Nubefact]], **FacturaloPeru / PRO respeta al 100% los códigos oficiales de los [[core/02_domain_entities_and_types#2. Catálogos Oficiales SUNAT (Anexo N° 8)|Catálogos SUNAT]]** (`"01"`, `"03"`, `"PEN"`, `"10"`, `"0101"`) y organiza el JSON en objetos anidados limpios:

```json
{
  "serie_documento": "F001",
  "numero_documento": "#",
  "fecha_de_emision": "2026-10-30",
  "hora_de_emision": "13:10:00",
  "codigo_tipo_operacion": "0101",
  "codigo_tipo_documento": "01",
  "codigo_tipo_moneda": "PEN",
  "fecha_de_vencimiento": "2026-11-30",
  "numero_orden_de_compra": "OC-2026-99",
  "codigo_condicion_de_pago": "02",
  "cuotas": [
    {
      "fecha": "2026-11-30",
      "codigo_tipo_moneda": "PEN",
      "monto": 118.00
    }
  ],
  "datos_del_cliente_o_receptor": {
    "codigo_tipo_documento_identidad": "6",
    "numero_documento": "20600695771",
    "apellidos_y_nombres_o_razon_social": "EMPRESA CLIENTE S.A.C.",
    "codigo_pais": "PE",
    "ubigeo": "150101",
    "direccion": "AV. PRINCIPAL 123 - LIMA",
    "correo_electronico": "facturacion@cliente.com",
    "telefono": "999888777"
  },
  "totales": {
    "total_exportacion": 0.00,
    "total_operaciones_gravadas": 100.00,
    "total_operaciones_inafectas": 0.00,
    "total_operaciones_exoneradas": 0.00,
    "total_operaciones_gratuitas": 0.00,
    "total_igv": 18.00,
    "total_impuestos": 18.00,
    "total_valor": 100.00,
    "total_venta": 118.00
  },
  "items": [
    {
      "codigo_interno": "PROD-01",
      "descripcion": "LICENCIA DE SOFTWARE ANUAL",
      "codigo_producto_sunat": "43231500",
      "unidad_de_medida": "ZZ",
      "cantidad": 1,
      "valor_unitario": 100.00,
      "codigo_tipo_precio": "01",
      "precio_unitario": 118.00,
      "codigo_tipo_afectacion_igv": "10",
      "total_base_igv": 100.00,
      "porcentaje_igv": 18.00,
      "total_igv": 18.00,
      "total_impuestos": 18.00,
      "total_valor_item": 100.00,
      "total_item": 118.00
    }
  ],
  "acciones": {
    "enviar_email": false,
    "formato_pdf": "a4"
  }
}
```

> [!TIP] Correlativo Automático Opcional (`"#"`)
> Si en `DocumentId.number` se pasa `0` y en `FacturaloConfig` se activa `allowServerAutoIncrement: true`, el mapper enviará `"numero_documento": "#"` permitiendo que el servidor asigne el siguiente correlativo y lo devuelva en la respuesta. Por defecto usa el correlativo exacto provisto por el ERP.

---

## 4. Estructura de Respuesta y Mapeo de Estados (`state_type_id`)

### 4.1 Respuesta JSON de `/api/documents`

```json
{
  "success": true,
  "data": {
    "number": "F001-00000045",
    "filename": "20100066603-01-F001-00000045",
    "external_id": "9b1deb4d-3b7d-4bad-9bdd-2b0d7b3dcb6d",
    "state_type_id": "05",
    "state_type_description": "Aceptado",
    "number_to_letter": "CIENTO DIECIOCHO CON 00/100 SOLES",
    "hash": "aB3dE5fG7...",
    "qr": "iVBORw0KGgoAAAANSUhEUgAA...",
    "cdr_response": {
      "code": "0",
      "description": "La Factura numero F001-00000045, ha sido aceptada",
      "notes": []
    }
  },
  "links": {
    "xml": "https://tudominio.com/downloads/document/xml/9b1deb4d...",
    "pdf": "https://tudominio.com/downloads/document/pdf/9b1deb4d...",
    "cdr": "https://tudominio.com/downloads/document/cdr/9b1deb4d..."
  }
}
```

### 4.2 Tabla de Estados (`state_type_id`) en FacturaloPeru / PRO

| `state_type_id` | Descripción en Facturalo | Mapeo a [[core/01_architecture_and_patterns#3. Modelo de Resultados y Errores (`CpeResult<T>`)\|`CpeResult`]] en `sunat_cpe_core` |
|-----------------|--------------------------|-----------------------------------------|
| `"01"` | Registrado (Pendiente de envío a SUNAT/OSE) | `CpeSuccess` -> `CpeProcessStatus.inProcess` (con `ticket: external_id`) |
| `"03"` | Enviado (Con ticket en espera de validación) | `CpeSuccess` -> `CpeProcessStatus.inProcess` |
| `"05"` | **Aceptado** | `CpeSuccess` -> `CpeProcessStatus.accepted` |
| `"07"` | **Observado** (Aceptado con advertencias 4000+) | `CpeSuccess` -> `CpeProcessStatus.acceptedWithWarnings` |
| `"09"` | **Rechazado** | `CpeFailure(SunatRejectionException)` |
| `"11"` | Anulado | Estado en consulta `voided` |
| `"13"` | Por anular (Con ticket de baja pendiente) | Estado en consulta `inProcess` |

---

## 5. Diseño de Clases del Paquete `sunat_cpe_facturaloperu`

```text
packages/sunat_cpe_facturaloperu/
├── lib/
│   ├── sunat_cpe_facturaloperu.dart
│   └── src/
│       ├── facturalo_config.dart         # baseUrl, apiToken, pdfFormat ('a4', 'ticket', 'a5'), sendEmail
│       ├── facturalo_provider.dart       # Implementa OseProvider + TaxpayerLookupCapability
│       └── mappers/
│           ├── facturalo_document_mapper.dart  # SalesCpeDocument -> /api/documents JSON
│           ├── facturalo_summary_mapper.dart   # DailySummaryDocument -> /api/summaries JSON
│           ├── facturalo_voided_mapper.dart    # VoidedDocument -> /api/voided JSON
│           ├── facturalo_dispatch_mapper.dart  # DespatchAdviceDocument -> /api/dispatches JSON
│           └── facturalo_response_mapper.dart  # state_type_id (01..13) -> CpeEmissionResponse / CpeException
```

---

> [!TIP] Navegación de Proveedores
> - [[README|🏠 Índice Principal]]
> - **Anterior**: [[providers/06_sovos_paperless|← Proveedor 06: Sovos / Paperless]]
> - **Siguiente**: [[providers/08_tci|Proveedor 08: TCI / Efacturación →]]
> - **Relacionados (JSON REST)**: [[providers/01_nubefact|01. Nubefact]] · [[providers/03_mifact|03. Mifact]]
