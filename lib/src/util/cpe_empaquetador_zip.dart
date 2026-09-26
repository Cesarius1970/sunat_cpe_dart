// Copyright (c) 2026, César A Vergara Buenaventura <cesarvergarab@gmail.com>.
// Todos los derechos reservados. Uso sujeto a la licencia en el archivo LICENSE.

import 'dart:convert';

import 'package:archive/archive.dart';

/// Utilidad para empaquetar comprobantes XML en ZIP y extraer respuestas CDR de SUNAT.
class CPE_EmpaquetadorZip {
  const CPE_EmpaquetadorZip();

  /// Comprime un documento XML en un archivo ZIP con el nombre especificado.
  ///
  /// Retorna los bytes comprimidos listos para ser enviados a los Web Services de SUNAT.
  List<int> empaquetarXml({
    required String nombreXml,
    required String contenidoXml,
  }) {
    final archive = Archive();
    final bytesXml = utf8.encode(contenidoXml);
    final nombreLimpio = nombreXml.endsWith('.xml')
        ? nombreXml
        : '$nombreXml.xml';

    archive.addFile(ArchiveFile(nombreLimpio, bytesXml.length, bytesXml));
    final zipEncoder = ZipEncoder();
    return zipEncoder.encode(archive);
  }

  /// Descomprime los bytes de un archivo ZIP de respuesta CDR y extrae el XML de constancia.
  ///
  /// El archivo dentro del CDR típicamente inicia con el prefijo `R-`.
  String? extraerXmlDeZip(List<int> bytesZip) {
    final zipDecoder = ZipDecoder();
    final archive = zipDecoder.decodeBytes(bytesZip);

    for (final file in archive) {
      if (file.isFile && file.name.toLowerCase().endsWith('.xml')) {
        final content = file.content as List<int>;
        return utf8.decode(content);
      }
    }
    return null;
  }
}
