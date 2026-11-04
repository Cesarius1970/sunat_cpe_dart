/// Configuration for [MifactProvider].
final class MifactConfig {
  /// Public Mifact beta/demo token.
  static const String demoToken = 'gN8zNRBV+/FVxTLwdaZx0w==';

  final Uri baseUri;
  final String token;
  final bool sendImmediatelyToSunat;
  final Duration timeout;

  const MifactConfig({
    required this.baseUri,
    required this.token,
    this.sendImmediatelyToSunat = true,
    this.timeout = const Duration(seconds: 30),
  });
}
