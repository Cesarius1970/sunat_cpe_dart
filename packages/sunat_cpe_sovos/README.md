# sunat_cpe_sovos

Adaptador oficial de **Sovos / Paperless (OSE / PSE)** para Facturación Electrónica SUNAT (Perú) escrito en **Dart 3 puro**, implementando los contratos de `sunat_cpe_core`.

Soporta tanto el flujo estándar **OSE SOAP 1.1 (`billService`) con firma XAdES-BES local** (`SovosIntegrationMode.oseUblSigned`) como el modo **PSE con firma HSM en la nube** (`SovosIntegrationMode.pseCloudSign`), incluyendo **recuperación idempotente automática de CDR** ante reintentos de red y extensión UBL para **campos adicionales de impresión Paperless**.

---

## Características Principales

- **Recuperación Idempotente Automática de CDR (`autoRecoverCdrOnDuplicate: true`)**:
  - Cuando ocurre un corte de red tras el envío de una Factura o Nota y el cliente reintenta la operación, Sovos OSE responde un SOAP Fault con código `1033` o `2017` (*El comprobante ya fue registrado previamente*).
  - `SovosProvider` intercepta automáticamente dicha excepción, invoca `queryDocumentStatus` (`urn:getStatusCdr`), recupera la Constancia de Recepción (CDR) original, reconstruye la cadena QR SUNAT y devuelve `CpeSuccess` con `providerRawMetadata['recoveredFromDuplicate'] == true`.
- **Inyección de Campos de Impresión Paperless (`SovosUblExtensionBuilder`)**:
  - Permite agregar parámetros personalizados (`customPrintFields`, como `VENDEDOR`, `SUCURSAL`, `CAJERO`) en un bloque `<ext:UBLExtension>` dedicado (`<SovosCustomPrintFields>`) dentro de `<ext:UBLExtensions>` antes de aplicar la firma digital XAdES-BES, garantizando la integridad del hash criptográfico.
- **Modos de Integración (`SovosIntegrationMode`)**:
  - `SovosIntegrationMode.oseUblSigned`: Emisión UBL 2.1 firmada localmente con certificado del contribuyente.
  - `SovosIntegrationMode.pseCloudSign`: Integración PSE con firma gestionada en HSM de Sovos.

---

## Endpoints Oficiales de Sovos / Paperless OSE

| Entorno | Propiedad Estática | URL del Servicio SOAP 1.1 (`billService`) |
| :--- | :--- | :--- |
| **Producción** | `SovosConfig.productionEndpoint` | `https://ose.sovos.com.pe/ol-ti-itcpe/billService` |
| **Certificación / QA** | `SovosConfig.certificationEndpoint` | `https://ose-cert.sovos.com.pe/ol-ti-itcpe/billService` |

---

## Instalación

Agrega `sunat_cpe_core` y `sunat_cpe_sovos` en tu archivo `pubspec.yaml`:

```yaml
dependencies:
  sunat_cpe_core: ^0.1.2
  sunat_cpe_sovos: ^0.1.2
```

---

## Uso Rápido

```dart
import 'package:sunat_cpe_core/sunat_cpe_core.dart';
import 'package:sunat_cpe_sovos/sunat_cpe_sovos.dart';

Future<void> main() async {
  final credentials = CpeCertificateCredentials.fromPem(
    privateKeyPem: '<LLAVE_PRIVADA_PEM>',
    certificatePem: '<CERTIFICADO_X509_PEM>',
  );

  final config = SovosConfig(
    endpointUri: SovosConfig.certificationEndpoint,
    username: '20100066603MODDATOS',
    password: 'moddatos',
    certificate: credentials,
    mode: SovosIntegrationMode.oseUblSigned,
    autoRecoverCdrOnDuplicate: true,
    customPrintFields: const {
      'VENDEDOR': 'JUAN PEREZ',
      'SUCURSAL': 'LIMA CENTRO',
    },
  );

  final provider = SovosProvider(config: config);
  // final result = await provider.sendDocument(invoice);
}
```

---

## Ejemplo Completo Ejecutable

El archivo [`example/main.dart`](example/main.dart) incluye una demostración 100% offline que ejercita todas las capacidades del paquete:
1. Configuración `SovosConfig` con `customPrintFields` e inyección en `<ext:UBLExtensions>` mediante `SovosUblExtensionBuilder`.
2. Emisión de Factura (`01`) en modos `SovosIntegrationMode.oseUblSigned` y `SovosIntegrationMode.pseCloudSign`.
3. Demostración de **Recuperación Idempotente Automática de CDR** cuando `sendBill` devuelve Fault `2017` y `SovosProvider` recupera el CDR por `getStatusCdr` con `providerRawMetadata['recoveredFromDuplicate'] == true`.
4. Emisión de Resumen Diario (`RC`) y Comunicación de Baja (`RA`).

Ejecútalo con:

```bash
dart run example/main.dart
```
