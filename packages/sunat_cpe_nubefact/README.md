# sunat_cpe_nubefact

Nubefact PSE/OSE JSON REST adapter for Peruvian Electronic Invoicing (SUNAT CPE), built on top of `sunat_cpe_core`.

## Features

- Translates official SUNAT Anexo N° 8 catalogs (`01`, `03`, `07`, `08`, `09`, `31`, `PEN`, `USD`, Catálogo 07 IGV affectations) into Nubefact's proprietary integer codes.
- Formats dates automatically to `DD-MM-YYYY` as expected by Nubefact's REST endpoint.
- Injects `Authorization: Token token="..."` authentication header.
- Supports `generar_comprobante`, `generar_anulacion`, `generar_guia`, `generar_retencion`, `generar_percepcion`, `consultar_comprobante`, `consultar_anulacion`, and `consultar_guia`.
- Maps Nubefact error codes (`10`-`11` Auth, `20`-`24` Validation) and SUNAT codes (`0100`-`1999` Exceptions vs `2000`-`3999` Rejections) into `CpeResult<T>`.

## Usage

```dart
import 'package:sunat_cpe_core/sunat_cpe_core.dart';
import 'package:sunat_cpe_nubefact/sunat_cpe_nubefact.dart';

Future<void> main() async {
  final provider = NubefactProvider(
    config: NubefactConfig(
      routeUri: Uri.parse('https://api.nubefact.com/api/v1/tu-ruta-unica'),
      apiToken: 'tu-token-nubefact',
    ),
  );
}
```
