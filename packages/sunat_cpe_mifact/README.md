# sunat_cpe_mifact

Adaptador oficial de **Mifact (PSE / OSE)** en Dart 3 puro para la emisión y gestión de Comprobantes de Pago Electrónicos (CPE) de **SUNAT (Perú)**, implementando todos los contratos de [`sunat_cpe_core`](https://pub.dev/packages/sunat_cpe_core).

---

## Características Principales

- **Mapeo JSON `UPPER_SNAKE_CASE` Nativo**:
  - `MifactInvoiceMapper`: Transforma Facturas (`01`), Boletas (`03`), Notas de Crédito (`07`), Notas de Débito (`08`), Retenciones (`20`) y Percepciones (`40`) a las claves propietarias `UPPER_SNAKE_CASE` de Mifact (`NUM_NIF_EMIS`, `COD_TIP_DOCU`, `NUM_SERIE_CPE`, `NUM_CORRE_CPE` con padding de 8 dígitos, `MNT_TOT_GRAVADO`, `MNT_TOT_TRIB_IGV`, `ITEMS`, `CUOTAS`, etc.).
  - `MifactGuideMapper`: Transforma Guías de Remisión (`09` y `31`) para el endpoint `/service.asmx/SendGuide`.
  - `MifactSummaryMapper`: Transforma Resúmenes Diarios (`RC`), Comunicaciones de Baja (`RA`) y Consultas de Estado para `/service.asmx/SendSummary`, `/service.asmx/lowInvoice` y `/service.asmx/GetStatus`.
- **Autenticación Inyectada en Payload (`TOKEN`)**:
  - Incluye el token público de pruebas `MifactConfig.demoToken` (`"gN8zNRBV+/FVxTLwdaZx0w=="`) listo para homologación/beta y soporte para el token de producción asignado a cada emisor.
- **Interpretación de `estado_documento` (`100` a `105`) y CDR Base64 (`MifactResponseMapper`)**:
  - Decodifica automáticamente `cdr_bytes` (archivo `.zip` CDR en Base64) y `xml_bytes` (XML UBL 2.1 firmado en Base64), además de extraer `codigo_hash`, `cadena_para_codigo_qr` y `url_pdf`.

---

## Endpoints REST JSON de Mifact

| Operación en `MifactProvider` | Ruta Relativa (`POST`) | Mapeador Asociado | Descripción |
| :--- | :--- | :--- | :--- |
| `sendDocument` / `sendRetentionOrPerception` | `/service.asmx/SendInvoice` | `MifactInvoiceMapper` | Emisión de Factura (`01`), Boleta (`03`), NC (`07`), ND (`08`), Retención (`20`) y Percepción (`40`). |
| `sendDespatchAdvice` | `/service.asmx/SendGuide` | `MifactGuideMapper` | Emisión de Guía de Remisión Remitente (`09`) y Transportista (`31`). |
| `sendDailySummary` | `/service.asmx/SendSummary` | `MifactSummaryMapper` | Envío de Resumen Diario de Boletas (`RC`). |
| `sendVoidedDocument` | `/service.asmx/lowInvoice` | `MifactSummaryMapper` | Envío de Comunicación de Baja (`RA`). |
| `checkTicket` / `queryDocumentStatus` | `/service.asmx/GetStatus` | `MifactSummaryMapper` | Consulta de estado de ticket o comprobante emitido. |

### Entornos de Mifact

- **Demostración / Pruebas (Beta)**: `https://demo.mifact.net.pe` (Token público: `MifactConfig.demoToken`).
- **Producción**: `https://mifact.net.pe` (con el `TOKEN` particular del emisor).

---

## Tabla de Estados de Mifact (`estado_documento`)

| `estado_documento` | Significado en Mifact | Mapeo en `sunat_cpe_core` |
| :---: | :--- | :--- |
| `"100"` | Error de validación en estructura o parámetros | `CpeFailure(CpeValidationException)` |
| `"101"` | En proceso de envío a SUNAT | `CpeSuccess` con `CpeProcessStatus.inProcess` |
| `"102"` | Aceptado por SUNAT | `CpeSuccess` con `CpeProcessStatus.accepted` |
| `"103"` | Aceptado con observaciones por SUNAT | `CpeSuccess` con `CpeProcessStatus.acceptedWithWarnings` |
| `"104"` | Rechazado por SUNAT (código 2000-3999) | `CpeFailure(SunatRejectionException)` |
| `"105"` | Anulado (Dado de baja) | `CpeSuccess` con `CpeProcessStatus.voided` |

---

## Opciones de Configuración (`MifactConfig`)

| Propiedad | Tipo | Por Defecto | Descripción |
| :--- | :--- | :--- | :--- |
| `baseUri` | `Uri` | *(Requerido)* | URL base del servidor Mifact (ej. `https://demo.mifact.net.pe`). |
| `token` | `String` | *(Requerido)* | Token de seguridad (`MifactConfig.demoToken` para pruebas). |
| `sendImmediatelyToSunat` | `bool` | `true` | Define el campo `"ENVIAR_A_SUNAT"` (`"true"` o `"false"`). |
| `timeout` | `Duration` | `30s` | Tiempo máximo de espera por petición HTTP. |

---

## Instalación

```yaml
dependencies:
  decimal: ^3.2.1
  sunat_cpe_core: ^0.1.2
  sunat_cpe_mifact: ^0.1.2
```

---

## Ejemplo de Uso Rápido

```dart
import 'package:sunat_cpe_core/sunat_cpe_core.dart';
import 'package:sunat_cpe_mifact/sunat_cpe_mifact.dart';

Future<void> main() async {
  final provider = MifactProvider(
    config: MifactConfig(
      baseUri: Uri.parse('https://demo.mifact.net.pe'),
      token: MifactConfig.demoToken,
      sendImmediatelyToSunat: true,
    ),
  );

  print('Proveedor Mifact inicializado: ${provider.providerId}');
}
```

> Ejecuta el ejemplo completo multiescenario y 100 % offline con:
> ```bash
> dart run example/main.dart
> ```
