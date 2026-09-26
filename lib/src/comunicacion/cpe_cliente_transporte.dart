// Copyright (c) 2026, César A Vergara Buenaventura <cesarvergarab@gmail.com>.
// Todos los derechos reservados. Uso sujeto a la licencia en el archivo LICENSE.

import 'cpe_respuesta_sunat.dart';

/// Interfaz abstracta común para el envío y consulta de comprobantes ante SUNAT.
///
/// Permite intercambiar de forma transparente la capa de transporte:
/// - SOAP (WS-Security para Facturas, Boletas, Notas y Resúmenes).
/// - REST (OAuth2 para Guías de Remisión y API CPE moderna).
abstract class CPE_ClienteTransporte {
  /// Envía un comprobante electrónico empaquetado en archivo ZIP.
  ///
  /// [nombreArchivoZip]: Nombre oficial según norma `{RUC}-{TIPO}-{SERIE}-{CORRELATIVO}.zip`.
  /// [bytesZip]: Bytes binarios del archivo comprimido.
  Future<CPE_RespuestaSunat> enviarComprobanteZip({
    required String nombreArchivoZip,
    required List<int> bytesZip,
  });

  /// Envía un resumen diario o comunicación de baja (operación asíncrona que retorna un ticket).
  Future<CPE_RespuestaSunat> enviarResumenAsincronoZip({
    required String nombreArchivoZip,
    required List<int> bytesZip,
  });

  /// Consulta el estado de procesamiento de un ticket asíncrono.
  Future<CPE_RespuestaSunat> consultarTicket(String ticket);
}
