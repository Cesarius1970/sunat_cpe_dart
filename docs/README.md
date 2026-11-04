---
title: "Índice General: Arquitectura y Proveedores OSE / PSE (SUNAT CPE)"
aliases:
  - "SUNAT CPE MOC"
  - "Índice Principal"
  - "README"
tags:
  - sunat
  - cpe
  - ubl21
  - dart
  - arquitectura
  - moc
type: moc
status: active
updated: 2026-11-04
---

# Arquitectura y Análisis de Proveedores OSE / PSE (SUNAT CPE)

> [!NOTE] Map of Content (MOC) — Navegación Rápida
> - **Núcleo (`sunat_cpe_core`)**: [[core/01_architecture_and_patterns|01. Arquitectura y Patrones]] · [[core/02_domain_entities_and_types|02. Entidades y Catálogos]] · [[core/03_validation_and_ubl_signing|03. Validación, UBL 2.1 y Firma XAdES-BES]]
> - **Proveedores JSON REST (PSE/OSE)**: [[providers/01_nubefact|01. Nubefact]] · [[providers/03_mifact|03. Mifact]] · [[providers/07_facturaloperu|07. FacturaloPeru / PRO]]
> - **Proveedores Híbridos (REST + SOAP UBL)**: [[providers/02_efact|02. EFACT]] · [[providers/06_sovos_paperless|06. Sovos / Paperless]] · [[providers/09_cavali_gosocket|09. Cavali / Gosocket]]
> - **Proveedores SOAP UBL 2.1 Puros (OSE)**: [[providers/04_bizlinks|04. Bizlinks]] · [[providers/05_digiflow|05. Digiflow]] · [[providers/08_tci|08. TCI / Efacturación]]
> - **Referencias Externas**: [Portal Oficial SUNAT CPE](https://cpe.sunat.gob.pe/) · [Guías y Manuales Técnicos SUNAT](https://cpe.sunat.gob.pe/node/88) · [Monorepo GitHub (`sunat_cpe`)](https://github.com/Cesarius1970/sunat_cpe)

Suite de especificación técnica para el monorepo `sunat_cpe` en **Dart 3 puro**. Define el paquete núcleo (`sunat_cpe_core`) y los 9 paquetes adaptadores para los principales Operadores de Servicios Electrónicos (OSE) y Proveedores de Servicios Electrónicos (PSE) registrados en [SUNAT (Perú)](https://cpe.sunat.gob.pe/).

---

## 1. Decisiones Arquitectónicas Clave (ADR Resumen)

1. **Modo de Operación Híbrido Completo**:
   - **Vía UBL Nativa (SOAP / REST XML)**: [[core/03_validation_and_ubl_signing#2. Generador XML UBL 2.1 / 2.0 (`UblXmlBuilder`)|`sunat_cpe_core`]] incluye generador XML UBL 2.1, empaquetador ZIP (`archive`), [[core/03_validation_and_ubl_signing#3. Firmador Digital XAdES-BES en Dart Puro (`XadesBesSigner`)|firmador digital XAdES-BES]] en Dart puro (`pointycastle` / `xml`) y lector de CDR. Usado por OSEs puros ([[providers/04_bizlinks|Bizlinks]], [[providers/05_digiflow|Digiflow]], [[providers/08_tci|TCI]], [[providers/06_sovos_paperless|Sovos]], [[providers/09_cavali_gosocket|Cavali/Gosocket]], [[providers/02_efact|EFACT XML]]).
   - **Vía Delegada (JSON REST DTO)**: Los paquetes adaptadores transforman las [[core/02_domain_entities_and_types|entidades del Core]] a payloads JSON propietarios cuando el PSE/OSE ofrece API simplificada ([[providers/01_nubefact|Nubefact]], [[providers/07_facturaloperu|FacturaloPeru]], [[providers/03_mifact|Mifact]], [[providers/02_efact|EFACT JSON]]).
2. **Cálculo de Impuestos Passthrough Estricto con Validación Matemática**:
   - El ERP/consumidor calcula y envía todos los importes (`valorUnitario`, `precioUnitario`, `igv`, `isc`, `icbper`, `totalImpuestos`, etc.).
   - El Core ejecuta un [[core/03_validation_and_ubl_signing#1. Motor de Validación Matemática (`CpeMathValidator`)|`CpeMathValidator`]] antes del envío para verificar cuadre aritmético según tolerancias UBL 2.1 SUNAT (±1.00 por línea o reglas de redondeo Catálogo 07) evitando rechazos por error `2000-3999`.
3. **Precisión Numérica Exacta**:
   - Prohibido el uso de `double` para montos, tasas, tipos de cambio o cantidades. Todo campo numérico financiero usa [[core/02_domain_entities_and_types#1. Reglas de Tipos de Datos y Precisión|`Decimal`]] (`package:decimal`), soportando hasta 10 decimales en valores unitarios y 2 decimales en totales monetarios.
4. **Cobertura Total de Comprobantes (CPE)**:
   - Ventas: Factura (`01`), Boleta (`03`), Liquidación de Compra (`04`), Nota de Crédito (`07`), Nota de Débito (`08`) — ver [[core/02_domain_entities_and_types#3. Jerarquía de Entidades de Dominio (`CpeDocument`)|Jerarquía `CpeDocument`]].
   - Resúmenes y Bajas: Resumen Diario (`RC`), Comunicación de Baja (`RA`), Reversión (`RR`).
   - Traslado: Guía de Remisión Remitente (`09`) y Transportista (`31`) (Flujo OSE / API REST GRE).
   - Agentes: Comprobante de Retención (`20`) y Percepción (`40`).
   - Consultas: Estado CPE, Consulta CDR, Consulta de Ticket asíncrono, Consulta RUC/DNI.
5. **Manejo de Errores Dual (`CpeResult<T>` + Excepciones)**:
   - Toda operación retorna [[core/01_architecture_and_patterns#3. Modelo de Resultados y Errores (`CpeResult<T>`)|`Future<CpeResult<T>>`]] (`sealed class` con `CpeSuccess<T>` y `CpeFailure<T>`).
   - Incluye extensión `.getOrThrow()` que desempaqueta el valor o lanza una excepción tipada (`SunatRejectionException`, `SunatExceptionError`, `CpeValidationException`, `OseTransportException`).
6. **Flujo Asíncrono Dual (Tickets)**:
   - Operaciones basadas en ticket (`RC`, `RA`, `RR`, `09`, `31`, [[providers/02_efact|EFACT]]) retornan `TicketResponse` de inmediato.
   - El Core provee el helper [[core/01_architecture_and_patterns#Helper de Polling Asíncrono (`PollingConfig`)|`pollTicketUntilDone(ticket, {PollingConfig config})`]] para consumidores que requieran esperar el CDR final en una sola llamada.
7. **Entidades Dart 3 Puro (Zero Codegen en Core)**:
   - Clases `sealed` y `final` inmutables con igualdad por valor y métodos `copyWith`, sin depender de `build_runner` ni `freezed`.
8. **Transporte Desacoplado (`CpeHttpClient`)**:
   - Interfaz [[core/01_architecture_and_patterns#6. Capa de Transporte (`CpeHttpClient`)|`CpeHttpClient`]] propia en el Core con implementación por defecto sobre `package:http`, soportando interceptores (logging, telemetría, renovación de tokens OAuth2, WS-Security headers y retries).

---

## 2. Estructura del Monorepo (Melos)

```text
sunat_cpe/
├── pubspec.yaml                        # Configuración de Workspace Dart 3 + Melos
├── docs/                               # Vault de documentación de arquitectura (Obsidian)
│   ├── README.md
│   ├── core/
│   │   ├── 01_architecture_and_patterns.md
│   │   ├── 02_domain_entities_and_types.md
│   │   └── 03_validation_and_ubl_signing.md
│   └── providers/
│       ├── 01_nubefact.md
│       ├── 02_efact.md
│       ├── 03_mifact.md
│       ├── 04_bizlinks.md
│       ├── 05_digiflow.md
│       ├── 06_sovos_paperless.md
│       ├── 07_facturaloperu.md
│       ├── 08_tci.md
│       └── 09_cavali_gosocket.md
└── packages/
    ├── sunat_cpe_core/                 # Dominio, contratos, validador, UBL 2.1, XAdES-BES
    ├── sunat_cpe_nubefact/             # Adaptador PSE/OSE Nubefact (REST JSON)
    ├── sunat_cpe_efact/                # Adaptador OSE EFACT (REST OAuth2 + SOAP UBL)
    ├── sunat_cpe_mifact/               # Adaptador PSE/OSE Mifact (REST JSON)
    ├── sunat_cpe_bizlinks/             # Adaptador OSE Bizlinks (SOAP WS-Security + REST)
    ├── sunat_cpe_digiflow/             # Adaptador OSE Digiflow (SOAP WS-Security + REST GRE)
    ├── sunat_cpe_sovos/                # Adaptador OSE Sovos Paperless (SOAP / REST)
    ├── sunat_cpe_facturaloperu/        # Adaptador PSE FacturaloPeru / PRO (REST JSON)
    ├── sunat_cpe_tci/                  # Adaptador OSE TCI (SOAP WS-Security / REST)
    └── sunat_cpe_cavali/               # Adaptador OSE Cavali / Gosocket (SOAP / REST + Factoring)
```

---

## 3. Matriz Comparativa de los 9 Proveedores OSE / PSE

| # | Proveedor | Rol SUNAT | Protocolo Principal | Formato Payload | Firma Digital | Autenticación | Flujo Emisión 01/03 | Nota de Especificación |
|---|-----------|-----------|---------------------|-----------------|---------------|---------------|---------------------|------------------------|
| 1 | **Nubefact** | PSE / OSE | REST HTTP POST | JSON / TXT propietario | En servidor (PSE) | Header `Authorization: Token token="..."` | Síncrono (o diferido configurable) | [[providers/01_nubefact\|01_nubefact]] |
| 2 | **EFACT** | OSE / PSE | REST API + SOAP 1.1 | XML UBL 2.1 / JSON / CSV | Local (XAdES) o Servidor | OAuth2 (`Bearer`) en REST / `wsse` en SOAP | Asíncrono en REST (Ticket UUID) / Síncrono en SOAP | [[providers/02_efact\|02_efact]] |
| 3 | **Mifact** | PSE / OSE | REST HTTP POST | JSON propietario | En servidor o Local | Campo `TOKEN` en body JSON | Síncrono (devuelve CDR y PDF) | [[providers/03_mifact\|03_mifact]] |
| 4 | **Bizlinks** | OSE / PSE | SOAP 1.1 / REST | ZIP con XML UBL 2.1 | Local (XAdES-BES) o Servidor | WS-Security (`UsernameToken`) / Basic | Síncrono (`sendBill`) y Asíncrono (`sendSummary`) | [[providers/04_bizlinks\|04_bizlinks]] |
| 5 | **Digiflow** | OSE | SOAP 1.1 / REST GRE | ZIP con XML UBL 2.1 | Local (XAdES-BES) | WS-Security (`UsernameToken`) / OAuth2 GRE | Síncrono (`sendBill`) y Asíncrono (`sendSummary`/`sendPack`) | [[providers/05_digiflow\|05_digiflow]] |
| 6 | **Sovos (Paperless)** | OSE / PSE | SOAP 1.1 / REST | XML UBL 2.1 / Text-Pipe / JSON | Local o Servidor (HSM) | WS-Security / API Key / Basic Auth | Síncrono (`sendBill`) / Híbrido ERP | [[providers/06_sovos_paperless\|06_sovos_paperless]] |
| 7 | **FacturaloPeru (PRO)** | PSE / OSE | REST HTTP POST | JSON anidado semántico | En servidor (PSE) | Header `Authorization: Bearer <api_token>` | Síncrono (con envío directo o a cola OSE) | [[providers/07_facturaloperu\|07_facturaloperu]] |
| 8 | **TCI (Efacturación)** | OSE / PSE | SOAP 1.1 / REST | ZIP con XML UBL 2.1 | Local (XAdES-BES) o Servidor | WS-Security (`UsernameToken`) / Token JWT | Síncrono (`sendBill`) y Asíncrono (`sendSummary`) | [[providers/08_tci\|08_tci]] |
| 9 | **Cavali / Gosocket** | OSE + Cavali | SOAP 1.1 / REST | ZIP con XML UBL 2.1 / JSON | Local (XAdES-BES) o Servidor | WS-Security / OAuth2 (`client_credentials`) | Síncrono (`sendBill`) + Eventos Factoring (Acuse/Conformidad) | [[providers/09_cavali_gosocket\|09_cavali_gosocket]] |

---

## 4. Índice de Documentos del Core (`docs/core/`)

1. [[core/01_architecture_and_patterns|01. Arquitectura, Patrones e Interfaces]]: Capas del paquete `sunat_cpe_core`, contratos `OseProvider`, `CpeResult<T>`, manejo de Tickets asíncronos, `CpeHttpClient` e interceptores.
2. [[core/02_domain_entities_and_types|02. Entidades de Dominio, Tipos y Catálogos SUNAT]]: Especificación completa de entidades Dart 3 (`CpeDocument`, `InvoiceDocument`, `CreditNoteDocument`, `DebitNoteDocument`, `VoidedDocument`, `DailySummaryDocument`, `DespatchAdviceDocument`, `RetentionDocument`, `PerceptionDocument`, `PurchaseSettlementDocument`) y Catálogos SUNAT.
3. [[core/03_validation_and_ubl_signing|03. Validación Matemática, Motor UBL 2.1 y Firma XAdES-BES]]: Motor de validación matemática Passthrough (`CpeMathValidator`), arquitectura del generador XML UBL 2.1, empaquetado ZIP y firma digital XAdES-BES en Dart puro.

---

## 5. Estado de Implementación de Paquetes

| Paquete | Documentación | Código Fuente | Directorio en Monorepo GitHub | Estado |
|---------|---------------|---------------|-------------------------------|--------|
| `sunat_cpe_core` | [[core/01_architecture_and_patterns\|Core Docs]] | [`lib/sunat_cpe_core.dart`](../packages/sunat_cpe_core/lib/sunat_cpe_core.dart) | [packages/sunat_cpe_core](https://github.com/Cesarius1970/sunat_cpe/tree/main/packages/sunat_cpe_core) | Completado |
| `sunat_cpe_nubefact` | [[providers/01_nubefact\|01_nubefact]] | [`lib/sunat_cpe_nubefact.dart`](../packages/sunat_cpe_nubefact/lib/sunat_cpe_nubefact.dart) | [packages/sunat_cpe_nubefact](https://github.com/Cesarius1970/sunat_cpe/tree/main/packages/sunat_cpe_nubefact) | Completado |
| `sunat_cpe_efact` | [[providers/02_efact\|02_efact]] | Pendiente | [packages/sunat_cpe_efact](https://github.com/Cesarius1970/sunat_cpe/tree/main/packages/sunat_cpe_efact) | En diseño |
| `sunat_cpe_mifact` | [[providers/03_mifact\|03_mifact]] | Pendiente | [packages/sunat_cpe_mifact](https://github.com/Cesarius1970/sunat_cpe/tree/main/packages/sunat_cpe_mifact) | En diseño |
| `sunat_cpe_bizlinks` | [[providers/04_bizlinks\|04_bizlinks]] | Pendiente | [packages/sunat_cpe_bizlinks](https://github.com/Cesarius1970/sunat_cpe/tree/main/packages/sunat_cpe_bizlinks) | En diseño |
| `sunat_cpe_digiflow` | [[providers/05_digiflow\|05_digiflow]] | Pendiente | [packages/sunat_cpe_digiflow](https://github.com/Cesarius1970/sunat_cpe/tree/main/packages/sunat_cpe_digiflow) | En diseño |
| `sunat_cpe_sovos` | [[providers/06_sovos_paperless\|06_sovos_paperless]] | Pendiente | [packages/sunat_cpe_sovos](https://github.com/Cesarius1970/sunat_cpe/tree/main/packages/sunat_cpe_sovos) | En diseño |
| `sunat_cpe_facturaloperu` | [[providers/07_facturaloperu\|07_facturaloperu]] | Pendiente | [packages/sunat_cpe_facturaloperu](https://github.com/Cesarius1970/sunat_cpe/tree/main/packages/sunat_cpe_facturaloperu) | En diseño |
| `sunat_cpe_tci` | [[providers/08_tci\|08_tci]] | Pendiente | [packages/sunat_cpe_tci](https://github.com/Cesarius1970/sunat_cpe/tree/main/packages/sunat_cpe_tci) | En diseño |
| `sunat_cpe_cavali` | [[providers/09_cavali_gosocket\|09_cavali_gosocket]] | Pendiente | [packages/sunat_cpe_cavali](https://github.com/Cesarius1970/sunat_cpe/tree/main/packages/sunat_cpe_cavali) | En diseño |
