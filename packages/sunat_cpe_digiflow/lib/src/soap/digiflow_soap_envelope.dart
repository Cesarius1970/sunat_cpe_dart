/// Constructor de sobres SOAP 1.1 compatibles con Digiflow OSE incluyendo `UsernameToken` WS-Security y `soapenv:mustUnderstand="1"`.
final class DigiflowSoapEnvelope {
  /// Crea una instancia constante de [DigiflowSoapEnvelope].
  const DigiflowSoapEnvelope();

  /// Construye el sobre XML SOAP 1.1 completo con cabeceras WS-Security y el cuerpo [bodyXml].
  String build({
    required String wsseUsername,
    required String wssePassword,
    required String bodyXml,
  }) {
    return '<?xml version="1.0" encoding="UTF-8"?>'
        '<soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/" '
        'xmlns:ser="http://service.sunat.gob.pe" '
        'xmlns:wsse="http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-wssecurity-secext-1.0.xsd">'
        '<soapenv:Header>'
        '<wsse:Security soapenv:mustUnderstand="1">'
        '<wsse:UsernameToken>'
        '<wsse:Username>$wsseUsername</wsse:Username>'
        '<wsse:Password Type="http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-username-token-profile-1.0#PasswordText">$wssePassword</wsse:Password>'
        '</wsse:UsernameToken>'
        '</wsse:Security>'
        '</soapenv:Header>'
        '<soapenv:Body>$bodyXml</soapenv:Body>'
        '</soapenv:Envelope>';
  }
}
