# sunat_cpe_bizlinks

Adaptador oficial de **Bizlinks (OSE / PSE)** para Facturación Electrónica SUNAT (Perú) escrito en **Dart 3 puro**, extendiendo `BaseUblOseProvider` de `sunat_cpe_core`.

Implementa el servicio web **SOAP 1.1 (`billService`)** con autenticación **OASIS WS-Security (`UsernameToken`)**, generación automática de XML **UBL 2.1**, firma digital **XAdES-BES (RSA-SHA256)** en memoria, empaquetado `.zip` normativo y un analizador especializado de errores SOAP (`BizlinksSoapFaultParser`).

---

## Características Principales

- **Integración SOAP 1.1 `billService` Completa**:
  - `sendBill`: Emisión síncrona de Facturas (`01`), Boletas de Venta (`03`), Liquidaciones de Compra (`04`), Notas de Crédito (`07`), Notas de Débito (`08`), Comprobantes de Retención (`20`) y Percepción (`40`).
  - `sendSummary`: Envío asíncrono mediante Ticket para Resumen Diario de Boletas (`RC`), Comunicación de Baja (`RA`), Resumen de Reversiones (`RR`) y Guías de Remisión (`09` / `31`).
  - `getStatus`: Consulta de estado de tickets asíncronos (`98` en proceso, `0` aceptado con CDR, `99` rechazado) y sondeo automático con backoff exponencial (`pollTicketUntilDone`).
  - `getStatusCdr`: Recuperación histórica de estado y Constancia de Recepción (CDR) por RUC, tipo, serie y correlativo (`queryDocumentStatus`).
- **Seguridad OASIS WS-Security**: Cabecera `<wsse:Security>` con `<wsse:UsernameToken>` y `<wsse:Password Type="...#PasswordText">`.
- **Analizador Especializado `BizlinksSoapFaultParser`**:
  - Detecta la convención particular de Bizlinks OSE donde `<faultstring>` contiene directamente el código numérico SUNAT (ej. `2017`) y la descripción detallada viaja dentro de `<detail><message>`.
  - Clasifica automáticamente los códigos en errores de autenticación (`0100–0109` -> `OseAuthException`), excepciones técnicas reintentables (`0100–1999` -> `SunatExceptionError`) y rechazos definitivos de negocio (`2000–3999` -> `SunatRejectionException`).

---

## Endpoints Oficiales de Bizlinks OSE

| Entorno | Enumeración | URL del Servicio SOAP 1.1 (`billService`) |
| :--- | :--- | :--- |
| **Producción** | `BizlinksEnvironment.production` | `https://ose.bizlinks.com.pe/ol-ti-itcpe/billService` |
| **Homologación / Pruebas** | `BizlinksEnvironment.testing` | `https://osetesting.bizlinks.com.pe/ol-ti-itcpe/billService` |

---

## Instalación

Agrega `sunat_cpe_core` y `sunat_cpe_bizlinks` en tu archivo `pubspec.yaml`:

```yaml
dependencies:
  sunat_cpe_core: ^0.1.2
  sunat_cpe_bizlinks: ^0.1.2
```

---

## Uso Rápido

```dart
import 'package:sunat_cpe_bizlinks/sunat_cpe_bizlinks.dart';
import 'package:sunat_cpe_core/sunat_cpe_core.dart';

Future<void> main() async {
  // 1. Cargar certificado digital X.509 y llave privada RSA (PEM)
  final credentials = CpeCertificateCredentials.fromPem(
    privateKeyPem: '<LLAVE_PRIVADA_PEM>',
    certificatePem: '<CERTIFICADO_X509_PEM>',
  );

  // 2. Configurar Bizlinks OSE por entorno (testing o production)
  final config = BizlinksConfig.forEnvironment(
    environment: BizlinksEnvironment.testing,
    username: '20100066603MODDATOS',
    password: 'moddatos',
    certificate: credentials,
  );

  final provider = BizlinksProvider(config: config);

  // 3. Emitir Factura Electrónica (01) -> SOAP sendBill
  // final result = await provider.sendDocument(invoice);
}
```

---

## Ejemplo Completo Ejecutable

El paquete incluye un ejemplo autocontenido y 100% offline en [`example/main.dart`](example/main.dart) que simula el transporte HTTP de Bizlinks OSE y demuestra:
1. Configuración por entorno (`BizlinksConfig.forEnvironment`).
2. Emisión de Factura Electrónica (`01`) con firma XAdES-BES real y lectura de CDR + QR SUNAT.
3. Emisión de Resumen Diario (`RC`) y Comunicación de Baja (`RA`) con `pollTicketUntilDone`.
4. Emisión de Guía de Remisión Remitente (`09`).
5. Diferenciación entre `SunatExceptionError` (`Client.0151`) y `SunatRejectionException` (`faultstring: 2017` + `<detail><message>`) con `BizlinksSoapFaultParser`.

Ejecútalo con:

```bash
dart run example/main.dart
```
