# Histórico de Prompts e Interacciones

Registro secuencial y numerado de solicitudes, directivas y respuestas del asistente para el proyecto `sunat_cpe_dart`.

---

## Interacción #001
- **Fecha y Hora:** 2026-09-26 08:43:15 -05:00
- **Usuario:**
  ```text
  /caveman
  ```
- **Asistente:**
  ```text
  Ready. What task?
  ```
- **Contexto y Resultado:** Activación del modo de comunicación concisa y técnica (caveman).

---

## Interacción #002
- **Fecha y Hora:** 2026-09-26 08:43:24 -05:00
- **Usuario:**
  ```text
  /karpathy-guidelines
  ```
- **Asistente:**
  ```text
  Understood. Karpathy rules active:

  1. Think first: state assumptions, ask when unclear.
  2. Simple code: minimum needed, zero speculation.
  3. Surgical edits: touch only required lines.
  4. Goal-driven: clear verification step for every change.

  What task we tackle?
  ```
- **Contexto y Resultado:** Adopción de directrices de desarrollo de software rigurosas, simples y de cambios quirúrgicos basadas en principios de Andrej Karpathy.

---

## Interacción #003
- **Fecha y Hora:** 2026-09-26 08:43:30 -05:00
- **Usuario:**
  ```text
  Pon como regla que debe generarse un commit al finalizar cada fase o interacción con el agente. Usar los estándares de git para nombrar los commit y las ramas

  Genera una carpeta "docs\prompts" y guarda en ella un histórico de los prompts (HISTORICO_PROMPTS.md) y solicitudes así como tus respuestas, de manera numerada y secuencializada. Mantén actualizada esta carpeta con la interacción que se genere respecto a este proyecto

  Modifica pubspec.yaml y añade descripciones y campos obligatorios. Crea la documentación necesaria para el copyright de esta librería a nombre de "César A Vergara Buenaventura" cesarvergarab@gmail.com. Sigue obligatoriamente el estándar del equipo de desarrollo de Dart y Flutter. Modifica o crea los archivos que sean necesarios.

  Genera comentarios pertinentes en los archivos y algoritmos de manera de generar un manual técnico en “docs\MANUAL_TECNICO.md”. Mantén actualizado este documento

  Pon como regla que debe usarse el idioma español y se debe usar el prefijo "CPE_" o "cpe_" según corresponda en la nomenclatura de objetos, siempre y cuando no colisione o altere la gestión con el API de SUNAT.

  Pon como regla que no se puede usar decimales de punto flotante para calcular o almacenar valores de moneda. Analizar la declaración de la API SUNAT para respaldar o ignorar esta regla.
  ```
- **Asistente:**
  - Se establecieron y documentaron las reglas de desarrollo y gobernanza del proyecto (`docs/REGLAS_PROYECTO.md`).
  - Se creó la carpeta `docs/prompts/` y este archivo `HISTORICO_PROMPTS.md`.
  - Se actualizó `pubspec.yaml` según los lineamientos de pub.dev y Dart team.
  - Se crearon los archivos de copyright y autoría: `LICENSE` (MIT a nombre de César A Vergara Buenaventura) y `AUTHORS`.
  - Se analizó técnicamente la normativa SUNAT UBL 2.1 respecto a tipos numéricos para importes y tributos: se confirmó y respaldó la regla de prohibir `double` (IEEE 754) e implementar precisión exacta usando `package:decimal`.
  - Se elaboró el manual técnico de arquitectura y algoritmos en `docs/MANUAL_TECNICO.md`.
  - Se documentaron en el código base inicial las convenciones de prefijos `CPE_` / `cpe_`, tipos monetarios y comentarios en español bajo formato dartdoc.
  - Se generó el commit Git estándar correspondiente al cierre de la interacción.

---

## Interacción #004
- **Fecha y Hora:** 2026-09-26 08:54:06 -05:00
- **Usuario:**
  ```text
  /GRILL-ME Analiza la web "https://cpe.sunat.gob.pe/". Implementa esta librería de manera que permita generar e interactuar (enviar documentos y recibir notificaciones, tanto en producción como en pruebas, diferencia por entorno ) según lo declarado en esa web. Limita el desarrollo e investigacion a CPE, NO planifiques ni desarrolles para SIRE u otros AOI SUNAT similares. Estructura los módulos que debe tener esta librería para implementar la generación de CPE según el estándar de la SUNAT. Prepara las declaraciones e interfaces de manera que sea fácil el implementar futuros cambios que la SUNAT publique. Emplea el mayor detalle en esta generación, emplea la mayor fidelidad con el API de SUNAT e implementa los catálogos en su totalidad con la mayor cantidad de datos declarados.
  ```
- **Alineación de Diseño (Grill-Me):**
  - **Pregunta 1:** Protocolo de comunicación (SOAP vs REST OAuth2 vs Arquitectura Híbrida).
    - *Respuesta acordada:* Arquitectura híbrida desacoplada: soporte de SOAP (WS-Security para Facturas/Boletas) y API REST (OAuth2 para Guías de Remisión/nuevo estándar) bajo interfaz común `CPE_ClienteTransporte`.
  - **Pregunta 2:** Mecanismo de firma digital XMLDSig y Certificados.
    - *Respuesta acordada:* Interfaz `CPE_Firmador` extensible con implementación nativa Dart (PKCS#12 .pfx/.p12 + XMLDSig) y opción de firmador externo/delegado.
  - **Pregunta 3:** Tipos de comprobantes a modelar en esta fase.
    - *Respuesta acordada:* Factura (01), Boleta (03), Notas de Crédito (07) y Débito (08), Guías Remitente (09) y Transportista (31), Resumen Diario (RC), Comunicación de Baja (RA), Retenciones (20) y Percepciones (40).
- **Asistente (Implementación):**
  - Se implementó la capa de configuración con diferenciación de entornos (`CPE_Entorno`: Beta, Homologación, Producción) y credenciales SOL/REST (`CPE_Credenciales`).
  - Se implementaron los catálogos oficiales completos de SUNAT (01, 02, 05, 06, 07, 09, 10, 17, 18, 20).
  - Se estructuraron los modelos de datos fuertemente tipados con soporte estricto de `CPE_Monto` (`package:decimal` sin punto flotante): `CPE_Item`, `CPE_Totales`, `CPE_Contribuyente`, `CPE_Direccion`, `CPE_Factura`, `CPE_Boleta`, `CPE_NotaCredito`, `CPE_NotaDebito`, `CPE_GuiaRemision`, `CPE_Retencion`, `CPE_Percepcion`, `CPE_ResumenDiario`, `CPE_ComunicacionBaja`.
  - Se diseñó la interfaz de firma `CPE_Firmador` e implementación `CPE_FirmadorXml` conforme al estándar W3C XMLDSig (C14N, Digest SHA-256, SignatureValue RSA-SHA256).
  - Se construyó el generador XML `CPE_GeneradorXml` para estructuras OASIS UBL 2.1 e interoperabilidad SUNAT.
  - Se creó la capa de transporte con interfaz común `CPE_ClienteTransporte`, cliente SOAP `CPE_ClienteSoap` (con WS-Security para `sendBill`, `sendSummary`, `getStatus`), cliente REST `CPE_ClienteRest` (con autenticación OAuth2 para Guías de Remisión) y modelo `CPE_RespuestaSunat` con parser automático de CDR.
  - Se implementó la fachada de alto nivel `CPE_EmisorServicio` para orquestar la generación, firma, empaquetado y emisión.
  - Se implementaron utilidades de compresión ZIP (`CPE_EmpaquetadorZip`) y validación de RUC por módulo 11 (`CPE_ValidadorRuc`).
  - Se actualizó el manual técnico en `docs/MANUAL_TECNICO.md`.
  - Se implementó suite de pruebas con 15 pruebas unitarias e integrales aprobadas al 100%.
  - Se generó el commit Git estándar al cierre de la interacción.

---

## Interacción #005
- **Fecha y Hora:** 2026-09-26 09:09:09 -05:00
- **Usuario:**
  ```text
  Refactoriza los documentos y enlaza el git con https://github.com/Cesarius1970/sunat_cpe_dart
  ```
- **Asistente:**
  - Se verificó y configuró el remoto Git `origin` apuntando a `https://github.com/Cesarius1970/sunat_cpe_dart.git`.
  - Se refactorizó exhaustivamente el archivo `README.md` incorporando insignias oficiales, descripción completa de características, instalación vía Git, ejemplo rápido de uso con `CPE_EmisorServicio` y enlaces a la documentación.
  - Se actualizó el encabezado de `docs/MANUAL_TECNICO.md` con el enlace al repositorio oficial.
  - Se incorporó la sección 6 en `docs/REGLAS_PROYECTO.md` formalizando la URL oficial del repositorio y la rama de seguimiento `main`.
  - Se actualizó el `CHANGELOG.md` detallando las capacidades de la versión 0.1.0 y el enlace del repositorio.
  - Se verificó la consistencia en `pubspec.yaml` (`homepage`, `repository`, `issue_tracker`, `documentation`).
  - Se validó el proyecto con `dart analyze` y `dart test`.
  - Se generó el commit Git estándar al cierre de la interacción.

---

## Interacción #006
- **Fecha/Hora:** 2026-09-26
- **Solicitud del Usuario:**
  > "Refactorizar las funciones que interactuen con la API en el envio/recepcion y que necesiten un certificado digital. Estas funciones deben pedir como parametro el certificado digital desde el llamador. SOLO usar un certificado mock en ambientes de “Pruebas”"
- **Acciones Realizadas:**
  - Se creó la clase `CPE_CertificadoDigital` en `lib/src/seguridad/cpe_firmador.dart` con soporte para X.509 Base64, clave privada PEM, contraseña PKCS#12, función de firma RSA y discriminador `esMock`.
  - Se actualizó el contrato `CPE_Firmador` y la implementación `CPE_FirmadorXml` para requerir el certificado digital de forma obligatoria en cada invocación de firma (`firmarXml(xml, certificado: cert)`).
  - Se refactorizó la fachada principal `CPE_EmisorServicio` (`lib/src/cpe_emisor_servicio.dart`), incorporando validación centralizada mediante `_resolverCertificado()`:
    - En ambientes de `produccion` y `homologacion`, se exige estrictamente un certificado digital válido no-mock; el intento de usar un mock o no proveer certificado lanza un `ArgumentError`.
    - En ambiente de pruebas (`beta`), se permite el uso de certificados mock (`CPE_CertificadoDigital.mockPruebas()`) o su resolución por omisión.
    - Se agregaron parámetros `{CPE_CertificadoDigital? certificado}` a todos los métodos de emisión: `emitirFactura`, `emitirBoleta`, `emitirNotaCredito`, `emitirNotaDebito`, `emitirGuiaRemision`, `emitirResumenDiario` y `emitirComunicacionBaja`.
  - Se actualizaron las pruebas unitarias en `test/sunat_cpe_dart_test.dart` con cobertura completa para:
    1. Emisión en Beta con mock por omisión.
    2. Emisión en Beta con mock explícito.
    3. Emisión en Producción sin certificado (falla con `ArgumentError`).
    4. Emisión en Producción con certificado mock (falla con `ArgumentError`).
    5. Emisión en Producción con certificado real (éxito).
  - Se actualizó `example/sunat_cpe_dart_example.dart` y la documentación técnica en `docs/MANUAL_TECNICO.md`.
  - Se validó la suite con `dart analyze` (0 errores) y `dart test` (17 pruebas aprobadas).
  - Se generó el commit Git correspondiente al cierre de la fase.

