# sunat_cpe_nubefact

Adaptador oficial de **Nubefact (PSE / OSE)** en Dart 3 puro para la emisión y gestión de Comprobantes de Pago Electrónicos (CPE) de **SUNAT (Perú)**, construido sobre los contratos y entidades de dominio de [`sunat_cpe_core`](https://pub.dev/packages/sunat_cpe_core).

---

## Características Principales

- **Traducción Automática de Catálogos SUNAT (`NubefactCatalogMapper`)**: Convierte de forma transparente los enumerados oficiales del Anexo N° 8 de SUNAT (`01` Factura, `03` Boleta, `07` Nota de Crédito, `08` Nota de Débito, `09`/`31` Guías de Remisión, monedas ISO 4217 `PEN`/`USD`/`EUR`, Catálogo 07 de afectación de IGV, Catálogo 51 de tipo de operación) a los códigos numéricos enteros propietarios requeridos por la API REST v1 de Nubefact.
- **Formateo de Fechas y Decimales**: Convierte objetos `DateTime` al formato `DD-MM-YYYY` esperado por Nubefact y preserva la exactitud tributaria de `Decimal` antes de serializar el payload JSON.
- **Autenticación por Cabecera Token**: Inyecta automáticamente la cabecera `Authorization: Token token="<TU_TOKEN>"` en cada petición `POST` hacia tu ruta única (`RUTA`).
- **Cobertura Completa de Operaciones**:
  - `generar_comprobante`: Facturas (`01`), Boletas (`03`), Notas de Crédito (`07`) y Notas de Débito (`08`), incluyendo ventas al contado, al crédito con cronograma de cuotas, detracciones SPOT y guías relacionadas.
  - `generar_guia`: Guías de Remisión Remitente (`09`) y Transportista (`31`).
  - `generar_anulacion`: Comunicación de Baja (`RA`) y Resumen Diario (`RC`).
  - `generar_retencion` / `generar_percepcion`: Comprobantes de Retención (`20`) y Percepción (`40`).
  - `consultar_comprobante`, `consultar_anulacion` y `consultar_guia`: Consulta de estado y polling exponencial automático con `pollTicketUntilDone`.
- **Tipado Estricto de Errores (`CpeResult<T>`)**:
  - Códigos Nubefact `10` y `11` (o HTTP `401`/`403`) $\rightarrow$ `OseAuthException`.
  - Códigos Nubefact `20` a `24` (validación de estructura/formato) $\rightarrow$ `CpeValidationException`.
  - Códigos SUNAT `0100` a `1999` (excepciones reintentables) $\rightarrow$ `SunatExceptionError`.
  - Códigos SUNAT `2000` a `3999` (rechazos definitivos de negocio) $\rightarrow$ `SunatRejectionException`.

---

## Arquitectura de Endpoints y Autenticación

Nubefact asigna una **RUTA** única y un **TOKEN** por cada serie/local o empresa registrada en su panel de control (`API - Integración`):

| Parámetro | Valor típico / Formato | Descripción |
| :--- | :--- | :--- |
| **Endpoint (`routeUri`)** | `https://api.nubefact.com/api/v1/<UUID-DE-TU-CUENTA>` | URL única por cuenta/serie provista en el panel de Nubefact. |
| **Cabecera HTTP** | `Authorization: Token token="<TU_TOKEN>"` | Token alfanumérico generado en el panel web de Nubefact. |
| **Método y Formato** | `POST` (`application/json; charset=utf-8`) | Todas las operaciones se discriminan mediante la clave `"operacion"`. |

---

## Mapeo de Catálogos SUNAT $\leftrightarrow$ Nubefact

`NubefactCatalogMapper` realiza automáticamente las siguientes conversiones:

| Concepto | Código SUNAT (`sunat_cpe_core`) | Código Entero Nubefact |
| :--- | :--- | :--- |
| **Factura Electrónica** | `CpeDocumentType.factura` (`"01"`) | `1` |
| **Boleta de Venta** | `CpeDocumentType.boleta` (`"03"`) | `2` |
| **Nota de Crédito** | `CpeDocumentType.notaCredito` (`"07"`) | `3` |
| **Nota de Débito** | `CpeDocumentType.notaDebito` (`"08"`) | `4` |
| **Guía de Remisión Remitente** | `CpeDocumentType.guiaRemisionRemitente` (`"09"`) | `7` |
| **Guía de Remisión Transportista** | `CpeDocumentType.guiaRemisionTransportista` (`"31"`) | `8` |
| **Moneda Soles / Dólares / Euros** | `PEN` / `USD` / `EUR` | `1` / `2` / `3` |
| **IGV Gravado Operación Onerosa** | `IgvAffectationType.gravadoOperacionOnerosa` (`"10"`) | `1` |
| **IGV Exonerado / Inafecto / Exportación** | `"20"` / `"30"` / `"40"` | `8` / `9` / `16` |

---

## Opciones de Configuración (`NubefactConfig`)

| Propiedad | Tipo | Por Defecto | Descripción |
| :--- | :--- | :--- | :--- |
| `routeUri` | `Uri` | *(Requerido)* | URL personal de la API de Nubefact (`RUTA`). |
| `apiToken` | `String` | *(Requerido)* | Token de acceso provisto por Nubefact (`TOKEN`). |
| `autoSendToSunat` | `bool` | `true` | Define `enviar_automaticamente_a_la_sunat`. |
| `autoSendToCustomer` | `bool` | `false` | Define `enviar_automaticamente_al_cliente` por correo. |
| `pdfFormat` | `String` | `'A4'` | Formato de representación impresa (`'A4'`, `'A5'`, `'TICKET'`). |

---

## Instalación

Agrega `sunat_cpe_core` y `sunat_cpe_nubefact` en tu archivo `pubspec.yaml`:

```yaml
dependencies:
  decimal: ^3.2.1
  sunat_cpe_core: ^0.1.2
  sunat_cpe_nubefact: ^0.1.2
```

---

## Ejemplo de Uso Rápido

```dart
import 'package:sunat_cpe_core/sunat_cpe_core.dart';
import 'package:sunat_cpe_nubefact/sunat_cpe_nubefact.dart';

Future<void> main() async {
  // 1. Configurar el proveedor con tu RUTA y TOKEN de Nubefact
  final provider = NubefactProvider(
    config: NubefactConfig(
      routeUri: Uri.parse('https://api.nubefact.com/api/v1/9b8a7c6d-demo-ruta'),
      apiToken: 'a1b2c3d4e5f6g7h8i9j0-tu-token-secreto',
      autoSendToSunat: true,
      pdfFormat: 'A4',
    ),
  );

  // 2. Construir una Factura Electrónica (01)
  final factura = InvoiceDocument(
    id: const DocumentId(
      issuerRuc: '20100066603',
      type: CpeDocumentType.factura,
      series: 'FFF1',
      number: 101,
    ),
    issuer: const CompanyParty(
      ruc: '20100066603',
      legalName: 'MI EMPRESA S.A.C.',
      address: Address(streetLine: 'AV. JAVIER PRADO ESTE 1234, SAN ISIDRO'),
    ),
    customer: const CustomerParty(
      documentType: IdentityDocumentType.ruc,
      documentNumber: '20600695771',
      legalName: 'NUBEFACT S.A.',
      address: Address(streetLine: 'CALLE LIBERTAD 116, MIRAFLORES'),
      email: 'facturacion@cliente.pe',
    ),
    issueDate: DateTime(2026, 11, 4),
    currency: CurrencyCode.pen,
    items: [
      CpeLineItem(
        lineNumber: 1,
        internalCode: 'SRV-CLOUD',
        unitCode: 'ZZ',
        description: 'SERVICIO DE HOSTING ANUAL',
        quantity: Decimal.one,
        unitValue: Decimal.parse('500.00'),
        unitPrice: Decimal.parse('590.00'),
        lineExtensionAmount: Decimal.parse('500.00'),
        taxableBaseAmount: Decimal.parse('500.00'),
        igvAffectation: IgvAffectationType.gravadoOperacionOnerosa,
        igvPercentage: Decimal.parse('18.00'),
        igvAmount: Decimal.parse('90.00'),
        totalLineTaxAmount: Decimal.parse('90.00'),
        totalLineAmount: Decimal.parse('590.00'),
      ),
    ],
    totals: MonetaryTotals(
      totalGravadas: Decimal.parse('500.00'),
      totalIgv: Decimal.parse('90.00'),
      totalValorVenta: Decimal.parse('500.00'),
      totalImpuestos: Decimal.parse('90.00'),
      totalPrecioVenta: Decimal.parse('590.00'),
      importeTotalPagar: Decimal.parse('590.00'),
    ),
  );

  // 3. Enviar el comprobante y manejar el resultado de forma segura
  final result = await provider.sendDocument(factura);
  switch (result) {
    case CpeSuccess(:final data):
      print('Estado: ${data.status}');
      print('Hash CPE: ${data.digestValue}');
      print('PDF URL: ${data.pdfDownloadUrl}');
      print('XML URL: ${data.xmlDownloadUrl}');
      print('CDR URL: ${data.cdrDownloadUrl}');
    case CpeFailure(:final error):
      print('Error [${error.runtimeType}]: ${error.message}');
  }
}
```

> Ejecuta el ejemplo interactivo completo y 100 % offline con:
> ```bash
> dart run example/main.dart
> ```
