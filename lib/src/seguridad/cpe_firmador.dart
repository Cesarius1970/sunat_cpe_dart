// Copyright (c) 2026, César A Vergara Buenaventura <cesarvergarab@gmail.com>.
// Todos los derechos reservados. Uso sujeto a la licencia en el archivo LICENSE.

/// Representa un certificado digital X.509 utilizado para la firma electrónica XML-DSig.
class CPE_CertificadoDigital {
  /// Contenido del certificado en Base64 (estándar X.509 sin delimitadores PEM).
  final String certificadoBase64;

  /// Clave privada en formato PEM (opcional).
  final String? clavePrivadaPem;

  /// Contraseña del certificado para archivos PKCS#12 (.pfx / .p12).
  final String? clave;

  /// Función personalizada de firma criptográfica RSA sobre los bytes de `SignedInfo`.
  final List<int> Function(List<int> datos)? funcionFirmaRsa;

  /// Indica si es un certificado simulado / mock exclusivo para entornos de pruebas.
  final bool esMock;

  const CPE_CertificadoDigital({
    required this.certificadoBase64,
    this.clavePrivadaPem,
    this.clave,
    this.funcionFirmaRsa,
    this.esMock = false,
  });

  /// Certificado mock exclusivo para desarrollo y entorno de Pruebas (Beta).
  ///
  /// **Nota:** Su uso en entornos de Homologación o Producción está terminantemente prohibido.
  factory CPE_CertificadoDigital.mockPruebas() {
    return const CPE_CertificadoDigital(
      certificadoBase64:
          'MIIE+zCCA+OgAwIBAgIUQWEzREVG...CERTIFICADO_MOCK_SUNAT_BETA...',
      esMock: true,
    );
  }
}

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
abstract class CPE_Firmador {
  /// Firma digitalmente el comprobante XML utilizando el [certificado] proporcionado por el llamador.
  Future<CPE_ResultadoFirma> firmarXml(
    String xmlSinFirmar, {
    required CPE_CertificadoDigital certificado,
    String idFirma = 'SignatureSUNAT',
  });
}
