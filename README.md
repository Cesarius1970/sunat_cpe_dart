# sunat_cpe_dart — Monorepo de Facturación Electrónica SUNAT (Perú) en Dart Puro

[![Dart 3](https://img.shields.io/badge/Dart-%3E%3D3.13.5-0175C2?logo=dart)](https://dart.dev)
[![pub package](https://img.shields.io/pub/v/sunat_cpe_dart.svg)](https://pub.dev/packages/sunat_cpe_dart)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](packages/sunat_cpe_core/LICENSE)

Ecosistema modular en **Dart 3 puro** para la emisión, validación aritmética, firma digital XAdES-BES, empaquetado UBL 2.1/2.0 y orquestación inteligente de **Comprobantes de Pago Electrónicos (CPE)** de la [SUNAT (Perú)](https://cpe.sunat.gob.pe/).

Soporta tanto la **emisión directa a SUNAT Operaciones en Línea (SOL)** como los **9 principales Operadores de Servicios Electrónicos (OSE) y Proveedores de Servicios Electrónicos (PSE)** del mercado peruano bajo un único contrato unificado (`OseProvider`).

---

## 📦 Tabla de los 12 Paquetes del Monorepo

| # | Paquete | Rol en la Arquitectura | Protocolos Soportados | pub.dev | Especificación Técnica (`docs/`) |
|---|---------|------------------------|-----------------------|---------|----------------------------------|
| 1 | [`sunat_cpe_core`](packages/sunat_cpe_core) | **Núcleo de Dominio**: Entidades inmutables, catálogos SUNAT, `CpeMathValidator`, generador UBL 2.1, firmador `XadesBesSigner` y `CpeHttpClient` | UBL 2.1 / 2.0, XAdES-BES, ZIP/CDR | [![pub](https://img.shields.io/pub/v/sunat_cpe_core.svg)](https://pub.dev/packages/sunat_cpe_core) | [Arquitectura Core](docs/core/01_architecture_and_patterns.md) · [Entidades](docs/core/02_domain_entities_and_types.md) · [UBL y Firma](docs/core/03_validation_and_ubl_signing.md) |
| 2 | [`sunat_cpe_dart`](packages/sunat_cpe_dart) | **Paquete Principal (Umbrella) y Enrutador (`SunatCpeRouter`)**: Enrutamiento por tipo de CPE, fallback contablemente seguro y fábrica multi-tenant | Todos (SOAP + REST + OAuth2) | [![pub](https://img.shields.io/pub/v/sunat_cpe_dart.svg)](https://pub.dev/packages/sunat_cpe_dart) | [04. Router Principal (`sunat_cpe_dart`)](docs/core/04_main_router_and_orchestration.md) |
| 3 | [`sunat_cpe_direct`](packages/sunat_cpe_direct) | **Emisión Directa SUNAT SOL**: Adaptador oficial hacia los Web Services gratuitos de SUNAT sin intermediarios | SOAP 1.1 (`e-factura`, `otroscpe`) + API REST OAuth2 GRE (`arcGreZip` + `hashZip`) | [![pub](https://img.shields.io/pub/v/sunat_cpe_direct.svg)](https://pub.dev/packages/sunat_cpe_direct) | [10. SUNAT Directo](docs/providers/10_sunat_direct.md) |
| 4 | [`sunat_cpe_nubefact`](packages/sunat_cpe_nubefact) | Adaptador PSE / OSE **Nubefact** | REST JSON (`Authorization: Token`) | [![pub](https://img.shields.io/pub/v/sunat_cpe_nubefact.svg)](https://pub.dev/packages/sunat_cpe_nubefact) | [01. Nubefact](docs/providers/01_nubefact.md) |
| 5 | [`sunat_cpe_efact`](packages/sunat_cpe_efact) | Adaptador OSE / PSE **EFACT** | API REST OAuth2 (Multipart XML / JSON) + SOAP 1.1 `billService` | [![pub](https://img.shields.io/pub/v/sunat_cpe_efact.svg)](https://pub.dev/packages/sunat_cpe_efact) | [02. EFACT](docs/providers/02_efact.md) |
| 6 | [`sunat_cpe_mifact`](packages/sunat_cpe_mifact) | Adaptador PSE / OSE **Mifact** | REST JSON (`SendInvoice`, `lowcommunication`, `GetStatus`) | [![pub](https://img.shields.io/pub/v/sunat_cpe_mifact.svg)](https://pub.dev/packages/sunat_cpe_mifact) | [03. Mifact](docs/providers/03_mifact.md) |
| 7 | [`sunat_cpe_bizlinks`](packages/sunat_cpe_bizlinks) | Adaptador OSE **Bizlinks** | SOAP 1.1 WS-Security (`UsernameToken`) con UBL 2.1 firmado | [![pub](https://img.shields.io/pub/v/sunat_cpe_bizlinks.svg)](https://pub.dev/packages/sunat_cpe_bizlinks) | [04. Bizlinks](docs/providers/04_bizlinks.md) |
| 8 | [`sunat_cpe_digiflow`](packages/sunat_cpe_digiflow) | Adaptador OSE **Digiflow** | SOAP 1.1 WS-Security (`billService`) con UBL 2.1 firmado | [![pub](https://img.shields.io/pub/v/sunat_cpe_digiflow.svg)](https://pub.dev/packages/sunat_cpe_digiflow) | [05. Digiflow](docs/providers/05_digiflow.md) |
| 9 | [`sunat_cpe_sovos`](packages/sunat_cpe_sovos) | Adaptador OSE / PSE **Sovos Paperless** | SOAP 1.1 UBL 2.1 (`BaseUblOseProvider`) | [![pub](https://img.shields.io/pub/v/sunat_cpe_sovos.svg)](https://pub.dev/packages/sunat_cpe_sovos) | [06. Sovos Paperless](docs/providers/06_sovos_paperless.md) |
| 10 | [`sunat_cpe_facturaloperu`](packages/sunat_cpe_facturaloperu) | Adaptador PSE / OSE **FacturaloPeru / Facturador PRO** (Smart / APIPeru) | REST JSON (`Bearer Token`) + Consultas RUC/DNI | [![pub](https://img.shields.io/pub/v/sunat_cpe_facturaloperu.svg)](https://pub.dev/packages/sunat_cpe_facturaloperu) | [07. FacturaloPeru / PRO](docs/providers/07_facturaloperu.md) |
| 11 | [`sunat_cpe_tci`](packages/sunat_cpe_tci) | Adaptador OSE **TCI (Transporte Confidencial de Información)** | SOAP 1.1 WS-Security (`billService`) con UBL 2.1 firmado | [![pub](https://img.shields.io/pub/v/sunat_cpe_tci.svg)](https://pub.dev/packages/sunat_cpe_tci) | [08. TCI](docs/providers/08_tci.md) |
| 12 | [`sunat_cpe_cavali`](packages/sunat_cpe_cavali) | Adaptador OSE **Gosocket / Carvajal** + **Cavali Factrack v2** (Factoring) | SOAP 1.1 OSE + API REST OAuth2 (`x-api-key`) para Facturas Negociables | [![pub](https://img.shields.io/pub/v/sunat_cpe_cavali.svg)](https://pub.dev/packages/sunat_cpe_cavali) | [09. Cavali / Gosocket](docs/providers/09_cavali_gosocket.md) |

---

## ✨ Pilares Arquitectónicos

1. **Precisión Financiera Exacta (`Decimal`)**:
   - Cero uso de `double` en montos, impuestos, tipos de cambio o cantidades en el modelo de dominio. Soporta hasta 10 decimales en valores unitarios y 2 decimales en importes monetarios.
2. **Validación Matemática Pre-Vuelo (`CpeMathValidator`)**:
   - Verifica el cuadre aritmético de cada línea y de los totales del comprobante según las tolerancias oficiales de UBL 2.1 SUNAT antes de realizar cualquier llamada de red, previniendo rechazos tributarios (`2000–3999`).
3. **Motor UBL 2.1 y Firma Digital XAdES-BES 100% en Dart Puro**:
   - Generación de XML UBL 2.1 (`Invoice`, `CreditNote`, `DebitNote`, `DespatchAdvice`) y UBL 2.0 (`SummaryDocuments`, `VoidedDocuments`, `Retention`, `Perception`), canonización C14N y firma RSA-SHA256 (`XadesBesSigner`) sin dependencias nativas ni binarios externos.
4. **Cobertura Total de Comprobantes SUNAT**:
   - **Ventas**: Factura (`01`), Boleta de Venta (`03`), Liquidación de Compra (`04`), Nota de Crédito (`07`), Nota de Débito (`08`), incluyendo ventas al crédito con cuotas (`CreditPaymentTerms`), detracciones SPOT y retenciones de IGV.
   - **Resúmenes y Bajas Asíncronas**: Resumen Diario (`RC`), Comunicación de Baja (`RA`) y Reversión (`RR`).
   - **Traslado de Bienes**: Guía de Remisión Remitente (`09`) y Transportista (`31`).
   - **Agentes**: Comprobante de Retención (`20`) y Comprobante de Percepción (`40`).
5. **Manejo de Errores Funcional y Tipado (`CpeResult<T>`)**:
   - Todas las operaciones retornan `Future<CpeResult<T>>` (`CpeSuccess<T>` o `CpeFailure<T>`) con soporte para `.getOrThrow()` y jerarquía sellada de excepciones (`CpeValidationException`, `SunatRejectionException`, `SunatExceptionError`, `OseTransportException`, `OseAuthException`).
6. **Enrutamiento Híbrido y Fallback Contablemente Seguro (`SunatCpeRouter`)**:
   - Permite enviar distintos tipos de comprobantes a distintos proveedores (p. ej., Facturas `01` por un PSE/OSE y Guías de Remisión `09`/`31` directo a la API REST gratuita de SUNAT) y conmutar a un proveedor de contingencia **únicamente** ante fallos de red o excepciones técnicas (`0100–1999`), bloqueando el reenvío ante rechazos tributarios (`2000–3999`) para evitar duplicación contable.

---

## 🚀 Inicio Rápido

### Opción A: Instalar el paquete principal (`sunat_cpe_dart`)

Ideal para ERPs multi-empresa o sistemas que combinan emisión directa a SUNAT con uno o varios OSE/PSE:

```yaml
dependencies:
  sunat_cpe_dart: ^1.0.2
```

```dart
import 'package:sunat_cpe_dart/sunat_cpe_dart.dart';

Future<void> main() async {
  // Configura un router híbrido:
  // - Facturas (01) y Boletas (03) -> Nubefact (PSE REST JSON)
  // - Guías de Remisión (09/31)   -> SUNAT Directo (API REST OAuth2 gratuita)
  // - Contingencia (Fallback)     -> SUNAT Directo (SOAP billService)
  final router = SunatCpeRouter.fromDescriptors(
    primaryDescriptor: NubefactDescriptor(
      NubefactConfig(
        routeUri: Uri.parse('https://api.nubefact.com/api/v1/tu-ruta'),
        apiToken: 'TU_TOKEN_NUBEFACT',
      ),
    ),
    routeDescriptorsByDocumentType: {
      CpeDocumentType.guiaRemisionRemitente: DirectSunatDescriptor(
        SunatDirectConfig.beta(
          clientId: 'SUNAT_OAUTH_CLIENT_ID',
          clientSecret: 'SUNAT_OAUTH_CLIENT_SECRET',
        ),
      ),
    },
    fallbackDescriptor: DirectSunatDescriptor(SunatDirectConfig.beta()),
    prefixTicketsWithProviderId: true,
  );

  print('Router listo: ${router.providerId}');
}
```

### Opción B: Instalar únicamente un adaptador específico

Si tu aplicación utiliza un único proveedor, puedes instalar solo `sunat_cpe_core` junto con el adaptador deseado (por ejemplo, `sunat_cpe_direct` o `sunat_cpe_facturaloperu`):

```yaml
dependencies:
  sunat_cpe_core: ^0.1.2
  sunat_cpe_direct: ^0.1.2
```

---

## 🛠️ Comandos de Desarrollo en el Workspace

Este repositorio utiliza **Dart Pub Workspaces** (Dart `>=3.13.5`):

```bash
# Resolver dependencias de todos los paquetes del monorepo
dart pub get

# Ejecutar análisis estático en los 12 paquetes
dart analyze

# Ejecutar toda la suite de pruebas unitarias
dart test
```

---

## 📚 Documentación de Arquitectura

Consulta el índice completo de diseño en [`docs/README.md`](docs/README.md).

## 📄 Licencia

Distribuido bajo la licencia MIT. Consulta el archivo `LICENSE` en cada paquete para más detalles.
