import 'dart:convert';

import 'package:sunat_cpe_core/sunat_cpe_core.dart';

/// REST client for EFACT `api-efact-ose` (`/v1/document`, `/v1/cdr/{ticket}`, `/v1/xml/{ticket}`, `/v1/pdf/{ticket}`).
final class EfactRestClient {
  final Uri baseUri;
  final CpeHttpClient httpClient;
  final CpeZipCodec zipCodec;
  final Duration timeout;

  const EfactRestClient({
    required this.baseUri,
    required this.httpClient,
    this.zipCodec = const CpeZipCodec(),
    this.timeout = const Duration(seconds: 30),
  });

  /// Sends a `multipart/form-data` payload to `POST /v1/document` and returns the Ticket UUID.
  Future<CpeResult<String>> submitMultipartDocument({
    required String fileName,
    required String contentType,
    required String fileContent,
  }) async {
    const boundary = '----SunatCpeEfactBoundary7MA4YWxkTrZu0gW';
    final multipartBody = StringBuffer()
      ..write('--$boundary\r\n')
      ..write(
        'Content-Disposition: form-data; name="file"; filename="$fileName"\r\n',
      )
      ..write('Content-Type: $contentType\r\n\r\n')
      ..write(fileContent)
      ..write('\r\n--$boundary--\r\n');

    final uri = _resolveEndpoint('/v1/document');

    try {
      final response = await httpClient.send(
        CpeHttpRequest(
          method: 'POST',
          uri: uri,
          headers: {
            'Content-Type': 'multipart/form-data; boundary=$boundary',
            'Accept': 'application/json',
          },
          body: multipartBody.toString(),
          timeout: timeout,
        ),
      );

      if (response.statusCode == 401 || response.statusCode == 403) {
        return CpeFailure(
          OseAuthException(
            message: 'EFACT REST unauthorized (HTTP ${response.statusCode})',
            code: response.statusCode.toString(),
            rawResponse: response.bodyAsString,
          ),
        );
      }

      final bodyText = response.bodyAsString.trim();
      Map<String, dynamic>? decoded;
      if (bodyText.startsWith('{')) {
        try {
          decoded = jsonDecode(bodyText) as Map<String, dynamic>;
        } catch (_) {}
      }

      if (response.statusCode == 200 || response.statusCode == 201) {
        final code = decoded?['code']?.toString() ?? '0';
        final description = decoded?['description']?.toString() ?? bodyText;
        if (code == '0' && description.isNotEmpty) {
          return CpeSuccess(description);
        }
        return _mapEfactError(code, description, response.statusCode, bodyText);
      }

      final errCode =
          decoded?['code']?.toString() ?? response.statusCode.toString();
      final errDesc = decoded?['description']?.toString() ?? bodyText;
      return _mapEfactError(errCode, errDesc, response.statusCode, bodyText);
    } on CpeException catch (e) {
      return CpeFailure(e);
    } catch (e, st) {
      return CpeFailure(
        OseTransportException(
          message: 'Error submitting multipart document to EFACT REST: $e',
          rawResponse: e,
          stackTrace: st,
        ),
      );
    }
  }

  /// Queries `GET /v1/cdr/{ticket}` to check ticket status and parse the CDR XML when ready.
  Future<CpeResult<TicketStatusResponse>> fetchTicketCdr(String ticket) async {
    final uri = _resolveEndpoint('/v1/cdr/$ticket');

    try {
      final response = await httpClient.send(
        CpeHttpRequest(
          method: 'GET',
          uri: uri,
          headers: const {'Accept': 'application/xml, application/json'},
          timeout: timeout,
        ),
      );

      final bodyText = response.bodyAsString.trim();

      // HTTP 202 Accepted or HTTP 412 with code -9998 means "In Process"
      if (response.statusCode == 202 ||
          (response.statusCode == 412 && bodyText.contains('-9998'))) {
        return CpeSuccess(
          TicketStatusResponse(
            ticket: ticket,
            status: CpeProcessStatus.inProcess,
            statusCode: '98',
            statusMessage: 'Documento en proceso en EFACT OSE',
          ),
        );
      }

      if (response.statusCode == 200) {
        if (bodyText.startsWith('<')) {
          final cdr = zipCodec.parseCdrFromXmlString(bodyText);
          if (!cdr.isAccepted) {
            return CpeSuccess(
              TicketStatusResponse(
                ticket: ticket,
                status: CpeProcessStatus.rejected,
                cdr: cdr,
                statusCode: cdr.responseCode,
                statusMessage: cdr.description,
              ),
            );
          }
          final status = cdr.warnings.isEmpty
              ? CpeProcessStatus.accepted
              : CpeProcessStatus.acceptedWithWarnings;
          return CpeSuccess(
            TicketStatusResponse(
              ticket: ticket,
              status: status,
              cdr: cdr,
              statusCode: cdr.responseCode,
              statusMessage: cdr.description,
            ),
          );
        }
      }

      // JSON error payload (e.g. SUNAT rejection or exception reported by EFACT)
      if (bodyText.startsWith('{')) {
        try {
          final decoded = jsonDecode(bodyText) as Map<String, dynamic>;
          final codeStr = decoded['code']?.toString() ?? '99';
          final descStr = decoded['description']?.toString() ?? bodyText;
          if (codeStr == '-9998' || codeStr == '98') {
            return CpeSuccess(
              TicketStatusResponse(
                ticket: ticket,
                status: CpeProcessStatus.inProcess,
                statusCode: '98',
                statusMessage: descStr,
              ),
            );
          }
          return CpeSuccess(
            TicketStatusResponse(
              ticket: ticket,
              status: CpeProcessStatus.rejected,
              statusCode: codeStr,
              statusMessage: descStr,
            ),
          );
        } catch (_) {}
      }

      return CpeFailure(
        OseTransportException(
          message:
              'Unexpected response from EFACT /v1/cdr/$ticket (HTTP ${response.statusCode})',
          httpStatusCode: response.statusCode,
          rawResponse: bodyText,
        ),
      );
    } on CpeException catch (e) {
      return CpeFailure(e);
    } catch (e, st) {
      return CpeFailure(
        OseTransportException(
          message: 'Error fetching CDR for ticket $ticket from EFACT REST: $e',
          rawResponse: e,
          stackTrace: st,
        ),
      );
    }
  }

  String cdrDownloadUrl(String ticket) =>
      _resolveEndpoint('/v1/cdr/$ticket').toString();
  String xmlDownloadUrl(String ticket) =>
      _resolveEndpoint('/v1/xml/$ticket').toString();
  String pdfDownloadUrl(String ticket) =>
      _resolveEndpoint('/v1/pdf/$ticket').toString();

  Uri _resolveEndpoint(String relativePath) {
    final baseStr = baseUri.toString().replaceAll(RegExp(r'/+$'), '');
    final cleanRel = relativePath.startsWith('/')
        ? relativePath
        : '/$relativePath';
    return Uri.parse('$baseStr$cleanRel');
  }

  CpeFailure<T> _mapEfactError<T>(
    String codeStr,
    String description,
    int httpStatus,
    Object raw,
  ) {
    final numericMatch = RegExp(r'\b(0[1-9]\d{2}|[1-3]\d{3})\b')
        .firstMatch('$codeStr $description');
    if (numericMatch != null) {
      final sunatCode = int.parse(numericMatch.group(1)!);
      if (sunatCode >= 100 && sunatCode < 2000) {
        return CpeFailure(
          SunatExceptionError(
            sunatCode: sunatCode,
            message: description,
            rawResponse: raw,
          ),
        );
      }
      if (sunatCode >= 2000 && sunatCode < 4000) {
        return CpeFailure(
          SunatRejectionException(
            sunatCode: sunatCode,
            message: description,
            rawResponse: raw,
          ),
        );
      }
    }
    return CpeFailure(
      OseTransportException(
        message: 'EFACT REST error [$codeStr]: $description',
        code: codeStr,
        httpStatusCode: httpStatus,
        isRetryable: httpStatus >= 500,
        rawResponse: raw,
      ),
    );
  }
}
