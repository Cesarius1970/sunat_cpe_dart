# sunat_cpe_dart

[![pub package](https://img.shields.io/pub/v/sunat_cpe_dart.svg)](https://pub.dev/packages/sunat_cpe_dart)

Paquete principal (umbrella) y enrutador inteligente de CPE (`SunatCpeRouter`) para **Facturación Electrónica SUNAT (Perú)** en Dart 3 puro.

Permite a aplicaciones y sistemas ERP multi-tenant enrutar dinámicamente comprobantes electrónicos entre la emisión directa a SUNAT (`sunat_cpe_direct`) y cualquiera de los 9 proveedores OSE/PSE (`Nubefact`, `EFACT`, `Mifact`, `Bizlinks`, `Digiflow`, `Sovos`, `FacturaloPeru`, `TCI`, `Cavali`).

## Características Principales

- **Importación Unificada (Umbrella Package)**: Re-exporta `sunat_cpe_core`, `sunat_cpe_direct` y los 9 adaptadores OSE/PSE en una sola dependencia.
- **Enrutamiento por Tipo de Comprobante (`routesByDocumentType`)**: Dirige valores específicos de `CpeDocumentType` a proveedores dedicados (p. ej., emitir Facturas `01` y Boletas `03` mediante un PSE/OSE mientras se envían las Guías de Remisión `09`/`31` directamente a la API REST gratuita de SUNAT con `sunat_cpe_direct`).
- **Contingencia Contablemente Segura (`fallbackProvider`)**: Conmuta automáticamente a un proveedor de respaldo **únicamente** cuando se garantiza que el documento no fue registrado (`OseTransportException` o `SunatExceptionError` códigos `0100–1999`), bloqueando la conmutación ante errores de validación local (`CpeValidationException`) o rechazos tributarios de SUNAT (`SunatRejectionException`, códigos `2000–3999`) para evitar duplicidad contable.
- **Rastreo Automático del Origen de Tickets**: Recuerda qué proveedor emitió cada ticket asíncrono (`RC`, `RA`, `RR`, `09`, `31`), con soporte opcional para prefijos `{providerId}:{ticket}` (`prefixTicketsWithProviderId: true`), de modo que `checkTicket` y `pollTicketUntilDone` consulten siempre al proveedor exacto que originó el ticket.
- **Fábrica Declarativa Multi-Tenant (`SunatProviderDescriptor` y `SunatProviderFactory`)**: Instancia proveedores individuales o topologías completas de `SunatCpeRouter` a partir de descriptores tipados inmutables.

## Instalación

```yaml
dependencies:
  sunat_cpe_dart: ^1.0.2
```

## Uso Básico

```dart
import 'package:sunat_cpe_dart/sunat_cpe_dart.dart';

void main() {
  final router = SunatCpeRouter.fromDescriptors(
    primaryDescriptor: NubefactDescriptor(
      NubefactConfig(
        routeUri: Uri.parse('https://api.nubefact.com/api/v1/demo'),
        apiToken: 'NUBEFACT_TOKEN',
      ),
    ),
    routeDescriptorsByDocumentType: {
      CpeDocumentType.guiaRemisionRemitente: DirectSunatDescriptor(
        SunatDirectConfig.beta(
          clientId: 'SUNAT_CLIENT_ID',
          clientSecret: 'SUNAT_CLIENT_SECRET',
        ),
      ),
    },
    fallbackDescriptor: DirectSunatDescriptor(SunatDirectConfig.beta()),
    prefixTicketsWithProviderId: true,
  );

  // Las Facturas (01) van a Nubefact; las Guías (09) van directo a SUNAT REST GRE.
  print('Router inicializado: ${router.providerId}');
}
```

Consulta el archivo [`example/main.dart`](example/main.dart) para ver una demostración completa y ejecutable offline de los 4 escenarios arquitectónicos del enrutador.
