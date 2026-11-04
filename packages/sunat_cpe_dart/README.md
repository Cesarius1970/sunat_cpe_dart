# sunat_cpe_dart

Umbrella package and intelligent CPE router (`SunatCpeRouter`) for Peruvian Electronic Invoicing (SUNAT CPE) in pure Dart.

Allows applications and multi-tenant ERPs to dynamically route electronic documents between direct SUNAT emission (`sunat_cpe_direct`) and any of the 9 OSE/PSE providers (`Nubefact`, `EFACT`, `Mifact`, `Bizlinks`, `Digiflow`, `Sovos`, `FacturaloPeru`, `TCI`, `Cavali`).

## Features

- **Single Umbrella Import**: Re-exports `sunat_cpe_core`, `sunat_cpe_direct`, and all 9 OSE/PSE adapters.
- **Content-Based Routing (`routesByDocumentType`)**: Route specific `CpeDocumentType` values to dedicated providers (e.g., send Invoices `01` and Boletas `03` via an OSE/PSE while sending Despatch Advices `09`/`31` directly to SUNAT's REST OAuth2 API via `sunat_cpe_direct`).
- **Circuit-Safe Fallback (`fallbackProvider`)**: Automatically fails over to a backup provider **only** when the document has not been registered (`OseTransportException` or `SunatExceptionError` codes `0100–1999`), never on local validation errors or formal SUNAT business rejections (`2000–3999`).
- **Automatic Ticket Origin Tracking**: Remembers which provider issued each asynchronous ticket (`RC`, `RA`, `RR`, `09`, `31`) so `checkTicket` and `pollTicketUntilDone` query the exact originating provider.
- **Declarative Factory (`SunatProviderDescriptor` & `SunatProviderFactory`)**: Instantiate single providers or full `SunatCpeRouter` topologies from typed descriptors.

## Usage

```dart
import 'package:sunat_cpe_dart/sunat_cpe_dart.dart';

void main() async {
  final router = SunatCpeRouter.fromDescriptors(
    primaryDescriptor: NubefactDescriptor(
      NubefactConfig(
        routeUri: Uri.parse('https://api.nubefact.com/api/v1/...'),
        apiToken: 'NUBEFACT_TOKEN',
      ),
    ),
    routeDescriptorsByDocumentType: {
      CpeDocumentType.guiaRemisionRemitente: DirectSunatDescriptor(
        SunatDirectConfig.beta(),
      ),
    },
  );

  // Invoices route to Nubefact; Despatch Advices route to SunatDirectProvider!
}
```
