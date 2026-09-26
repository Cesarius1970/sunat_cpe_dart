// Copyright (c) 2026, César A Vergara Buenaventura <cesarvergarab@gmail.com>.
// Todos los derechos reservados. Uso sujeto a la licencia en el archivo LICENSE.

import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:xml/xml.dart';

import '../config/cpe_credenciales.dart';
import '../util/cpe_empaquetador_zip.dart';
import 'cpe_cliente_transporte.dart';
import 'cpe_respuesta_sunat.dart';

/// Cliente de comunicación SOAP con WS-Security para los Web Services de SUNAT (billService).
class CPE_ClienteSoap implements CPE_ClienteTransporte {
  final CPE_Credenciales credenciales;
  final http.Client _httpClient;
  final CPE_EmpaquetadorZip _zipUtil;

  CPE_ClienteSoap({
    required this.credenciales,
    http.Client? httpClient,
    CPE_EmpaquetadorZip? zipUtil,
  }) : _httpClient = httpClient ?? http.Client(),
       _zipUtil = zipUtil ?? const CPE_EmpaquetadorZip();

  @override
  Future<CPE_RespuestaSunat> enviarComprobanteZip({
    required String nombreArchivoZip,
    required List<int> bytesZip,
  }) async {
    final base64Zip = base64.encode(bytesZip);
    final soapBody =
        '''
      <ser:sendBill xmlns:ser="http://service.sunat.gob.pe">
        <fileName>$nombreArchivoZip</fileName>
        <contentFile>$base64Zip</contentFile>
      </ser:sendBill>
    ''';

    final envelope = _construirEnvelope(soapBody);
    final url = Uri.parse(credenciales.entorno.urlSoapFactura);

    try {
      final response = await _httpClient.post(
        url,
        headers: {'Content-Type': 'text/xml; charset=utf-8', 'SOAPAction': ''},
        body: envelope,
      );

      return _procesarRespuestaSendBill(response.body);
    } catch (e) {
      return CPE_RespuestaSunat.errorTecnico(
        'Error en la llamada SOAP sendBill: $e',
      );
    }
  }

  @override
  Future<CPE_RespuestaSunat> enviarResumenAsincronoZip({
    required String nombreArchivoZip,
    required List<int> bytesZip,
  }) async {
    final base64Zip = base64.encode(bytesZip);
    final soapBody =
        '''
      <ser:sendSummary xmlns:ser="http://service.sunat.gob.pe">
        <fileName>$nombreArchivoZip</fileName>
        <contentFile>$base64Zip</contentFile>
      </ser:sendSummary>
    ''';

    final envelope = _construirEnvelope(soapBody);
    final url = Uri.parse(credenciales.entorno.urlSoapFactura);

    try {
      final response = await _httpClient.post(
        url,
        headers: {'Content-Type': 'text/xml; charset=utf-8', 'SOAPAction': ''},
        body: envelope,
      );

      return _procesarRespuestaSendSummary(response.body);
    } catch (e) {
      return CPE_RespuestaSunat.errorTecnico(
        'Error en la llamada SOAP sendSummary: $e',
      );
    }
  }

  @override
  Future<CPE_RespuestaSunat> consultarTicket(String ticket) async {
    final soapBody =
        '''
      <ser:getStatus xmlns:ser="http://service.sunat.gob.pe">
        <ticket>$ticket</ticket>
      </ser:getStatus>
    ''';

    final envelope = _construirEnvelope(soapBody);
    final url = Uri.parse(credenciales.entorno.urlSoapFactura);

    try {
      final response = await _httpClient.post(
        url,
        headers: {'Content-Type': 'text/xml; charset=utf-8', 'SOAPAction': ''},
        body: envelope,
      );

      return _procesarRespuestaGetStatus(response.body);
    } catch (e) {
      return CPE_RespuestaSunat.errorTecnico(
        'Error en la llamada SOAP getStatus: $e',
      );
    }
  }

  String _construirEnvelope(String bodyContent) {
    return '''<?xml version="1.0" encoding="utf-8"?>
<soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/">
  <soapenv:Header>
    <wsse:Security xmlns:wsse="http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-wssecurity-secext-1.0.xsd">
      <wsse:UsernameToken>
        <wsse:Username>${credenciales.usuarioWsSecurity}</wsse:Username>
        <wsse:Password>${credenciales.claveSol}</wsse:Password>
      </wsse:UsernameToken>
    </wsse:Security>
  </soapenv:Header>
  <soapenv:Body>
    $bodyContent
  </soapenv:Body>
</soapenv:Envelope>''';
  }

  CPE_RespuestaSunat _procesarRespuestaSendBill(String xmlRespuesta) {
    try {
      final doc = XmlDocument.parse(xmlRespuesta);

      final fault =
          doc.findAllElements('soap-env:Fault').firstOrNull ??
          doc.findAllElements('soapenv:Fault').firstOrNull ??
          doc.findAllElements('Fault').firstOrNull;

      if (fault != null) {
        final faultCode =
            fault.findElements('faultcode').firstOrNull?.innerText ??
            'SOAP_FAULT';
        final faultString =
            fault.findElements('faultstring').firstOrNull?.innerText ??
            'Error de servidor SUNAT';
        return CPE_RespuestaSunat.errorTecnico(faultString, codigo: faultCode);
      }

      final appResponseNode = doc
          .findAllElements('applicationResponse')
          .firstOrNull;
      if (appResponseNode != null) {
        final base64Cdr = appResponseNode.innerText.trim();
        final bytesZipCdr = base64.decode(base64Cdr);
        final xmlCdr = _zipUtil.extraerXmlDeZip(bytesZipCdr);

        if (xmlCdr != null) {
          return CPE_RespuestaSunat.desdeCdrXml(xmlCdr, bytesZip: bytesZipCdr);
        } else {
          return CPE_RespuestaSunat(
            exito: true,
            codigoRespuesta: '0',
            mensaje: 'Comprobante procesado (CDR binario recibido)',
            cdrZipBytes: bytesZipCdr,
          );
        }
      }

      return CPE_RespuestaSunat.errorTecnico(
        'Respuesta SOAP no contiene applicationResponse ni Fault',
      );
    } catch (e) {
      return CPE_RespuestaSunat.errorTecnico(
        'Fallo al procesar XML de respuesta SOAP: $e',
      );
    }
  }

  CPE_RespuestaSunat _procesarRespuestaSendSummary(String xmlRespuesta) {
    try {
      final doc = XmlDocument.parse(xmlRespuesta);

      final fault =
          doc.findAllElements('soapenv:Fault').firstOrNull ??
          doc.findAllElements('Fault').firstOrNull;

      if (fault != null) {
        final faultCode = fault
            .findElements('faultcode')
            .firstOrNull
            ?.innerText;
        final faultString =
            fault.findElements('faultstring').firstOrNull?.innerText ??
            'Error SOAP';
        return CPE_RespuestaSunat.errorTecnico(faultString, codigo: faultCode);
      }

      final ticketNode = doc.findAllElements('ticket').firstOrNull;
      if (ticketNode != null) {
        final ticket = ticketNode.innerText.trim();
        return CPE_RespuestaSunat(
          exito: true,
          ticket: ticket,
          mensaje: 'Resumen recibido por SUNAT. Ticket asignado: $ticket',
        );
      }

      return CPE_RespuestaSunat.errorTecnico(
        'No se recibió ticket en respuesta sendSummary',
      );
    } catch (e) {
      return CPE_RespuestaSunat.errorTecnico(
        'Error al procesar ticket sendSummary: $e',
      );
    }
  }

  CPE_RespuestaSunat _procesarRespuestaGetStatus(String xmlRespuesta) {
    try {
      final doc = XmlDocument.parse(xmlRespuesta);

      final fault =
          doc.findAllElements('soapenv:Fault').firstOrNull ??
          doc.findAllElements('Fault').firstOrNull;

      if (fault != null) {
        final faultCode = fault
            .findElements('faultcode')
            .firstOrNull
            ?.innerText;
        final faultString =
            fault.findElements('faultstring').firstOrNull?.innerText ??
            'Error SOAP';
        return CPE_RespuestaSunat.errorTecnico(faultString, codigo: faultCode);
      }

      final statusCode = doc
          .findAllElements('statusCode')
          .firstOrNull
          ?.innerText
          .trim();
      final content = doc
          .findAllElements('content')
          .firstOrNull
          ?.innerText
          .trim();

      if (statusCode == '0' && content != null) {
        final bytesZip = base64.decode(content);
        final xmlCdr = _zipUtil.extraerXmlDeZip(bytesZip);
        if (xmlCdr != null) {
          return CPE_RespuestaSunat.desdeCdrXml(xmlCdr, bytesZip: bytesZip);
        }
      } else if (statusCode == '98') {
        return const CPE_RespuestaSunat(
          exito: true,
          codigoRespuesta: '98',
          mensaje: 'Ticket en proceso de validación en SUNAT',
        );
      }

      return CPE_RespuestaSunat(
        exito: statusCode == '0',
        codigoRespuesta: statusCode,
        mensaje: 'Estado retornado: $statusCode',
      );
    } catch (e) {
      return CPE_RespuestaSunat.errorTecnico(
        'Error al procesar respuesta getStatus: $e',
      );
    }
  }
}
