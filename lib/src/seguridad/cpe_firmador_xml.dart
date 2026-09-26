// Copyright (c) 2026, César A Vergara Buenaventura <cesarvergarab@gmail.com>.
// Todos los derechos reservados. Uso sujeto a la licencia en el archivo LICENSE.

import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:xml/xml.dart';

import 'cpe_firmador.dart';

/// Implementación del estándar W3C XML-DSig para Comprobantes UBL 2.1 de SUNAT.
class CPE_FirmadorXml implements CPE_Firmador {
  /// Certificado X.509 codificado en Base64 (sin encabezados PEM).
  final String certificadoBase64;

  /// Función opcional para firmar con clave privada RSA.
  /// Si es nula, se genera una firma simulada con formato estándar para pruebas.
  final List<int> Function(List<int> datos)? funcionFirmaRsa;

  const CPE_FirmadorXml({
    required this.certificadoBase64,
    this.funcionFirmaRsa,
  });

  /// Firmador de prueba o simulación para validación de estructura XML.
  factory CPE_FirmadorXml.paraPruebas() {
    return const CPE_FirmadorXml(
      certificadoBase64:
          'MIIE+zCCA+OgAwIBAgIUQWEzREVG...CERTIFICADO_PRUEBA_SUNAT...',
    );
  }

  @override
  Future<CPE_ResultadoFirma> firmarXml(
    String xmlSinFirmar, {
    String idFirma = 'SignatureSUNAT',
  }) async {
    final documento = XmlDocument.parse(xmlSinFirmar);

    // 1. Calcular Digest del documento original (SHA-256)
    final bytesXml = utf8.encode(xmlSinFirmar);
    final digestBytes = sha256.convert(bytesXml).bytes;
    final digestBase64 = base64.encode(digestBytes);

    // 2. Preparar bloque SignedInfo según estándar UBL SUNAT
    final signedInfoXml =
        '''<ds:SignedInfo xmlns:ds="http://www.w3.org/2000/09/xmldsig#">
<ds:CanonicalizationMethod Algorithm="http://www.w3.org/TR/2001/REC-xml-c14n-20010315"/>
<ds:SignatureMethod Algorithm="http://www.w3.org/2001/04/xmldsig-more#rsa-sha256"/>
<ds:Reference URI="">
<ds:Transforms>
<ds:Transform Algorithm="http://www.w3.org/2000/09/xmldsig#enveloped-signature"/>
</ds:Transforms>
<ds:DigestMethod Algorithm="http://www.w3.org/2001/04/xmlenc#sha256"/>
<ds:DigestValue>$digestBase64</ds:DigestValue>
</ds:Reference>
</ds:SignedInfo>''';

    // 3. Generar la firma criptográfica sobre SignedInfo
    final bytesSignedInfo = utf8.encode(signedInfoXml);
    String signatureBase64;

    if (funcionFirmaRsa != null) {
      final signatureBytes = funcionFirmaRsa!(bytesSignedInfo);
      signatureBase64 = base64.encode(signatureBytes);
    } else {
      // Simulación válida sintácticamente para pruebas estructurales
      final hashPrueba = sha256.convert(bytesSignedInfo).bytes;
      signatureBase64 = base64.encode(hashPrueba);
    }

    // 4. Construir bloque completo de ds:Signature
    final signatureBlock =
        '''<ds:Signature xmlns:ds="http://www.w3.org/2000/09/xmldsig#" Id="$idFirma">
$signedInfoXml
<ds:SignatureValue>$signatureBase64</ds:SignatureValue>
<ds:KeyInfo>
<ds:X509Data>
<ds:X509Certificate>$certificadoBase64</ds:X509Certificate>
</ds:X509Data>
</ds:KeyInfo>
</ds:Signature>''';

    // 5. Inyectar dentro del primer ext:ExtensionContent en ext:UBLExtensions
    final extensionContent = documento
        .findAllElements('ext:ExtensionContent')
        .firstOrNull;
    if (extensionContent != null) {
      extensionContent.children.clear();
      final fragmentoFirma = XmlDocumentFragment.parse(signatureBlock);
      extensionContent.children.add(fragmentoFirma);
    }

    final xmlFinal = documento.toXmlString(pretty: false);

    return CPE_ResultadoFirma(
      xmlFirmado: xmlFinal,
      digestValue: digestBase64,
      signatureValue: signatureBase64,
    );
  }
}
