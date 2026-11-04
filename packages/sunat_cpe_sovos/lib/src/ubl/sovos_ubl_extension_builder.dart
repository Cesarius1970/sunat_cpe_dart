import 'package:xml/xml.dart';

/// Inyecta parámetros personalizados de impresión de Paperless / Sovos (`<SovosCustomPrintFields>`)
/// dentro de `<ext:UBLExtensions>` antes de ejecutar la firma digital XAdES-BES.
final class SovosUblExtensionBuilder {
  /// Crea una instancia constante de [SovosUblExtensionBuilder].
  const SovosUblExtensionBuilder();

  /// Retorna una cadena XML UBL modificada que incluye los campos personalizados de impresión dentro de `<ext:UBLExtensions>`.
  String injectCustomPrintFields(
    String unsignedXml,
    Map<String, String> customPrintFields,
  ) {
    if (customPrintFields.isEmpty) {
      return unsignedXml;
    }

    final doc = XmlDocument.parse(unsignedXml);
    final extensionsEl = doc
        .findAllElements('UBLExtensions', namespaceUri: '*')
        .firstOrNull;
    if (extensionsEl == null) {
      return unsignedXml;
    }

    final extPrefix = extensionsEl.name.prefix ?? 'ext';
    final propsBuf = StringBuffer()
      ..write('<$extPrefix:UBLExtension>')
      ..write('<$extPrefix:ExtensionContent>')
      ..write('<SovosCustomPrintFields>');
    for (final entry in customPrintFields.entries) {
      final escapedKey = _escapeXml(entry.key);
      final escapedVal = _escapeXml(entry.value);
      propsBuf.write('<Field name="$escapedKey">$escapedVal</Field>');
    }
    propsBuf
      ..write('</SovosCustomPrintFields>')
      ..write('</$extPrefix:ExtensionContent>')
      ..write('</$extPrefix:UBLExtension>');

    final fragment = XmlDocumentFragment.parse(propsBuf.toString());
    extensionsEl.children.add(fragment.copy());
    return doc.toXmlString();
  }

  static String _escapeXml(String input) {
    return input
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .replaceAll('"', '&quot;')
        .replaceAll("'", '&apos;');
  }
}
