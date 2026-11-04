# sunat_cpe_cavali

[![pub package](https://img.shields.io/pub/v/sunat_cpe_cavali.svg)](https://pub.dev/packages/sunat_cpe_cavali)

Adaptador oficial de **Cavali / Gosocket / Carvajal (OSE + Factoring Factrack v2)** para facturación electrónica SUNAT (Perú) y Facturas Negociables en Dart 3 puro, implementando `OseProvider` de `sunat_cpe_core` y `CavaliFactoringCapability`.

## Características Principales

- **Validación OSE (Gosocket / Carvajal SOAP 1.1 `billService`)**:
  - Generación automática de XML UBL 2.1, firma digital local XAdES-BES, compresión ZIP y envío mediante WS-Security (`UsernameToken`).
  - Soporte completo para Facturas Comerciales al Crédito con cuotas (`CreditPaymentTerms`), Boletas, Notas de Crédito/Débito, Resumen Diario (`RC`), Comunicación de Baja (`RA`) y consulta de CDR (`queryDocumentStatus`).
- **Factoring Electrónico en Cavali Factrack v2 (`CavaliFactoringCapability`)**:
  - **Registro de Lotes de Facturas Negociables (`registerInvoicesForFactoring`)**: Codifica en Base64 los XML UBL 2.1 firmados y aceptados y los envía a `POST /invoice/xml`, devolviendo el `idProceso` de Cavali.
  - **Seguimiento de Conformidad y Anotación en Cuenta (`checkConformityStatus`)**: Consulta `POST /invoice/status` para verificar la ventana legal de 8 días calendario (DU 013-2020): `pending`, `expressConformity` (Conformidad Expresa), `presumedConformity` (Conformidad Presunta) o `disconformity` (Disconformidad), así como el indicador `isRegisteredInCavali`.
- **Autenticación OAuth2 + `x-api-key` (`CavaliOAuth2Interceptor`)**:
  - Adquisición y almacenamiento en caché de tokens `Bearer` mediante flujo `client_credentials` e inyección automática de la cabecera `x-api-key`.

## Instalación

```yaml
dependencies:
  sunat_cpe_core: ^0.1.2
  sunat_cpe_cavali: ^0.1.2
```

## Ejemplo Rápido

```dart
import 'package:sunat_cpe_cavali/sunat_cpe_cavali.dart';
import 'package:sunat_cpe_core/sunat_cpe_core.dart';

Future<void> main() async {
  print('OSE Gosocket Testing: ${CavaliConfig.testingOseSoapUri}');
  print('Factrack v2 Testing:  ${CavaliConfig.testingFactrackUri}');
}
```

Consulta el archivo [`example/main.dart`](example/main.dart) para ver un ejemplo completo y ejecutable offline que demuestra tanto la validación OSE SOAP 1.1 en Gosocket como el registro y seguimiento de Factoring en Cavali Factrack v2.
