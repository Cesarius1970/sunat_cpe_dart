# sunat_cpe_direct

[![pub package](https://img.shields.io/pub/v/sunat_cpe_direct.svg)](https://pub.dev/packages/sunat_cpe_direct)

Adaptador oficial de **Emisión Directa a SUNAT Operaciones en Línea (SOL)** para facturación electrónica SUNAT (Perú) en Dart 3 puro, implementando los contratos de `sunat_cpe_core`.

## Características Principales

- **Enrutamiento Multiprotocolo Inteligente hacia SUNAT**:
  - **Canal 1 — SOAP `e-factura` (`soapInvoiceUri`)**: Emisión directa de Facturas (`01`), Boletas (`03`), Liquidaciones de Compra (`04`), Notas de Crédito/Débito (`07`/`08`), Resumen Diario (`RC`) y Comunicación de Baja (`RA`).
  - **Canal 2 — SOAP `otroscpe` (`soapOtrosCpeUri`)**: Emisión directa de Comprobantes de Retención (`20`), Percepción (`40`) y Resumen de Reversiones (`RR`).
  - **Canal 3 — API REST OAuth2 GRE (`api-cpe.sunat.gob.pe` + `api-seguridad.sunat.gob.pe`)**: Emisión de Guías de Remisión Remitente (`09`) y Transportista (`31`) generando automáticamente `arcGreZip` (Base64 del archivo `.zip`) y `hashZip` (resumen SHA-256 hexadecimal de 64 caracteres del binario `.zip`).
- **Registro Interno de Origen de Tickets (`_ticketChannelRegistry`)**:
  - Cuando se emite un Resumen Diario (`RC`), una Baja (`RA`), una Reversión (`RR`) o una Guía de Remisión (`09`/`31`), `SunatDirectProvider` recuerda en qué canal se originó el ticket para que `checkTicket` y `pollTicketUntilDone` consulten automáticamente el endpoint SOAP o REST correspondiente.
- **Seguridad Estricta de Certificado Digital (`beta` vs `homologacion` / `produccion`)**:
  - Incluye `SunatDirectMockCertificateFactory` para pruebas inmediatas en `SunatDirectEnvironment.beta` (`20100066603` / `MODDATOS`), y bloquea mediante `ArgumentError` cualquier intento de usar certificados simulados en `homologacion` o `produccion`.

## Instalación

```yaml
dependencies:
  sunat_cpe_core: ^0.1.2
  sunat_cpe_direct: ^0.1.2
```

## Ejemplo Rápido

```dart
import 'package:sunat_cpe_direct/sunat_cpe_direct.dart';

void main() {
  final provider = SunatDirectProvider(
    config: SunatDirectConfig.beta(
      clientId: 'SUNAT_OAUTH_CLIENT_ID',
      clientSecret: 'SUNAT_OAUTH_CLIENT_SECRET',
    ),
  );

  print('Proveedor inicializado: ${provider.providerId} (${provider.config.environment.name})');
}
```

Consulta el archivo [`example/main.dart`](example/main.dart) para ver un ejemplo completo y ejecutable offline que ejercita los 3 canales de SUNAT SOL (`e-factura`, `otroscpe` y `REST GRE`).
