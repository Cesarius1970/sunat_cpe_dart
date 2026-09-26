// Copyright (c) 2026, César A Vergara Buenaventura <cesarvergarab@gmail.com>.
// Todos los derechos reservados. Uso sujeto a la licencia en el archivo LICENSE.

/// Resultado de la firma digital de un comprobante XML.
class CPE_ResultadoFirma {
  /// Contenido completo del documento XML con el bloque `ds:Signature` embebido.
  final String xmlFirmado;

  /// Valor del resumen digital (DigestValue en Base64), empleado como Hash del comprobante en el código QR.
  final String digestValue;

  /// Valor criptográfico de la firma digital (SignatureValue en Base64).
  final String signatureValue;

  const CPE_ResultadoFirma({
    required this.xmlFirmado,
    required this.digestValue,
    required this.signatureValue,
  });
}

/// Contrato abstracto para firmadores de comprobantes electrónicos XML (XMLDSig).
///
/// Permite desacoplar el motor de firma:
/// - Firma nativa con certificados X.509 (.pfx/.p12).
/// - Firma remota delegada (servidor HSM, API de firma externa o PSE).
abstract class CPE_Firmador {
  /// Firma digitalmente el comprobante XML conforme al estándar W3C XML-DSig y UBL 2.1.
  Future<CPE_ResultadoFirma> firmarXml(
    String xmlSinFirmar, {
    String idFirma = 'SignatureSUNAT',
  });
}
