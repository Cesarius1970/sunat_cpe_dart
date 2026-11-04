## 0.1.0

- Initial release of `sunat_cpe_main`:
  - Umbrella re-export of `sunat_cpe_core`, `sunat_cpe_direct`, and all 9 OSE/PSE adapters (`nubefact`, `efact`, `mifact`, `bizlinks`, `digiflow`, `sovos`, `facturaloperu`, `tci`, `cavali`).
  - `SunatCpeRouter` implementing `OseProvider` with dynamic routing by `CpeDocumentType`, circuit-safe fallback (`OseTransportException` & `SunatExceptionError` only), and ticket origin tracking (`TicketOriginRegistry`).
  - `SunatProviderDescriptor` sealed hierarchy and `SunatProviderFactory` for declarative multi-tenant initialization.
