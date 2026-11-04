import 'dart:convert';
import 'dart:typed_data';

import 'package:pointycastle/export.dart';
import 'package:sunat_cpe_core/sunat_cpe_core.dart';

/// Generates a deterministic mock RSA keypair exclusively for `SunatDirectEnvironment.beta` testing.
final class SunatDirectMockCertificateFactory {
  static CpeCertificateCredentials? _cachedMock;

  const SunatDirectMockCertificateFactory._();

  /// Returns a valid 1024-bit RSA test certificate for SUNAT Beta environment.
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
