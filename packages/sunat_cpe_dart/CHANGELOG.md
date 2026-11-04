## 1.0.0

- Major architectural evolution into a modular pure-Dart monorepo:
  - Umbrella re-export of `sunat_cpe_core`, `sunat_cpe_direct`, and all 9 OSE/PSE adapters (`nubefact`, `efact`, `mifact`, `bizlinks`, `digiflow`, `sovos`, `facturaloperu`, `tci`, `cavali`).
  - `SunatCpeRouter` implementing `OseProvider` with dynamic routing by `CpeDocumentType`, circuit-safe fallback (`OseTransportException` & `SunatExceptionError` only), and automatic ticket origin tracking.
  - `SunatProviderDescriptor` sealed hierarchy and `SunatProviderFactory` for declarative multi-tenant initialization.

## 0.1.1

- Ajustes de metadatos y compatibilidad inicial en `pub.dev`.

## 0.1.0 - 2026-09-26

- Configuración inicial del paquete conforme a lineamientos de `pub.dev` y Dart team.
- Documentación de autoría, derechos y licencia MIT a nombre de César A Vergara Buenaventura.
- Precisión decimal estricta con `package:decimal`, catálogos oficiales de SUNAT, generador UBL 2.1, firma XML-DSig y transporte híbrido SOAP/REST a SUNAT.
