# Registro de Cambios (CHANGELOG)

Todas las modificaciones notables a este proyecto serán documentadas en este archivo.

## 0.1.0 - 2026-09-26

### Añadido
- Configuración inicial del paquete conforme a lineamientos de pub.dev y Dart team.
- Documentación de autoría, derechos y licencia MIT a nombre de César A Vergara Buenaventura.
- Repositorio oficial enlazado: `https://github.com/Cesarius1970/sunat_cpe_dart`.
- Regla y arquitectura de precisión decimal estricta (`CPE_Monto`) con `package:decimal` para evitar errores de redondeo de punto flotante en cálculos SUNAT UBL 2.1.
- Catálogos oficiales completos de SUNAT: 01, 02, 05, 06, 07, 09, 10, 17, 18, 20.
- Modelos fuertemente tipados: Factura (01), Boleta (03), Nota de Crédito (07), Nota de Débito (08), Guías Remitente (09) y Transportista (31), Retención (20), Percepción (40), Resumen Diario (RC) y Comunicación de Baja (RA).
- Firma digital W3C XML-DSig con canonicalización C14N, Digest SHA-256 e inyección en `UBLExtensions`.
- Generador XML UBL 2.1 oficial (`CPE_GeneradorXml`).
- Capa de comunicación híbrida: SOAP con WS-Security (`CPE_ClienteSoap`) y REST OAuth2 (`CPE_ClienteRest`).
- Fachada integral de emisión y consulta `CPE_EmisorServicio`.
- Utilidades: compresión ZIP y parser de CDR (`CPE_EmpaquetadorZip`), validación de RUC Módulo 11 (`CPE_ValidadorRuc`).
- Manual Técnico en `docs/MANUAL_TECNICO.md`.
- Reglas de gobernanza y Git en `docs/REGLAS_PROYECTO.md`.
- Histórico cronológico de prompts en `docs/prompts/HISTORICO_PROMPTS.md`.
