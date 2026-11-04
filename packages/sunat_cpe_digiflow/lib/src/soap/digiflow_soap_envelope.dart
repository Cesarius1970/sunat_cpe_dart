/// Helper to construct Digiflow-compliant SOAP 1.1 envelopes with WS-Security `UsernameToken`.
final class DigiflowSoapEnvelope {
  const DigiflowSoapEnvelope();

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
