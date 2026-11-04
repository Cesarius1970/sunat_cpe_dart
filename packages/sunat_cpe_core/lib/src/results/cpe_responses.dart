import '../catalogs/sunat_catalogs.dart';
import '../entities/cpe_entities.dart';

/// Estado de procesamiento de un comprobante CPE o Ticket.
enum CpeProcessStatus {
  accepted,
  acceptedWithWarnings,
  inProcess,
  rejected,
  voided,
}

/// Observación no bloqueante devuelta por SUNAT/OSE (Códigos 4000+).
final class SunatWarning {
  final String code;
  final String description;

  const SunatWarning({required this.code, required this.description});

  @override
  String toString() => '[$code] $description';
}

/// Constancia de Recepción (CDR) extraída de `R-{RUC}-{TIPO}-{SERIE}-{NUM}.zip` o JSON de un PSE.
final class CdrData {
  final String id;
  final String responseCode;
  final String description;
  final DateTime responseDateTime;
  final String? digestValue;
  final List<int>? cdrZipBytes;
  final String? cdrXmlContent;
  final String? qrContent;
  final List<SunatWarning> warnings;

  const CdrData({
    required this.id,
    required this.responseCode,
    required this.description,
    required this.responseDateTime,
    this.digestValue,
    this.cdrZipBytes,
    this.cdrXmlContent,
    this.qrContent,
    this.warnings = const [],
  });

  bool get isAccepted => responseCode == '0' || responseCode == '0000';
}

/// Respuesta de emisión unificada para operaciones CPE síncronas y diferidas.
final class CpeEmissionResponse {
  final DocumentId documentId;
  final CpeProcessStatus status;
  final CdrData? cdr;
  final String? ticket;
  final String? signedXmlContent;
  final String? digestValue;
  final String? qrContent;
  final String? xmlDownloadUrl;
  final String? cdrDownloadUrl;
  final String? pdfDownloadUrl;

  const CpeEmissionResponse({
    required this.documentId,
    required this.status,
    this.cdr,
    this.ticket,
    this.signedXmlContent,
    this.digestValue,
    this.qrContent,
    this.xmlDownloadUrl,
    this.cdrDownloadUrl,
    this.pdfDownloadUrl,
  });
}

/// Respuesta inmediata para operaciones asíncronas (RC, RA, RR, GRE, EFACT REST).
final class TicketResponse {
  final String ticket;
  final DocumentId? referenceId;
  final DateTime receivedAt;
  final String? signedXmlContent;

  const TicketResponse({
    required this.ticket,
    this.referenceId,
    required this.receivedAt,
    this.signedXmlContent,
  });
}

/// Respuesta de estado al consultar un Ticket asíncrono (`checkTicket`).
final class TicketStatusResponse {
  final String ticket;
  final CpeProcessStatus status;
  final CdrData? cdr;
  final String? statusCode;
  final String? statusMessage;

  const TicketStatusResponse({
    required this.ticket,
    required this.status,
    this.cdr,
    this.statusCode,
    this.statusMessage,
  });
}

/// Parámetros de consulta para verificar el estado y obtener el CDR de un CPE emitido previamente.
final class DocumentStatusQuery {
  final String issuerRuc;
  final CpeDocumentType documentType;
  final String series;
  final int number;

  const DocumentStatusQuery({
    required this.issuerRuc,
    required this.documentType,
    required this.series,
    required this.number,
  });
}

/// Resultado de consultar el estado de un comprobante emitido previamente (`queryDocumentStatus`).
final class CpeStatusQueryResponse {
  final CpeProcessStatus status;
  final String statusCode;
  final String statusMessage;
  final CdrData? cdr;
  final String? xmlDownloadUrl;
  final String? cdrDownloadUrl;
  final String? pdfDownloadUrl;

  const CpeStatusQueryResponse({
    required this.status,
    required this.statusCode,
    required this.statusMessage,
    this.cdr,
    this.xmlDownloadUrl,
    this.cdrDownloadUrl,
    this.pdfDownloadUrl,
  });
}
