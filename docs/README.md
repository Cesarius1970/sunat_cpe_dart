# Arquitectura y Análisis de Proveedores OSE / PSE (SUNAT CPE)

Suite de especificación técnica para el monorepo `sunat_cpe` en **Dart 3 puro**. Define el paquete núcleo (`sunat_cpe_core`) y los 9 paquetes adaptadores para los principales Operadores de Servicios Electrónicos (OSE) y Proveedores de Servicios Electrónicos (PSE) registrados en SUNAT (Perú).

---

## 1. Decisiones Arquitectónicas Clave (ADR Resumen)

1. **Modo de Operación Híbrido Completo**:
   - **Vía UBL Nativa (SOAP / REST XML)**: `sunat_cpe_core` incluye generador XML UBL 2.1, empaquetador ZIP (`archive`), firmador digital XAdES-BES en Dart puro (`pointycastle` / `xml`) y lector de CDR. Usado por OSEs puros (Bizlinks, Digiflow, TCI, Sovos, Cavali/Gosocket, EFACT XML).
   - **Vía Delegada (JSON REST DTO)**: Los paquetes adaptadores transforman las entidades del Core a payloads JSON propietarios cuando el PSE/OSE ofrece API simplificada (Nubefact, FacturaloPeru, Mifact, EFACT JSON).
2. **Cálculo de Impuestos Passthrough Estricto con Validación Matemática**:
   - El ERP/consumidor calcula y envía todos los importes (`valorUnitario`, `precioUnitario`, `igv`, `isc`, `icbper`, `totalImpuestos`, etc.).
   - El Core ejecuta un `CpeMathValidator` antes del envío para verificar cuadre aritmético según tolerancias UBL 2.1 SUNAT (±1.00 por línea o reglas de redondeo Catálogo 07) evitando rechazos por error `2000-3999`.
3. **Precisión Numérica Exacta**:
   - Prohibido el uso de `double` para montos, tasas, tipos de cambio o cantidades. Todo campo numérico financiero usa `Decimal` (`package:decimal`), soportando hasta 10 decimales en valores unitarios y 2 decimales en totales monetarios.
4. **Cobertura Total de Comprobantes (CPE)**:
   - Ventas: Factura (`01`), Boleta (`03`), Liquidación de Compra (`04`), Nota de Crédito (`07`), Nota de Débito (`08`).
   - Resúmenes y Bajas: Resumen Diario (`RC`), Comunicación de Baja (`RA`), Reversión (`RR`).
   - Traslado: Guía de Remisión Remitente (`09`) y Transportista (`31`) (Flujo OSE / API REST GRE).
   - Agentes: Comprobante de Retención (`20`) y Percepción (`40`).
   - Consultas: Estado CPE, Consulta CDR, Consulta de Ticket asíncrono, Consulta RUC/DNI.
5. **Manejo de Errores Dual (`CpeResult<T>` + Excepciones)**:
   - Toda operación retorna `Future<CpeResult<T>>` (`sealed class` con `CpeSuccess<T>` y `CpeFailure<T>`).
   - Incluye extensión `.getOrThrow()` que desempaqueta el valor o lanza una excepción tipada (`SunatRejectionException`, `SunatExceptionError`, `CpeValidationException`, `OseTransportException`).
6. **Flujo Asíncrono Dual (Tickets)**:
   - Operaciones basadas en ticket (`RC`, `RA`, `RR`, `09`, `31`, EFACT) retornan `TicketResponse` de inmediato.
   - El Core provee el helper `pollTicketUntilDone(ticket, {BackoffStrategy strategy})` para consumidores que requieran esperar el CDR final en una sola llamada.
7. **Entidades Dart 3 Puro (Zero Codegen en Core)**:
   - Clases `sealed` y `final` inmutables con igualdad por valor y métodos `copyWith`, sin depender de `build_runner` ni `freezed`.
8. **Transporte Desacoplado (`CpeHttpClient`)**:
   - Interfaz propia en el Core con implementación por defecto sobre `package:http`, soportando interceptores (logging, telemetría, renovación de tokens OAuth2, WS-Security headers y retries).

---

## 2. Estructura del Monorepo (Melos)

```text
sunat_cpe/
├── pubspec.yaml                        # Configuración de Workspace Dart 3 + Melos
├── docs/                               # Documentación de arquitectura y análisis OSE/PSE
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

| # | Proveedor | Rol SUNAT | Protocolo Principal | Formato Payload | Firma Digital | Autenticación | Flujo Emisión 01/03 | Documentación Detallada |
|---|-----------|-----------|---------------------|-----------------|---------------|---------------|---------------------|-------------------------|
| 1 | **Nubefact** | PSE / OSE | REST HTTP POST | JSON / TXT propietario | En servidor (PSE) | Header `Authorization: Token token="..."` | Síncrono (o diferido configurable) | [01_nubefact.md](file:///home/cesar/Proyectos/Dart/sunat_cpe/docs/providers/01_nubefact.md) |
| 2 | **EFACT** | OSE / PSE | REST API + SOAP 1.1 | XML UBL 2.1 / JSON / CSV | Local (XAdES) o Servidor | OAuth2 (`Bearer`) en REST / `wsse` en SOAP | Asíncrono en REST (Ticket UUID) / Síncrono en SOAP | [02_efact.md](file:///home/cesar/Proyectos/Dart/sunat_cpe/docs/providers/02_efact.md) |
| 3 | **Mifact** | PSE / OSE | REST HTTP POST | JSON propietario | En servidor o Local | Campo `TOKEN` en body JSON | Síncrono (devuelve CDR y PDF) | [03_mifact.md](file:///home/cesar/Proyectos/Dart/sunat_cpe/docs/providers/03_mifact.md) |
| 4 | **Bizlinks** | OSE / PSE | SOAP 1.1 / REST | ZIP con XML UBL 2.1 | Local (XAdES-BES) o Servidor | WS-Security (`UsernameToken`) / Basic | Síncrono (`sendBill`) y Asíncrono (`sendSummary`) | [04_bizlinks.md](file:///home/cesar/Proyectos/Dart/sunat_cpe/docs/providers/04_bizlinks.md) |
| 5 | **Digiflow** | OSE | SOAP 1.1 / REST GRE | ZIP con XML UBL 2.1 | Local (XAdES-BES) | WS-Security (`UsernameToken`) / OAuth2 GRE | Síncrono (`sendBill`) y Asíncrono (`sendSummary`/`sendPack`) | [05_digiflow.md](file:///home/cesar/Proyectos/Dart/sunat_cpe/docs/providers/05_digiflow.md) |
| 6 | **Sovos (Paperless)** | OSE / PSE | SOAP 1.1 / REST | XML UBL 2.1 / Text-Pipe / JSON | Local o Servidor (HSM) | WS-Security / API Key / Basic Auth | Síncrono (`sendBill`) / Híbrido ERP | [06_sovos_paperless.md](file:///home/cesar/Proyectos/Dart/sunat_cpe/docs/providers/06_sovos_paperless.md) |
| 7 | **FacturaloPeru (PRO)** | PSE / OSE | REST HTTP POST | JSON anidado semántico | En servidor (PSE) | Header `Authorization: Bearer <api_token>` | Síncrono (con envío directo o a cola OSE) | [07_facturaloperu.md](file:///home/cesar/Proyectos/Dart/sunat_cpe/docs/providers/07_facturaloperu.md) |
| 8 | **TCI (Efacturación)** | OSE / PSE | SOAP 1.1 / REST | ZIP con XML UBL 2.1 | Local (XAdES-BES) o Servidor | WS-Security (`UsernameToken`) / Token JWT | Síncrono (`sendBill`) y Asíncrono (`sendSummary`) | [08_tci.md](file:///home/cesar/Proyectos/Dart/sunat_cpe/docs/providers/08_tci.md) |
| 9 | **Cavali / Gosocket** | OSE + Cavali | SOAP 1.1 / REST | ZIP con XML UBL 2.1 / JSON | Local (XAdES-BES) o Servidor | WS-Security / OAuth2 (`client_credentials`) | Síncrono (`sendBill`) + Eventos Factoring (Acuse/Conformidad) | [09_cavali_gosocket.md](file:///home/cesar/Proyectos/Dart/sunat_cpe/docs/providers/09_cavali_gosocket.md) |

---

## 4. Índice de Documentos del Core (`docs/core/`)

1. [01_architecture_and_patterns.md](file:///home/cesar/Proyectos/Dart/sunat_cpe/docs/core/01_architecture_and_patterns.md): Capas del paquete `sunat_cpe_core`, contratos `OseProvider`, `CpeResult<T>`, manejo de Tickets asíncronos, `CpeHttpClient` e interceptores.
2. [02_domain_entities_and_types.md](file:///home/cesar/Proyectos/Dart/sunat_cpe/docs/core/02_domain_entities_and_types.md): Especificación completa de entidades Dart 3 (`CpeDocument`, `InvoiceDocument`, `CreditNoteDocument`, `DebitNoteDocument`, `VoidedDocument`, `DailySummaryDocument`, `DespatchAdviceDocument`, `RetentionDocument`, `PerceptionDocument`, `PurchaseSettlementDocument`) y Catálogos SUNAT.
3. [03_validation_and_ubl_signing.md](file:///home/cesar/Proyectos/Dart/sunat_cpe/docs/core/03_validation_and_ubl_signing.md): Motor de validación matemática Passthrough (`CpeMathValidator`), arquitectura del generador XML UBL 2.1, empaquetado ZIP y firma digital XAdES-BES en Dart puro.
