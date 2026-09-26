// Copyright (c) 2026, César A Vergara Buenaventura <cesarvergarab@gmail.com>.
// Todos los derechos reservados. Uso sujeto a la licencia en el archivo LICENSE.

import 'comunicacion/cpe_cliente_rest.dart';
import 'comunicacion/cpe_cliente_soap.dart';
import 'comunicacion/cpe_cliente_transporte.dart';
import 'comunicacion/cpe_respuesta_sunat.dart';
import 'config/cpe_credenciales.dart';
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
  }) : firmador = firmador ?? CPE_FirmadorXml.paraPruebas(),
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

  /// Construye el XML, lo firma digitalmente, lo empaqueta en ZIP y lo envía a SUNAT.
  Future<CPE_RespuestaSunat> emitirFactura(CPE_Factura factura) async {
    final xmlSinFirmar = generadorXml.generarFactura(factura);
    final resultadoFirma = await firmador.firmarXml(xmlSinFirmar);

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

  /// Construye el XML, lo firma digitalmente, lo empaqueta en ZIP y lo envía a SUNAT.
  Future<CPE_RespuestaSunat> emitirBoleta(CPE_Boleta boleta) async {
    final xmlSinFirmar = generadorXml.generarBoleta(boleta);
    final resultadoFirma = await firmador.firmarXml(xmlSinFirmar);

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

  /// Emite una Nota de Crédito Electrónica ante SUNAT.
  Future<CPE_RespuestaSunat> emitirNotaCredito(CPE_NotaCredito nota) async {
    final xmlSinFirmar = generadorXml.generarNotaCredito(nota);
    final resultadoFirma = await firmador.firmarXml(xmlSinFirmar);

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

  /// Emite una Nota de Débito Electrónica ante SUNAT.
  Future<CPE_RespuestaSunat> emitirNotaDebito(CPE_NotaDebito nota) async {
    final xmlSinFirmar = generadorXml.generarNotaDebito(nota);
    final resultadoFirma = await firmador.firmarXml(xmlSinFirmar);

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

  /// Emite una Guía de Remisión Electrónica (GRE), usando API REST por defecto o SOAP opcional.
  Future<CPE_RespuestaSunat> emitirGuiaRemision(
    CPE_GuiaRemision guia, {
    bool usarRest = true,
  }) async {
    final xmlSinFirmar = generadorXml.generarGuiaRemision(guia);
    final resultadoFirma = await firmador.firmarXml(xmlSinFirmar);

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

  /// Envía un Resumen Diario de Boletas (RC) que genera un ticket asíncrono.
  Future<CPE_RespuestaSunat> emitirResumenDiario(
    CPE_ResumenDiario resumen,
  ) async {
    final xmlSinFirmar = generadorXml.generarResumenDiario(resumen);
    final resultadoFirma = await firmador.firmarXml(xmlSinFirmar);

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

  /// Envía una Comunicación de Baja (RA) para anular comprobantes emitidos.
  Future<CPE_RespuestaSunat> emitirComunicacionBaja(
    CPE_ComunicacionBaja baja,
  ) async {
    final xmlSinFirmar = generadorXml.generarComunicacionBaja(baja);
    final resultadoFirma = await firmador.firmarXml(xmlSinFirmar);

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
