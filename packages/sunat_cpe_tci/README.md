# sunat_cpe_tci

Adaptador oficial de **TCI - Transporte Confidencial de Información / Efacturación (OSE / PSE)** para Facturación Electrónica SUNAT (Perú) escrito en **Dart 3 puro**, extendiendo `BaseUblOseProvider` de `sunat_cpe_core`.

Implementa el servicio web **SOAP 1.1 (`billService`)** con autenticación **OASIS WS-Security (`UsernameToken`)**, concatenación automática de credencial `{RUC}{USUARIO_OSE_TCI}` (`formattedWsseUsername`), firma digital **XAdES-BES (RSA-SHA256)** y analizador especializado de errores SOAP (`TciSoapFaultParser`).

---

## Características Principales

- **Formateo Automático de Credenciales WS-Security (`formattedWsseUsername`)**:
  - Construye automáticamente el `<wsse:Username>` bajo el formato exigido por TCI OSE `{RUC}{USUARIO_OSE_TCI}` (idempotente si `oseUser` ya incluye el RUC como prefijo).
- **Cobertura Integral Comercial, Logística y de Agentes (UBL 2.1)**:
  - Comprobantes de venta: Factura (`01`), Boleta de Venta (`03`), Liquidación de Compra (`04`), Nota de Crédito (`07`) y Nota de Débito (`08`).
  - Agentes de Retención y Percepción: Comprobante de Retención (`20`) y Comprobante de Percepción (`40`) mediante `sendRetentionOrPerception`.
  - Traslado de bienes y resúmenes: Guía de Remisión Remitente (`09`), Guía de Remisión Transportista (`31`), Resumen Diario (`RC`) y Comunicación de Baja (`RA`).
- **Analizador Especializado `TciSoapFaultParser`**:
  - Extrae códigos SUNAT de 4 dígitos desde `<faultcode>` con prefijos `soap-env:Client.XXXX` o `soap-env:Server.XXXX` (p. ej. `soap-env:Client.2800` o `soap-env:Client.0151`) y los mapea a `OseAuthException`, `SunatExceptionError` o `SunatRejectionException`.

---

## Endpoints Oficiales de TCI OSE

| Entorno | Enumeración | URL del Servicio SOAP 1.1 (`billService`) |
| :--- | :--- | :--- |
| **Producción** | `TciEnvironment.production` | `https://ose.tci.net.pe/ol-ti-itcpe/billService` |
| **Homologación / Pruebas** | `TciEnvironment.testing` | `https://osetest.tci.net.pe/ol-ti-itcpe/billService` |

---

## Instalación

Agrega `sunat_cpe_core` y `sunat_cpe_tci` en tu `pubspec.yaml`:

```yaml
dependencies:
  sunat_cpe_core: ^0.1.2
  sunat_cpe_tci: ^0.1.2
```

---

## Uso Rápido

```dart
import 'package:sunat_cpe_core/sunat_cpe_core.dart';
import 'package:sunat_cpe_tci/sunat_cpe_tci.dart';

Future<void> main() async {
  final credentials = CpeCertificateCredentials.fromPem(
    privateKeyPem: '<LLAVE_PRIVADA_PEM>',
    certificatePem: '<CERTIFICADO_X509_PEM>',
  );

  final config = TciConfig.forEnvironment(
    environment: TciEnvironment.testing,
    ruc: '20100066603',
    oseUser: 'MODDATOS',
    osePassword: 'moddatos',
    certificate: credentials,
  );

  // formattedWsseUsername => "20100066603MODDATOS"
  final provider = TciProvider(config: config);
  // final result = await provider.sendDocument(invoice);
}
```

---

## Ejemplo Completo Ejecutable

El archivo [`example/main.dart`](example/main.dart) contiene una demostración completa y 100% offline de las capacidades del paquete:
1. Configuración por entorno (`TciConfig.forEnvironment`) y verificación de `formattedWsseUsername`.
2. Emisión de Factura (`01`), Comprobante de Percepción (`40` vía `sendRetentionOrPerception`) y Guía de Remisión Remitente (`09`).
3. Demostración de `TciSoapFaultParser` extrayendo códigos de rechazo (`soap-env:Client.2800`) y excepción (`soap-env:Client.0151`).

Ejecútalo con:

```bash
dart run example/main.dart
```
