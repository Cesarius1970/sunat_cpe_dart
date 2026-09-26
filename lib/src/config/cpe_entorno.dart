// Copyright (c) 2026, César A Vergara Buenaventura <cesarvergarab@gmail.com>.
// Todos los derechos reservados. Uso sujeto a la licencia en el archivo LICENSE.

/// Entornos de operación disponibles para interactuar con la SUNAT.
enum CPE_Entorno {
  /// Entorno de pruebas o Beta de SUNAT para validar estructura de comprobantes.
  beta,

  /// Entorno de homologación (empleado principalmente por PSE / OSE).
  homologacion,

  /// Entorno de producción real de SUNAT.
  produccion;

  /// Retorna la URL del Web Service SOAP para Facturas, Boletas y Notas asociadas.
  String get urlSoapFactura => switch (this) {
    CPE_Entorno.beta =>
      'https://e-beta.sunat.gob.pe/ol-ti-itcpfegem-beta/billService',
    CPE_Entorno.homologacion =>
      'https://www.sunat.gob.pe/ol-ti-itcpgem-sqa/billService',
    CPE_Entorno.produccion =>
      'https://e-factura.sunat.gob.pe/ol-ti-itcpfegem/billService',
  };

  /// Retorna la URL del Web Service SOAP para Guías de Remisión Electrónicas (UBL 2.1 clásico).
  String get urlSoapGuiaRemision => switch (this) {
    CPE_Entorno.beta =>
      'https://e-beta.sunat.gob.pe/ol-ti-itemision-guia-gem-beta/billService',
    CPE_Entorno.homologacion =>
      'https://www.sunat.gob.pe/ol-ti-itemision-guia-gem-sqa/billService',
    CPE_Entorno.produccion => 'https://e-guiaremision.sunat.gob.pe/ol-ti-itemision-guia-gem/billService',
  };

  /// Retorna la URL del Web Service SOAP para Retenciones y Percepciones.
  String get urlSoapOtrosCpe => switch (this) {
    CPE_Entorno.beta => 'https://e-beta.sunat.gob.pe/ol-ti-itemision-otroscpe-gem-beta/billService',
    CPE_Entorno.homologacion =>
      'https://www.sunat.gob.pe/ol-ti-itemision-otroscpe-gem-sqa/billService',
    CPE_Entorno.produccion =>
      'https://e-factura.sunat.gob.pe/ol-ti-itemision-otroscpe-gem/billService',
  };

  /// Endpoint OAuth2 de SUNAT para generar token de seguridad (REST API).
  String urlRestToken(String clientId) => switch (this) {
    CPE_Entorno.beta =>
      'https://api-seguridad.sunat.gob.pe/v1/clientessol/$clientId/oauth2/token',
    CPE_Entorno.homologacion =>
      'https://api-seguridad.sunat.gob.pe/v1/clientessol/$clientId/oauth2/token',
    CPE_Entorno.produccion =>
      'https://api-seguridad.sunat.gob.pe/v1/clientessol/$clientId/oauth2/token',
  };

  /// URL base de la API REST de comprobantes y guías de remisión (GRE).
  String get urlRestApiBase => switch (this) {
    CPE_Entorno.beta => 'https://api-cpe.sunat.gob.pe/v1/contribuyente/gem',
    CPE_Entorno.homologacion =>
      'https://api-cpe.sunat.gob.pe/v1/contribuyente/gem',
    CPE_Entorno.produccion =>
      'https://api-cpe.sunat.gob.pe/v1/contribuyente/gem',
  };
}
