// Copyright (c) 2026, César A Vergara Buenaventura <cesarvergarab@gmail.com>.
// Todos los derechos reservados. Uso sujeto a la licencia en el archivo LICENSE.

import 'package:decimal/decimal.dart';
import 'package:sunat_cpe_dart/sunat_cpe_dart.dart';
import 'package:test/test.dart';

void main() {
  group('Pruebas de CPE_Monto y precisión contable', () {
    test('Creación desde texto y centavos', () {
      final montoTexto = CPE_Monto.desdeTexto('100.50');
      final montoCentavos = CPE_Monto.desdeCentavos(10050);

      expect(montoTexto, equals(montoCentavos));
      expect(montoTexto.aFormatoUbl(), equals('100.50'));
    });

    test('Precisión decimal sin errores IEEE 754', () {
      final m1 = CPE_Monto.desdeTexto('0.10');
      final m2 = CPE_Monto.desdeTexto('0.20');
      final suma = m1 + m2;

      expect(suma.aFormatoUbl(), equals('0.30'));
      expect(suma.valor, equals(Decimal.parse('0.3')));
    });

    test('Cálculo de IGV estándar al 18%', () {
      final base = CPE_Monto.desdeTexto('1000.00');
      final igv = cpe_calcular_igv(base);

      expect(igv.aFormatoUbl(), equals('180.00'));
      expect(igv.moneda, equals('PEN'));
    });

    test('Rechazo al operar distintas divisas', () {
      final sol = CPE_Monto.desdeTexto('100.00', moneda: 'PEN');
      final usd = CPE_Monto.desdeTexto('100.00', moneda: 'USD');

      expect(() => sol + usd, throwsArgumentError);
    });
  });

  group('Pruebas de Validación de RUC (Módulo 11)', () {
    test('RUCs válidos conocidos', () {
      expect(CPE_ValidadorRuc.esValido('20131312955'), isTrue); // SUNAT
      expect(CPE_ValidadorRuc.esValido('20100047218'), isTrue); // BCP
      expect(CPE_ValidadorRuc.esValido('20100130204'), isTrue); // BBVA
    });

    test('RUCs inválidos', () {
      expect(CPE_ValidadorRuc.esValido('12345678901'), isFalse);
      expect(CPE_ValidadorRuc.esValido('20100070979'), isFalse);
      expect(CPE_ValidadorRuc.esValido('abc'), isFalse);
      expect(CPE_ValidadorRuc.esValido(null), isFalse);
    });
  });

  group('Pruebas de Catálogos Oficiales SUNAT', () {
    test('Catálogo 01 Tipos de Comprobante', () {
      expect(CPE_Catalogo01_TipoDocumento.factura.codigo, equals('01'));
      expect(CPE_Catalogo01_TipoDocumento.boletaVenta.codigo, equals('03'));
      expect(CPE_Catalogo01_TipoDocumento.notaCredito.codigo, equals('07'));
      expect(CPE_Catalogo01_TipoDocumento.notaDebito.codigo, equals('08'));
      expect(
        CPE_Catalogo01_TipoDocumento.guiaRemisionRemitente.codigo,
        equals('09'),
      );
      expect(CPE_Catalogo01_TipoDocumento.resumenDiario.codigo, equals('RC'));
      expect(
        CPE_Catalogo01_TipoDocumento.comunicacionBaja.codigo,
        equals('RA'),
      );
    });

    test('Catálogo 02 Monedas', () {
      expect(CPE_Catalogo02_Moneda.sol.codigoIso, equals('PEN'));
      expect(
        CPE_Catalogo02_Moneda.dolarEstadounidense.codigoIso,
        equals('USD'),
      );
    });

    test('Catálogo 05 Tributos y Catálogo 07 Afectación IGV', () {
      expect(CPE_Catalogo05_TipoTributo.igv.codigoSunat, equals('1000'));
      expect(
        CPE_Catalogo07_AfectacionIgv.gravadoOperacionOnerosa.codigo,
        equals('10'),
      );
      expect(
        CPE_Catalogo07_AfectacionIgv.exoneradoOperacionOnerosa.codigo,
        equals('20'),
      );
      expect(
        CPE_Catalogo07_AfectacionIgv.inafectoOperacionOnerosa.codigo,
        equals('30'),
      );
    });
  });

  group('Pruebas de Generación de XML UBL 2.1 y Firma XML-DSig', () {
    final emisor = CPE_Contribuyente.emisorRuc(
      ruc: '20100070970',
      razonSocial: 'SUPERMERCADOS PERU S.A.C.',
      direccion: const CPE_Direccion(
        direccion: 'AV. DE LA REPUBLICA 123',
        ubigeo: '150101',
      ),
    );

    final receptor = const CPE_Contribuyente(
      numeroDocumento: '20600000001',
      tipoDocumento: CPE_Catalogo06_TipoDocumentoIdentidad.ruc,
      razonSocial: 'CLIENTE EMPRESA S.A.C.',
    );

    final item1 = CPE_Item.calcularDesdeValorUnitario(
      numeroLinea: 1,
      codigo: 'PROD-001',
      descripcion: 'Laptop Gamer 16GB',
      cantidad: Decimal.parse('2'),
      valorUnitario: CPE_Monto.desdeTexto('2500.00'),
    );

    final totales = CPE_Totales.calcularDesdeItems([item1]);

    test('Generar Factura XML UBL 2.1 válida', () {
      final factura = CPE_Factura(
        serie: 'F001',
        correlativo: 105,
        fechaEmision: DateTime(2026, 9, 26),
        horaEmision: '12:30:00',
        emisor: emisor,
        receptor: receptor,
        moneda: CPE_Catalogo02_Moneda.sol,
        items: [item1],
        totales: totales,
      );

      final generador = const CPE_GeneradorXml();
      final xml = generador.generarFactura(factura);

      expect(xml, contains('<cbc:UBLVersionID>2.1</cbc:UBLVersionID>'));
      expect(xml, contains('<cbc:ID>F001-00000105</cbc:ID>'));
      expect(xml, contains('<cbc:IssueDate>2026-09-26</cbc:IssueDate>'));
      expect(
        xml,
        contains(
          '<cbc:LineExtensionAmount currencyID="PEN">5000.00</cbc:LineExtensionAmount>',
        ),
      );
      expect(
        xml,
        contains('<cbc:TaxAmount currencyID="PEN">900.00</cbc:TaxAmount>'),
      );
      expect(
        xml,
        contains(
          '<cbc:PayableAmount currencyID="PEN">5900.00</cbc:PayableAmount>',
        ),
      );
    });

    test('Firma digital XML-DSig inyectada correctamente', () async {
      final factura = CPE_Factura(
        serie: 'F001',
        correlativo: 1,
        fechaEmision: DateTime(2026, 9, 26),
        emisor: emisor,
        receptor: receptor,
        moneda: CPE_Catalogo02_Moneda.sol,
        items: [item1],
        totales: totales,
      );

      final generador = const CPE_GeneradorXml();
      final xmlSinFirmar = generador.generarFactura(factura);

      final firmador = CPE_FirmadorXml.paraPruebas();
      final resultadoFirma = await firmador.firmarXml(xmlSinFirmar);

      expect(resultadoFirma.xmlFirmado, contains('<ds:Signature'));
      expect(resultadoFirma.xmlFirmado, contains('<ds:DigestValue>'));
      expect(resultadoFirma.xmlFirmado, contains('<ds:SignatureValue>'));
      expect(resultadoFirma.digestValue.isNotEmpty, isTrue);
    });

    test('Generar Guía de Remisión DespatchAdvice UBL 2.1', () {
      final guia = CPE_GuiaRemision(
        tipoDocumento: CPE_Catalogo01_TipoDocumento.guiaRemisionRemitente,
        serie: 'T001',
        correlativo: 1,
        fechaEmision: DateTime(2026, 9, 26),
        fechaInicioTraslado: DateTime(2026, 9, 27),
        remitente: emisor,
        destinatario: receptor,
        modalidadTraslado: CPE_Catalogo18_ModalidadTraslado.transportePrivado,
        motivoTraslado: CPE_Catalogo20_MotivoTraslado.venta,
        pesoBrutoTotal: Decimal.parse('45.50'),
        puntoPartida: const CPE_Direccion(
          direccion: 'Av. Partida 100',
          ubigeo: '150101',
        ),
        puntoLlegada: const CPE_Direccion(
          direccion: 'Av. Llegada 200',
          ubigeo: '150102',
        ),
        items: [
          CPE_ItemGuia(
            numeroLinea: 1,
            codigo: 'P01',
            descripcion: 'Caja de repuestos',
            cantidad: Decimal.fromInt(10),
          ),
        ],
      );

      final generador = const CPE_GeneradorXml();
      final xml = generador.generarGuiaRemision(guia);

      expect(xml, contains('<DespatchAdvice'));
      expect(xml, contains('<cbc:HandlingCode>01</cbc:HandlingCode>'));
      expect(
        xml,
        contains(
          '<cbc:GrossWeightMeasure unitCode="KGM">45.50</cbc:GrossWeightMeasure>',
        ),
      );
    });
  });

  group('Pruebas de Empaquetado ZIP y Parseo de CDR', () {
    test('Empaquetar y extraer XML', () {
      const empaquetador = CPE_EmpaquetadorZip();
      const contenidoXml = '<Invoice><ID>F001-00000001</ID></Invoice>';

      final zipBytes = empaquetador.empaquetarXml(
        nombreXml: '20100070970-01-F001-00000001',
        contenidoXml: contenidoXml,
      );

      expect(zipBytes.isNotEmpty, isTrue);

      final xmlExtraido = empaquetador.extraerXmlDeZip(zipBytes);
      expect(xmlExtraido, equals(contenidoXml));
    });

    test('Parsear CDR Aceptado de SUNAT', () {
      const cdrXmlSimulado = '''<?xml version="1.0" encoding="utf-8"?>
<ApplicationResponse xmlns="urn:oasis:names:specification:ubl:schema:xsd:ApplicationResponse-2"
  xmlns:cac="urn:oasis:names:specification:ubl:schema:xsd:CommonAggregateComponents-2"
  xmlns:cbc="urn:oasis:names:specification:ubl:schema:xsd:CommonBasicComponents-2"
  xmlns:ds="http://www.w3.org/2000/09/xmldsig#">
  <cac:DocumentResponse>
    <cac:Response>
      <cbc:ResponseCode>0</cbc:ResponseCode>
      <cbc:Description>La Factura numero F001-00000105, ha sido aceptada</cbc:Description>
    </cac:Response>
    <cac:DocumentReference>
      <cbc:ID>F001-00000105</cbc:ID>
    </cac:DocumentReference>
  </cac:DocumentResponse>
  <cbc:Note>Advertencia 4000: Fecha de emisión adelantada</cbc:Note>
  <ds:DigestValue>mY5yYl/k8h7J1v...</ds:DigestValue>
</ApplicationResponse>''';

      final respuesta = CPE_RespuestaSunat.desdeCdrXml(cdrXmlSimulado);

      expect(respuesta.exito, isTrue);
      expect(respuesta.esAceptado, isTrue);
      expect(respuesta.codigoRespuesta, equals('0'));
      expect(respuesta.mensaje, contains('ha sido aceptada'));
      expect(respuesta.observaciones.length, equals(1));
      expect(respuesta.observaciones.first, contains('Advertencia 4000'));
      expect(respuesta.hashCdr, equals('mY5yYl/k8h7J1v...'));
    });
  });

  group('Pruebas de Fachada CPE_EmisorServicio con Transporte Simulado', () {
    test('Emisión completa de Factura con transporte simulado', () async {
      final emisor = CPE_Contribuyente.emisorRuc(
        ruc: '20100070970',
        razonSocial: 'EMISOR TEST S.A.C.',
      );
      final receptor = const CPE_Contribuyente(
        numeroDocumento: '20500000002',
        tipoDocumento: CPE_Catalogo06_TipoDocumentoIdentidad.ruc,
        razonSocial: 'CLIENTE PRUEBA',
      );
      final item = CPE_Item.calcularDesdeValorUnitario(
        numeroLinea: 1,
        codigo: 'SERV-01',
        descripcion: 'Consultoría TI',
        cantidad: Decimal.one,
        valorUnitario: CPE_Monto.desdeTexto('100.00'),
      );
      final totales = CPE_Totales.calcularDesdeItems([item]);

      final factura = CPE_Factura(
        serie: 'F001',
        correlativo: 1,
        fechaEmision: DateTime.now(),
        emisor: emisor,
        receptor: receptor,
        moneda: CPE_Catalogo02_Moneda.sol,
        items: [item],
        totales: totales,
      );

      final credenciales = const CPE_Credenciales(
        ruc: '20100070970',
        usuarioSol: 'MODDATOS',
        claveSol: 'moddatos',
        entorno: CPE_Entorno.beta,
      );

      final mockTransporte = _MockTransporte();
      final servicio = CPE_EmisorServicio(
        credenciales: credenciales,
        clienteTransportePersonalizado: mockTransporte,
      );

      final respuesta = await servicio.emitirFactura(factura);

      expect(respuesta.exito, isTrue);
      expect(
        mockTransporte.ultimoNombreArchivoEnviado,
        equals('20100070970-01-F001-00000001.zip'),
      );
    });
  });
}

class _MockTransporte implements CPE_ClienteTransporte {
  String? ultimoNombreArchivoEnviado;

  @override
  Future<CPE_RespuestaSunat> enviarComprobanteZip({
    required String nombreArchivoZip,
    required List<int> bytesZip,
  }) async {
    ultimoNombreArchivoEnviado = nombreArchivoZip;
    return const CPE_RespuestaSunat(
      exito: true,
      codigoRespuesta: '0',
      mensaje: 'Comprobante simulado aceptado',
    );
  }

  @override
  Future<CPE_RespuestaSunat> enviarResumenAsincronoZip({
    required String nombreArchivoZip,
    required List<int> bytesZip,
  }) async {
    return const CPE_RespuestaSunat(
      exito: true,
      ticket: '123456789',
      mensaje: 'Ticket simulado',
    );
  }

  @override
  Future<CPE_RespuestaSunat> consultarTicket(String ticket) async {
    return const CPE_RespuestaSunat(
      exito: true,
      codigoRespuesta: '0',
      mensaje: 'Ticket finalizado',
    );
  }
}
