# Registro de Cambios (CHANGELOG)

Todas las modificaciones notables a este proyecto serán documentadas en este archivo.

## 0.1.0 - 2026-09-26

### Añadido
- Configuración inicial del paquete conforme a lineamientos de pub.dev y Dart team.
- Documentación de autoría, derechos y licencia MIT a nombre de César A Vergara Buenaventura.
- Regla y arquitectura de precisión decimal estricta (`CPE_Monto`) con `package:decimal` para evitar errores de redondeo de punto flotante en cálculos SUNAT UBL 2.1.
- Catálogo 01 de tipos de comprobante (`CPE_TipoDocumento`).
- Función de cálculo impositivo para IGV (`cpe_calcular_igv`).
- Manual Técnico en `docs/MANUAL_TECNICO.md`.
- Reglas de gobernanza y Git en `docs/REGLAS_PROYECTO.md`.
- Histórico cronológico de prompts en `docs/prompts/HISTORICO_PROMPTS.md`.
