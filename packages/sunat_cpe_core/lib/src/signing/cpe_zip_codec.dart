import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:xml/xml.dart';

import '../results/cpe_responses.dart';
import '../results/cpe_result.dart';

/// Compresses UBL XML documents into SUNAT-compliant `.zip` archives and parses CDR `.zip` responses.
final class CpeZipCodec {
  const CpeZipCodec();

  /// Compresses `{fileNameBase}.xml` into `{fileNameBase}.zip` and returns raw bytes + Base64.
  ({Uint8List zipBytes, String base64Zip}) encodeXmlToZip({
    required String fileNameBase,
    required String xmlContent,
  }) {
    final xmlBytes = utf8.encode(xmlContent);
    final archive = Archive()
      ..addFile(ArchiveFile('$fileNameBase.xml', xmlBytes.length, xmlBytes));

    final encoded = ZipEncoder().encode(archive);
    final zipBytes = Uint8List.fromList(encoded);
    return (zipBytes: zipBytes, base64Zip: base64.encode(zipBytes));
  }

  /// Extracts and parses a SUNAT/OSE `<ApplicationResponse>` CDR from Base64 or raw ZIP bytes.
  CdrData parseCdrFromBase64Zip(String base64Zip) {
    final zipBytes = base64.decode(base64Zip.replaceAll(RegExp(r'\s+'), ''));
    return parseCdrFromZipBytes(zipBytes);
  }

  /// Extracts the `.xml` file inside `R-{RUC}-{TIPO}-{SERIE}-{NUM}.zip` and parses `<ApplicationResponse>`.
  CdrData parseCdrFromZipBytes(List<int> zipBytes) {
    final archive = ZipDecoder().decodeBytes(zipBytes);
    ArchiveFile? xmlEntry;

    for (final file in archive.files) {
      if (file.isFile && file.name.toLowerCase().endsWith('.xml')) {
        xmlEntry = file;
        if (file.name.startsWith('R-') || file.name.contains('/R-')) {
          break;
        }
      }
    }

    if (xmlEntry == null) {
      throw const OseTransportException(
        message: 'CDR ZIP archive does not contain any .xml file',
        isRetryable: false,
      );
    }

    final xmlString = utf8.decode(xmlEntry.content, allowMalformed: true);
    return parseCdrFromXmlString(xmlString, cdrZipBytes: zipBytes);
  }

  /// Parses an unpacked `<ApplicationResponse>` XML string directly (also used by EFACT REST `/v1/cdr`).
  CdrData parseCdrFromXmlString(
    String cdrXmlContent, {
    List<int>? cdrZipBytes,
  }) {
    final doc = XmlDocument.parse(cdrXmlContent);
    final root = doc.rootElement;

    final id = _firstElementText(root, 'ID') ?? 'CDR';
    final responseDateStr = _firstElementText(root, 'ResponseDate');
    final responseTimeStr = _firstElementText(root, 'ResponseTime');

    final docResponse = root
        .findAllElements('DocumentResponse', namespaceUri: '*')
        .firstOrNull;
    final responseNode =
        docResponse?.findElements('Response', namespaceUri: '*').firstOrNull ??
        root;

    final responseCode = _firstElementText(responseNode, 'ResponseCode') ?? '0';
    final description = _firstElementText(responseNode, 'Description') ?? '';
    final digestValue = _firstElementText(root, 'DigestValue');

    final warnings = <SunatWarning>[];
    for (final noteEl in root.findAllElements('Note', namespaceUri: '*')) {
      final rawNote = noteEl.innerText.trim();
      if (rawNote.isEmpty) continue;
      final parts = rawNote.split(' - ');
      if (parts.length >= 2) {
        warnings.add(
          SunatWarning(
            code: parts.first.trim(),
            description: parts.sublist(1).join(' - ').trim(),
          ),
        );
      } else {
        warnings.add(SunatWarning(code: '4000', description: rawNote));
      }
    }

    DateTime responseDateTime = DateTime.now();
    if (responseDateStr != null) {
      final parsedDate = DateTime.tryParse(
        responseTimeStr != null
            ? '${responseDateStr}T${responseTimeStr.replaceAll('Z', '')}'
            : responseDateStr,
      );
      if (parsedDate != null) {
        responseDateTime = parsedDate;
      }
    }

    return CdrData(
      id: id,
      responseCode: responseCode.trim(),
      description: description.trim(),
      responseDateTime: responseDateTime,
      digestValue: digestValue?.trim(),
      cdrZipBytes: cdrZipBytes,
      cdrXmlContent: cdrXmlContent,
      warnings: List.unmodifiable(warnings),
    );
  }

  static String? _firstElementText(XmlElement parent, String localName) {
    final el = parent.findAllElements(localName, namespaceUri: '*').firstOrNull;
    return el?.innerText;
  }
}
