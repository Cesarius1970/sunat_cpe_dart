# Validación Matemática Passthrough, Motor UBL 2.1 y Firma XAdES-BES (`sunat_cpe_core`)

Especificación de las tres piezas de infraestructura interna de `sunat_cpe_core`:
1. **`CpeMathValidator`**: Validador aritmético y de reglas de negocio SUNAT en modo *Passthrough Estricto*.
2. **`UblXmlBuilder`**: Generador de XML UBL 2.1 y UBL 2.0 según las Guías de Elaboración de Documentos Electrónicos de SUNAT.
3. **`XadesBesSigner`**: Firmador digital XML-DSig / XAdES-BES en Dart puro.

---

## 1. Motor de Validación Matemática (`CpeMathValidator`)

Dado que el paquete opera en modo **Passthrough Estricto** (el ERP envía todos los montos precalculados), `CpeMathValidator` actúa como barrera preventiva antes de invocar cualquier red OSE/PSE. Si detecta inconsistencias, retorna un `CpeFailure(CpeValidationException)` indicando exactamente qué línea o total falla.

### 1.1 Reglas Aritméticas por Línea (`CpeLineItem`)

Con una tolerancia configurable (por defecto `±0.01` para cruces directos y `±1.00` según tolerancia máxima UBL 2.1 SUNAT para cálculo de IGV sobre base):

1. **Operaciones Onerosas (`!igvAffectation.isFree`)**:
   - `lineExtensionAmount` debe cuadrar con `(quantity * unitValue) - (discount?.amount ?? 0)`.
   - Si es Gravada (`10` o `17`):
     - `igvAmount` debe cuadrar con `(taxableBaseAmount + (iscAmount ?? 0)) * (igvPercentage / 100)`.
     - `unitPrice` debe cuadrar con `unitValue * (1 + igvPercentage / 100)` (considerando ISC si aplica).
   - Si es Exonerada (`20`), Inafecta (`30`) o Exportación (`40`):
     - `igvAmount` debe ser exactamente `0.00`.
     - `unitPrice` debe ser igual a `unitValue` (salvo que exista ISC).
2. **Operaciones Gratuitas (`igvAffectation.isFree == true`)**:
   - `isReferencePrice` debe ser `true` (Catálogo 16 código `'02'`).
   - `unitValue` debe ser `0.00` y `unitPrice` debe ser `> 0.00` (Valor Referencial unitario).
   - `lineExtensionAmount` representa el valor referencial total de la línea (`quantity * unitPrice`).
3. **ICBPER (`icbperAmount`)**:
   - Si `icbperQuantity != null`, `icbperAmount == icbperQuantity * icbperUnitTax`.
4. **Total Impuestos de Línea (`totalLineTaxAmount`)**:
   - Para líneas onerosas: `totalLineTaxAmount == igvAmount + (iscAmount ?? 0) + (icbperAmount ?? 0)`.

### 1.2 Reglas de Cuadre de Cabecera (`MonetaryTotals`)

1. **Suma de Bases Imponibles**:
   - `totalGravadas == sum(line.taxableBaseAmount para líneas con código '10') - descuentoGlobalAfectaBase - totalAnticiposGravados`.
   - `totalExoneradas == sum(line.lineExtensionAmount para líneas con código '20')`.
   - `totalInafectas == sum(line.lineExtensionAmount para líneas con código '30')`.
   - `totalGratuitas == sum(line.lineExtensionAmount para líneas gratuitas)`.
2. **Suma de Impuestos**:
   - `totalIgv == sum(line.igvAmount para líneas código '10') - igvDescuentoGlobal - igvAnticipos`.
   - `totalImpuestos == totalIgv + totalIvap + totalIsc + totalIcbper + totalOtrosTributos`.
3. **Totales Finales**:
   - `totalValorVenta == totalGravadas + totalExoneradas + totalInafectas + totalExportacion + totalIvapBase`.
   - `totalPrecioVenta == totalValorVenta + totalImpuestos`.
   - `importeTotalPagar == totalPrecioVenta - descuentoGlobalNoAfectaBase + totalOtrosCargos - totalAnticipos + redondeo`.
4. **Validación de Crédito y Cuotas (`CreditPaymentTerms`)**:
   - `sum(installment.amount) == netPendingAmount`.
   - `netPendingAmount == importeTotalPagar - (detractionInDocumentCurrency ?? 0) - (retentionAmount ?? 0)`.

---

## 2. Generador XML UBL 2.1 / 2.0 (`UblXmlBuilder`)

Construye el árbol XML utilizando `package:xml` (`XmlBuilder`) respetando el orden estricto de etiquetas exigido por los esquemas XSD de SUNAT/OSE.

### 2.1 Versiones UBL por Tipo de Documento

| Código | Comprobante | Versión UBL | CustomizationID | Root Tag XML |
|--------|-------------|-------------|-----------------|--------------|
| `01`, `03`, `04` | Factura, Boleta, Liquidación Compra | `2.1` | `2.0` | `<Invoice>` |
| `07` | Nota de Crédito | `2.1` | `2.0` | `<CreditNote>` |
| `08` | Nota de Débito | `2.1` | `2.0` | `<DebitNote>` |
| `09`, `31` | Guía de Remisión (Remitente / Transportista) | `2.1` | `2.0` | `<DespatchAdvice>` |
| `RC` | Resumen Diario de Boletas | `2.0` | `1.1` | `<SummaryDocuments>` |
| `RA`, `RR` | Comunicación de Baja / Reversión | `2.0` | `1.0` | `<VoidedDocuments>` |
| `20` | Comprobante de Retención | `2.0` | `1.0` | `<Retention>` |
| `40` | Comprobante de Percepción | `2.0` | `1.0` | `<Perception>` |

### 2.2 Estructura de Namespaces y Contenedor de Firma

Todo XML generado reserva el nodo `<ext:UBLExtensions>` en primer lugar con un `<ext:ExtensionContent>` vacío donde `XadesBesSigner` inyectará el nodo `<ds:Signature Id="SignSUNAT">`:

```xml
<?xml version="1.0" encoding="UTF-8" standalone="no"?>
<Invoice xmlns="urn:oasis:names:specification:ubl:schema:xsd:Invoice-2"
         xmlns:cac="urn:oasis:names:specification:ubl:schema:xsd:CommonAggregateComponents-2"
         xmlns:cbc="urn:oasis:names:specification:ubl:schema:xsd:CommonBasicComponents-2"
         xmlns:ds="http://www.w3.org/2000/09/xmldsig#"
         xmlns:ext="urn:oasis:names:specification:ubl:schema:xsd:CommonExtensionComponents-2">
  <ext:UBLExtensions>
    <ext:UBLExtension>
      <ext:ExtensionContent>
        <!-- Aquí XadesBesSigner inyecta <ds:Signature> -->
      </ext:ExtensionContent>
    </ext:UBLExtension>
  </ext:UBLExtensions>
  <cbc:UBLVersionID>2.1</cbc:UBLVersionID>
  <cbc:CustomizationID schemeAgencyName="PE:SUNAT">2.0</cbc:CustomizationID>
  ...
</Invoice>
```

---

## 3. Firmador Digital XAdES-BES en Dart Puro (`XadesBesSigner`)

Para los OSEs que exigen envío de XML firmado localmente (Bizlinks, Digiflow, TCI, Sovos, Cavali, EFACT), `sunat_cpe_core` implementa la firma XML-DSig Enveloped con perfil SUNAT sin requerir binarios nativos (`openssl` o `xmlsec1`).

### 3.1 Dependencias Dart Puro para Criptografía
- `pointycastle`: RSA-SHA256 / RSA-SHA1, parseo ASN.1 de llave privada RSA y certificado X.509.
- `crypto`: Hashing `sha256` y `sha1`.
- `xml`: Manipulación del DOM y Canonicalización XML.
- `archive`: Compresión `ZipEncoder` y descompresión `ZipDecoder` en memoria (`Uint8List`).

### 3.2 Algoritmo de Firma Paso a Paso

```mermaid
sequenceDiagram
    participant Builder as UblXmlBuilder
    participant C14N as XmlC14nCanonicalizer
    participant Signer as XadesBesSigner (PointyCastle)
    participant Zip as CpeZipCodec

    Builder->>C14N: 1. XML UBL 2.1 con <ext:ExtensionContent/> vacío
    C14N->>C14N: 2. Canonicalización C14N Exclusiva/Inclusiva (http://www.w3.org/TR/2001/REC-xml-c14n-20010315)
    C14N->>Signer: 3. Calcula DigestValue (SHA-256 en Base64) del documento (Transform: enveloped-signature)
    Signer->>Signer: 4. Construye nodo <ds:SignedInfo> con Reference URI=""
    Signer->>C14N: 5. Canonicaliza el nodo <ds:SignedInfo>
    C14N->>Signer: 6. Firma bytes de <ds:SignedInfo> con RSA-SHA256 usando PrivateKey del .p12/.pem
    Signer->>Signer: 7. Ensambla <ds:Signature> con <ds:SignatureValue> y <ds:X509Certificate>
    Signer->>Zip: 8. Inyecta <ds:Signature> en <ext:ExtensionContent> y retorna XML firmado + DigestValue
    Zip->>Zip: 9. Empaqueta en {RUC}-{TIPO}-{SERIE}-{NUMERO}.zip y codifica en Base64
```

### 3.3 Carga de Certificados Digitales (`CpeCertificateCredentials`)

Soporta dos formatos de entrada para máxima compatibilidad en servidores Linux, contenedores Docker, Flutter Web/Mobile:
1. **Formato PEM Desacoplado (Recomendado para rendimiento)**:
   - `privateKeyPem` (`-----BEGIN PRIVATE KEY-----`) + `certificatePem` (`-----BEGIN CERTIFICATE-----`).
2. **Formato PKCS#12 (`.pfx` / `.p12`)**:
   - Lector ASN.1 PKCS#12 puro en Dart que extrae el `PrivateKeyInfo` y el `X509Certificate` usando la contraseña del certificado tributario.

---

## 4. Empaquetado ZIP y Lector de CDR (`CpeZipCodec`)

1. **Compresión de Envío (`encodeXmlToZipBase64`)**:
   - Toma el `String xmlContent` codificado en `UTF-8` (o `ISO-8859-1` si se configura para caracteres especiales legacy).
   - Crea una entrada `ArchiveFile('{RUC}-{TIPO}-{SERIE}-{NUMERO}.xml', bytes.length, bytes)`.
   - Comprime con nivel `Deflate` estándar y devuelve `Uint8List` y su representación `String` en Base64 para inyectar en `<contentFile>` (SOAP) o `multipart/form-data` (REST).
2. **Descompresión y Parseo de CDR (`parseCdrZipBytes`)**:
   - Recibe los bytes del archivo `R-{RUC}-{TIPO}-{SERIE}-{NUMERO}.zip` devuelto por el OSE.
   - Busca la entrada `.xml` que comienza con `R-` (ignorando carpetas vacías o archivos `dummy` que algunos OSE agregan).
   - Parsea el XML `<ar:ApplicationResponse>` extrayendo:
     - `<cbc:ID>` -> ID de respuesta.
     - `<cbc:ResponseDate>` y `<cbc:ResponseTime>`.
     - `<cac:DocumentResponse>/<cac:Response>/<cbc:ResponseCode>` -> Código (`"0"`, `"2000"`, etc.).
     - `<cac:DocumentResponse>/<cac:Response>/<cbc:Description>` -> Mensaje oficial.
     - `<cbc:Note>` -> Lista de observaciones (`4000+`) separando código y descripción.
     - `<ds:Reference>/<ds:DigestValue>` -> Hash del comprobante aceptado.
