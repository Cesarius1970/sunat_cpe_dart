import 'package:decimal/decimal.dart';
import 'package:xml/xml.dart';

import '../contracts/ose_provider.dart';
import '../entities/cpe_entities.dart';
import '../results/cpe_responses.dart';
import '../results/cpe_result.dart';
import '../signing/cpe_zip_codec.dart';
import '../signing/xades_bes_signer.dart';
import '../transport/cpe_http_client.dart';
import '../ubl/ubl_xml_builder.dart';
import '../validation/cpe_math_validator.dart';

/// Implementación base con patrón Template Method para todos los proveedores OSE SOAP 1.1 UBL 2.1
/// (Bizlinks, Digiflow, TCI, Sovos, Cavali/Gosocket, EFACT SOAP).
abstract base class BaseUblOseProvider
    with TicketPollingMixin
    implements OseProvider {
  final Uri endpointUri;
  final String wsseUsername;
  final String wssePassword;
  final CpeCertificateCredentials certificate;
  final CpeHttpClient httpClient;
  final CpeMathValidator validator;
  final UblXmlBuilder xmlBuilder;
  final XadesBesSigner signer;
  final CpeZipCodec zipCodec;
  final bool includeSoapActionHeader;

  BaseUblOseProvider({
    required this.endpointUri,
    required this.wsseUsername,
    required this.wssePassword,
    required this.certificate,
    CpeHttpClient? httpClient,
    CpeMathValidator? validator,
    this.xmlBuilder = const UblXmlBuilder(),
    this.signer = const XadesBesSigner(),
    this.zipCodec = const CpeZipCodec(),
    this.includeSoapActionHeader = true,
  }) : httpClient = httpClient ?? DefaultCpeHttpClient(),
       validator = validator ?? CpeMathValidator();

  @override
  Set<ProviderCapability> get capabilities => const {
    ProviderCapability.invoiceAndNotes,
    ProviderCapability.purchaseSettlement,
    ProviderCapability.dailySummary,
    ProviderCapability.voidedDocuments,
    ProviderCapability.despatchAdvice,
    ProviderCapability.retentionPerception,
    ProviderCapability.statusQuery,
  };

  @override
  Future<CpeResult<CpeEmissionResponse>> sendDocument(
    SalesCpeDocument document,
  ) => _executeSendBill(
    document,
    totalAmountForQr: document.totals.importeTotalPagar,
    igvAmountForQr: document.totals.totalIgv,
    customerForQr: document.customer,
  );

  @override
  Future<CpeResult<CpeEmissionResponse>> sendRetentionOrPerception(
    AgentCpeDocument document,
  ) => _executeSendBill(
    document,
    totalAmountForQr: document.totalAmountInPen,
    igvAmountForQr: Decimal.zero,
    customerForQr: document.partner,
  );

  @override
  Future<CpeResult<TicketResponse>> sendDailySummary(
    DailySummaryDocument summary,
  ) => _executeSendSummary(summary);

  @override
  Future<CpeResult<TicketResponse>> sendVoidedDocument(VoidedDocument voided) =>
      _executeSendSummary(voided);

  @override
  Future<CpeResult<TicketResponse>> sendDespatchAdvice(
    DespatchAdviceDocument guide,
  ) => _executeSendSummary(guide);

  Future<CpeResult<CpeEmissionResponse>> _executeSendBill(
    CpeDocument document, {
    required Decimal totalAmountForQr,
    required Decimal igvAmountForQr,
    required CustomerParty customerForQr,
  }) async {
    final validation = validator.validate(document);
    if (validation is CpeFailure<void>) {
      return CpeFailure(validation.error);
    }

    try {
      final unsignedXml = xmlBuilder.buildUnsignedXml(document);
      final signed = signer.signXml(unsignedXml, certificate);
      final encodedZip = zipCodec.encodeXmlToZip(
        fileNameBase: document.id.fileNameBase,
        xmlContent: signed.signedXml,
      );

      final soapEnvelope = buildSoapEnvelope(
        bodyXml:
            '<ser:sendBill>'
            '<fileName>${document.id.fileNameBase}.zip</fileName>'
            '<contentFile>${encodedZip.base64Zip}</contentFile>'
            '</ser:sendBill>',
      );

      final response = await _postSoap(
        soapEnvelope,
        soapAction: 'urn:sendBill',
      );
      final faultError = parseSoapFaultIfPresent(response);
      if (faultError != null) {
        return CpeFailure(faultError);
      }

      final xmlDoc = XmlDocument.parse(response.bodyAsString);
      final appResponseBase64 = xmlDoc
          .findAllElements('applicationResponse', namespaceUri: '*')
          .firstOrNull
          ?.innerText
          .trim();

      if (appResponseBase64 == null || appResponseBase64.isEmpty) {
        return CpeFailure(
          OseTransportException(
            message:
                'Missing <applicationResponse> in SOAP sendBill response from $providerId',
            httpStatusCode: response.statusCode,
            rawResponse: response.bodyAsString,
          ),
        );
      }

      final cdr = zipCodec.parseCdrFromBase64Zip(appResponseBase64);
      final qrString = buildStandardSunatQr(
        document: document,
        igvAmount: igvAmountForQr,
        totalAmount: totalAmountForQr,
        customer: customerForQr,
        digestValue: signed.digestValue,
      );

      if (!cdr.isAccepted) {
        final code = int.tryParse(cdr.responseCode) ?? 2000;
        return CpeFailure(
          SunatRejectionException(
            sunatCode: code,
            message: cdr.description,
            rejectionCdr: cdr,
            rawResponse: response.bodyAsString,
          ),
        );
      }

      final status = cdr.warnings.isEmpty
          ? CpeProcessStatus.accepted
          : CpeProcessStatus.acceptedWithWarnings;

      return CpeSuccess(
        CpeEmissionResponse(
          documentId: document.id,
          status: status,
          cdr: CdrData(
            id: cdr.id,
            responseCode: cdr.responseCode,
            description: cdr.description,
            responseDateTime: cdr.responseDateTime,
            digestValue: cdr.digestValue ?? signed.digestValue,
            cdrZipBytes: cdr.cdrZipBytes,
            cdrXmlContent: cdr.cdrXmlContent,
            qrContent: qrString,
            warnings: cdr.warnings,
          ),
          signedXmlContent: signed.signedXml,
          digestValue: signed.digestValue,
          qrContent: qrString,
        ),
      );
    } on CpeException catch (e) {
      return CpeFailure(e);
    } catch (e, st) {
      return CpeFailure(
        OseTransportException(
          message: 'Unexpected error in $providerId sendBill: $e',
          rawResponse: e,
          stackTrace: st,
        ),
      );
    }
  }

  Future<CpeResult<TicketResponse>> _executeSendSummary(
    CpeDocument document,
  ) async {
    final validation = validator.validate(document);
    if (validation is CpeFailure<void>) {
      return CpeFailure(validation.error);
    }

    try {
      final unsignedXml = xmlBuilder.buildUnsignedXml(document);
      final signed = signer.signXml(unsignedXml, certificate);
      final encodedZip = zipCodec.encodeXmlToZip(
        fileNameBase: document.id.fileNameBase,
        xmlContent: signed.signedXml,
      );

      final soapEnvelope = buildSoapEnvelope(
        bodyXml:
            '<ser:sendSummary>'
            '<fileName>${document.id.fileNameBase}.zip</fileName>'
            '<contentFile>${encodedZip.base64Zip}</contentFile>'
            '</ser:sendSummary>',
      );

      final response = await _postSoap(
        soapEnvelope,
        soapAction: 'urn:sendSummary',
      );
      final faultError = parseSoapFaultIfPresent(response);
      if (faultError != null) {
        return CpeFailure(faultError);
      }

      final xmlDoc = XmlDocument.parse(response.bodyAsString);
      final ticket = xmlDoc
          .findAllElements('ticket', namespaceUri: '*')
          .firstOrNull
          ?.innerText
          .trim();

      if (ticket == null || ticket.isEmpty) {
        return CpeFailure(
          OseTransportException(
            message:
                'Missing <ticket> in SOAP sendSummary response from $providerId',
            httpStatusCode: response.statusCode,
            rawResponse: response.bodyAsString,
          ),
        );
      }

      return CpeSuccess(
        TicketResponse(
          ticket: ticket,
          referenceId: document.id,
          receivedAt: DateTime.now(),
          signedXmlContent: signed.signedXml,
        ),
      );
    } on CpeException catch (e) {
      return CpeFailure(e);
    } catch (e, st) {
      return CpeFailure(
        OseTransportException(
          message: 'Unexpected error in $providerId sendSummary: $e',
          rawResponse: e,
          stackTrace: st,
        ),
      );
    }
  }

  @override
  Future<CpeResult<TicketStatusResponse>> checkTicket(
    String ticket, {
    DocumentId? referenceId,
  }) async {
    try {
      final soapEnvelope = buildSoapEnvelope(
        bodyXml:
            '<ser:getStatus>'
            '<ticket>$ticket</ticket>'
            '</ser:getStatus>',
      );

      final response = await _postSoap(
        soapEnvelope,
        soapAction: 'urn:getStatus',
      );
      final faultError = parseSoapFaultIfPresent(response);
      if (faultError != null) {
        return CpeFailure(faultError);
      }

      final xmlDoc = XmlDocument.parse(response.bodyAsString);
      final statusCode =
          xmlDoc
              .findAllElements('statusCode', namespaceUri: '*')
              .firstOrNull
              ?.innerText
              .trim() ??
          '98';
      final contentBase64 = xmlDoc
          .findAllElements('content', namespaceUri: '*')
          .firstOrNull
          ?.innerText
          .trim();

      if (statusCode == '98' || statusCode == '0098') {
        return CpeSuccess(
          TicketStatusResponse(
            ticket: ticket,
            status: CpeProcessStatus.inProcess,
            statusCode: statusCode,
            statusMessage: 'En proceso',
          ),
        );
      }

      CdrData? cdr;
      if (contentBase64 != null && contentBase64.isNotEmpty) {
        try {
          cdr = zipCodec.parseCdrFromBase64Zip(contentBase64);
        } catch (_) {
          // Some OSEs place plain text message in <content> on 99 errors
        }
      }

      if (statusCode == '0' ||
          statusCode == '0000' ||
          (cdr != null && cdr.isAccepted)) {
        final processStatus = (cdr?.warnings.isNotEmpty ?? false)
            ? CpeProcessStatus.acceptedWithWarnings
            : CpeProcessStatus.accepted;
        return CpeSuccess(
          TicketStatusResponse(
            ticket: ticket,
            status: processStatus,
            cdr: cdr,
            statusCode: statusCode,
            statusMessage: cdr?.description ?? 'Aceptado',
          ),
        );
      }

      return CpeSuccess(
        TicketStatusResponse(
          ticket: ticket,
          status: CpeProcessStatus.rejected,
          cdr: cdr,
          statusCode: statusCode,
          statusMessage:
              cdr?.description ?? 'Ticket rechazado (código $statusCode)',
        ),
      );
    } on CpeException catch (e) {
      return CpeFailure(e);
    } catch (e, st) {
      return CpeFailure(
        OseTransportException(
          message: 'Error checking ticket $ticket on $providerId: $e',
          rawResponse: e,
          stackTrace: st,
        ),
      );
    }
  }

  @override
  Future<CpeResult<CpeStatusQueryResponse>> queryDocumentStatus(
    DocumentStatusQuery query,
  ) async {
    try {
      final soapEnvelope = buildSoapEnvelope(
        bodyXml:
            '<ser:getStatusCdr>'
            '<rucComprobante>${query.issuerRuc}</rucComprobante>'
            '<tipoComprobante>${query.documentType.code}</tipoComprobante>'
            '<serieComprobante>${query.series}</serieComprobante>'
            '<numeroComprobante>${query.number}</numeroComprobante>'
            '</ser:getStatusCdr>',
      );

      final response = await _postSoap(
        soapEnvelope,
        soapAction: 'urn:getStatusCdr',
      );
      final faultError = parseSoapFaultIfPresent(response);
      if (faultError != null) {
        return CpeFailure(faultError);
      }

      final xmlDoc = XmlDocument.parse(response.bodyAsString);
      final statusCode =
          xmlDoc
              .findAllElements('statusCode', namespaceUri: '*')
              .firstOrNull
              ?.innerText
              .trim() ??
          '0';
      final statusMessage =
          xmlDoc
              .findAllElements('statusMessage', namespaceUri: '*')
              .firstOrNull
              ?.innerText
              .trim() ??
          '';
      final contentBase64 = xmlDoc
          .findAllElements('content', namespaceUri: '*')
          .firstOrNull
          ?.innerText
          .trim();

      CdrData? cdr;
      if (contentBase64 != null && contentBase64.isNotEmpty) {
        cdr = zipCodec.parseCdrFromBase64Zip(contentBase64);
      }

      final isAccepted =
          statusCode == '0' ||
          statusCode == '0004' ||
          (cdr?.isAccepted ?? false);
      return CpeSuccess(
        CpeStatusQueryResponse(
          status: isAccepted
              ? CpeProcessStatus.accepted
              : CpeProcessStatus.rejected,
          statusCode: statusCode,
          statusMessage: statusMessage.isNotEmpty
              ? statusMessage
              : (cdr?.description ?? ''),
          cdr: cdr,
        ),
      );
    } on CpeException catch (e) {
      return CpeFailure(e);
    } catch (e, st) {
      return CpeFailure(
        OseTransportException(
          message: 'Error querying document status on $providerId: $e',
          rawResponse: e,
          stackTrace: st,
        ),
      );
    }
  }

  /// Construye el sobre SOAP 1.1 con cabecera OASIS WS-Security `UsernameToken`.
  String buildSoapEnvelope({required String bodyXml}) {
    return '<?xml version="1.0" encoding="UTF-8"?>'
        '<soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/" '
        'xmlns:ser="http://service.sunat.gob.pe" '
        'xmlns:wsse="http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-wssecurity-secext-1.0.xsd">'
        '<soapenv:Header>'
        '<wsse:Security>'
        '<wsse:UsernameToken>'
        '<wsse:Username>$wsseUsername</wsse:Username>'
        '<wsse:Password Type="http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-username-token-profile-1.0#PasswordText">$wssePassword</wsse:Password>'
        '</wsse:UsernameToken>'
        '</wsse:Security>'
        '</soapenv:Header>'
        '<soapenv:Body>$bodyXml</soapenv:Body>'
        '</soapenv:Envelope>';
  }

  Future<CpeHttpResponse> _postSoap(
    String soapEnvelope, {
    required String soapAction,
  }) {
    final headers = <String, String>{
      'Content-Type': 'text/xml; charset=utf-8',
      if (includeSoapActionHeader) 'SOAPAction': '"$soapAction"',
    };
    return httpClient.send(
      CpeHttpRequest(
        method: 'POST',
        uri: endpointUri,
        headers: headers,
        body: soapEnvelope,
      ),
    );
  }

  /// Extrae una excepción tipada [CpeException] si la respuesta SOAP contiene un nodo `<Fault>`.
  CpeException? parseSoapFaultIfPresent(CpeHttpResponse response) {
    final body = response.bodyAsString;
    if (!body.contains('Fault')) {
      if (response.statusCode == 401 || response.statusCode == 403) {
        return OseAuthException(
          message: 'HTTP ${response.statusCode} Unauthorized from $providerId',
          rawResponse: body,
        );
      }
      if (response.statusCode >= 500) {
        return OseTransportException(
          message: 'HTTP ${response.statusCode} Server Error from $providerId',
          httpStatusCode: response.statusCode,
          rawResponse: body,
        );
      }
      return null;
    }

    try {
      final doc = XmlDocument.parse(body);
      final faultEl = doc
          .findAllElements('Fault', namespaceUri: '*')
          .firstOrNull;
      if (faultEl == null) return null;

      final faultCode =
          faultEl
              .findAllElements('faultcode', namespaceUri: '*')
              .firstOrNull
              ?.innerText
              .trim() ??
          '';
      final faultString =
          faultEl
              .findAllElements('faultstring', namespaceUri: '*')
              .firstOrNull
              ?.innerText
              .trim() ??
          '';
      final detailMsg =
          faultEl
              .findAllElements('message', namespaceUri: '*')
              .firstOrNull
              ?.innerText
              .trim() ??
          '';

      final combinedText = '$faultCode $faultString $detailMsg';
      final codeMatch = RegExp(r'\b(0[1-9]\d{2}|[1-3]\d{3})\b')
          .firstMatch(combinedText);

      if (codeMatch != null) {
        final sunatCode = int.parse(codeMatch.group(1)!);
        final description = detailMsg.isNotEmpty ? detailMsg : faultString;

        if (sunatCode >= 100 && sunatCode <= 109) {
          return OseAuthException(
            message:
                'WS-Security authentication error ($sunatCode): $description',
            code: sunatCode.toString().padLeft(4, '0'),
            rawResponse: body,
          );
        }
        if (sunatCode >= 100 && sunatCode < 2000) {
          return SunatExceptionError(
            sunatCode: sunatCode,
            message: description,
            rawResponse: body,
          );
        }
        if (sunatCode >= 2000 && sunatCode < 4000) {
          return SunatRejectionException(
            sunatCode: sunatCode,
            message: description,
            rawResponse: body,
          );
        }
      }

      return OseTransportException(
        message: 'SOAP Fault ($faultCode): $faultString $detailMsg'.trim(),
        httpStatusCode: response.statusCode,
        isRetryable: false,
        rawResponse: body,
      );
    } catch (_) {
      return OseTransportException(
        message:
            'Unparseable SOAP Fault from $providerId (HTTP ${response.statusCode})',
        httpStatusCode: response.statusCode,
        rawResponse: body,
      );
    }
  }

  /// Genera la cadena estándar de texto QR de SUNAT:
  /// `{RUC}|{TIPO}|{SERIE}|{NUMERO}|{IGV}|{TOTAL}|{FECHA}|{TIPO_DOC_CLI}|{NUM_DOC_CLI}|{HASH}|`
  static String buildStandardSunatQr({
    required CpeDocument document,
    required Decimal igvAmount,
    required Decimal totalAmount,
    required CustomerParty customer,
    required String digestValue,
  }) {
    final y = document.issueDate.year.toString().padLeft(4, '0');
    final m = document.issueDate.month.toString().padLeft(2, '0');
    final d = document.issueDate.day.toString().padLeft(2, '0');
    return '${document.issuer.ruc}|'
        '${document.id.type.code}|'
        '${document.id.series}|'
        '${document.id.number}|'
        '${igvAmount.toStringAsFixed(2)}|'
        '${totalAmount.toStringAsFixed(2)}|'
        '$y-$m-$d|'
        '${customer.documentType.code}|'
        '${customer.documentNumber}|'
        '$digestValue|';
  }
}
