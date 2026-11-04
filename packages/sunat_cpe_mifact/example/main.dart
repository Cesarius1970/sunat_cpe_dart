import 'dart:convert';
import 'dart:typed_data';

import 'package:sunat_cpe_core/sunat_cpe_core.dart';
import 'package:sunat_cpe_mifact/sunat_cpe_mifact.dart';

/// Cliente HTTP simulado (100 % offline) que emula los endpoints REST JSON
/// de Mifact (`/service.asmx/SendInvoice`, `SendGuide`, `SendSummary`, `lowInvoice`, `GetStatus`).
final class SimulatedMifactHttpClient implements CpeHttpClient {
  String nextInvoiceEstado = '102';
  String nextInvoiceErrors = '';

  @override
  Future<CpeHttpResponse> send(CpeHttpRequest request) async {
    final path = request.uri.path;
    final body = jsonDecode(request.body.toString()) as Map<String, dynamic>;

    if (path.endsWith('/service.asmx/SendInvoice')) {
      final serie = body['NUM_SERIE_CPE'];
      final corre = body['NUM_CORRE_CPE'];
      final estado = nextInvoiceEstado;
      final errors = nextInvoiceErrors;

      // Restaurar estado por defecto para la siguiente llamada
      nextInvoiceEstado = '102';
      nextInvoiceErrors = '';

      if (estado == '104') {
        return _jsonResponse(200, {
          'estado_documento': '104',
          'errors': errors.isNotEmpty ? errors : '2800 - El tipo de documento de identidad del receptor no es valido',
          'sunat_description': '',
        });
      }

      return _jsonResponse(200, {
        'estado_documento': estado,
        'codigo_hash': 'MifactHash/$serie-$corre==',
        'cadena_para_codigo_qr':
            '${body['NUM_NIF_EMIS']}|${body['COD_TIP_DOCU']}|$serie|$corre|${body['MNT_TOT_TRIB_IGV']}|${body['MNT_TOT']}|${body['FEC_EMIS']}|${body['COD_TIP_NIF_RECP']}|${body['NUM_NIF_RECP']}|MifactHash/$serie-$corre==|',
        'sunat_description': estado == '103'
            ? 'La Factura $serie-$corre ha sido aceptada con observaciones (4252 - Ubigeo referencial)'
            : 'La Factura numero $serie-$corre, ha sido aceptada',
        'url_pdf': 'https://demo.mifact.net.pe/pdf/$serie-$corre.pdf',
        'xml_bytes': base64.encode(
          utf8.encode('<Invoice><ID>$serie-$corre</ID></Invoice>'),
        ),
        'errors': '',
      });
    }

    if (path.endsWith('/service.asmx/SendGuide')) {
      final serie = body['NUM_SERIE_CPE'];
      final corre = body['NUM_CORRE_CPE'];
      return _jsonResponse(200, {
        'estado_documento': '101',
        'ticket': 'MIFACT-GRE-TICKET-$serie-$corre',
        'errors': '',
      });
    }

    if (path.endsWith('/service.asmx/SendSummary')) {
      final idResumen = body['ID_RESUMEN'];
      return _jsonResponse(200, {
        'estado_documento': '101',
        'ticket': 'MIFACT-RC-TICKET-$idResumen',
        'errors': '',
      });
    }

    if (path.endsWith('/service.asmx/lowInvoice')) {
      final idBaja = body['ID_BAJA'];
      return _jsonResponse(200, {
        'estado_documento': '101',
        'ticket': 'MIFACT-RA-TICKET-$idBaja',
        'errors': '',
      });
    }

    if (path.endsWith('/service.asmx/GetStatus')) {
      final ticket = body['TICKET'] as String?;
      final serie = body['NUM_SERIE_CPE'] ?? 'F001';
      final corre = body['NUM_CORRE_CPE'] ?? '00000001';
      return _jsonResponse(200, {
        'estado_documento': '102',
        'sunat_description': ticket != null
            ? 'El Ticket $ticket ha sido procesado y ACEPTADO por SUNAT'
            : 'El comprobante $serie-$corre se encuentra ACEPTADO en Mifact/SUNAT',
        'url_pdf': 'https://demo.mifact.net.pe/pdf/$serie-$corre.pdf',
        'errors': '',
      });
    }

    return _jsonResponse(404, {
      'estado_documento': '100',
      'errors': 'Ruta Mifact no encontrada: $path',
    });
  }

  CpeHttpResponse _jsonResponse(int statusCode, Map<String, Object?> map) {
    return CpeHttpResponse(
      statusCode: statusCode,
      headers: const {'content-type': 'application/json; charset=utf-8'},
      bodyBytes: Uint8List.fromList(utf8.encode(jsonEncode(map))),
    );
  }

  @override
  void close() {}
}

const _emisor = CompanyParty(
  ruc: '20100113612',
  legalName: 'SOLUCIONES EMPRESARIALES MIFACT DEMO S.A.C.',
  tradeName: 'MIFACT DEMO',
  address: Address(
    ubigeo: '150101',
    streetLine: 'AV. AREQUIPA 2450, LINCE, LIMA',
  ),
);

const _cliente = CustomerParty(
  documentType: IdentityDocumentType.ruc,
  documentNumber: '20600695771',
  legalName: 'IMPORTACIONES TECNOLOGICAS S.A.C.',
  address: Address(streetLine: 'CALLE LOS NEGOCIOS 180, SURQUILLO'),
);

InvoiceDocument _crearFactura({required int correlativo}) {
  return InvoiceDocument(
    id: DocumentId(
      issuerRuc: '20100113612',
      type: CpeDocumentType.factura,
      series: 'F001',
      number: correlativo,
    ),
    issueDate: DateTime(2026, 11, 4),
    issueTime: '10:15:00',
    dueDate: DateTime(2026, 12, 4),
    issuer: _emisor,
    customer: _cliente,
    currency: CurrencyCode.pen,
    paymentTerms: CreditPaymentTerms(
      netPendingAmount: Decimal.parse('590.00'),
      installments: [
        PaymentInstallment(
          number: 1,
          amount: Decimal.parse('590.00'),
          dueDate: DateTime(2026, 12, 4),
        ),
      ],
    ),
    items: [
      CpeLineItem(
        lineNumber: 1,
        internalCode: 'SRV-ERP',
        unitCode: 'ZZ',
        description: 'IMPLEMENTACION E INTEGRACION API FACTURACION',
        quantity: Decimal.one,
        unitValue: Decimal.parse('500.00'),
        unitPrice: Decimal.parse('590.00'),
        lineExtensionAmount: Decimal.parse('500.00'),
        taxableBaseAmount: Decimal.parse('500.00'),
        igvAffectation: IgvAffectationType.gravadoOperacionOnerosa,
        igvPercentage: Decimal.parse('18.00'),
        igvAmount: Decimal.parse('90.00'),
        totalLineTaxAmount: Decimal.parse('90.00'),
        totalLineAmount: Decimal.parse('590.00'),
      ),
    ],
    totals: MonetaryTotals(
      totalGravadas: Decimal.parse('500.00'),
      totalIgv: Decimal.parse('90.00'),
      totalValorVenta: Decimal.parse('500.00'),
      totalImpuestos: Decimal.parse('90.00'),
      totalPrecioVenta: Decimal.parse('590.00'),
      importeTotalPagar: Decimal.parse('590.00'),
    ),
  );
}

Future<void> main() async {
  print('===================================================================');
  print('  DEMO OFFLINE: sunat_cpe_mifact (API REST JSON PSE/OSE)');
  print(
    '===================================================================\n',
  );

  // En pruebas reales se apunta a https://demo.mifact.net.pe con MifactConfig.demoToken,
  // y en producción a https://mifact.net.pe con el token asignado al RUC emisor.
  final config = MifactConfig(
    baseUri: Uri.parse('https://demo.mifact.net.pe'),
    token: MifactConfig.demoToken,
    sendImmediatelyToSunat: true,
  );

  final simulatedHttp = SimulatedMifactHttpClient();
  final provider = MifactProvider(config: config, httpClient: simulatedHttp);

  // ---------------------------------------------------------------------------
  // ESCENARIO 1: Emisión de Factura (01) con MifactInvoiceMapper (102 y 103)
  // ---------------------------------------------------------------------------
  print('--- [1] Emisión de Factura (01) con MifactInvoiceMapper ---');
  final factura1 = _crearFactura(correlativo: 1);
  final mappedJson = const MifactInvoiceMapper().mapSalesDocument(
    factura1,
    config,
  );
  print(
    'Claves UPPER_SNAKE_CASE generadas: '
    'TOKEN="${mappedJson['TOKEN']}", '
    'COD_TIP_DOCU="${mappedJson['COD_TIP_DOCU']}", '
    'NUM_SERIE_CPE="${mappedJson['NUM_SERIE_CPE']}", '
    'NUM_CORRE_CPE="${mappedJson['NUM_CORRE_CPE']}", '
    'MNT_TOT="${mappedJson['MNT_TOT']}"',
  );

  // 1.1 Estado 102 -> CpeProcessStatus.accepted
  simulatedHttp.nextInvoiceEstado = '102';
  final res102 = (await provider.sendDocument(factura1)).getOrThrow();
  print('Factura F001-1 (estado_documento="102") -> Estado: ${res102.status}');
  print('  Hash / Digest : ${res102.digestValue}');
  print('  Enlace PDF    : ${res102.pdfDownloadUrl}');
  print('  XML Decodif.  : ${res102.signedXmlContent}');

  // 1.2 Estado 103 -> CpeProcessStatus.acceptedWithWarnings
  final factura2 = _crearFactura(correlativo: 2);
  simulatedHttp.nextInvoiceEstado = '103';
  final res103 = (await provider.sendDocument(factura2)).getOrThrow();
  print('Factura F001-2 (estado_documento="103") -> Estado: ${res103.status}');
  print('  Descripción   : ${res103.cdr?.description}\n');

  // ---------------------------------------------------------------------------
  // ESCENARIO 2: Emisión de Guía de Remisión (09) con MifactGuideMapper
  // ---------------------------------------------------------------------------
  print('--- [2] Emisión de Guía de Remisión (09) con MifactGuideMapper ---');
  final guia = DespatchAdviceDocument(
    id: const DocumentId(
      issuerRuc: '20100113612',
      type: CpeDocumentType.guiaRemisionRemitente,
      series: 'T001',
      number: 12,
    ),
    issuer: _emisor,
    recipient: _cliente,
    issueDate: DateTime(2026, 11, 4),
    transferStartDate: DateTime(2026, 11, 5),
    transferReason: DespatchReasonCode.venta,
    transportMode: TransportModeCode.transportePrivado,
    grossWeight: Decimal.parse('45.00'),
    weightUnitCode: 'KGM',
    originAddress: const Address(
      ubigeo: '150116',
      streetLine: 'AV. AREQUIPA 2450, LINCE',
    ),
    deliveryAddress: const Address(
      ubigeo: '150141',
      streetLine: 'CALLE LOS NEGOCIOS 180, SURQUILLO',
    ),
    items: [
      DespatchLineItem(
        lineNumber: 1,
        internalCode: 'EQ-POS',
        unitCode: 'NIU',
        description: 'TERMINAL PUNTO DE VENTA TACTIL',
        quantity: Decimal.fromInt(3),
      ),
    ],
  );

  final guidePayload = const MifactGuideMapper().mapGuide(guia, config);
  print(
    'Payload SendGuide: NUM_CORRE_CPE="${guidePayload['NUM_CORRE_CPE']}", '
    'PESO_BRUTO="${guidePayload['PESO_BRUTO']}" ${guidePayload['UND_PESO_BRUTO']}',
  );
  final ticketGuia = (await provider.sendDespatchAdvice(guia)).getOrThrow();
  print('Guía ${guia.id.ublId} enviada -> Ticket: ${ticketGuia.ticket}\n');

  // ---------------------------------------------------------------------------
  // ESCENARIO 3: Resumen Diario (RC), Comunicación de Baja (RA) y checkTicket
  // ---------------------------------------------------------------------------
  print('--- [3] Resumen Diario (RC), Comunicación de Baja (RA) y Ticket ---');
  final resumenDiario = DailySummaryDocument(
    id: const DocumentId(
      issuerRuc: '20100113612',
      type: CpeDocumentType.resumenDiario,
      series: 'RC-20261104',
      number: 1,
    ),
    issuer: _emisor,
    issueDate: DateTime(2026, 11, 4),
    referenceDate: DateTime(2026, 11, 4),
    lines: [
      DailySummaryLine(
        lineNumber: 1,
        documentType: CpeDocumentType.boleta,
        series: 'B001',
        number: 1,
        status: SummaryLineStatus.adicionar,
        totalGravadas: Decimal.parse('100.00'),
        totalIgv: Decimal.parse('18.00'),
        totalSaleAmount: Decimal.parse('118.00'),
      ),
    ],
  );

  final ticketRc = (await provider.sendDailySummary(resumenDiario))
      .getOrThrow();
  print('Resumen Diario enviado -> Ticket: ${ticketRc.ticket}');

  final comunicacionBaja = VoidedDocument(
    id: const DocumentId(
      issuerRuc: '20100113612',
      type: CpeDocumentType.comunicacionBaja,
      series: 'RA-20261104',
      number: 1,
    ),
    issuer: _emisor,
    issueDate: DateTime(2026, 11, 4),
    referenceDate: DateTime(2026, 11, 4),
    lines: const [
      VoidedLine(
        lineNumber: 1,
        documentType: CpeDocumentType.factura,
        series: 'F001',
        number: 2,
        voidReason: 'ERROR EN MONTO DE OPERACION',
      ),
    ],
  );

  final ticketRa = (await provider.sendVoidedDocument(comunicacionBaja))
      .getOrThrow();
  print('Comunicación de Baja enviada -> Ticket: ${ticketRa.ticket}');

  final estadoTicket = (await provider.checkTicket(
    ticketRa.ticket,
    referenceId: comunicacionBaja.id,
  )).getOrThrow();
  print(
    'Consulta de Ticket (${estadoTicket.ticket}): ${estadoTicket.status} -> ${estadoTicket.statusMessage}\n',
  );

  // ---------------------------------------------------------------------------
  // ESCENARIO 4: Consulta de Estado (GetStatus) y Manejo de Rechazo (104)
  // ---------------------------------------------------------------------------
  print('--- [4] Consulta de Estado (`GetStatus`) y Rechazo (`104`) ---');
  final statusRes = (await provider.queryDocumentStatus(
    const DocumentStatusQuery(
      issuerRuc: '20100113612',
      documentType: CpeDocumentType.factura,
      series: 'F001',
      number: 1,
    ),
  )).getOrThrow();
  print(
    'Estado F001-00000001: ${statusRes.status} (Código Mifact: ${statusRes.statusCode}) - ${statusRes.statusMessage}',
  );

  // Simulamos un rechazo de negocio SUNAT con estado_documento = "104"
  simulatedHttp
    ..nextInvoiceEstado = '104'
    ..nextInvoiceErrors =
        '2800 - El tipo de documento de identidad del receptor no es valido';
  final rechazoResult = await provider.sendDocument(
    _crearFactura(correlativo: 99),
  );
  final rejection = rechazoResult.errorOrNull as SunatRejectionException;
  print(
    'Rechazo Mifact (estado_documento="104") -> ${rejection.runtimeType} '
    '(Código SUNAT ${rejection.sunatCode}): ${rejection.message}',
  );
}
