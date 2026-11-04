import 'cpe_responses.dart';

/// Tipo de resultado sellado que soporta tanto programación funcional (`fold`/`switch`)
/// como lanzamiento imperativo de excepciones (`getOrThrow()`).
sealed class CpeResult<T> {
  const CpeResult();

  bool get isSuccess => this is CpeSuccess<T>;
  bool get isFailure => this is CpeFailure<T>;

  T? get dataOrNull => switch (this) {
    CpeSuccess<T>(:final data) => data,
    CpeFailure<T>() => null,
  };

  CpeException? get errorOrNull => switch (this) {
    CpeSuccess<T>() => null,
    CpeFailure<T>(:final error) => error,
  };

  /// Desenvuelve el valor exitoso o lanza la excepción tipada [CpeException].
  T getOrThrow() => switch (this) {
    CpeSuccess<T>(:final data) => data,
    CpeFailure<T>(:final error) => throw error,
  };

  R fold<R>(
    R Function(T data) onSuccess,
    R Function(CpeException error) onFailure,
  ) => switch (this) {
    CpeSuccess<T>(:final data) => onSuccess(data),
    CpeFailure<T>(:final error) => onFailure(error),
  };
}

final class CpeSuccess<T> extends CpeResult<T> {
  final T data;
  final Map<String, Object?> providerRawMetadata;

  const CpeSuccess(this.data, {this.providerRawMetadata = const {}});
}

final class CpeFailure<T> extends CpeResult<T> {
  final CpeException error;

  const CpeFailure(this.error);
}

/// Incidencia específica de validación detectada antes de la transmisión por red.
final class ValidationIssue {
  final String field;
  final String message;
  final int? lineNumber;

  const ValidationIssue({
    required this.field,
    required this.message,
    this.lineNumber,
  });

  @override
  String toString() => lineNumber != null
      ? '[Line $lineNumber] $field: $message'
      : '$field: $message';
}

/// Jerarquía sellada para todas las excepciones de CPE, OSE y SUNAT.
sealed class CpeException implements Exception {
  final String message;
  final String? code;
  final Object? rawResponse;
  final StackTrace? stackTrace;

  const CpeException({
    required this.message,
    this.code,
    this.rawResponse,
    this.stackTrace,
  });

  @override
  String toString() => '$runtimeType(code: $code, message: $message)';
}

/// 1. Error local de validación aritmética o estructural previo a la llamada de red.
final class CpeValidationException extends CpeException {
  final List<ValidationIssue> issues;

  const CpeValidationException({required super.message, required this.issues})
    : super(code: 'LOCAL_VALIDATION_ERROR');

  @override
  String toString() =>
      'CpeValidationException($message -> ${issues.map((e) => e.toString()).join('; ')})';
}

/// 2. Error de transporte de red, tiempo de espera (timeout), TLS o HTTP 5xx.
final class OseTransportException extends CpeException {
  final int? httpStatusCode;
  final bool isRetryable;

  const OseTransportException({
    required super.message,
    this.httpStatusCode,
    this.isRetryable = true,
    super.code = 'TRANSPORT_ERROR',
    super.rawResponse,
    super.stackTrace,
  });
}

/// 3. Error de autenticación (Token inválido, OAuth2 401/403, rechazo WS-Security).
final class OseAuthException extends CpeException {
  const OseAuthException({
    required super.message,
    super.code = 'AUTH_ERROR',
    super.rawResponse,
  });
}

/// 4. Excepción técnica de SUNAT/OSE (Códigos 0100 a 1999).
/// El comprobante NO fue registrado; es seguro corregirlo y reintentar con el mismo correlativo.
final class SunatExceptionError extends CpeException {
  final int sunatCode;

  SunatExceptionError({
    required this.sunatCode,
    required super.message,
    super.rawResponse,
  }) : super(code: sunatCode.toString().padLeft(4, '0'));
}

/// 5. Rechazo definitivo de negocio por SUNAT/OSE (Códigos 2000 a 3999).
/// El comprobante queda RECHAZADO; incluye el CDR de rechazo si fue generado por el OSE.
final class SunatRejectionException extends CpeException {
  final int sunatCode;
  final CdrData? rejectionCdr;

  SunatRejectionException({
    required this.sunatCode,
    required super.message,
    this.rejectionCdr,
    super.rawResponse,
  }) : super(code: sunatCode.toString().padLeft(4, '0'));
}
