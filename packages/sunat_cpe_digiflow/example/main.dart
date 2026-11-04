import 'package:sunat_cpe_digiflow/sunat_cpe_digiflow.dart';

void main() {
  const envelope = DigiflowSoapEnvelope();
  final xml = envelope.build(
    wsseUsername: '20100066603MODDATOS',
    wssePassword: 'moddatos',
    bodyXml: '<ser:getStatus><ticket>DEMO-TICKET</ticket></ser:getStatus>',
  );
  print('Digiflow SOAP 1.1 Envelope (${xml.length} chars)');
}
