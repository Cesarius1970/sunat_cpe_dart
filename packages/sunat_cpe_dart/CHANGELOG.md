## 1.0.2

- Traducción completa de la documentación API (`dartdoc`), `README.md` y metadatos del paquete al español técnico.
- Ampliación de `example/main.dart` demostrando: fábrica declarativa multi-tenant (`SunatProviderFactory` y `SunatCpeRouter.fromDescriptors`), enrutamiento inteligente por tipo de comprobante (`routesByDocumentType`), rastreo automático de origen de tickets con `prefixTicketsWithProviderId: true`, y política de contingencia contablemente segura (`fallbackProvider`).
- Actualización de las restricciones de dependencia de `sunat_cpe_core`, `sunat_cpe_direct` y los 9 adaptadores OSE/PSE a `^0.1.2`.

## 1.0.1

- Adición de ejemplo ejecutable (`example/main.dart`) para alcanzar la puntuación máxima de 160/160 en Pana (`pub.dev`).
- Actualización de las restricciones internas de adaptadores a `^0.1.1` (`xml: ^7.0.0`).

## 1.0.0

- Evolución arquitectónica mayor hacia un monorepo modular en Dart 3 puro:
  - Re-exportación unificada (umbrella) de `sunat_cpe_core`, `sunat_cpe_direct` y los 9 adaptadores OSE/PSE (`nubefact`, `efact`, `mifact`, `bizlinks`, `digiflow`, `sovos`, `facturaloperu`, `tci`, `cavali`).
  - `SunatCpeRouter` implementando `OseProvider` con enrutamiento dinámico por `CpeDocumentType`, contingencia contablemente segura (`OseTransportException` y `SunatExceptionError` únicamente) y rastreo automático del proveedor de origen de tickets.
  - Jerarquía sellada `SunatProviderDescriptor` y `SunatProviderFactory` para inicialización declarativa multi-tenant.

## 0.1.1

- Ajustes de metadatos y compatibilidad inicial en `pub.dev`.

## 0.1.0 - 2026-09-26

- Configuración inicial del paquete conforme a lineamientos de `pub.dev` y Dart team.
- Documentación de autoría, derechos y licencia MIT a nombre de César A Vergara Buenaventura.
- Precisión decimal estricta con `package:decimal`, catálogos oficiales de SUNAT, generador UBL 2.1, firma XML-DSig y transporte híbrido SOAP/REST a SUNAT.
