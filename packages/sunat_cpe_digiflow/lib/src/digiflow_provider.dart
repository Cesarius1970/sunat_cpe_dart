import 'package:sunat_cpe_core/sunat_cpe_core.dart';
import 'package:xml/xml.dart';

import 'digiflow_config.dart';
import 'soap/digiflow_soap_envelope.dart';

/// Proveedor OSE de Digiflow que extiende [BaseUblOseProvider] con cabecera `SOAPAction` estricta y modos duales para GRE.
final class DigiflowProvider extends BaseUblOseProvider {
  /// Configuración de endpoint, credenciales WS-Security y modo de despacho GRE de Digiflow.
  final DigiflowConfig config;

  /// Constructor de sobres SOAP 1.1 con atributo `soapenv:mustUnderstand="1"`.
  final DigiflowSoapEnvelope envelopeBuilder;
  final Map<String, CdrData> _syncDespatchCdrCache = {};

  /// Inicializa el proveedor [DigiflowProvider] con la configuración y dependencias opcionales.
  DigiflowProvider({
    required this.config,
    super.httpClient,
    super.validator,
    super.xmlBuilder,
    super.signer,
    super.zipCodec,
    this.envelopeBuilder = const DigiflowSoapEnvelope(),
  }) : super(
         endpointUri: config.endpointUri,
         wsseUsername: config.username,
         wssePassword: config.password,
         certificate: config.certificate,
         includeSoapActionHeader: true,
       );

  @override
  String get providerId => 'digiflow';

  @override
  String buildSoapEnvelope({required String bodyXml}) {
    return envelopeBuilder.build(
      wsseUsername: wsseUsername,
      wssePassword: wssePassword,
      bodyXml: bodyXml,
    );
  }

  @override
  Future<CpeResult<TicketResponse>> sendDespatchAdvice(
    DespatchAdviceDocument guide,
  ) async {
    if (config.despatchMode == DigiflowDespatchMode.asyncTicket) {
      return super.sendDespatchAdvice(guide);
    }

    // Synchronous sendBill mode for GRE (09/31) in Digiflow OSE
    final validation = validator.validate(guide);
    if (validation is CpeFailure<void>) {
      return CpeFailure(validation.error);
    }

    try {
      final unsignedXml = xmlBuilder.buildUnsignedXml(guide);
      final signed = signer.signXml(unsignedXml, certificate);
      final encodedZip = zipCodec.encodeXmlToZip(
        fileNameBase: guide.id.fileNameBase,
        xmlContent: signed.signedXml,
      );

      final soapEnvelope = buildSoapEnvelope(
        bodyXml:
            '<ser:sendBill>'
            '<fileName>${guide.id.fileNameBase}.zip</fileName>'
            '<contentFile>${encodedZip.base64Zip}</contentFile>'
            '</ser:sendBill>',
      );

      final response = await httpClient.send(
        CpeHttpRequest(
          method: 'POST',
          uri: endpointUri,
          headers: const {
            'Content-Type': 'text/xml; charset=utf-8',
            'SOAPAction': '"urn:sendBill"',
          },
          body: soapEnvelope,
        ),
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
            message: 'Missing <applicationResponse> in Digiflow GRE sendBill response',
            httpStatusCode: response.statusCode,
            rawResponse: response.bodyAsString,
          ),
        );
      }

      final cdr = zipCodec.parseCdrFromBase64Zip(appResponseBase64);
      final syntheticTicket = 'DIGIFLOW-GRE-${guide.id.fileNameBase}';
      _syncDespatchCdrCache[syntheticTicket] = cdr;

      return CpeSuccess(
        TicketResponse(
          ticket: syntheticTicket,
          referenceId: guide.id,
          receivedAt: DateTime.now(),
          signedXmlContent: signed.signedXml,
        ),
      );
    } on CpeException catch (e) {
      return CpeFailure(e);
    } catch (e, st) {
      return CpeFailure(
        OseTransportException(
          message: 'Unexpected error in Digiflow GRE sendBill: $e',
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
    final cachedCdr = _syncDespatchCdrCache.remove(ticket);
    if (cachedCdr != null) {
      final status = cachedCdr.isAccepted
          ? (cachedCdr.warnings.isEmpty
                ? CpeProcessStatus.accepted
                : CpeProcessStatus.acceptedWithWarnings)
          : CpeProcessStatus.rejected;
      return CpeSuccess(
        TicketStatusResponse(
          ticket: ticket,
          status: status,
          cdr: cachedCdr,
          statusCode: cachedCdr.responseCode,
          statusMessage: cachedCdr.description,
        ),
      );
    }
    return super.checkTicket(ticket, referenceId: referenceId);
  }
}
