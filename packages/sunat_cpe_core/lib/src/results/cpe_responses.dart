import '../catalogs/sunat_catalogs.dart';
import '../entities/cpe_entities.dart';

/// Processing status of a CPE document or Ticket.
enum CpeProcessStatus {
  accepted,
  acceptedWithWarnings,
  inProcess,
  rejected,
  voided,
}

/// Non-blocking observation returned by SUNAT/OSE (Codes 4000+).
final class SunatWarning {
  final String code;
  final String description;

  const SunatWarning({required this.code, required this.description});

  @override
  String toString() => '[$code] $description';
}

/// Constancia de Recepción (CDR) parsed from `R-{RUC}-{TIPO}-{SERIE}-{NUM}.zip` or PSE JSON.
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

/// Unified emission response for synchronous and deferred CPE operations.
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

/// Immediate response for asynchronous operations (RC, RA, RR, GRE, EFACT REST).
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

/// Status response when checking an asynchronous Ticket (`checkTicket`).
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

/// Query parameters to check the status/CDR of a previously issued CPE.
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

/// Result of querying a previously issued document (`queryDocumentStatus`).
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
