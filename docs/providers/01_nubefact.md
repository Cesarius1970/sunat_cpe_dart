# Análisis de Proveedor 01: Nubefact (PSE / OSE)

Especificación técnica para el paquete `packages/sunat_cpe_nubefact`.

---

## 1. Perfil Técnico del Proveedor

- **Rol en SUNAT**: PSE (Proveedor de Servicios Electrónicos) y OSE (Operador de Servicios Electrónicos) autorizado.
- **Modo de Integración**: **Vía Delegada (JSON REST)** (también soporta TXT separado por pipes `|`, pero el paquete Dart usará exclusivamente **JSON UTF-8** por tipado y legibilidad).
- **Generación UBL y Firma**: Ejecutada en los servidores de Nubefact. El paquete **no** requiere certificado `.pfx` local; solo utiliza `CpeMathValidator` del Core antes de enviar el JSON.
- **Protocolo y Transporte**: `HTTPS POST` a una **Ruta Única (Endpoint personal por RUC/Local)** entregada en el panel de Nubefact.
- **Autenticación**: Header HTTP personalizado:
  ```http
  Authorization: Token token="9d8f7a6b5c4d3e2f1a..."
  Content-Type: application/json; charset=utf-8
  ```

---

## 2. Operaciones (`operacion`) Soportadas en el Endpoint Único

Nubefact enruta todas las acciones sobre el mismo URL mediante el campo raíz `"operacion"`:

| Valor de `"operacion"` | Método de `OseProvider` en Core | Comprobantes Cubiertos |
|------------------------|---------------------------------|------------------------|
| `"generar_comprobante"` | `sendDocument` | Factura (`1`), Boleta (`2`), Nota de Crédito (`3`), Nota de Débito (`4`) |
| `"generar_anulacion"` | `sendVoidedDocument` | Comunicación de Baja (`RA`) y Resumen Diario de Anulación de Boletas |
| `"generar_guia"` | `sendDespatchAdvice` | Guía de Remisión Remitente (`7`) y Transportista (`8`) |
| `"generar_retencion"` | `sendRetentionOrPerception` | Comprobante de Retención (`20`) |
| `"generar_percepcion"` | `sendRetentionOrPerception` | Comprobante de Percepción (`40`) |
| `"consultar_comprobante"`| `queryDocumentStatus` | Consulta de estado, XML, CDR y PDF de Factura, Boleta, NC, ND |
| `"consultar_anulacion"` | `checkTicket` / `queryDocumentStatus` | Consulta de ticket de Comunicación de Baja |
| `"consultar_guia"` | `checkTicket` / `queryDocumentStatus` | Consulta de estado/CDR de Guía de Remisión |

---

## 3. Particularidades Críticas y Códigos Propios de Nubefact

> [!WARNING]
> **Nubefact NO usa los códigos directos de los Catálogos SUNAT 01, 02 ni 07 en todos sus campos.** El adaptador `NubefactMapper` debe traducir los enums del Core a los enteros propietarios de Nubefact.

### 3.1 Tabla de Traducción de Códigos (`Core` -> `Nubefact`)

| Concepto | Valor en `sunat_cpe_core` (SUNAT) | Valor en `sunat_cpe_nubefact` (`int`) |
|----------|-----------------------------------|---------------------------------------|
| **Tipo de Comprobante** (`tipo_de_comprobante`) | `'01'` (Factura)<br>`'03'` (Boleta)<br>`'07'` (Nota Crédito)<br>`'08'` (Nota Débito)<br>`'09'` (Guía Remitente)<br>`'31'` (Guía Transportista) | `1`<br>`2`<br>`3`<br>`4`<br>`7`<br>`8` |
| **Moneda** (`moneda`) | `'PEN'`<br>`'USD'`<br>`'EUR'` | `1`<br>`2`<br>`3` |
| **Tipo de Operación** (`sunat_transaction`) | `'0101'` (Venta Interna)<br>`'0200'` (Exportación)<br>`'0102'` (Anticipos)<br>`'1001'` (Detracción)<br>`'2001'` (Percepción) | `1` (Venta Interna)<br>`2` (Exportación)<br>`4` (Venta Interna - Anticipos)<br>`30` (Operación sujeta a Detracción)<br>`33` (Detracción - Transporte Carga) |
| **Tipo de Afectación IGV** (`tipo_de_igv`) | `'10'` (Gravado Onerosa)<br>`'11'`..`'16'` (Retiros Gravados)<br>`'20'` (Exonerado Onerosa)<br>`'21'` (Exonerado Transferencia Gratuita)<br>`'30'` (Inafecto Onerosa)<br>`'31'`..`'36'` (Retiros Inafectos)<br>`'40'` (Exportación)<br>`'17'` (Gravado IVAP) | `1`<br>`2` al `7`<br>`8`<br>`9`<br>`9` (o `16` según config)<br>`10` al `15`<br>`16`<br>`17` |
| **Catálogo 09 Nota de Crédito** (`tipo_de_nota_de_credito`) | `'01'` al `'13'` | `1` al `13` (`int`) |
| **Catálogo 10 Nota de Débito** (`tipo_de_nota_de_debito`) | `'01'`, `'02'`, `'03'` | `1`, `2`, `3` (`int`) |

---

## 4. Estructura del Payload JSON (`generar_comprobante`)

```json
{
  "operacion": "generar_comprobante",
  "tipo_de_comprobante": 1,
  "serie": "FFF1",
  "numero": 1,
  "sunat_transaction": 1,
  "cliente_tipo_de_documento": 6,
  "cliente_numero_de_documento": "20600695771",
  "cliente_denominacion": "NUBEFACT SA",
  "cliente_direccion": "CALLE LIBERTAD 116 MIRAFLORES - LIMA - PERU",
  "cliente_email": "cliente@empresa.com",
  "fecha_de_emision": "30-10-2026",
  "fecha_de_vencimiento": "30-11-2026",
  "moneda": 1,
  "tipo_de_cambio": "",
  "porcentaje_de_igv": 18.00,
  "descuento_global": "",
  "total_descuento": "",
  "total_anticipo": "",
  "total_gravada": 100.00,
  "total_inafecta": "",
  "total_exonerada": "",
  "total_igv": 18.00,
  "total_gratuita": "",
  "total_otros_cargos": "",
  "total_impuestos_bolsas": "",
  "total": 118.00,
  "detraccion": false,
  "enviar_automaticamente_a_la_sunat": true,
  "enviar_automaticamente_al_cliente": false,
  "condiciones_de_pago": "CRÉDITO",
  "medio_de_pago": "credito",
  "venta_al_credito": [
    {
      "cuota": 1,
      "fecha_de_pago": "30-11-2026",
      "importe": 118.00
    }
  ],
  "items": [
    {
      "unidad_de_medida": "NIU",
      "codigo": "001",
      "codigo_producto_sunat": "10000000",
      "descripcion": "DETALLE DEL PRODUCTO",
      "cantidad": 1,
      "valor_unitario": 100.00,
      "precio_unitario": 118.00,
      "descuento": "",
      "subtotal": 100.00,
      "tipo_de_igv": 1,
      "igv": 18.00,
      "impuesto_bolsas": "",
      "total": 118.00,
      "anticipo_regularizacion": false
    }
  ]
}
```

> [!IMPORTANT]
> **Formato de Fechas en Nubefact**: A diferencia del estándar ISO (`YYYY-MM-DD`), Nubefact acepta o prefiere `DD-MM-YYYY` en `fecha_de_emision`, `fecha_de_vencimiento` y `fecha_de_pago`. El mapper de `sunat_cpe_nubefact` formatea `DateTime` a `DD-MM-YYYY` automáticamente.

---

## 5. Manejo de Respuestas y Errores en `sunat_cpe_nubefact`

### 5.1 Respuesta Exitosa (HTTP 200 / 201)

```json
{
  "tipo_de_comprobante": 1,
  "serie": "FFF1",
  "numero": 1,
  "enlace": "https://www.nubefact.com/cpe/...",
  "aceptada_por_sunat": true,
  "sunat_description": "La Factura numero FFF1-00000001, ha sido aceptada",
  "sunat_note": null,
  "sunat_responsecode": "0",
  "sunat_soap_error": "",
  "cadena_para_codigo_qr": "20100066603|01|FFF1|00000001|18.00|118.00|30/10/2026|6|20600695771|xYz123...|",
  "codigo_hash": "xYz123...",
  "enlace_del_pdf": "https://www.nubefact.com/cpe/...pdf",
  "enlace_del_xml": "https://www.nubefact.com/cpe/...xml",
  "enlace_del_cdr": "https://www.nubefact.com/cpe/...cdr"
}
```

### 5.2 Mapeo de Estados y Errores hacia `CpeResult<CpeEmissionResponse>`

1. **Si HTTP Status == 400 / 401 / 422 y contiene `"errors"`**:
   - Código `10` / `11` (Token inválido o ruta incorrecta) -> `CpeFailure(OseAuthException)`.
   - Código `20` al `23` (Error de validación de campos de Nubefact) -> `CpeFailure(CpeValidationException)`.
   - Código `24` ("El documento ya existe en Nubefact") -> Se mapea a una excepción controlada o permite invocar `consultar_comprobante` para recuperar el CDR si hubo corte de red previo.
2. **Si HTTP Status == 200 pero `aceptada_por_sunat == false`**:
   - Si `sunat_responsecode` está entre `2000` y `3999` -> `CpeFailure(SunatRejectionException)`.
   - Si `sunat_responsecode` está entre `0100` y `1999` -> `CpeFailure(SunatExceptionError)`.
   - Si `sunat_responsecode` es vacío y `sunat_soap_error` es vacío -> El comprobante quedó **En Cola Diferida** en Nubefact -> Retorna `CpeSuccess` con `status: CpeProcessStatus.inProcess` para ser consultado luego con `queryDocumentStatus` (`consultar_comprobante`).

---

## 6. Diseño de Clases del Paquete `sunat_cpe_nubefact`

```text
packages/sunat_cpe_nubefact/
├── lib/
│   ├── sunat_cpe_nubefact.dart
│   └── src/
│       ├── nubefact_config.dart         # routeUrl, apiToken, autoSendToSunat, sendEmailToCustomer
│       ├── nubefact_provider.dart       # Implementa OseProvider
│       ├── mappers/
│       │   ├── nubefact_catalog_mapper.dart  # Traducción Catálogos SUNAT <-> Enteros Nubefact
│       │   ├── nubefact_invoice_mapper.dart  # SalesCpeDocument -> Map<String, dynamic>
│       │   ├── nubefact_voided_mapper.dart   # VoidedDocument -> generar_anulacion
│       │   ├── nubefact_guide_mapper.dart    # DespatchAdviceDocument -> generar_guia
│       │   └── nubefact_response_mapper.dart # JSON Response -> CpeEmissionResponse / CpeException
```
