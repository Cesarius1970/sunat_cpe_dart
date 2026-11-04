import 'package:sunat_cpe_core/sunat_cpe_core.dart';
import 'package:xml/xml.dart';

/// Extracts SUNAT exception and rejection codes from TCI `<soap-env:Fault>` (`Client.XXXX` / `Server.XXXX`).
final class TciSoapFaultParser {
  const TciSoapFaultParser();

  CpeException? parseFault(CpeHttpResponse response) {
    final body = response.bodyAsString;
    if (!body.contains('Fault')) {
      return null;
    }

    try {
      final doc = XmlDocument.parse(body);
      final faultEl = doc.findAllElements('Fault', namespace: '*').firstOrNull;
      if (faultEl == null) return null;

      final faultCode = faultEl
              .findAllElements('faultcode', namespace: '*')
              .firstOrNull
              ?.innerText
              .trim() ??
          '';
      final faultString = faultEl
              .findAllElements('faultstring', namespace: '*')
              .firstOrNull
              ?.innerText
              .trim() ??
          '';
      final detailMsg = faultEl
              .findAllElements('message', namespace: '*')
              .firstOrNull
              ?.innerText
              .trim() ??
          '';

      final suffixMatch = RegExp(r'(?:Client|Server)\.(\d{4})\b').firstMatch(faultCode);
      final regexMatch = RegExp(r'\b(0[1-9]\d{2}|[1-3]\d{3})\b')
          .firstMatch('$faultCode $faultString $detailMsg');

      final int? sunatCode = (suffixMatch != null
              ? int.tryParse(suffixMatch.group(1)!)
              : null) ??
          (regexMatch != null ? int.tryParse(regexMatch.group(1)!) : null);

      final description = faultString.isNotEmpty
          ? faultString
          : (detailMsg.isNotEmpty ? detailMsg : faultCode);

      if (sunatCode != null) {
        if (sunatCode >= 100 && sunatCode <= 109) {
          return OseAuthException(
            message: 'TCI WS-Security error ($sunatCode): $description',
            code: sunatCode.toString().padLeft(4, '0'),
            rawResponse: body,
          );
        }
        if (sunatCode >= 100 && sunatCode < 2000) {
          return SunatExceptionError(
            sunatCode: sunatCode,
            message: description,
            rawResponse: body,
          );
        }
        if (sunatCode >= 2000 && sunatCode < 4000) {
          return SunatRejectionException(
            sunatCode: sunatCode,
            message: description,
            rawResponse: body,
          );
        }
      }

      return OseTransportException(
        message: 'TCI SOAP Fault ($faultCode): $description',
        httpStatusCode: response.statusCode,
        isRetryable: false,
        rawResponse: body,
      );
    } catch (_) {
      return null;
    }
  }
}
