# sunat_cpe_facturaloperu

[![pub package](https://img.shields.io/pub/v/sunat_cpe_facturaloperu.svg)](https://pub.dev/packages/sunat_cpe_facturaloperu)

Adaptador oficial de **FacturaloPeru / Facturador PRO (PRO X, PRO 4, PRO 5, Smart, APIPeru)** para facturación electrónica SUNAT (Perú) en Dart 3 puro, implementando los contratos de `sunat_cpe_core`.

## Características Principales

- **Endpoints Semánticos RESTful**:
  - `/api/documents` y `/api/documents/status`: Emisión síncrona y consulta de estado para Facturas (`01`), Boletas (`03`), Notas de Crédito (`07`) y Notas de Débito (`08`).
  - `/api/summaries` y `/api/summaries/status`: Envío asíncrono de Resumen Diario (`RC`) y consulta de ticket.
  - `/api/voided` y `/api/voided/status`: Envío asíncrono de Comunicación de Baja (`RA`) y consulta de ticket.
  - `/api/dispatches` y `/api/dispatches/status`: Envío asíncrono de Guías de Remisión (`09`/`31`) y consulta de ticket.
  - `/api/retentions`: Emisión de Comprobantes de Retención (`20`) y Percepción (`40`).
- **Correlativo Autoincremental en Servidor (`allowServerAutoIncrement`)**: Permite enviar `"numero_documento": "#"` cuando el correlativo del comprobante es `0`, delegando la numeración al servidor Facturador PRO.
- **Consulta de Padrón SUNAT y RENIEC (`lookupTaxpayer`)**: Consulta auxiliar de RUC (`/api/service/ruc/{ruc}`) y DNI (`/api/service/dni/{dni}`) devolviendo `FacturaloTaxpayerInfo` (razón social, estado, condición, dirección y ubigeo).
- **Mapeo de Estados (`state_type_id` `01..13`)**: Traduce las respuestas JSON anidadas (`data.state_type_id`, `cdr_response`, `links.xml/pdf/cdr`) a `CpeResult<CpeEmissionResponse>`.

## Instalación

```yaml
dependencies:
  sunat_cpe_core: ^0.1.2
  sunat_cpe_facturaloperu: ^0.1.2
```

## Ejemplo Rápido

```dart
import 'package:sunat_cpe_facturaloperu/sunat_cpe_facturaloperu.dart';

Future<void> main() async {
  final provider = FacturaloProvider(
    config: FacturaloConfig(
      baseUri: Uri.parse('https://tu-instancia.facturaloperu.com'),
      apiToken: 'TU_BEARER_TOKEN',
      allowServerAutoIncrement: true,
    ),
  );

  // Consulta de RUC en el padrón SUNAT
  final rucInfo = await provider.lookupTaxpayer(
    documentNumber: '20100066603',
    isRuc: true,
  );
  print(rucInfo);
}
```

Consulta el archivo [`example/main.dart`](example/main.dart) para ver un ejemplo completo y ejecutable offline con todos los flujos soportados.
