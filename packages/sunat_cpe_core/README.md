# sunat_cpe_core

Núcleo de dominio, catálogos oficiales del Anexo N° 8 de SUNAT, validador aritmético de traspaso directo (*Strict Passthrough*), generador XML UBL 2.1/2.0, firmador digital XAdES-BES (RSA-SHA256) en Dart puro y contratos unificados OSE/PSE para Facturación Electrónica en el Perú (CPE).

---

## Propósito y Arquitectura *Strict Passthrough* con `Decimal`

`sunat_cpe_core` constituye la base compartida por los 9 adaptadores de Operadores de Servicios Electrónicos (OSE) y Proveedores de Servicios Electrónicos (PSE) del ecosistema `sunat_cpe`, así como por la fachada unificada multimarca.

### Principios de Diseño

1. **Precisión Financiera Exacta (`Decimal`)**: Todos los valores monetarios, precios unitarios, valores unitarios sin impuestos, cantidades, tasas impositivas y tipos de cambio utilizan el tipo `Decimal` (reexportado directamente por `sunat_cpe_core`), eliminando por completo los errores de redondeo de punto flotante binario (`double` IEEE 754).
2. **Arquitectura *Strict Passthrough* (Traspaso Directo)**: La librería **nunca muta, inventa ni recalcula silenciosamente** los importes tributarios enviados por el ERP o sistema de facturación. En su lugar, transmite exactamente los montos calculados por el sistema origen y los verifica previamente mediante `CpeMathValidator` respetando las tolerancias oficiales de redondeo de SUNAT.
3. **100 % Dart 3 Puro**: Construido con clases selladas (`sealed class`), evaluación exhaustiva por *pattern matching* y cero generación de código (`build_runner`).

---

## Jerarquía de Entidades de Dominio (`CpeDocument`)

Todos los comprobantes electrónicos heredan de la clase sellada raíz `CpeDocument`:

| Entidad | Clase Padre | Código(s) SUNAT | Estándar XML | Descripción |
| :--- | :--- | :---: | :---: | :--- |
| `InvoiceDocument` | `SalesCpeDocument` | `01`, `03` | UBL 2.1 | Factura Electrónica y Boleta de Venta Electrónica (incluye cuotas al crédito RS 000193-2020, detracciones SPOT, retenciones IGV, percepciones y anticipos). |
| `CreditNoteDocument` | `SalesCpeDocument` | `07` | UBL 2.1 | Nota de Crédito Electrónica (incluye causal Catálogo 09 y reprogramación de cuotas con código `13`). |
| `DebitNoteDocument` | `SalesCpeDocument` | `08` | UBL 2.1 | Nota de Débito Electrónica (intereses por mora, aumento en el valor, penalidades según Catálogo 10). |
| `PurchaseSettlementDocument` | `SalesCpeDocument` | `04` | UBL 2.1 | Liquidación de Compra Electrónica emitida a personas naturales sin RUC con ubicación de operación. |
| `DailySummaryDocument` | `CpeDocument` | `RC` | UBL 2.0 | Resumen Diario de Boletas de Venta y Notas Electrónicas vinculadas (`SummaryDocuments`). |
| `VoidedDocument` | `CpeDocument` | `RA`, `RR` | UBL 2.0 | Comunicación de Baja de comprobantes y Resumen de Reversiones (`VoidedDocuments`). |
| `DespatchAdviceDocument` | `CpeDocument` | `09`, `31` | UBL 2.1 | Guía de Remisión Electrónica Remitente (`09`) y Transportista (`31`) con vehículos, conductores y puntos de partida/llegada. |
| `RetentionDocument` | `AgentCpeDocument` | `20` | UBL 2.0 | Comprobante de Retención Electrónico con detalle de pagos y tipo de cambio. |
| `PerceptionDocument` | `AgentCpeDocument` | `40` | UBL 2.0 | Comprobante de Percepción Electrónico con detalle de cobros y régimen aplicable. |

---

## Catálogos Oficiales SUNAT (Anexo N° 8)

El paquete incluye enumeraciones tipadas con los códigos oficiales de SUNAT:

- **`CpeDocumentType`** (Catálogo 01): Tipo de Documento (`factura`, `boleta`, `liquidacionCompra`, `notaCredito`, `notaDebito`, `guiaRemisionRemitente`, `comprobanteRetencion`, `guiaRemisionTransportista`, `comprobantePercepcion`, `resumenDiario`, `comunicacionBaja`, `reversion`).
- **`CurrencyCode`** (Catálogo 02): Monedas ISO 4217 (`pen`, `usd`, `eur`).
- **`TaxCategoryCode`** (Catálogo 05): Tipos de Tributos (`1000` IGV, `1016` IVAP, `9997` Exonerado, `9998` Inafecto, `9996` Gratuito, `9995` Exportación, `2000` ISC, `7152` ICBPER, `9999` Otros).
- **`IdentityDocumentType`** (Catálogo 06): Documentos de Identidad (`noDomiciliado`, `dni`, `carnetExtranjeria`, `ruc`, `pasaporte`, `cedulaDiplomatica`, `tam`).
- **`IgvAffectationType`** (Catálogo 07): Afectación del IGV (`gravadoOperacionOnerosa` `10`, retiros gratuitos gravados `11`–`16`, `gravadoIvap` `17`, `exoneradoOperacionOnerosa` `20`, `inafectoOperacionOnerosa` `30`, retiros inafectos `31`–`36`, `exportacion` `40`).
- **`CreditNoteReasonCode`** (Catálogo 09): Motivos de Nota de Crédito (`01` Anulación de la operación hasta `13` Corrección del monto neto pendiente de pago y/o fechas de vencimiento).
- **`DebitNoteReasonCode`** (Catálogo 10): Motivos de Nota de Débito (`01` Intereses por mora, `02` Aumento en el valor, `03` Penalidades, `10` Exportación, `11` IVAP).
- **`TransportModeCode`** (Catálogo 18): Modalidad de Traslado (`transportePublico` `01`, `transportePrivado` `02`).
- **`SummaryLineStatus`** (Catálogo 19): Estado de ítem en Resumen Diario (`adicionar` `1`, `modificar` `2`, `anulado` `3`).
- **`DespatchReasonCode`** (Catálogo 20): Motivos de Traslado para Guías de Remisión (`venta` `01`, `compra` `02`, `trasladoEntreEstablecimientos` `04`, `importacion` `08`, `exportacion` `09`, etc.).
- **`PerceptionRegimeCode`** (Catálogo 22): Régimen de Percepción (`ventaInterna` `01` al 2 %, `adquisicionCombustible` `02` al 1 %, `tasaEspecial` `03` al 0.5 %).
- **`RetentionRegimeCode`** (Catálogo 23): Régimen de Retención (`tasaTresPorCiento` `01` al 3 %, `tasaSeisPorCiento` `02` al 6 %).
- **`OperationType`** (Catálogo 51): Tipo de Operación (`ventaInterna` `0101`, `operacionSujetaDetraccion` `1001`, etc.).

---

## Motores Core: Validación, UBL 2.1, Firma XAdES-BES y Códec ZIP/CDR

### 1. Validador Matemático (`CpeMathValidator`)

Valida un `CpeDocument` antes de generar el XML o transmitirlo a la red:
- Verifica formato de RUC de 11 dígitos, consistencia entre `DocumentId.issuerRuc` y `CompanyParty.ruc`, y correlativo positivo.
- Verifica ecuaciones por cada `CpeLineItem`: valor de venta por línea, reglas de transferencia gratuita (`isReferencePrice = true`, `unitValue == 0.00`), cálculo de IGV/IVAP, ISC e impuesto a las bolsas plásticas (`ICBPER`).
- Verifica sumatorias de bases imponibles hacia `MonetaryTotals` (`totalGravadas`, `totalExoneradas`, `totalInafectas`, `totalExportacion`, `totalGratuitas`, `totalValorVenta`, `totalImpuestos`, `totalPrecioVenta`, `importeTotalPagar`).
- Aplica la regla obligatoria de la **RS 000193-2020/SUNAT** en ventas al crédito: el monto neto pendiente de pago (`netPendingAmount`) y la suma de cuotas (`Cuota001`, `Cuota002`...) deben descontar la detracción SPOT y/o retención del IGV respecto al `importeTotalPagar`.

### 2. Generador XML UBL 2.1 y 2.0 (`UblXmlBuilder`)

Construye el documento XML estándar con todos los espacios de nombres (`cac`, `cbc`, `ds`, `ext`, `sac`) y el contenedor `<ext:ExtensionContent/>` listo para la firma digital mediante `buildUnsignedXml(document)`.

### 3. Firmador Digital RSA-SHA256 (`XadesBesSigner`)

Firma digitalmente en Dart puro (sin dependencias nativas ni OpenSSL externo):
- Incluye un serializador determinista de **XML Canónico 1.0 (W3C C14N)**.
- Calcula el resumen criptográfico SHA-256 (`digestValue`) y la firma RSA-SHA256 (`signatureValue`) usando `CpeCertificateCredentials` (cargable desde formato PEM PKCS#1 o PKCS#8 con `CpeCertificateCredentials.fromPem`).
- Inyecta el nodo `<ds:Signature Id="SignSUNAT">` en `<ext:ExtensionContent>`.

### 4. Códec ZIP y Analizador de CDR (`CpeZipCodec`)

- **`encodeXmlToZip`**: Empaqueta `{RUC}-{TIPO}-{SERIE}-{NUMERO}.xml` en un archivo `.zip` en memoria y devuelve tanto los bytes (`Uint8List`) como su representación en Base64.
- **`parseCdrFromBase64Zip` / `parseCdrFromZipBytes` / `parseCdrFromXmlString`**: Extrae y analiza la Constancia de Recepción (`<ar:ApplicationResponse>`), obteniendo el código de respuesta (`0` aceptado), descripción, *hash* (`digestValue`), fecha/hora y observaciones no bloqueantes (`SunatWarning`, códigos 4000+).

---

## Manejo de Errores Tipado con `CpeResult<T>`

Todas las operaciones de validación y emisión devuelven `CpeResult<T>`, una clase sellada con dos variantes (`CpeSuccess<T>` y `CpeFailure<T>`) que soporta tres estilos de consumo:

1. **Pattern Matching Exhaustivo (`switch`)**:
   ```dart
   switch (resultado) {
     case CpeSuccess(:final data):
       print('Éxito: $data');
     case CpeFailure(:final error):
       print('Fallo (${error.code}): ${error.message}');
   }
   ```
2. **Programación Funcional (`fold`)**:
   ```dart
   final mensaje = resultado.fold(
     (data) => 'Procesado correctamente',
     (error) => 'Error detectado: ${error.message}',
   );
   ```
3. **Estilo Imperativo (`getOrThrow()`)**:
   ```dart
   try {
     final data = resultado.getOrThrow();
   } on CpeValidationException catch (e) {
     for (final issue in e.issues) {
       print(issue);
     }
   }
   ```

### Jerarquía Sellada de Excepciones (`CpeException`)

- **`CpeValidationException`**: Error aritmético o estructural detectado localmente antes de enviar a la red (contiene `List<ValidationIssue>`).
- **`OseTransportException`**: Error de red, *timeout* o fallo HTTP 5xx (reintentable).
- **`OseAuthException`**: Credenciales WS-Security o token OAuth2 inválidos.
- **`SunatExceptionError`**: Excepción técnica de SUNAT/OSE (códigos `0100` a `1999`). El comprobante **no** fue registrado y puede corregirse reutilizando el mismo correlativo.
- **`SunatRejectionException`**: Rechazo definitivo de negocio por SUNAT/OSE (códigos `2000` a `3999`). Incluye el CDR de rechazo (`rejectionCdr`) si fue emitido.

---

## Ejemplo Rápido

Ejecuta el ejemplo completo incluido en el paquete para ver los 6 escenarios en acción (100 % offline):

```bash
dart run packages/sunat_cpe_core/example/main.dart
```
