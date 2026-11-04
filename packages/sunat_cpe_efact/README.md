# sunat_cpe_efact

Adaptador oficial de **EFACT (OSE / PSE)** en Dart 3 puro para la emisión y validación de Comprobantes de Pago Electrónicos (CPE) de **SUNAT (Perú)**, implementando todos los contratos de [`sunat_cpe_core`](https://pub.dev/packages/sunat_cpe_core).

---

## Características Principales y Modos de Integración

EFACT opera tanto como **OSE (Operador de Servicios Electrónicos)** como **PSE (Proveedor de Servicios Electrónicos)**. Este paquete soporta sus **3 canales oficiales de integración**:

1. **Modo 1 — REST OAuth2 JSON (`EfactIntegrationMode.restJson`)**:
   - Transforma las entidades de dominio de `sunat_cpe_core` al formato JSON UBL de EFACT mediante `EfactJsonMapper` (modalidad PSE con firma en la nube).
   - Envía el archivo `.json` por `multipart/form-data` a `POST /v1/document` y recibe el UUID del Ticket.
   - Realiza auto-polling exponencial (configurable con `autoPollInRest`) contra `GET /v1/cdr/{ticket}` mientras devuelva HTTP `202` o HTTP `412` (`code: "-9998"`), hasta obtener HTTP `200` con el `<ApplicationResponse>` CDR XML.
2. **Modo 2 — REST OAuth2 XML (`EfactIntegrationMode.restXml`)**:
   - Genera el documento UBL 2.1 / 2.0 localmente con `UblXmlBuilder` y lo firma en memoria con RSA-SHA256 (`XadesBesSigner` + certificado X.509).
   - Envía el XML firmado por `multipart/form-data` a `POST /v1/document` y descarga el CDR desde `GET /v1/cdr/{ticket}`, exponiendo además las rutas de descarga `/v1/xml/{ticket}`, `/v1/cdr/{ticket}` y `/v1/pdf/{ticket}`.
3. **Modo 3 — SOAP 1.1 UBL 2.1 (`EfactIntegrationMode.soapUbl`)**:
   - Se conecta directamente al servicio `billService` de EFACT (`sendBill`, `sendSummary`, `getStatus`, `getStatusCdr`) mediante `EfactSoapDelegate`, adjuntando cabecera OASIS WS-Security (`UsernameToken`) y el archivo `.zip` UBL 2.1 codificado en Base64.
4. **Interceptor OAuth2 con Caché (`EfactOAuth2Interceptor`)**:
   - Obtiene automáticamente el token `Bearer` desde `POST /oauth/token` (`grant_type=password` con autenticación `Basic clientId:clientSecret`), lo almacena en caché hasta su expiración (con margen `refreshBuffer`) y lo invalida automáticamente ante respuestas HTTP `401`.

---

## Endpoints Oficiales de EFACT

| Canal / Entorno | Constante en `EfactConfig` | URL Oficial |
| :--- | :--- | :--- |
| **REST OAuth2 (Producción)** | `EfactConfig.productionRestUri` | `https://ose.efact.pe/api-efact-ose` |
| **REST OAuth2 (Pruebas / Homologación)** | `EfactConfig.testRestUri` | `https://ose-gw1.efact.pe:443/api-efact-ose` |
| **SOAP 1.1 `billService` (Producción)** | `EfactConfig.productionSoapUri` | `https://ose.efact.pe/ol-ti-itcpe/billService` |
| **SOAP 1.1 `billService` (Pruebas)** | `EfactConfig.testSoapUri` | `https://ose-gw1.efact.pe/ol-ti-itcpe/billService` |

### Rutas del API REST (`api-efact-ose`)

- `POST /oauth/token`: Obtención de token JWT (`Bearer`).
- `POST /v1/document`: Recepción `multipart/form-data` de `.xml` o `.json` (retorna `{"code": "0", "description": "<TICKET_UUID>"}`).
- `GET /v1/cdr/{ticket}`: Consulta y descarga del CDR XML (`202`/`412 -9998` en proceso $\rightarrow$ `200 OK` aceptado).
- `GET /v1/xml/{ticket}` y `GET /v1/pdf/{ticket}`: Descarga de XML firmado y representación impresa PDF.

---

## Tipos de Comprobantes Soportados

- **Factura Electrónica (`01`)** y **Boleta de Venta (`03`)** (Contado, Crédito con cuotas, Detracciones, Retenciones, Percepciones).
- **Liquidación de Compra Electrónica (`04`)**.
- **Nota de Crédito (`07`)** y **Nota de Débito (`08`)**.
- **Resumen Diario de Boletas (`RC`)** y **Comunicación de Baja (`RA`) / Reversión (`RR`)**.
- **Guía de Remisión Electrónica (`09` Remitente y `31` Transportista)**.
- **Comprobante de Retención (`20`)** y **Percepción (`40`)**.
- **Consulta de Estado y CDR (`queryDocumentStatus`)**.

---

## Opciones de Configuración (`EfactConfig`)

Constructores factory recomendados:

- `EfactConfig.restJson(...)`: Modo PSE con firma en la nube (no requiere certificado local).
- `EfactConfig.restXml(...)`: Modo OSE REST con firma XAdES-BES local (`certificate` obligatorio).
- `EfactConfig.soap(...)`: Modo OSE SOAP 1.1 `billService` con WS-Security (`certificate` obligatorio).

| Propiedad | Tipo | Por Defecto | Descripción |
| :--- | :--- | :--- | :--- |
| `mode` | `EfactIntegrationMode` | *(Requerido)* | `restJson`, `restXml` o `soapUbl`. |
| `baseUri` | `Uri` | `productionRestUri` / `productionSoapUri` | URI base REST o endpoint SOAP. |
| `username` | `String` | *(Requerido)* | RUC del emisor o usuario WS-Security. |
| `password` | `String` | *(Requerido)* | Contraseña REST OAuth2 (hash) o clave SOAP. |
| `oauthClientId` | `String` | `'efact-ose-client'` | Client ID para `/oauth/token`. |
| `oauthClientSecret` | `String` | `'secret'` | Client Secret para `/oauth/token`. |
| `certificate` | `CpeCertificateCredentials?` | `null` | Certificado X.509 + llave privada RSA (requerido en `restXml` y `soapUbl`). |
| `autoPollInRest` | `bool` | `true` | Si es `true`, `sendDocument` espera automáticamente el CDR en `/v1/cdr/{ticket}`. |
| `pollingConfig` | `PollingConfig` | `300ms`, `8` intentos | Configuración de backoff exponencial para polling. |

---

## Instalación

```yaml
dependencies:
  decimal: ^3.2.1
  sunat_cpe_core: ^0.1.2
  sunat_cpe_efact: ^0.1.2
```

---

## Ejemplo de Uso Rápido

```dart
import 'package:sunat_cpe_core/sunat_cpe_core.dart';
import 'package:sunat_cpe_efact/sunat_cpe_efact.dart';

Future<void> main() async {
  // Modo REST JSON (PSE con firma en la nube y OAuth2 automático)
  final provider = EfactProvider(
    config: EfactConfig.restJson(
      baseUri: EfactConfig.testRestUri,
      username: '20100066603',
      password: 'tu-password-hash-efact',
      autoPollInRest: true,
    ),
  );

  // También puedes usar EfactConfig.restXml(...) o EfactConfig.soap(...)
  print('Proveedor inicializado: ${provider.providerId}');
}
```

> Ejecuta el ejemplo completo con los 3 modos de integración y todos los tipos de documentos (100 % offline) con:
> ```bash
> dart run example/main.dart
> ```
