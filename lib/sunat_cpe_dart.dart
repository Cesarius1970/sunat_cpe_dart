// Copyright (c) 2026, César A Vergara Buenaventura <cesarvergarab@gmail.com>.
// Todos los derechos reservados. Uso sujeto a la licencia en el archivo LICENSE.

/// Librería Dart para la emisión, validación y gestión de Comprobantes de Pago
/// Electrónico (CPE) conforme a la normativa SUNAT y al estándar UBL 2.1.
library;

// Clases base y montos decimales
export 'src/sunat_cpe_dart_base.dart';

// Configuración y credenciales
export 'src/config/cpe_credenciales.dart';
export 'src/config/cpe_entorno.dart';

// Catálogos oficiales SUNAT
export 'src/catalogos/cpe_catalogos.dart';

// Modelos de comprobantes y entidades
export 'src/modelos/cpe_modelos.dart';

// Seguridad y firma XML-DSig
export 'src/seguridad/cpe_seguridad.dart';

// Generador de XML UBL 2.1
export 'src/xml/cpe_generador_xml.dart';

// Capa de comunicación (SOAP y REST)
export 'src/comunicacion/cpe_cliente_rest.dart';
export 'src/comunicacion/cpe_cliente_soap.dart';
export 'src/comunicacion/cpe_cliente_transporte.dart';
export 'src/comunicacion/cpe_respuesta_sunat.dart';

// Fachada principal de emisión
export 'src/cpe_emisor_servicio.dart';

// Utilidades
export 'src/util/cpe_empaquetador_zip.dart';
export 'src/util/cpe_validador_ruc.dart';
