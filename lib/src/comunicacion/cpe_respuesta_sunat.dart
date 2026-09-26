// Copyright (c) 2026, César A Vergara Buenaventura <cesarvergarab@gmail.com>.
// Todos los derechos reservados. Uso sujeto a la licencia en el archivo LICENSE.

import 'package:xml/xml.dart';

/// Respuesta oficial emitida por los Web Services SOAP o API REST de SUNAT.
class CPE_RespuestaSunat {
  /// Indica si la transacción técnica fue exitosa.
  final bool exito;

  /// Código de respuesta o estado retornado por SUNAT (ej. '0' para Aceptado).
  final String? codigoRespuesta;

  /// Descripción o mensaje legible de la respuesta de SUNAT.
  final String? mensaje;

  /// Ticket asignado para operaciones asíncronas (Resúmenes diarios, Bajas o Guías REST).
  final String? ticket;

  /// Lista de advertencias u observaciones fiscales reportadas en el CDR.
  final List<String> observaciones;

  /// Contenido XML desempaquetado de la Constancia de Recepción (CDR).
  final String? cdrXml;

  /// Bytes brutos del archivo ZIP del CDR entregado por SUNAT.
  final List<int>? cdrZipBytes;

  /// Código hash criptográfico del comprobante extraído del CDR.
  final String? hashCdr;

  const CPE_RespuestaSunat({
    required this.exito,
    this.codigoRespuesta,
    this.mensaje,
    this.ticket,
    this.observaciones = const [],
    this.cdrXml,
    this.cdrZipBytes,
    this.hashCdr,
  });

  /// Indica si el comprobante fue aceptado formalmente por SUNAT (código '0').
  bool get esAceptado => codigoRespuesta == '0';

  /// Indica si el comprobante fue aceptado pero cuenta con observaciones.
  bool get esAceptadoConObservaciones => esAceptado && observaciones.isNotEmpty;

  /// Analiza y construye una [CPE_RespuestaSunat] a partir del XML de la Constancia de Recepción (CDR).
  factory CPE_RespuestaSunat.desdeCdrXml(String cdrXml, {List<int>? bytesZip}) {
    try {
      final doc = XmlDocument.parse(cdrXml);
      final responseNode = doc
          .findAllElements('cac:DocumentResponse')
          .firstOrNull;
      final responseCode =
          responseNode
              ?.findElements('cac:Response')
              .firstOrNull
              ?.findElements('cbc:ResponseCode')
              .firstOrNull
              ?.innerText ??
          doc.findAllElements('cbc:ResponseCode').firstOrNull?.innerText;
      final description =
          responseNode
              ?.findElements('cac:Response')
              .firstOrNull
              ?.findElements('cbc:Description')
              .firstOrNull
              ?.innerText ??
          doc.findAllElements('cbc:Description').firstOrNull?.innerText;

      final obs = <String>[];
      for (final note in doc.findAllElements('cbc:Note')) {
        obs.add(note.innerText);
      }

      final digestValue = doc
          .findAllElements('ds:DigestValue')
          .firstOrNull
          ?.innerText;

      return CPE_RespuestaSunat(
        exito: responseCode == '0',
        codigoRespuesta: responseCode,
        mensaje: description,
        observaciones: obs,
        cdrXml: cdrXml,
        cdrZipBytes: bytesZip,
        hashCdr: digestValue,
      );
    } catch (e) {
      return CPE_RespuestaSunat(
        exito: false,
        mensaje: 'Error al interpretar el CDR de SUNAT: $e',
        cdrXml: cdrXml,
        cdrZipBytes: bytesZip,
      );
    }
  }

  /// Constructor para errores técnicos de conexión o excepciones HTTP/SOAP.
  factory CPE_RespuestaSunat.errorTecnico(
    String detalleError, {
    String? codigo,
  }) {
    return CPE_RespuestaSunat(
      exito: false,
      codigoRespuesta: codigo,
      mensaje: detalleError,
    );
  }
}
