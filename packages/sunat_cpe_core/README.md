# sunat_cpe_core

Core domain entities, official SUNAT Anexo N° 8 catalogs, strict passthrough mathematical validator, UBL 2.1/2.0 XML builder, pure-Dart XAdES-BES (RSA-SHA256) digital signer, and unified OSE/PSE provider contracts for Peruvian Electronic Invoicing (CPE).

## Features

- **100% Pure Dart 3**: Sealed domain hierarchies (`CpeDocument`, `SalesCpeDocument`, `CpeResult<T>`) with zero `build_runner` codegen overhead.
- **Exact Financial Precision**: Uses `Decimal` for all monetary totals, unit values, quantities, and tax rates.
- **Strict Passthrough Validation (`CpeMathValidator`)**: Verifies line-level and header-level UBL 2.1 equations, free-item rules, and RS 000193-2020 credit installment net pending amounts before network calls.
- **Native UBL 2.1 & XAdES-BES Engine**: Generates UBL 2.1/2.0 XML, signs with RSA-SHA256 C14N (`XadesBesSigner`), packages `.zip` payloads, and parses `<ApplicationResponse>` CDR archives (`CpeZipCodec`).
- **Unified `OseProvider` Contract**: Supports synchronous emission, asynchronous Ticket polling with exponential backoff (`pollTicketUntilDone`), and status queries across OSE and PSE adapters.

## Usage

```dart
import 'package:sunat_cpe_core/sunat_cpe_core.dart';

void main() {
  final validator = CpeMathValidator();
  // Validate any CpeDocument before sending to an OSE/PSE provider
}
```
