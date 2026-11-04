import 'dart:convert';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:pointycastle/asn1.dart';
import 'package:pointycastle/export.dart';
import 'package:xml/xml.dart';

import '../results/cpe_result.dart';

/// Contiene la clave privada RSA y el certificado X.509 para la firma XML-DSig / XAdES-BES.
final class CpeCertificateCredentials {
  final RSAPrivateKey privateKey;
  final String base64X509Certificate;

  const CpeCertificateCredentials({
    required this.privateKey,
    required this.base64X509Certificate,
  });

  /// Analiza una clave privada RSA (PKCS#8 o PKCS#1) y un certificado X.509 codificados en formato PEM.
  factory CpeCertificateCredentials.fromPem({
    required String privateKeyPem,
    required String certificatePem,
  }) {
    final cleanCert = certificatePem
        .replaceAll(RegExp(r'-----BEGIN [^-]+-----'), '')
        .replaceAll(RegExp(r'-----END [^-]+-----'), '')
        .replaceAll(RegExp(r'\s+'), '');

    final keyBytes = _decodePemBlocks(privateKeyPem);
    final rsaPrivateKey = _parseRsaPrivateKey(keyBytes);

    return CpeCertificateCredentials(
      privateKey: rsaPrivateKey,
      base64X509Certificate: cleanCert,
    );
  }

  static Uint8List _decodePemBlocks(String pem) {
    final clean = pem
        .replaceAll(RegExp(r'-----BEGIN [^-]+-----'), '')
        .replaceAll(RegExp(r'-----END [^-]+-----'), '')
        .replaceAll(RegExp(r'\s+'), '');
    if (clean.isEmpty) {
      throw const CpeValidationException(
        message: 'Empty PEM private key provided',
        issues: [
          ValidationIssue(
            field: 'privateKeyPem',
            message: 'PEM content is empty',
          ),
        ],
      );
    }
    return base64.decode(clean);
  }

  static RSAPrivateKey _parseRsaPrivateKey(Uint8List bytes) {
    final parser = ASN1Parser(bytes);
    final topSeq = parser.nextObject() as ASN1Sequence;
    final elements = topSeq.elements!;

    // PKCS#8 PrivateKeyInfo has 3 elements (version, AlgorithmIdentifier, PrivateKey OctetString)
    if (elements.length >= 3 &&
        elements[1] is ASN1Sequence &&
        elements[2] is ASN1OctetString) {
      final octetString = elements[2] as ASN1OctetString;
      final pkcs1Parser = ASN1Parser(octetString.octets!);
      final pkcs1Seq = pkcs1Parser.nextObject() as ASN1Sequence;
      return _extractPkcs1Sequence(pkcs1Seq);
    }

    // PKCS#1 RSAPrivateKey sequence directly
    return _extractPkcs1Sequence(topSeq);
  }

  static RSAPrivateKey _extractPkcs1Sequence(ASN1Sequence seq) {
    final el = seq.elements!;
    final modulus = (el[1] as ASN1Integer).integer!;
    final privateExponent = (el[3] as ASN1Integer).integer!;
    final p = (el[4] as ASN1Integer).integer!;
    final q = (el[5] as ASN1Integer).integer!;
    return RSAPrivateKey(modulus, privateExponent, p, q);
  }
}

/// Resultado de firmar digitalmente un documento XML UBL.
final class SignedXmlOutput {
  final String signedXml;
  final String digestValue;
  final String signatureValue;

  const SignedXmlOutput({
    required this.signedXml,
    required this.digestValue,
    required this.signatureValue,
  });
}

/// Firmador XML-DSig Enveloped (RSA-SHA256) en Dart puro compatible con SUNAT UBL 2.1.
final class XadesBesSigner {
  const XadesBesSigner();

  static const String _c14nAlgorithm =
      'http://www.w3.org/TR/2001/REC-xml-c14n-20010315';
  static const String _envelopedSignatureAlgorithm =
      'http://www.w3.org/2000/09/xmldsig#enveloped-signature';
  static const String _rsaSha256Algorithm =
      'http://www.w3.org/2001/04/xmldsig-more#rsa-sha256';
  static const String _sha256DigestAlgorithm =
      'http://www.w3.org/2001/04/xmlenc#sha256';

  /// Firma un documento XML UBL sin firmar e inyecta `<ds:Signature Id="SignSUNAT">`
  /// dentro del primer elemento `<ext:ExtensionContent>`.
  SignedXmlOutput signXml(
    String unsignedXml,
    CpeCertificateCredentials credentials,
  ) {
    final doc = XmlDocument.parse(unsignedXml);

    // 1. Canonicalize the unsigned document (enveloped-signature transform)
    final canonicalDocBytes = utf8.encode(
      _canonicalizeElement(doc.rootElement),
    );
    final digestBytes = sha256.convert(canonicalDocBytes).bytes;
    final digestBase64 = base64.encode(digestBytes);

    // 2. Build <ds:SignedInfo> with inherited xmlns:ds declaration for C14N
    final signedInfoCanonical =
        '<ds:SignedInfo xmlns:ds="http://www.w3.org/2000/09/xmldsig#">'
        '<ds:CanonicalizationMethod Algorithm="$_c14nAlgorithm"></ds:CanonicalizationMethod>'
        '<ds:SignatureMethod Algorithm="$_rsaSha256Algorithm"></ds:SignatureMethod>'
        '<ds:Reference URI="">'
        '<ds:Transforms>'
        '<ds:Transform Algorithm="$_envelopedSignatureAlgorithm"></ds:Transform>'
        '</ds:Transforms>'
        '<ds:DigestMethod Algorithm="$_sha256DigestAlgorithm"></ds:DigestMethod>'
        '<ds:DigestValue>$digestBase64</ds:DigestValue>'
        '</ds:Reference>'
        '</ds:SignedInfo>';

    // 3. Sign canonical <ds:SignedInfo> using RSA-SHA256 (PKCS#1 v1.5)
    final signatureBytes = _rsaSha256Sign(
      Uint8List.fromList(utf8.encode(signedInfoCanonical)),
      credentials.privateKey,
    );
    final signatureBase64 = base64.encode(signatureBytes);

    // 4. Construct full <ds:Signature Id="SignSUNAT"> element
    final signatureFragment = XmlDocumentFragment.parse(
      '<ds:Signature xmlns:ds="http://www.w3.org/2000/09/xmldsig#" Id="SignSUNAT">'
      '<ds:SignedInfo>'
      '<ds:CanonicalizationMethod Algorithm="$_c14nAlgorithm"/>'
      '<ds:SignatureMethod Algorithm="$_rsaSha256Algorithm"/>'
      '<ds:Reference URI="">'
      '<ds:Transforms>'
      '<ds:Transform Algorithm="$_envelopedSignatureAlgorithm"/>'
      '</ds:Transforms>'
      '<ds:DigestMethod Algorithm="$_sha256DigestAlgorithm"/>'
      '<ds:DigestValue>$digestBase64</ds:DigestValue>'
      '</ds:Reference>'
      '</ds:SignedInfo>'
      '<ds:SignatureValue>$signatureBase64</ds:SignatureValue>'
      '<ds:KeyInfo>'
      '<ds:X509Data>'
      '<ds:X509Certificate>${credentials.base64X509Certificate}</ds:X509Certificate>'
      '</ds:X509Data>'
      '</ds:KeyInfo>'
      '</ds:Signature>',
    );

    // 5. Find <ext:ExtensionContent> and inject signature
    final extContent = doc
        .findAllElements('ExtensionContent', namespaceUri: '*')
        .firstOrNull;
    if (extContent == null) {
      throw const CpeValidationException(
        message: 'Missing <ext:ExtensionContent> node in UBL XML document',
        issues: [
          ValidationIssue(
            field: 'ext:ExtensionContent',
            message: 'Required UBL extension container not found',
          ),
        ],
      );
    }

    extContent.children.clear();
    extContent.children.add(signatureFragment.firstElementChild!.copy());

    return SignedXmlOutput(
      signedXml: doc.toXmlString(pretty: false),
      digestValue: digestBase64,
      signatureValue: signatureBase64,
    );
  }

  static Uint8List _rsaSha256Sign(Uint8List data, RSAPrivateKey privateKey) {
    // SHA-256 DigestInfo DER prefix (RFC 8017: 30 31 30 0d 06 09 60 86 48 01 65 03 04 02 01 05 00 04 20)
    final signer = RSASigner(SHA256Digest(), '0609608648016503040201');
    signer.init(true, PrivateKeyParameter<RSAPrivateKey>(privateKey));
    final sig = signer.generateSignature(data);
    return sig.bytes;
  }

  /// Serializador determinista de XML Canónico 1.0 (C14N):
  /// - Expande etiquetas autocerradas `<a/>` a `<a></a>`
  /// - Ordena las declaraciones de espacios de nombres antes que los atributos regulares, ambos lexicográficamente
  /// - Escapa caracteres especiales según la especificación W3C C14N
  static String _canonicalizeElement(XmlElement element) {
    final buffer = StringBuffer();
    _writeCanonicalElement(element, buffer, const {});
    return buffer.toString();
  }

  static void _writeCanonicalElement(
    XmlElement element,
    StringBuffer out,
    Map<String, String> inScopeNamespaces,
  ) {
    out.write('<');
    out.write(element.name.qualified);

    final nextInScope = Map<String, String>.of(inScopeNamespaces);
    final nsDeclarations = <MapEntry<String, String>>[];
    final regularAttrs = <XmlAttribute>[];

    for (final attr in element.attributes) {
      final qName = attr.name.qualified;
      if (qName == 'xmlns') {
        if (nextInScope[''] != attr.value) {
          nextInScope[''] = attr.value;
          nsDeclarations.add(MapEntry('', attr.value));
        }
      } else if (qName.startsWith('xmlns:')) {
        final prefix = qName.substring(6);
        if (nextInScope[prefix] != attr.value) {
          nextInScope[prefix] = attr.value;
          nsDeclarations.add(MapEntry(prefix, attr.value));
        }
      } else {
        regularAttrs.add(attr);
      }
    }

    nsDeclarations.sort((a, b) => a.key.compareTo(b.key));
    for (final ns in nsDeclarations) {
      final attrName = ns.key.isEmpty ? 'xmlns' : 'xmlns:${ns.key}';
      out.write(' $attrName="${_escapeAttr(ns.value)}"');
    }

    regularAttrs.sort((a, b) => a.name.qualified.compareTo(b.name.qualified));
    for (final attr in regularAttrs) {
      out.write(' ${attr.name.qualified}="${_escapeAttr(attr.value)}"');
    }

    out.write('>');

    for (final child in element.children) {
      if (child is XmlElement) {
        _writeCanonicalElement(child, out, nextInScope);
      } else if (child is XmlText) {
        out.write(_escapeText(child.value));
      } else if (child is XmlCDATA) {
        out.write(_escapeText(child.value));
      }
    }

    out.write('</');
    out.write(element.name.qualified);
    out.write('>');
  }

  static String _escapeText(String value) => value
      .replaceAll('&', '&amp;')
      .replaceAll('<', '&lt;')
      .replaceAll('>', '&gt;')
      .replaceAll('\r', '&#xD;');

  static String _escapeAttr(String value) => value
      .replaceAll('&', '&amp;')
      .replaceAll('<', '&lt;')
      .replaceAll('"', '&quot;')
      .replaceAll('\t', '&#x9;')
      .replaceAll('\n', '&#xA;')
      .replaceAll('\r', '&#xD;');
}
