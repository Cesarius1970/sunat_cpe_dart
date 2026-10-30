# Análisis de Proveedor 06: Sovos / Paperless (OSE / PSE)

Especificación técnica para el paquete `packages/sunat_cpe_sovos`.

---

## 1. Perfil Técnico del Proveedor

- **Rol en SUNAT**: OSE y PSE multinacional (anteriormente *Paperless Perú*, adquirido por *Sovos Compliance*), ampliamente utilizado por grandes cadenas de retail, banca y corporaciones regionales (SAP / Oracle ERP).
- **Modos de Integración Soportados por `sunat_cpe_sovos`**:
  1. **Modo OSE Estándar (SOAP 1.1 `billService`)**:
     - Recibe el archivo `.zip` con el XML UBL 2.1 firmado localmente (`XadesBesSigner`) mediante WS-Security `<wsse:UsernameToken>`.
  2. **Modo PSE / Sovos Online (`OnlineGeneration` SOAP / REST)**:
     - Recibe el documento UBL sin firma (o estructura intermedia) y Sovos aplica la firma digital mediante sus propios HSM en la nube, genera la representación impresa PDF con plantilla personalizada y despacha al OSE/SUNAT.

---

## 2. Endpoints Oficiales de Sovos / Paperless

| Entorno | Modalidad | URL |
|---------|-----------|-----|
| **Producción** | SOAP 1.1 OSE | `https://ose.sovos.com.pe/ol-ti-itcpe/billService` (o endpoint corporativo dedicado `*.paperless.com.pe`) |
| **Certificación / QA** | SOAP 1.1 OSE | `https://ose-cert.sovos.com.pe/ol-ti-itcpe/billService` |

---

## 3. Particularidades Técnicas de Sovos / Paperless

1. **Extensiones de Impresión y Campos Personalizados (`AdditionalInformation` / `CustomFields`)**:
   - En implementaciones retail y corporativas con Sovos, el generador de PDF de Sovos lee nodos adicionales dentro de `<ext:UBLExtensions>` o `<cbc:Note>` para imprimir datos comerciales (cajero, sucursal, puntos acumulados, orden de compra, centro de costo).
   - `sunat_cpe_sovos` permite pasar un `Map<String, String> customPrintFields` en `SovosMetadata` que se inyecta en un segundo `<ext:UBLExtension>` sin invalidar la firma XAdES-BES ni el esquema XSD de SUNAT.
2. **Idempotencia en Reintentos de Red (`Documento Previamente Declarado`)**:
   - Cuando ocurre un corte de red tras enviar un comprobante y el ERP reintenta el envío del mismo correlativo, Sovos responde con el código `2017` / `1033` o un código específico de documento duplicado.
   - `sunat_cpe_sovos` incluye la opción `autoRecoverCdrOnDuplicate: true`: si detecta que el comprobante ya fue registrado previamente por el mismo emisor, invoca automáticamente `getStatusCdr` para devolver el CDR original como `CpeSuccess` en lugar de fallar.

---

## 4. Diseño de Clases del Paquete `sunat_cpe_sovos`

```text
packages/sunat_cpe_sovos/
├── lib/
│   ├── sunat_cpe_sovos.dart
│   └── src/
│       ├── sovos_config.dart             # baseUrl, username, password, mode (oseUblSigned, pseCloudSign), autoRecoverCdrOnDuplicate
│       ├── sovos_provider.dart           # Implementa OseProvider
│       ├── ubl/
│       │   └── sovos_ubl_extension_builder.dart # Inyección de nodos adicionales para PDF corporativo Paperless
│       └── soap/
│           └── sovos_soap_delegate.dart  # Cliente SOAP billService + recuperación automática de CDR
```
