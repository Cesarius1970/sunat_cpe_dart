// Copyright (c) 2026, César A Vergara Buenaventura <cesarvergarab@gmail.com>.
// Todos los derechos reservados. Uso sujeto a la licencia en el archivo LICENSE.

import 'comunicacion/cpe_cliente_rest.dart';
import 'comunicacion/cpe_cliente_soap.dart';
import 'comunicacion/cpe_cliente_transporte.dart';
import 'comunicacion/cpe_respuesta_sunat.dart';
import 'config/cpe_credenciales.dart';
import 'config/cpe_entorno.dart';
import 'modelos/cpe_boleta.dart';
import 'modelos/cpe_comunicacion_baja.dart';
import 'modelos/cpe_factura.dart';
import 'modelos/cpe_guia_remision.dart';
import 'modelos/cpe_nota_credito.dart';
import 'modelos/cpe_nota_debito.dart';
import 'modelos/cpe_resumen_diario.dart';
import 'seguridad/cpe_firmador.dart';
import 'seguridad/cpe_firmador_xml.dart';
import 'util/cpe_empaquetador_zip.dart';
import 'xml/cpe_generador_xml.dart';

/// Fachada de alto nivel para la construcción, firma y emisión de CPE ante SUNAT.
///
/// Todas las operaciones de emisión exigen un [CPE_CertificadoDigital] desde el llamador,
/// permitiendo el uso de certificados simulados (mock) **únicamente** en ambientes de pruebas ([CPE_Entorno.beta]).
class CPE_EmisorServicio {
  final CPE_Credenciales credenciales;
  final CPE_Firmador firmador;
  final CPE_GeneradorXml generadorXml;
  final CPE_EmpaquetadorZip empaquetadorZip;
  final CPE_ClienteTransporte? clienteTransportePersonalizado;

  late final CPE_ClienteSoap _clienteSoap;
  late final CPE_ClienteRest _clienteRest;

  CPE_EmisorServicio({
    required this.credenciales,
    CPE_Firmador? firmador,
    CPE_GeneradorXml? generadorXml,
    CPE_EmpaquetadorZip? empaquetadorZip,
    this.clienteTransportePersonalizado,
  })  : firmador = firmador ?? const CPE_FirmadorXml(),
        generadorXml = generadorXml ?? const CPE_GeneradorXml(),
        empaquetadorZip = empaquetadorZip ?? const CPE_EmpaquetadorZip() {
    _clienteSoap = CPE_ClienteSoap(
      credenciales: credenciales,
      zipUtil: this.empaquetadorZip,
    );
    _clienteRest = CPE_ClienteRest(
      credenciales: credenciales,
      zipUtil: this.empaquetadorZip,
    );
  }

  /// Valida y resuelve el certificado digital requerido para la firma:
  /// - Si se recibe [certificado]: se prohíbe el uso de mock en Producción u Homologación.
  /// - Si NO se recibe [certificado]: SOLO se genera un mock automático en entorno [CPE_Entorno.beta].
  /// - En Producción u Homologación, la omisión del certificado lanza un [ArgumentError].
  CPE_CertificadoDigital _resolverCertificado(CPE_CertificadoDigital? certificado) {
    if (certificado != null) {
      if (certificado.esMock && credenciales.entorno != CPE_Entorno.beta) {
        throw ArgumentError(
          'No se permite utilizar un certificado mock en ambiente de ${credenciales.entorno.name}. '
          'Debe proporcionar un certificado digital válido emitido por una entidad de certificación autorizada.',
        );
      }
      return certificado;
    }

    if (credenciales.entorno == CPE_Entorno.beta) {
      return CPE_CertificadoDigital.mockPruebas();
    }

    throw ArgumentError(
      'El parámetro [certificado] es obligatorio para emitir comprobantes en ambiente de ${credenciales.entorno.name}. '
      'El uso de certificados mock está restringido únicamente a ambientes de pruebas (Beta).',
    );
  }

  /// Construye el XML de la Factura, lo firma con el [certificado], lo empaqueta en ZIP y lo envía a SUNAT.
  Future<CPE_RespuestaSunat> emitirFactura(
    CPE_Factura factura, {
    CPE_CertificadoDigital? certificado,
  }) async {
    final cert = _resolverCertificado(certificado);
    final xmlSinFirmar = generadorXml.generarFactura(factura);
    final resultadoFirma = await firmador.firmarXml(
      xmlSinFirmar,
      certificado: cert,
    );

    final nombreBase = factura.nombreArchivoSunat;
    final bytesZip = empaquetadorZip.empaquetarXml(
      nombreXml: nombreBase,
      contenidoXml: resultadoFirma.xmlFirmado,
    );

    final cliente = clienteTransportePersonalizado ?? _clienteSoap;
    return cliente.enviarComprobanteZip(
      nombreArchivoZip: '$nombreBase.zip',
      bytesZip: bytesZip,
    );
  }

  /// Construye el XML de la Boleta, lo firma con el [certificado], lo empaqueta en ZIP y lo envía a SUNAT.
  Future<CPE_RespuestaSunat> emitirBoleta(
    CPE_Boleta boleta, {
    CPE_CertificadoDigital? certificado,
  }) async {
    final cert = _resolverCertificado(certificado);
    final xmlSinFirmar = generadorXml.generarBoleta(boleta);
    final resultadoFirma = await firmador.firmarXml(
      xmlSinFirmar,
      certificado: cert,
    );

    final nombreBase = boleta.nombreArchivoSunat;
    final bytesZip = empaquetadorZip.empaquetarXml(
      nombreXml: nombreBase,
      contenidoXml: resultadoFirma.xmlFirmado,
    );

    final cliente = clienteTransportePersonalizado ?? _clienteSoap;
    return cliente.enviarComprobanteZip(
      nombreArchivoZip: '$nombreBase.zip',
      bytesZip: bytesZip,
    );
  }

  /// Emite una Nota de Crédito Electrónica firmada con el [certificado] ante SUNAT.
  Future<CPE_RespuestaSunat> emitirNotaCredito(
    CPE_NotaCredito nota, {
    CPE_CertificadoDigital? certificado,
  }) async {
    final cert = _resolverCertificado(certificado);
    final xmlSinFirmar = generadorXml.generarNotaCredito(nota);
    final resultadoFirma = await firmador.firmarXml(
      xmlSinFirmar,
      certificado: cert,
    );

    final nombreBase = nota.nombreArchivoSunat;
    final bytesZip = empaquetadorZip.empaquetarXml(
      nombreXml: nombreBase,
      contenidoXml: resultadoFirma.xmlFirmado,
    );

    final cliente = clienteTransportePersonalizado ?? _clienteSoap;
    return cliente.enviarComprobanteZip(
      nombreArchivoZip: '$nombreBase.zip',
      bytesZip: bytesZip,
    );
  }

  /// Emite una Nota de Débito Electrónica firmada con el [certificado] ante SUNAT.
  Future<CPE_RespuestaSunat> emitirNotaDebito(
    CPE_NotaDebito nota, {
    CPE_CertificadoDigital? certificado,
  }) async {
    final cert = _resolverCertificado(certificado);
    final xmlSinFirmar = generadorXml.generarNotaDebito(nota);
    final resultadoFirma = await firmador.firmarXml(
      xmlSinFirmar,
      certificado: cert,
    );

    final nombreBase = nota.nombreArchivoSunat;
    final bytesZip = empaquetadorZip.empaquetarXml(
      nombreXml: nombreBase,
      contenidoXml: resultadoFirma.xmlFirmado,
    );

    final cliente = clienteTransportePersonalizado ?? _clienteSoap;
    return cliente.enviarComprobanteZip(
      nombreArchivoZip: '$nombreBase.zip',
      bytesZip: bytesZip,
    );
  }

  /// Emite una Guía de Remisión Electrónica firmada con el [certificado], usando REST por defecto o SOAP opcional.
  Future<CPE_RespuestaSunat> emitirGuiaRemision(
    CPE_GuiaRemision guia, {
    CPE_CertificadoDigital? certificado,
    bool usarRest = true,
  }) async {
    final cert = _resolverCertificado(certificado);
    final xmlSinFirmar = generadorXml.generarGuiaRemision(guia);
    final resultadoFirma = await firmador.firmarXml(
      xmlSinFirmar,
      certificado: cert,
    );

    final nombreBase = guia.nombreArchivoSunat;
    final bytesZip = empaquetadorZip.empaquetarXml(
      nombreXml: nombreBase,
      contenidoXml: resultadoFirma.xmlFirmado,
    );

    final cliente =
        clienteTransportePersonalizado ??
        (usarRest ? _clienteRest : _clienteSoap);
    return cliente.enviarComprobanteZip(
      nombreArchivoZip: '$nombreBase.zip',
      bytesZip: bytesZip,
    );
  }

  /// Envía un Resumen Diario de Boletas (RC) firmado con el [certificado] que genera un ticket asíncrono.
  Future<CPE_RespuestaSunat> emitirResumenDiario(
    CPE_ResumenDiario resumen, {
    CPE_CertificadoDigital? certificado,
  }) async {
    final cert = _resolverCertificado(certificado);
    final xmlSinFirmar = generadorXml.generarResumenDiario(resumen);
    final resultadoFirma = await firmador.firmarXml(
      xmlSinFirmar,
      certificado: cert,
    );

    final nombreBase = resumen.nombreArchivoSunat;
    final bytesZip = empaquetadorZip.empaquetarXml(
      nombreXml: nombreBase,
      contenidoXml: resultadoFirma.xmlFirmado,
    );

    final cliente = clienteTransportePersonalizado ?? _clienteSoap;
    return cliente.enviarResumenAsincronoZip(
      nombreArchivoZip: '$nombreBase.zip',
      bytesZip: bytesZip,
    );
  }

  /// Envía una Comunicación de Baja (RA) firmada con el [certificado] para anular comprobantes emitidos.
  Future<CPE_RespuestaSunat> emitirComunicacionBaja(
    CPE_ComunicacionBaja baja, {
    CPE_CertificadoDigital? certificado,
  }) async {
    final cert = _resolverCertificado(certificado);
    final xmlSinFirmar = generadorXml.generarComunicacionBaja(baja);
    final resultadoFirma = await firmador.firmarXml(
      xmlSinFirmar,
      certificado: cert,
    );

    final nombreBase = baja.nombreArchivoSunat;
    final bytesZip = empaquetadorZip.empaquetarXml(
      nombreXml: nombreBase,
      contenidoXml: resultadoFirma.xmlFirmado,
    );

    final cliente = clienteTransportePersonalizado ?? _clienteSoap;
    return cliente.enviarResumenAsincronoZip(
      nombreArchivoZip: '$nombreBase.zip',
      bytesZip: bytesZip,
    );
  }

  /// Consulta el resultado de un ticket asíncrono en SUNAT.
  Future<CPE_RespuestaSunat> consultarTicket(
    String ticket, {
    bool esRest = false,
  }) async {
    final cliente =
        clienteTransportePersonalizado ??
        (esRest ? _clienteRest : _clienteSoap);
    return cliente.consultarTicket(ticket);
  }
}
