// Copyright (c) 2026, César A Vergara Buenaventura <cesarvergarab@gmail.com>.
// Todos los derechos reservados. Uso sujeto a la licencia en el archivo LICENSE.

import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;

import '../config/cpe_credenciales.dart';
import '../util/cpe_empaquetador_zip.dart';
import 'cpe_cliente_transporte.dart';
import 'cpe_respuesta_sunat.dart';

/// Cliente de comunicación REST con OAuth2 para la API de Guías de Remisión y CPE modernos de SUNAT.
class CPE_ClienteRest implements CPE_ClienteTransporte {
  final CPE_Credenciales credenciales;
  final http.Client _httpClient;
  final CPE_EmpaquetadorZip _zipUtil;

  String? _tokenAcceso;
  DateTime? _expiracionToken;

  CPE_ClienteRest({
    required this.credenciales,
    http.Client? httpClient,
    CPE_EmpaquetadorZip? zipUtil,
  }) : _httpClient = httpClient ?? http.Client(),
       _zipUtil = zipUtil ?? const CPE_EmpaquetadorZip();

  /// Obtiene un token Bearer OAuth2 vigente de SUNAT mediante flujo Password Credentials.
  Future<String> obtenerTokenAcceso() async {
    if (_tokenAcceso != null &&
        _expiracionToken != null &&
        DateTime.now().isBefore(_expiracionToken!)) {
      return _tokenAcceso!;
    }

    if (!credenciales.tieneCredencialesRest) {
      throw StateError(
        'Se requieren clientId y clientSecret para autenticación en la API REST de SUNAT.',
      );
    }

    final urlToken = Uri.parse(
      credenciales.entorno.urlRestToken(credenciales.clientId!),
    );

    final respuesta = await _httpClient.post(
      urlToken,
      headers: {'Content-Type': 'application/x-www-form-urlencoded'},
      body: {
        'grant_type': 'password',
        'scope': 'https://api-cpe.sunat.gob.pe',
        'client_id': credenciales.clientId!,
        'client_secret': credenciales.clientSecret!,
        'username': credenciales.usernameOAuth2,
        'password': credenciales.claveSol,
      },
    );

    if (respuesta.statusCode != 200) {
      throw http.ClientException(
        'Fallo en la autenticación OAuth2 de SUNAT (${respuesta.statusCode}): ${respuesta.body}',
      );
    }

    final data = jsonDecode(respuesta.body) as Map<String, dynamic>;
    _tokenAcceso = data['access_token'] as String;
    final expiresInSegundos = (data['expires_in'] as num?)?.toInt() ?? 3600;
    _expiracionToken = DateTime.now().add(
      Duration(seconds: expiresInSegundos - 60),
    );

    return _tokenAcceso!;
  }

  @override
  Future<CPE_RespuestaSunat> enviarComprobanteZip({
    required String nombreArchivoZip,
    required List<int> bytesZip,
  }) async {
    return enviarResumenAsincronoZip(
      nombreArchivoZip: nombreArchivoZip,
      bytesZip: bytesZip,
    );
  }

  @override
  Future<CPE_RespuestaSunat> enviarResumenAsincronoZip({
    required String nombreArchivoZip,
    required List<int> bytesZip,
  }) async {
    try {
      final token = await obtenerTokenAcceso();
      final base64Zip = base64.encode(bytesZip);
      final hashSha256 = sha256.convert(bytesZip).toString();

      final urlEnvio = Uri.parse(
        '${credenciales.entorno.urlRestApiBase}/comprobantes/$nombreArchivoZip',
      );

      final payload = jsonEncode({
        'archivo': {
          'nomArchivo': nombreArchivoZip,
          'arcGreZip': base64Zip,
          'hashZip': hashSha256,
        },
      });

      final respuesta = await _httpClient.post(
        urlEnvio,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: payload,
      );

      if (respuesta.statusCode == 200 || respuesta.statusCode == 202) {
        final data = jsonDecode(respuesta.body) as Map<String, dynamic>;
        final numTicket = data['numTicket'] as String?;
        return CPE_RespuestaSunat(
          exito: true,
          ticket: numTicket,
          mensaje: 'Documento recibido en API REST SUNAT. Ticket: $numTicket',
        );
      } else {
        return CPE_RespuestaSunat.errorTecnico(
          'Error en API REST SUNAT (${respuesta.statusCode}): ${respuesta.body}',
        );
      }
    } catch (e) {
      return CPE_RespuestaSunat.errorTecnico('Error en envío REST: $e');
    }
  }

  @override
  Future<CPE_RespuestaSunat> consultarTicket(String ticket) async {
    try {
      final token = await obtenerTokenAcceso();
      final urlConsulta = Uri.parse(
        '${credenciales.entorno.urlRestApiBase}/comprobantes/envios/$ticket',
      );

      final respuesta = await _httpClient.get(
        urlConsulta,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (respuesta.statusCode == 200) {
        final data = jsonDecode(respuesta.body) as Map<String, dynamic>;
        final codRespuesta = data['codRespuesta']?.toString();
        final arcCdr = data['arcCdr'] as String?;

        if (arcCdr != null && arcCdr.isNotEmpty) {
          final bytesZipCdr = base64.decode(arcCdr);
          final xmlCdr = _zipUtil.extraerXmlDeZip(bytesZipCdr);
          if (xmlCdr != null) {
            return CPE_RespuestaSunat.desdeCdrXml(
              xmlCdr,
              bytesZip: bytesZipCdr,
            );
          }
        }

        return CPE_RespuestaSunat(
          exito: codRespuesta == '0',
          codigoRespuesta: codRespuesta,
          ticket: ticket,
          mensaje: 'Ticket procesado con código: $codRespuesta',
        );
      } else {
        return CPE_RespuestaSunat.errorTecnico(
          'Error al consultar ticket REST (${respuesta.statusCode}): ${respuesta.body}',
        );
      }
    } catch (e) {
      return CPE_RespuestaSunat.errorTecnico(
        'Error en consulta de ticket REST: $e',
      );
    }
  }
}
