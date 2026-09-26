# Manual Técnico: sunat_cpe_dart

**Librería Dart para Comprobantes de Pago Electrónico (CPE) SUNAT - Estándar UBL 2.1**  
**Autor y Titular de Derechos:** César A Vergara Buenaventura (<cesarvergarab@gmail.com>)  
**Licencia:** MIT (ver archivo `LICENSE`)  
**Versión:** 0.1.0  
**Fecha de actualización:** 2026-09-26  

---

## 1. Introducción y Objetivos de la Librería

`sunat_cpe_dart` es una biblioteca integral desarrollada en Dart para la modelación, cálculo fiscal, generación XML UBL 2.1, firma digital XML-DSig, compresión ZIP y transmisión electrónica de Comprobantes de Pago Electrónico (CPE) hacia la Superintendencia Nacional de Aduanas y de Administración Tributaria (**SUNAT**, Perú).

### 1.1. Alcance de Comprobantes Soportados
- **Factura Electrónica (Tipo 01)**
- **Boleta de Venta Electrónica (Tipo 03)**
- **Nota de Crédito Electrónica (Tipo 07)**
- **Nota de Débito Electrónica (Tipo 08)**
- **Guía de Remisión Remitente (Tipo 09)** y **Guía de Remisión Transportista (Tipo 31)**
- **Comprobante de Retención Electrónica (Tipo 20)**
- **Comprobante de Percepción Electrónica (Tipo 40)**
- **Resumen Diario de Boletas y Notas (RC)**
- **Comunicación de Baja / Anulación (RA)**

---

## 2. Fundamentación Técnica: Representación Monetaria y Cero Punto Flotante

### 2.1. Problema de la Coma Flotante Binaria (IEEE 754)
Los tipos de coma flotante nativos (`double` en Dart) introducen imprecisiones binarias en operaciones decimales cotidianas (por ejemplo `0.1 + 0.2 = 0.30000000000000004`).

### 2.2. Reglas de Validación de SUNAT y Códigos de Rechazo
La normativa tributaria (RS N.° 097-2012 y RS N.° 340-2017) exige que la suma de valores de venta por ítem, las bases imponibles por tributo y el importe total a pagar cuadren con precisión absoluta de 2 decimales. Una discrepancia de solo `0.01` causa el rechazo inmediato del CPE:
- **Error 2017:** *El valor de venta de la operación debe ser igual a la suma de los valores de venta por ítem*.
- **Error 2019:** *El importe total de la operación es diferente a la suma de los tributos más el valor de venta*.
- **Error 2021:** *El importe del IGV es incorrecto en el ítem o total*.

### 2.3. Solución Implementada: `CPE_Monto` con `Decimal`
Todos los importes monetarios, bases gravadas, tasas y totales se gestionan con la clase `CPE_Monto`, respaldada por el paquete `decimal`, garantizando aritmética decimal exacta en base 10 sin aproximaciones de punto flotante.

---

## 3. Arquitectura Modular del Proyecto

La biblioteca se estructura en capas desacopladas para facilitar el mantenimiento y la adaptación a futuras resoluciones de SUNAT:

```text
lib/
├── sunat_cpe_dart.dart                 # Exportador público de la librería
└── src/
    ├── cpe_emisor_servicio.dart        # Fachada de alto nivel para emisión y consulta
    ├── sunat_cpe_dart_base.dart        # CPE_Monto, CPE_TipoDocumento y cpe_calcular_igv
    ├── config/
    │   ├── cpe_entorno.dart            # Ambientes SUNAT (beta, homologación, producción) y URLs
    │   └── cpe_credenciales.dart       # Credenciales Clave SOL y credenciales REST OAuth2
    ├── catalogos/                      # Catálogos oficiales completos de SUNAT
    │   ├── cpe_catalogo_01_tipo_documento.dart
    │   ├── cpe_catalogo_02_monedas.dart
    │   ├── cpe_catalogo_05_tipo_tributo.dart
    │   ├── cpe_catalogo_06_tipo_documento_identidad.dart
    │   ├── cpe_catalogo_07_afectacion_igv.dart
    │   ├── cpe_catalogo_09_tipo_nota_credito.dart
    │   ├── cpe_catalogo_10_tipo_nota_debito.dart
    │   ├── cpe_catalogo_17_tipo_operacion.dart
    │   ├── cpe_catalogo_18_modalidad_traslado.dart
    │   ├── cpe_catalogo_20_motivo_traslado.dart
    │   └── cpe_catalogos.dart
    ├── modelos/                        # Modelos fuertemente tipados
    │   ├── cpe_contribuyente.dart      # Emisor y receptor
    │   ├── cpe_direccion.dart          # Domicilio fiscal y puntos de partida/llegada
    │   ├── cpe_item.dart               # Línea de detalle con cálculo impositivo
    │   ├── cpe_totales.dart            # Bases imponibles y totales consolidados
    │   ├── cpe_comprobante.dart        # Clase abstracta base
    │   ├── cpe_factura.dart            # Factura (01)
    │   ├── cpe_boleta.dart             # Boleta (03)
    │   ├── cpe_nota_credito.dart       # Nota de Crédito (07)
    │   ├── cpe_nota_debito.dart        # Nota de Débito (08)
    │   ├── cpe_guia_remision.dart      # Guías Remitente (09) y Transportista (31)
    │   ├── cpe_retencion.dart          # Comprobante de Retención (20)
    │   ├── cpe_percepcion.dart         # Comprobante de Percepción (40)
    │   ├── cpe_resumen_diario.dart     # Resumen Diario (RC)
    │   ├── cpe_comunicacion_baja.dart  # Comunicación de Baja (RA)
    │   └── cpe_modelos.dart
    ├── seguridad/                      # Firma digital XML-DSig
    │   ├── cpe_firmador.dart           # Interfaz abstracta y CPE_ResultadoFirma
    │   ├── cpe_firmador_xml.dart       # Implementación W3C XMLDSig UBL 2.1
    │   └── cpe_seguridad.dart
    ├── xml/                            # Constructores UBL 2.1
    │   └── cpe_generador_xml.dart      # Generador de XML conformes a OASIS y SUNAT
    ├── comunicacion/                   # Capa de transporte y conexión SUNAT
    │   ├── cpe_cliente_transporte.dart # Interfaz de transporte común
    │   ├── cpe_cliente_soap.dart       # Cliente SOAP (billService) con WS-Security
    │   ├── cpe_cliente_rest.dart       # Cliente REST con autenticación OAuth2
    │   └── cpe_respuesta_sunat.dart    # Modelo de respuesta y parser de CDR
    └── util/                           # Utilidades de soporte
        ├── cpe_empaquetador_zip.dart   # Compresión ZIP y descompresión de CDR
        └── cpe_validador_ruc.dart      # Algoritmo de validación Módulo 11 de RUC
```

---

## 4. Canales de Comunicación con SUNAT

### 4.1. Canal SOAP Tradicional (`CPE_ClienteSoap`)
- **Protocolo:** SOAP 1.1 sobre HTTPS.
- **Seguridad:** Encabezado WS-Security con `UsernameToken` (`RUC + USUARIO_SOL` y `CLAVE_SOL`).
- **Operaciones:**
  - `sendBill`: Envío sincrónico de Facturas, Boletas y Notas. Retorna el ZIP con el CDR inmediato.
  - `sendSummary`: Envío asíncrono de Resúmenes Diarios (RC) y Comunicaciones de Baja (RA). Retorna un `ticket`.
  - `getStatus`: Consulta de estado del ticket para descargar el CDR definitivo.

### 4.2. Canal REST API Moderno (`CPE_ClienteRest`)
- **Protocolo:** HTTP REST JSON sobre HTTPS con OAuth2.
- **Autenticación:** Token Bearer obtenido vía `POST` a `api-seguridad.sunat.gob.pe` mediante Client ID, Client Secret, RUC, Usuario y Clave SOL.
- **Endpoints:** Usado prioritariamente para la emisión de Guías de Remisión Electrónicas (GRE) en `api-cpe.sunat.gob.pe/v1/contribuyente/gem/comprobantes/`.

### 4.3. Diferenciación de Entornos (`CPE_Entorno`)
- `CPE_Entorno.beta`: Ambiente de pruebas para validar estructura XML sin validez tributaria.
- `CPE_Entorno.homologacion`: Ambiente para pruebas de certificación (PSE/OSE).
- `CPE_Entorno.produccion`: Servidores reales de SUNAT para emisión con validez legal.

---

## 5. Firma Digital XML-DSig y Seguridad

Conforme a la norma técnica peruana y OASIS UBL:
1. El comprobante XML se procesa mediante canonicalización C14N (`http://www.w3.org/TR/2001/REC-xml-c14n-20010315`).
2. Se calcula el resumen criptográfico SHA-256 (`DigestValue`), que a su vez se utiliza para el Hash del comprobante en el código QR.
3. Se firma digitalmente con el algoritmo RSA-SHA256 (`http://www.w3.org/2001/04/xmldsig-more#rsa-sha256`).
4. El bloque `ds:Signature` se inyecta en la primera extensión `ext:UBLExtensions > ext:UBLExtension > ext:ExtensionContent`.
5. La arquitectura permite inyectar certificados X.509 en archivo `.p12`/`.pfx` o delegar la firma a un HSM o servicio externo vía `CPE_Firmador`.

---

## 6. Algoritmo de Validación de RUC (Módulo 11)

Implementado en `CPE_ValidadorRuc`:
1. Verifica longitud exacta de 11 dígitos numéricos y prefijos tributarios válidos (`10`, `15`, `17`, `20`).
2. Aplica factores cíclicos ponderados `[5, 4, 3, 2, 7, 6, 5, 4, 3, 2]` de izquierda a derecha sobre los primeros 10 dígitos.
3. Calcula `residuo = suma % 11`.
4. Determina el dígito verificador: `11 - residuo`. Si el resultado es `11`, el dígito es `0`; si es `10`, el dígito es `1`.
5. Compara con el undécimo dígito del RUC.

---

## 7. Ejemplo de Emisión de Factura Completa

```dart
import 'package:decimal/decimal.dart';
import 'package:sunat_cpe_dart/sunat_cpe_dart.dart';

void main() async {
  final credenciales = const CPE_Credenciales(
    ruc: '20131312955',
    usuarioSol: 'MODDATOS',
    claveSol: 'moddatos',
    entorno: CPE_Entorno.beta,
  );

  final emisor = CPE_Contribuyente.emisorRuc(
    ruc: credenciales.ruc,
    razonSocial: 'MI EMPRESA S.A.C.',
  );

  final receptor = const CPE_Contribuyente(
    numeroDocumento: '20100047218',
    tipoDocumento: CPE_Catalogo06_TipoDocumentoIdentidad.ruc,
    razonSocial: 'CLIENTE S.A.',
  );

  final item = CPE_Item.calcularDesdeValorUnitario(
    numeroLinea: 1,
    codigo: 'P001',
    descripcion: 'Servicio Cloud',
    cantidad: Decimal.one,
    valorUnitario: CPE_Monto.desdeTexto('100.00'),
  );

  final totales = CPE_Totales.calcularDesdeItems([item]);

  final factura = CPE_Factura(
    serie: 'F001',
    correlativo: 1,
    fechaEmision: DateTime.now(),
    emisor: emisor,
    receptor: receptor,
    moneda: CPE_Catalogo02_Moneda.sol,
    items: [item],
    totales: totales,
  );

  final servicio = CPE_EmisorServicio(credenciales: credenciales);
  final respuesta = await servicio.emitirFactura(factura);

  if (respuesta.esAceptado) {
    print('Factura aceptada por SUNAT: ${respuesta.mensaje}');
    print('Hash CDR: ${respuesta.hashCdr}');
  }
}
```

---

## 8. Verificación y Calidad

```bash
dart analyze
dart test
dart format .
```
Resultados actuales:
- `dart analyze`: Cero advertencias o errores.
- `dart test`: 15 pruebas unitarias e integrales aprobadas al 100%.
