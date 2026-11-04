import 'dart:convert';
import 'dart:typed_data';

import 'package:pointycastle/export.dart';
import 'package:sunat_cpe_core/sunat_cpe_core.dart';

/// Genera un par de llaves RSA determinista de prueba exclusivamente para el ambiente `SunatDirectEnvironment.beta`.
final class SunatDirectMockCertificateFactory {
  static CpeCertificateCredentials? _cachedMock;

  const SunatDirectMockCertificateFactory._();

  /// Devuelve un certificado RSA de 1024 bits de prueba válido para el ambiente Beta de SUNAT.
  static CpeCertificateCredentials createBetaMockCertificate() {
    if (_cachedMock != null) {
      return _cachedMock!;
    }
    final keyParams = RSAKeyGeneratorParameters(
      BigInt.parse('65537'),
      1024,
      12,
    );
    final secureRandom = FortunaRandom()
      ..seed(
        KeyParameter(
          Uint8List.fromList(
            List<int>.generate(32, (i) => (i * 7 + 13) & 0xFF),
          ),
        ),
      );

    final generator = RSAKeyGenerator()
      ..init(ParametersWithRandom(keyParams, secureRandom));
    final pair = generator.generateKeyPair();

    _cachedMock = CpeCertificateCredentials(
      privateKey: pair.privateKey,
      base64X509Certificate: base64.encode(
        utf8.encode('SUNAT-BETA-MOCK-X509-CERTIFICATE'),
      ),
    );
    return _cachedMock!;
  }
}
