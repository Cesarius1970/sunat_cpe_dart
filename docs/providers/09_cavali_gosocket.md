# Análisis de Proveedor 09: Cavali / Gosocket / Carvajal (OSE + Factoring Factrack)

Especificación técnica para el paquete `packages/sunat_cpe_cavali`.

---

## 1. Perfil Técnico del Proveedor

- **Rol en SUNAT y Mercado Financiero**: Alianza / Ecosistema conformado por **Gosocket / Carvajal Tecnología y Servicios** (OSE autorizado por SUNAT) y **Cavali ICLV (Registro Central de Valores y Liquidaciones - Factrack)** para la anotación en cuenta y negociación de Facturas Negociables (Factoring).
- **Doble Funcionalidad del Paquete `sunat_cpe_cavali`**:
  1. **Validación OSE (SOAP 1.1 `billService` / REST Gosocket)**:
     - Emisión y validación de CPE (`01`, `03`, `07`, `08`, `09`, `20`, `31`, `40`, `RA`, `RC`) mediante XML UBL 2.1 firmado localmente (`XadesBesSigner`).
  2. **Integración API REST Cavali Factrack (Capacidad `ProviderCapability.cavaliFactoring`)**:
     - Registro de Facturas Comerciales al Crédito (`CreditPaymentTerms`), consulta de estado de Conformidad / Disconformidad (plazo de 8 días calendario según DU 013-2020) y constancia de anotación en cuenta.

---

## 2. Endpoints Oficiales (OSE y Cavali Factrack)

| Servicio | Entorno | URL Base |
|----------|---------|----------|
| **OSE SOAP 1.1 (Gosocket / Carvajal)** | Producción | `https://ose.gosocket.net/ol-ti-itcpe/billService` (o endpoint asignado por tenant) |
| **OSE SOAP 1.1 (Gosocket / Carvajal)** | Pruebas / QA | `https://osetest.gosocket.net/ol-ti-itcpe/billService` |
| **API REST Cavali Factrack (OAuth2)** | Producción | `https://api.cavali.com.pe/factrack/v2` |
| **API REST Cavali Factrack (OAuth2)** | Pruebas / QA | `https://apidev.cavali.com.pe/factrack/v2` |

---

## 3. Requisitos UBL 2.1 Críticos para Cavali / Factoring

Para que una Factura Electrónica (`01`) o Recibo por Honorarios al crédito sea aceptada sin observaciones tanto por el OSE como por la plataforma de Factoring de Cavali, `sunat_cpe_core` y `sunat_cpe_cavali` garantizan:

1. **Forma de Pago Obligatoria (`PaymentTerms`)**:
   - Nodo `<cac:PaymentTerms>` con `<cbc:ID>FormaPago</cbc:ID>`, `<cbc:PaymentMeansID>Credito</cbc:PaymentMeansID>` y `<cbc:Amount currencyID="PEN">MONTO_NETO_PENDIENTE</cbc:Amount>`.
2. **Descuento de Detracciones y Retenciones en el Neto Pendiente**:
   - En Cavali/SUNAT, el `netPendingAmount` **nunca** puede incluir el monto de la detracción ni de la retención del IGV, ya que el título valor negociable (Factura Negociable) solo representa el saldo neto exigible al adquirente.
   - `CpeMathValidator` verifica que `sum(cuotas) == netPendingAmount == importeTotalPagar - detraccion - retencion`.
3. **Ubicación Exacta de Entrega / Domicilio del Adquirente**:
   - El nodo `<cac:AccountingCustomerParty>/<cac:Party>/<cac:PartyLegalEntity>/<cac:RegistrationAddress>` debe incluir el `<cbc:ID>` con el Ubigeo de 6 dígitos para la notificación de conformidad.

---

## 4. Capacidad Extendida: Interfaz `CavaliFactoringCapability`

Además de implementar `OseProvider`, `CavaliProvider` implementa la interfaz especializada para consultar y gestionar eventos sobre facturas al crédito:

```dart
enum InvoiceConformityStatus {
  pending,             // Dentro del plazo de 8 días calendario
  expressConformity,   // Conformidad expresa otorgada por el adquirente
  presumedConformity,  // Conformidad presunta por vencimiento de plazo
  disconformity,       // Disconformidad registrada (reclamo por bienes/servicios o plazos)
}

final class CavaliInvoiceStatus {
  final DocumentId documentId;
  final InvoiceConformityStatus conformityStatus;
  final bool isRegisteredInCavali;
  final String? cavaliProcessId;
  final DateTime? conformityDate;

  const CavaliInvoiceStatus({
    required this.documentId,
    required this.conformityStatus,
    required this.isRegisteredInCavali,
    this.cavaliProcessId,
    this.conformityDate,
  });
}

abstract interface class CavaliFactoringCapability {
  /// Envía un lote de XMLs de Facturas al Crédito y sus CDRs a Cavali Factrack (POST /invoice/xml).
  Future<CpeResult<String>> registerInvoicesForFactoring(List<CpeEmissionResponse> acceptedInvoices);

  /// Consulta el estado de Conformidad y Anotación en Cuenta en Cavali.
  Future<CpeResult<CavaliInvoiceStatus>> checkConformityStatus(DocumentId documentId);
}
```

---

## 5. Diseño de Clases del Paquete `sunat_cpe_cavali`

```text
packages/sunat_cpe_cavali/
├── lib/
│   ├── sunat_cpe_cavali.dart
│   └── src/
│       ├── cavali_config.dart            # oseSoapUrl, wsseUsername, wssePassword, factrackClientId, factrackClientSecret, apiKey
│       ├── cavali_provider.dart          # Extiende BaseUblOseProvider + implementa CavaliFactoringCapability
│       ├── ose/
│       │   └── gosocket_soap_delegate.dart # Cliente SOAP 1.1 para validación OSE
│       └── factrack/
│           ├── cavali_oauth2_interceptor.dart # Autenticación OAuth2 + x-api-key de Cavali
│           └── cavali_factrack_client.dart    # Registro de XML Base64 y consulta de conformidad
```
