---
title: "Proveedor 08: TCI - Transporte Confidencial de Información (OSE / PSE)"
aliases:
  - "TCI"
  - "Efacturación"
  - "sunat_cpe_tci"
tags:
  - sunat
  - cpe
  - proveedor
  - ose
  - pse
  - soap
  - ubl21
  - tci
type: provider-spec
package: sunat_cpe_tci
protocol: SOAP 1.1 WS-Security + REST
status: planned
updated: 2026-11-04
---

# Análisis de Proveedor 08: TCI - Transporte Confidencial de Información / Efacturación (OSE / PSE)

> [!NOTE] Navegación del Vault
> [[README|🏠 Índice Principal]] · **Anterior**: [[providers/07_facturaloperu|← Proveedor 07: FacturaloPeru / PRO]] · **Siguiente**: [[providers/09_cavali_gosocket|Proveedor 09: Cavali / Gosocket →]]
> **Base Core**: [[core/01_architecture_and_patterns#2. Patrones de Diseño Aplicados|`BaseUblOseProvider`]] · [[core/03_validation_and_ubl_signing|Motor UBL 2.1 y Firma XAdES-BES]]
> **Enlaces Externos**: [Portal Oficial TCI](https://www.tci.net.pe/) · [Paquete en Monorepo GitHub](https://github.com/Cesarius1970/sunat_cpe/tree/main/packages/sunat_cpe_tci)

Especificación técnica para el paquete `packages/sunat_cpe_tci` que extiende [`BaseUblOseProvider`](../../packages/sunat_cpe_core/lib/src/providers/base_ubl_ose_provider.dart) e implementa [[core/01_architecture_and_patterns#5. Contrato Principal `OseProvider` y Capacidades Modulares|`OseProvider`]].

---

## 1. Perfil Técnico del Proveedor

- **Rol en SUNAT**: OSE y PSE histórico en el Perú (*Transporte Confidencial de Información S.A. - TCI*, plataforma *e-facturación*), con fuerte presencia en aduanas, operadores logísticos, agroindustria y grandes empresas.
- **Modos de Integración Soportados por `sunat_cpe_tci`**:
  1. **Modo OSE Estándar (SOAP 1.1 `billService` con WS-Security)**:
     - Recibe el archivo `.zip` con el XML UBL 2.1 firmado localmente ([[core/03_validation_and_ubl_signing#3. Firmador Digital XAdES-BES en Dart Puro (`XadesBesSigner`)|`XadesBesSigner`]]) y retorna el CDR `R-*.zip` firmado por TCI OSE.
  2. **Modo PSE / Portal e-facturación TCI (Web Service Propietario / REST)**:
     - Permite el envío de documentos electrónicos para firma centralizada en TCI y generación de PDF corporativo.

---

## 2. Endpoints Oficiales de TCI OSE

| Entorno | Servicio | URL |
|---------|----------|-----|
| **Producción** | SOAP 1.1 OSE | `https://ose.tci.net.pe/ol-ti-itcpe/billService` |
| **Homologación / Test** | SOAP 1.1 OSE | `https://osetest.tci.net.pe/ol-ti-itcpe/billService` |

---

## 3. Particularidades Técnicas de TCI OSE

1. **Autenticación WS-Security Estricta (`UsernameToken`)**:
   - El nodo `<wsse:Username>` sigue el formato `{RUC}{USUARIO_OSE_TCI}` (11 dígitos de RUC seguidos del usuario habilitado en el portal OSE de TCI).
   - Requiere el atributo `Type="http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-username-token-profile-1.0#PasswordText"` explícito en `<wsse:Password>`.
2. **Soporte Completo de Guías de Remisión (`09` y `31`) y Liquidación de Compra (`04`)**:
   - Dada la alta presencia de TCI en el sector agroindustrial y logístico/aduanero, `sunat_cpe_tci` valida y soporta de primera clase (ver [[core/02_domain_entities_and_types#3. Jerarquía de Entidades de Dominio (`CpeDocument`)|Entidades de Dominio]]):
     - **Liquidación de Compra Electrónica (`04` - `PurchaseSettlementDocument`)** bajo UBL 2.1 (incluyendo datos del vendedor persona natural sin RUC, ubicación geográfica de la operación `DeliveryTerms` y retenciones de renta/IGV si aplican).
     - **Guías de Remisión Remitente (`09`) y Transportista (`31` - `DespatchAdviceDocument`)** con datos de comercio exterior (DAM / DS, puerto/aeropuerto, contenedor y precinto).
3. **Estructura de `<soap:Fault>` en TCI**:
   - Cuando existe una Excepción o Rechazo sin generación de CDR, TCI devuelve:
     ```xml
     <soap-env:Fault>
       <faultcode>soap-env:Client.2800</faultcode>
       <faultstring>El dato ingresado en el tipo de documento de identidad del receptor no esta permitido</faultstring>
       <detail>
         <message>Detalle adicional TCI OSE</message>
       </detail>
     </soap-env:Fault>
     ```
   - `TciSoapFaultParser` extrae el código numérico tras el sufijo `.` en `faultcode` (`2800` -> [[core/01_architecture_and_patterns#Jerarquía de Excepciones (`CpeException`)|`SunatRejectionException`]]) y el mensaje descriptivo en `faultstring`.

---

## 4. Diseño de Clases del Paquete `sunat_cpe_tci`

```text
packages/sunat_cpe_tci/
├── lib/
│   ├── sunat_cpe_tci.dart
│   └── src/
│       ├── tci_config.dart               # environment, ruc, oseUser, osePassword, certificateCredentials
│       ├── tci_provider.dart             # Extiende BaseUblOseProvider e implementa OseProvider
│       └── soap/
│           └── tci_soap_fault_parser.dart # Extracción de códigos Client.XXXX y Server.XXXX
```

---

> [!TIP] Navegación de Proveedores
> - [[README|🏠 Índice Principal]]
> - **Anterior**: [[providers/07_facturaloperu|← Proveedor 07: FacturaloPeru / PRO]]
> - **Siguiente**: [[providers/09_cavali_gosocket|Proveedor 09: Cavali / Gosocket →]]
> - **Relacionados (SOAP UBL)**: [[providers/04_bizlinks|04. Bizlinks]] · [[providers/05_digiflow|05. Digiflow]]
