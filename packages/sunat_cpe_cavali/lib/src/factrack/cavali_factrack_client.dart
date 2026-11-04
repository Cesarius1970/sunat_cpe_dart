import 'dart:convert';

import 'package:sunat_cpe_core/sunat_cpe_core.dart';

/// Conformity status of a credit invoice in Cavali Factrack (DU 013-2020 8-day window).
enum InvoiceConformityStatus {
  /// Within the 8 calendar day review window.
  pending,

  /// Express conformity granted by the buyer/acquirer.
  expressConformity,

  /// Presumed conformity due to expiration of the 8-day window.
  presumedConformity,

  /// Disconformity registered by the buyer.
  disconformity,
}

/// Cavali Factrack status for a negotiable invoice.
final class CavaliInvoiceStatus {
  final DocumentId documentId;
  final InvoiceConformityStatus conformityStatus;
  final bool isRegisteredInCavali;
  final String? cavaliProcessId;
  final DateTime? conformityDate;

  const CavaliInvoiceStatus({
    required this.documentId,
    required this.conformityStatus,
    required this.isRegisteredInCavali,
    this.cavaliProcessId,
    this.conformityDate,
  });
}

/// Extended capability interface for Cavali Factrack factoring operations.
abstract interface class CavaliFactoringCapability {
  /// Sends a batch of accepted credit invoices (XML + CDR) to Cavali Factrack (`POST /invoice/xml`).
  Future<CpeResult<String>> registerInvoicesForFactoring(
    List<CpeEmissionResponse> acceptedInvoices,
  );

  /// Queries the conformity and book-entry status of a credit invoice in Cavali.
  Future<CpeResult<CavaliInvoiceStatus>> checkConformityStatus(
    DocumentId documentId,
  );
}

/// REST client for Cavali Factrack v2 (`/invoice/xml` and `/invoice/status`).
final class CavaliFactrackClient implements CavaliFactoringCapability {
  final Uri baseUri;
  final CpeHttpClient httpClient;
  final Duration timeout;

  const CavaliFactrackClient({
    required this.baseUri,
    required this.httpClient,
    this.timeout = const Duration(seconds: 30),
  });

  @override
  Future<CpeResult<String>> registerInvoicesForFactoring(
    List<CpeEmissionResponse> acceptedInvoices,
  ) async {
    try {
      final invoiceEntries = acceptedInvoices.map((inv) {
        final xmlBase64 = inv.signedXmlContent != null
            ? base64.encode(utf8.encode(inv.signedXmlContent!))
            : '';
        return {
          'name': '${inv.documentId.fileNameBase}.xml',
          'fileXml': xmlBase64,
        };
      }).toList();

      final payload = {
        'invoiceXMLDetail': {'invoiceXML': invoiceEntries},
      };

      final baseStr = baseUri.toString().replaceAll(RegExp(r'/+$'), '');
      final response = await httpClient.send(
        CpeHttpRequest(
          method: 'POST',
          uri: Uri.parse('$baseStr/invoice/xml'),
          headers: const {
            'Content-Type': 'application/json; charset=utf-8',
            'Accept': 'application/json',
          },
          body: jsonEncode(payload),
          timeout: timeout,
        ),
      );

      if (response.statusCode != 200 && response.statusCode != 201) {
        return CpeFailure(
          OseTransportException(
            message:
                'Cavali Factrack /invoice/xml error (HTTP ${response.statusCode}): ${response.bodyAsString}',
            httpStatusCode: response.statusCode,
            rawResponse: response.bodyAsString,
          ),
        );
      }

      final decoded = jsonDecode(response.bodyAsString) as Map<String, dynamic>;
      final processId =
          decoded['idProceso']?.toString() ??
          decoded['processId']?.toString() ??
          'CAVALI-PROC';
      return CpeSuccess(processId);
    } on CpeException catch (e) {
      return CpeFailure(e);
    } catch (e, st) {
      return CpeFailure(
        OseTransportException(
          message:
              'Unexpected error registering invoices in Cavali Factrack: $e',
          rawResponse: e,
          stackTrace: st,
        ),
      );
    }
  }

  @override
  Future<CpeResult<CavaliInvoiceStatus>> checkConformityStatus(
    DocumentId documentId,
  ) async {
    try {
      final baseStr = baseUri.toString().replaceAll(RegExp(r'/+$'), '');
      final response = await httpClient.send(
        CpeHttpRequest(
          method: 'POST',
          uri: Uri.parse('$baseStr/invoice/status'),
          headers: const {
            'Content-Type': 'application/json; charset=utf-8',
            'Accept': 'application/json',
          },
          body: jsonEncode({
            'rucProveedor': documentId.issuerRuc,
            'tipoComprobante': documentId.type.code,
            'serie': documentId.series,
            'numeracion': documentId.number,
          }),
          timeout: timeout,
        ),
      );

      if (response.statusCode != 200) {
        return CpeFailure(
          OseTransportException(
            message:
                'Cavali Factrack /invoice/status error (HTTP ${response.statusCode})',
            httpStatusCode: response.statusCode,
            rawResponse: response.bodyAsString,
          ),
        );
      }

      final decoded = jsonDecode(response.bodyAsString) as Map<String, dynamic>;
      final stateCode =
          decoded['estadoConformidad']?.toString().toUpperCase() ?? 'PENDIENTE';
      final conformity = switch (stateCode) {
        'EXPRESA' ||
        'EXPRESS' ||
        '01' => InvoiceConformityStatus.expressConformity,
        'PRESUNTA' ||
        'PRESUMED' ||
        '02' => InvoiceConformityStatus.presumedConformity,
        'DISCONFORME' ||
        'DISCONFORMITY' ||
        '03' => InvoiceConformityStatus.disconformity,
        _ => InvoiceConformityStatus.pending,
      };

      return CpeSuccess(
        CavaliInvoiceStatus(
          documentId: documentId,
          conformityStatus: conformity,
          isRegisteredInCavali:
              decoded['anotadaEnCuenta'] == true ||
              decoded['registered'] == true ||
              conformity != InvoiceConformityStatus.pending,
          cavaliProcessId: decoded['idProceso']?.toString(),
          conformityDate: decoded['fechaConformidad'] != null
              ? DateTime.tryParse(decoded['fechaConformidad'].toString())
              : null,
        ),
      );
    } on CpeException catch (e) {
      return CpeFailure(e);
    } catch (e, st) {
      return CpeFailure(
        OseTransportException(
          message: 'Error checking conformity status in Cavali Factrack: $e',
          rawResponse: e,
          stackTrace: st,
        ),
      );
    }
  }
}
