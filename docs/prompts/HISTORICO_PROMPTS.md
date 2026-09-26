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
