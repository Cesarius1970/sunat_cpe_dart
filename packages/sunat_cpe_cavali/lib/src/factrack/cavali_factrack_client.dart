import 'dart:convert';

import 'package:sunat_cpe_core/sunat_cpe_core.dart';

/// Estado de conformidad de una factura comercial al crédito en Cavali Factrack (plazo de 8 días según DU 013-2020).
enum InvoiceConformityStatus {
  /// Dentro de la ventana de revisión de 8 días calendario.
  pending,

  /// Conformidad expresa otorgada por el adquirente o comprador.
  expressConformity,

  /// Conformidad presunta por vencimiento del plazo legal de 8 días.
  presumedConformity,

  /// Disconformidad registrada por el adquirente.
  disconformity,
}

/// Estado en Cavali Factrack para una factura comercial negociable.
final class CavaliInvoiceStatus {
  /// Identificador de la factura consultada.
  final DocumentId documentId;

  /// Estado actual de conformidad de la factura.
  final InvoiceConformityStatus conformityStatus;

  /// Indica si la factura ya se encuentra anotada en cuenta en Cavali ICLV.
  final bool isRegisteredInCavali;

  /// Identificador de proceso o lote asignado por Cavali Factrack.
  final String? cavaliProcessId;

  /// Fecha y hora en que se registró la conformidad.
  final DateTime? conformityDate;

  /// Crea un registro inmutable de estado de factura negociable en Cavali.
  const CavaliInvoiceStatus({
    required this.documentId,
    required this.conformityStatus,
    required this.isRegisteredInCavali,
    this.cavaliProcessId,
    this.conformityDate,
  });
}

/// Interfaz de capacidad extendida para operaciones de Factoring en Cavali Factrack.
abstract interface class CavaliFactoringCapability {
  /// Envía un lote de facturas al crédito aceptadas (XML + CDR) a Cavali Factrack (`POST /invoice/xml`).
  Future<CpeResult<String>> registerInvoicesForFactoring(
    List<CpeEmissionResponse> acceptedInvoices,
  );

  /// Consulta el estado de conformidad y anotación en cuenta de una factura al crédito en Cavali.
  Future<CpeResult<CavaliInvoiceStatus>> checkConformityStatus(
    DocumentId documentId,
  );
}

/// Cliente REST para Cavali Factrack v2 (`/invoice/xml` y `/invoice/status`).
final class CavaliFactrackClient implements CavaliFactoringCapability {
  /// URL base del servicio REST Cavali Factrack v2.
  final Uri baseUri;

  /// Cliente HTTP subyacente (usualmente configurado con [CavaliOAuth2Interceptor]).
  final CpeHttpClient httpClient;

  /// Tiempo máximo de espera por petición HTTP.
  final Duration timeout;

  /// Crea una instancia constante de [CavaliFactrackClient].
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
