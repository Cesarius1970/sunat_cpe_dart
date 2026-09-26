# sunat_cpe_dart

[![Licencia MIT](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)
[![Dart SDK](https://img.shields.io/badge/Dart-^3.13.4-0175C2.svg?logo=dart)](https://dart.dev)
[![SUNAT UBL](https://img.shields.io/badge/SUNAT-UBL%202.1-red.svg)](https://cpe.sunat.gob.pe)

Librería Dart pura para la construcción, validación, firma digital (XML-DSig), empaquetado ZIP y emisión de **Comprobantes de Pago Electrónico (CPE)** bajo la normativa de la **SUNAT** (Perú) y el estándar internacional **UBL 2.1**.

Repositorio oficial: [https://github.com/Cesarius1970/sunat_cpe_dart](https://github.com/Cesarius1970/sunat_cpe_dart)

---

## Características Principales

- **Cálculo Monetario Exacto (Cero Punto Flotante):**  
  Implementación estricta con `CPE_Monto` (`package:decimal`), eliminando errores de redondeo IEEE 754 y evitando rechazos de SUNAT por descuadres de céntimos (Errores 2017, 2019, 2021).
- **Tipos de Comprobantes Completos:**
  - Factura Electrónica (01)
  - Boleta de Venta Electrónica (03)
  - Nota de Crédito Electrónica (07)
  - Nota de Débito Electrónica (08)
  - Guía de Remisión Remitente (09) y Transportista (31)
  - Comprobante de Retención (20) y Percepción (40)
  - Resumen Diario de Boletas y Notas (RC)
  - Comunicación de Baja de Comprobantes (RA)
- **Catálogos Oficiales de SUNAT:**  
  Catálogos 01, 02, 05, 06, 07, 09, 10, 17, 18 y 20 completamente declarados y fuertemente tipados.
- **Doble Canal de Comunicación:**
  - **Canal SOAP (`CPE_ClienteSoap`):** Integración con WS-Security (`UsernameToken`) para `sendBill`, `sendSummary` y `getStatus`.
  - **Canal REST (`CPE_ClienteRest`):** Autenticación OAuth2 para Guías de Remisión Electrónicas (GRE) en `api-cpe.sunat.gob.pe`.
- **Diferenciación de Entornos:**  
  Soporte configurable para `CPE_Entorno.beta` (pruebas), `CPE_Entorno.homologacion` y `CPE_Entorno.produccion`.
- **Firma Digital XML-DSig:**  
  Canonicalización C14N, Digest SHA-256 (Hash QR) y firma RSA-SHA256 desacoplada vía `CPE_Firmador`.
- **Empaquetado y Lectura de CDR:**  
  Generación de ZIP `{RUC}-{TIPO}-{SERIE}-{CORRELATIVO}.zip` y descompresión / análisis automático de Constancias de Recepción (`R-*.xml`).
- **Validador de RUC:**  
  Algoritmo nativo de verificación mediante Módulo 11 con ponderadores oficiales SUNAT.

---

## Instalación

En tu archivo `pubspec.yaml`:

```yaml
dependencies:
  sunat_cpe_dart:
    git:
      url: https://github.com/Cesarius1970/sunat_cpe_dart.git
      ref: main
```

O instala dependencias:

```bash
dart pub get
```

---

## Ejemplo Rápido de Uso

```dart
import 'package:decimal/decimal.dart';
import 'package:sunat_cpe_dart/sunat_cpe_dart.dart';

void main() async {
  // 1. Configurar credenciales (Entorno de pruebas Beta)
  final credenciales = const CPE_Credenciales(
    ruc: '20131312955',
    usuarioSol: 'MODDATOS',
    claveSol: 'moddatos',
    entorno: CPE_Entorno.beta,
  );

  // 2. Definir emisor y receptor
  final emisor = CPE_Contribuyente.emisorRuc(
    ruc: credenciales.ruc,
    razonSocial: 'MI EMPRESA S.A.C.',
    direccion: const CPE_Direccion(
      direccion: 'AV. JAVIER PRADO ESTE 1234',
      ubigeo: '150140',
    ),
  );

  final receptor = const CPE_Contribuyente(
    numeroDocumento: '20100047218',
    tipoDocumento: CPE_Catalogo06_TipoDocumentoIdentidad.ruc,
    razonSocial: 'CLIENTE EMPRESARIAL S.A.',
  );

  // 3. Crear ítem con cálculo impositivo exacto
  final item = CPE_Item.calcularDesdeValorUnitario(
    numeroLinea: 1,
    codigo: 'SRV-01',
    descripcion: 'Servicio de Consultoría de Software',
    cantidad: Decimal.one,
    valorUnitario: CPE_Monto.desdeTexto('1000.00'),
    afectacion: CPE_Catalogo07_AfectacionIgv.gravadoOperacionOnerosa,
  );

  final totales = CPE_Totales.calcularDesdeItems([item]);

  // 4. Armar Factura Electrónica
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

  // 5. Emitir ante SUNAT mediante la fachada de alto nivel
  final servicio = CPE_EmisorServicio(credenciales: credenciales);
  final respuesta = await servicio.emitirFactura(factura);

  if (respuesta.esAceptado) {
    print('Comprobante aceptado por SUNAT: ${respuesta.mensaje}');
    print('Hash CDR: ${respuesta.hashCdr}');
  } else {
    print('Error reportado: ${respuesta.mensaje} (Código: ${respuesta.codigoRespuesta})');
  }
}
```

---

## Documentación del Proyecto

- [Manual Técnico Detallado](doc/MANUAL_TECNICO.md) - Arquitectura, protocolos, algoritmos y catálogos.
- [Reglas y Gobernanza del Proyecto](doc/REGLAS_PROYECTO.md) - Estándares de Git, código y nomenclatura.
- [Histórico de Prompts](doc/prompts/HISTORICO_PROMPTS.md) - Registro cronológico y secuencial de interacciones.
- [Registro de Cambios (CHANGELOG)](CHANGELOG.md) - Versiones y notas de lanzamiento.

---

## Licencia y Derechos de Autor

Copyright (c) 2026 **César A Vergara Buenaventura** (<cesarvergarab@gmail.com>).  
Distribuido bajo los términos de la Licencia MIT. Consulta el archivo [LICENSE](LICENSE) para más información.
