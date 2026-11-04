import 'package:sunat_cpe_core/sunat_cpe_core.dart';
import 'package:xml/xml.dart';

/// Analizador especializado de fallos SOAP (`<soap:Fault>`) para Bizlinks OSE
/// (patrones en `faultcode`, `faultstring` numérico y `<detail><message>`).
final class BizlinksSoapFaultParser {
  /// Crea una instancia constante de [BizlinksSoapFaultParser].
  const BizlinksSoapFaultParser();

  /// Analiza estructuras `<soap:Fault>` específicas de Bizlinks convirtiéndolas en subtipos tipados de [CpeException].
  CpeException? parseFault(CpeHttpResponse response) {
    final body = response.bodyAsString;
    if (!body.contains('Fault')) {
      return null;
    }

    try {
      final doc = XmlDocument.parse(body);
      final faultEl = doc
          .findAllElements('Fault', namespaceUri: '*')
          .firstOrNull;
      if (faultEl == null) return null;

      final faultCode =
          faultEl
              .findAllElements('faultcode', namespaceUri: '*')
              .firstOrNull
              ?.innerText
              .trim() ??
          '';
      final faultString =
          faultEl
              .findAllElements('faultstring', namespaceUri: '*')
              .firstOrNull
              ?.innerText
              .trim() ??
          '';
      final detailMsg =
          faultEl
              .findAllElements('message', namespaceUri: '*')
              .firstOrNull
              ?.innerText
              .trim() ??
          '';

      // Bizlinks a menudo retorna el código numérico en faultstring ("2017") con la descripción en detail/message
      final directCode = int.tryParse(faultString);
      final suffixMatch = RegExp(r'\.(\d{4})$').firstMatch(faultCode);
      final regexMatch = RegExp(r'\b(0[1-9]\d{2}|[1-3]\d{3})\b')
          .firstMatch('$faultCode $faultString $detailMsg');

      final int? sunatCode =
          directCode ??
          (suffixMatch != null ? int.tryParse(suffixMatch.group(1)!) : null) ??
          (regexMatch != null ? int.tryParse(regexMatch.group(1)!) : null);

      final message = detailMsg.isNotEmpty
          ? detailMsg
          : (faultString.isNotEmpty ? faultString : faultCode);

      if (sunatCode != null) {
        if (sunatCode >= 100 && sunatCode <= 109) {
          return OseAuthException(
            message: 'Bizlinks WS-Security error ($sunatCode): $message',
            code: sunatCode.toString().padLeft(4, '0'),
            rawResponse: body,
          );
        }
        if (sunatCode >= 100 && sunatCode < 2000) {
          return SunatExceptionError(
            sunatCode: sunatCode,
            message: message,
            rawResponse: body,
          );
        }
        if (sunatCode >= 2000 && sunatCode < 4000) {
          return SunatRejectionException(
            sunatCode: sunatCode,
            message: message,
            rawResponse: body,
          );
        }
      }

      return OseTransportException(
        message: 'Bizlinks SOAP Fault ($faultCode): $message',
        httpStatusCode: response.statusCode,
        isRetryable: false,
        rawResponse: body,
      );
    } catch (_) {
      return null;
    }
  }
}
