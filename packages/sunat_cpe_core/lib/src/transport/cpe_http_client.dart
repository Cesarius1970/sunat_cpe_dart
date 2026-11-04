import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

import '../results/cpe_result.dart';

/// Representación inmutable de una solicitud HTTP para llamadas REST y SOAP.
final class CpeHttpRequest {
  final String method;
  final Uri uri;
  final Map<String, String> headers;
  final Object? body; // String, List<int>, or Map<String, String>
  final Duration timeout;

  const CpeHttpRequest({
    required this.method,
    required this.uri,
    this.headers = const {},
    this.body,
    this.timeout = const Duration(seconds: 30),
  });

  CpeHttpRequest copyWith({
    String? method,
    Uri? uri,
    Map<String, String>? headers,
    Object? body,
    Duration? timeout,
  }) {
    return CpeHttpRequest(
      method: method ?? this.method,
      uri: uri ?? this.uri,
      headers: headers ?? this.headers,
      body: body ?? this.body,
      timeout: timeout ?? this.timeout,
    );
  }
}

/// Representación inmutable de una respuesta HTTP.
final class CpeHttpResponse {
  final int statusCode;
  final Map<String, String> headers;
  final Uint8List bodyBytes;

  const CpeHttpResponse({
    required this.statusCode,
    required this.headers,
    required this.bodyBytes,
  });

  String get bodyAsString => utf8.decode(bodyBytes, allowMalformed: true);
}

/// Interfaz de interceptor para autenticación, cabeceras SOAP, registro de trazas y reintentos.
abstract interface class CpeHttpInterceptor {
  Future<CpeHttpRequest> onRequest(CpeHttpRequest request);
  Future<CpeHttpResponse> onResponse(
    CpeHttpRequest request,
    CpeHttpResponse response,
  );
}

/// Abstracción de transporte que desacopla el núcleo y los proveedores de paquetes HTTP específicos.
abstract interface class CpeHttpClient {
  Future<CpeHttpResponse> send(CpeHttpRequest request);
  void close();
}

/// Implementación predeterminada de [CpeHttpClient] respaldada por `package:http`.
final class DefaultCpeHttpClient implements CpeHttpClient {
  final http.Client _inner;
  final List<CpeHttpInterceptor> _interceptors;
  final bool _ownsInnerClient;

  DefaultCpeHttpClient({
    http.Client? client,
    List<CpeHttpInterceptor> interceptors = const [],
  }) : _inner = client ?? http.Client(),
       _interceptors = List.unmodifiable(interceptors),
       _ownsInnerClient = client == null;

  @override
  Future<CpeHttpResponse> send(CpeHttpRequest request) async {
    var currentReq = request;
    for (final interceptor in _interceptors) {
      currentReq = await interceptor.onRequest(currentReq);
    }

    final httpReq = http.Request(currentReq.method, currentReq.uri);
    httpReq.headers.addAll(currentReq.headers);

    final body = currentReq.body;
    if (body is String) {
      httpReq.bodyBytes = utf8.encode(body);
    } else if (body is List<int>) {
      httpReq.bodyBytes = body;
    } else if (body is Map<String, String>) {
      httpReq.bodyFields = body;
    }

    try {
      final streamedResponse = await _inner
          .send(httpReq)
          .timeout(currentReq.timeout);
      final bytes = await streamedResponse.stream.toBytes();
      var currentRes = CpeHttpResponse(
        statusCode: streamedResponse.statusCode,
        headers: streamedResponse.headers,
        bodyBytes: bytes,
      );

      for (final interceptor in _interceptors) {
        currentRes = await interceptor.onResponse(currentReq, currentRes);
      }
      return currentRes;
    } on TimeoutException catch (e, st) {
      throw OseTransportException(
        message:
            'HTTP request timed out after ${currentReq.timeout.inSeconds}s: ${currentReq.uri}',
        isRetryable: true,
        rawResponse: e,
        stackTrace: st,
      );
    } catch (e, st) {
      if (e is CpeException) rethrow;
      throw OseTransportException(
        message: 'Transport error communicating with ${currentReq.uri}: $e',
        isRetryable: true,
        rawResponse: e,
        stackTrace: st,
      );
    }
  }

  @override
  void close() {
    if (_ownsInnerClient) {
      _inner.close();
    }
  }
}
