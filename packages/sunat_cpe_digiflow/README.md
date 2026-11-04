# sunat_cpe_digiflow

Adaptador oficial de **Digiflow (OSE)** para Facturación Electrónica SUNAT (Perú) escrito en **Dart 3 puro**, extendiendo `BaseUblOseProvider` de `sunat_cpe_core`.

Implementa el servicio web **SOAP 1.1 (`billService`)** de Digiflow con cumplimiento estricto de la cabecera `<wsse:Security soapenv:mustUnderstand="1">`, cabeceras HTTP `SOAPAction` obligatorias, firma digital **XAdES-BES (RSA-SHA256)** y soporte dual para Guías de Remisión Electrónicas (`DigiflowDespatchMode`).

---

## Características Principales

- **Sobre SOAP 1.1 Estricto (`DigiflowSoapEnvelope`)**:
  - Incluye el atributo obligatorio `soapenv:mustUnderstand="1"` en `<wsse:Security>` y `Type="...#PasswordText"` en `<wsse:Password>`.
  - Envía siempre la cabecera HTTP `SOAPAction` entrecomillada (`"urn:sendBill"`, `"urn:sendSummary"`, `"urn:getStatus"`, `"urn:getStatusCdr"`).
- **Modos Duales para Guías de Remisión (`DigiflowDespatchMode`)**:
  - `DigiflowDespatchMode.syncSendBill`: Envía la GRE (`09` / `31`) por `urn:sendBill`, recibe el CDR inmediatamente en `<applicationResponse>`, genera un ticket sintético (`DIGIFLOW-GRE-{RUC}-{TIPO}-{SERIE}-{NUM}`) y lo resuelve al instante desde caché en `checkTicket` / `pollTicketUntilDone` sin realizar llamadas de red adicionales.
  - `DigiflowDespatchMode.asyncTicket`: Envía la GRE por flujo asíncrono y consulta el ticket mediante `urn:getStatus`.
- **Cobertura Completa de Comprobantes UBL 2.1**:
  - Facturas (`01`), Boletas (`03`), Liquidaciones de Compra (`04`), Notas de Crédito (`07`), Notas de Débito (`08`).
  - Comprobantes de Retención (`20`) y Percepción (`40`) vía `sendRetentionOrPerception`.
  - Resumen Diario (`RC`), Comunicación de Baja (`RA`) y Reversiones (`RR`).
  - Consulta histórica de estado y CDR (`queryDocumentStatus` -> `urn:getStatusCdr`).

---

## Endpoints Oficiales de Digiflow OSE

| Entorno | Enumeración | URL del Servicio SOAP 1.1 (`billService`) |
| :--- | :--- | :--- |
| **Producción** | `DigiflowEnvironment.production` | `https://ose.digiflow.pe/ol-ti-itcpe/billService` |
| **Homologación / Pruebas** | `DigiflowEnvironment.testing` | `https://osetest.digiflow.pe/ol-ti-itcpe/billService` |

---

## Instalación

Agrega `sunat_cpe_core` y `sunat_cpe_digiflow` en tu `pubspec.yaml`:

```yaml
dependencies:
  sunat_cpe_core: ^0.1.2
  sunat_cpe_digiflow: ^0.1.2
```

---

## Uso Rápido

```dart
import 'package:sunat_cpe_core/sunat_cpe_core.dart';
import 'package:sunat_cpe_digiflow/sunat_cpe_digiflow.dart';

Future<void> main() async {
  final credentials = CpeCertificateCredentials.fromPem(
    privateKeyPem: '<LLAVE_PRIVADA_PEM>',
    certificatePem: '<CERTIFICADO_X509_PEM>',
  );

  final config = DigiflowConfig.forEnvironment(
    environment: DigiflowEnvironment.testing,
    username: '20100066603MODDATOS',
    password: 'moddatos',
    certificate: credentials,
    despatchMode: DigiflowDespatchMode.syncSendBill,
  );

  final provider = DigiflowProvider(config: config);
  // final result = await provider.sendDocument(invoice);
}
```

---

## Ejemplo Completo Ejecutable

El archivo [`example/main.dart`](example/main.dart) contiene una demostración completa y 100% offline de todas las capacidades del paquete:
1. Construcción de sobre SOAP 1.1 con `DigiflowSoapEnvelope` (`mustUnderstand="1"` y `SOAPAction`).
2. Emisión de Factura (`01`) y Comprobante de Retención (`20` con `sendRetentionOrPerception`).
3. Modo 1 de Guía de Remisión (`DigiflowDespatchMode.syncSendBill`) con resolución instantánea desde caché.
4. Modo 2 de Guía de Remisión (`DigiflowDespatchMode.asyncTicket`) con consulta `getStatus`.
5. Recuperación histórica de CDR con `queryDocumentStatus` (`getStatusCdr`).

Ejecútalo con:

```bash
dart run example/main.dart
```
