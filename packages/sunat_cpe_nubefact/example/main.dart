import 'dart:convert';
import 'dart:typed_data';

import 'package:sunat_cpe_core/sunat_cpe_core.dart';
import 'package:sunat_cpe_nubefact/sunat_cpe_nubefact.dart';

/// Cliente HTTP simulado (100 % offline) que emula las respuestas reales
/// del servidor REST JSON v1 de Nubefact (`https://api.nubefact.com/api/v1/<RUTA>`).
final class SimulatedNubefactHttpClient implements CpeHttpClient {
  int _voidedPollAttempt = 0;
  int? forcedErrorCode;
  int forcedHttpStatus = 200;

  @override
  Future<CpeHttpResponse> send(CpeHttpRequest request) async {
    final bodyMap = jsonDecode(request.body.toString()) as Map<String, Object?>;
    final operacion = bodyMap['operacion'] as String? ?? '';

    // Si se configuró un escenario de error forzado para demostración:
    if (forcedErrorCode != null) {
      final code = forcedErrorCode!;
      forcedErrorCode = null;
      final status = forcedHttpStatus;
      forcedHttpStatus = 200;

      if (code >= 2000) {
        return _jsonResponse(200, {
          'aceptada_por_sunat': false,
          'sunat_responsecode': '$code',
          'sunat_description':
              'El RUC del receptor no se encuentra activo en SUNAT (Código $code)',
          'sunat_soap_error': '',
        });
      }

      return _jsonResponse(status, {
        'errors': code == 10
            ? 'Token no válido o ruta desautorizada en Nubefact'
            : 'La serie ingresada no coincide con el tipo de comprobante',
        'codigo': code,
      });
    }

    switch (operacion) {
      case 'generar_comprobante':
        final tipo = bodyMap['tipo_de_comprobante'];
        final serie = bodyMap['serie'];
        final numero = bodyMap['numero'];
        return _jsonResponse(200, {
          'tipo_de_comprobante': tipo,
          'serie': serie,
          'numero': numero,
          'enlace': 'https://www.nubefact.com/cpe/$serie-$numero',
          'aceptada_por_sunat': true,
          'sunat_description':
              'El comprobante $serie-$numero ha sido aceptado por SUNAT',
          'sunat_note': null,
          'sunat_responsecode': '0',
          'sunat_soap_error': '',
          'codigo_hash': 'NubeHash/${serie}_$numero==',
          'cadena_para_codigo_qr':
              '20100066603|0$tipo|$serie|$numero|18.00|118.00|04/11/2026|6|20600695771|NubeHash/${serie}_$numero==|',
          'enlace_del_pdf': 'https://www.nubefact.com/cpe/$serie-$numero.pdf',
          'enlace_del_xml': 'https://www.nubefact.com/cpe/$serie-$numero.xml',
          'enlace_del_cdr': 'https://www.nubefact.com/cpe/R-$serie-$numero.zip',
        });

      case 'generar_guia':
        final serie = bodyMap['serie'];
        final numero = bodyMap['numero'];
        return _jsonResponse(200, {
          'tipo_de_comprobante': bodyMap['tipo_de_comprobante'],
          'serie': serie,
          'numero': numero,
          'aceptada_por_sunat': true,
          'sunat_ticket_numero': 'GRE-TICKET-2026-00981',
          'enlace_del_pdf': 'https://www.nubefact.com/guia/$serie-$numero.pdf',
          'enlace_del_xml': 'https://www.nubefact.com/guia/$serie-$numero.xml',
          'enlace_del_cdr':
              'https://www.nubefact.com/guia/R-$serie-$numero.zip',
        });

      case 'generar_anulacion':
        _voidedPollAttempt = 0;
        return _jsonResponse(200, {
          'aceptada_por_sunat': false,
          'sunat_ticket_numero': 'RA-TICKET-20261104-001',
          'sunat_description': 'Comunicación de baja en proceso',
        });

      case 'consultar_anulacion':
        _voidedPollAttempt++;
        final listo = _voidedPollAttempt >= 2;
        return _jsonResponse(200, {
          'aceptada_por_sunat': listo,
          'sunat_responsecode': listo ? '0' : '',
          'sunat_description': listo
              ? 'La Comunicación de Baja RA-20261104-1 ha sido aceptada'
              : '',
          'codigo_hash': listo ? 'HashBajaRA001==' : '',
        });

      case 'consultar_comprobante':
        final serie = bodyMap['serie'];
        final numero = bodyMap['numero'];
        return _jsonResponse(200, {
          'tipo_de_comprobante': bodyMap['tipo_de_comprobante'],
          'serie': serie,
          'numero': numero,
          'aceptada_por_sunat': true,
          'sunat_responsecode': '0',
          'sunat_description':
              'El comprobante $serie-$numero se encuentra ACEPTADO en SUNAT',
          'codigo_hash': 'NubeHash/${serie}_$numero==',
          'cadena_para_codigo_qr':
              '20100066603|01|$serie|$numero|18.00|118.00|04/11/2026|6|20600695771|NubeHash/${serie}_$numero==|',
          'enlace_del_pdf': 'https://www.nubefact.com/cpe/$serie-$numero.pdf',
          'enlace_del_xml': 'https://www.nubefact.com/cpe/$serie-$numero.xml',
          'enlace_del_cdr': 'https://www.nubefact.com/cpe/R-$serie-$numero.zip',
        });

      default:
        return _jsonResponse(400, {
          'errors': 'Operación no soportada: $operacion',
          'codigo': 20,
        });
    }
  }

  CpeHttpResponse _jsonResponse(int statusCode, Map<String, Object?> jsonMap) {
    return CpeHttpResponse(
      statusCode: statusCode,
      headers: const {'content-type': 'application/json; charset=utf-8'},
      bodyBytes: Uint8List.fromList(utf8.encode(jsonEncode(jsonMap))),
    );
  }

  @override
  void close() {}
}

const _emisor = CompanyParty(
  ruc: '20100066603',
  legalName: 'CORPORACION TECNOLOGICA PERU S.A.C.',
  tradeName: 'CORPTECH PERU',
  address: Address(
    ubigeo: '150101',
    streetLine: 'AV. PASEO DE LA REPUBLICA 3210, SAN ISIDRO',
  ),
);

const _clienteRuc = CustomerParty(
  documentType: IdentityDocumentType.ruc,
  documentNumber: '20600695771',
  legalName: 'NUBEFACT S.A.',
  address: Address(streetLine: 'CALLE LIBERTAD 116, MIRAFLORES'),
  email: 'contacto@nubefact.com',
);

const _clienteDni = CustomerParty(
  documentType: IdentityDocumentType.dni,
  documentNumber: '45678912',
  legalName: 'JUAN CARLOS PEREZ GOMEZ',
  address: Address(streetLine: 'JR. DE LA UNION 550, LIMA'),
);

CpeLineItem _itemGravado({
  required String codigo,
  required String descripcion,
  required String valorUnitario,
  required String precioUnitario,
  required String igv,
  required String total,
}) {
  return CpeLineItem(
    lineNumber: 1,
    internalCode: codigo,
    sunatProductCode: '43231500',
    unitCode: 'NIU',
    description: descripcion,
    quantity: Decimal.one,
    unitValue: Decimal.parse(valorUnitario),
    unitPrice: Decimal.parse(precioUnitario),
    lineExtensionAmount: Decimal.parse(valorUnitario),
    taxableBaseAmount: Decimal.parse(valorUnitario),
    igvAffectation: IgvAffectationType.gravadoOperacionOnerosa,
    igvPercentage: Decimal.parse('18.00'),
    igvAmount: Decimal.parse(igv),
    totalLineTaxAmount: Decimal.parse(igv),
    totalLineAmount: Decimal.parse(total),
  );
}

MonetaryTotals _totalesGravados({
  required String gravada,
  required String igv,
  required String total,
}) {
  return MonetaryTotals(
    totalGravadas: Decimal.parse(gravada),
    totalIgv: Decimal.parse(igv),
    totalValorVenta: Decimal.parse(gravada),
    totalImpuestos: Decimal.parse(igv),
    totalPrecioVenta: Decimal.parse(total),
    importeTotalPagar: Decimal.parse(total),
  );
}

Future<void> main() async {
  print('===================================================================');
  print('  DEMO OFFLINE: sunat_cpe_nubefact (API REST JSON v1 PSE/OSE)');
  print(
    '===================================================================\n',
  );

  // En producción/pruebas se utiliza la RUTA y TOKEN asignados en el panel de Nubefact:
  // routeUri: Uri.parse('https://api.nubefact.com/api/v1/<UUID-DE-TU-RUTA>')
  final config = NubefactConfig(
    routeUri: Uri.parse(
      'https://api.nubefact.com/api/v1/demo-ruta-empresa-20100066603',
    ),
    apiToken: 'DEMO_TOKEN_NUBEFACT_2026_XYZ',
    autoSendToSunat: true,
    autoSendToCustomer: true,
    pdfFormat: 'A4',
  );

  final simulatedClient = SimulatedNubefactHttpClient();
  final provider = NubefactProvider(
    config: config,
    httpClient: simulatedClient,
  );

  // ---------------------------------------------------------------------------
  // ESCENARIO 1: Emisión de Factura (01) y Boleta (03) + Mapeo de Catálogos
  // ---------------------------------------------------------------------------
  print('--- [1] Emisión de Factura (01) y Boleta (03) ---');
  print(
    'Mapeo de catálogos Nubefact: '
    'Factura(01)->${NubefactCatalogMapper.mapDocumentType(CpeDocumentType.factura)}, '
    'Boleta(03)->${NubefactCatalogMapper.mapDocumentType(CpeDocumentType.boleta)}, '
    'PEN->${NubefactCatalogMapper.mapCurrency(CurrencyCode.pen)}, '
    'IGV(10)->${NubefactCatalogMapper.mapIgvAffectation(IgvAffectationType.gravadoOperacionOnerosa)}',
  );

  final factura = InvoiceDocument(
    id: const DocumentId(
      issuerRuc: '20100066603',
      type: CpeDocumentType.factura,
      series: 'FFF1',
      number: 15,
    ),
    issuer: _emisor,
    customer: _clienteRuc,
    issueDate: DateTime(2026, 11, 4),
    dueDate: DateTime(2026, 12, 4),
    currency: CurrencyCode.pen,
    paymentTerms: CreditPaymentTerms(
      netPendingAmount: Decimal.parse('118.00'),
      installments: [
        PaymentInstallment(
          number: 1,
          amount: Decimal.parse('118.00'),
          dueDate: DateTime(2026, 12, 4),
        ),
      ],
    ),
    items: [
      _itemGravado(
        codigo: 'LIC-001',
        descripcion: 'LICENCIA ANUAL DE FACTURACION CLOUD',
        valorUnitario: '100.00',
        precioUnitario: '118.00',
        igv: '18.00',
        total: '118.00',
      ),
    ],
    totals: _totalesGravados(gravada: '100.00', igv: '18.00', total: '118.00'),
  );

  final facturaRes = (await provider.sendDocument(factura)).getOrThrow();
  print(
    'Factura emitida: ${facturaRes.documentId.ublId} -> ${facturaRes.status}',
  );
  print('  CDR Descripción : ${facturaRes.cdr?.description}');
  print('  Hash / Digest   : ${facturaRes.digestValue}');
  print('  Enlace PDF      : ${facturaRes.pdfDownloadUrl}');
  print('  Enlace XML      : ${facturaRes.xmlDownloadUrl}');
  print('  Enlace CDR      : ${facturaRes.cdrDownloadUrl}');

  final boleta = InvoiceDocument(
    id: const DocumentId(
      issuerRuc: '20100066603',
      type: CpeDocumentType.boleta,
      series: 'BBB1',
      number: 42,
    ),
    issuer: _emisor,
    customer: _clienteDni,
    issueDate: DateTime(2026, 11, 4),
    currency: CurrencyCode.pen,
    items: [
      _itemGravado(
        codigo: 'ACC-010',
        descripcion: 'LECTOR DE CODIGO DE BARRAS USB',
        valorUnitario: '50.00',
        precioUnitario: '59.00',
        igv: '9.00',
        total: '59.00',
      ),
    ],
    totals: _totalesGravados(gravada: '50.00', igv: '9.00', total: '59.00'),
  );

  final boletaRes = (await provider.sendDocument(boleta)).getOrThrow();
  print(
    'Boleta emitida : ${boletaRes.documentId.ublId} -> ${boletaRes.status}\n',
  );

  // ---------------------------------------------------------------------------
  // ESCENARIO 2: Emisión de Nota de Crédito Electrónica (07)
  // ---------------------------------------------------------------------------
  print('--- [2] Emisión de Nota de Crédito (07) ---');
  final notaCredito = CreditNoteDocument(
    id: const DocumentId(
      issuerRuc: '20100066603',
      type: CpeDocumentType.notaCredito,
      series: 'FFF1',
      number: 1,
    ),
    issuer: _emisor,
    customer: _clienteRuc,
    issueDate: DateTime(2026, 11, 4),
    currency: CurrencyCode.pen,
    reasonCode: CreditNoteReasonCode.anulacionOperacion,
    reasonDescription: 'ANULACION DE LA OPERACION POR DESISTIMIENTO',
    affectedDocument: const DocumentReference(
      documentType: CpeDocumentType.factura,
      series: 'FFF1',
      number: 15,
    ),
    items: [
      _itemGravado(
        codigo: 'LIC-001',
        descripcion: 'LICENCIA ANUAL DE FACTURACION CLOUD',
        valorUnitario: '100.00',
        precioUnitario: '118.00',
        igv: '18.00',
        total: '118.00',
      ),
    ],
    totals: _totalesGravados(gravada: '100.00', igv: '18.00', total: '118.00'),
  );

  final ncRes = (await provider.sendDocument(notaCredito)).getOrThrow();
  print(
    'Nota de Crédito ${ncRes.documentId.ublId} afecta a FFF1-15 -> ${ncRes.status}\n',
  );

  // ---------------------------------------------------------------------------
  // ESCENARIO 3: Emisión de Guía de Remisión Remitente (09)
  // ---------------------------------------------------------------------------
  print('--- [3] Emisión de Guía de Remisión Remitente (09) ---');
  final guiaRemitente = DespatchAdviceDocument(
    id: const DocumentId(
      issuerRuc: '20100066603',
      type: CpeDocumentType.guiaRemisionRemitente,
      series: 'TTT1',
      number: 8,
    ),
    issuer: _emisor,
    recipient: _clienteRuc,
    issueDate: DateTime(2026, 11, 4),
    transferStartDate: DateTime(2026, 11, 5),
    transferReason: DespatchReasonCode.venta,
    transportMode: TransportModeCode.transportePrivado,
    grossWeight: Decimal.parse('25.50'),
    weightUnitCode: 'KGM',
    packageCount: 2,
    originAddress: const Address(
      ubigeo: '150131',
      streetLine: 'AV. PASEO DE LA REPUBLICA 3210, SAN ISIDRO',
    ),
    deliveryAddress: const Address(
      ubigeo: '150122',
      streetLine: 'CALLE LIBERTAD 116, MIRAFLORES',
    ),
    vehicles: const [TransportVehicle(plateNumber: 'ABC-123')],
    drivers: const [
      DriverPerson(
        documentType: IdentityDocumentType.dni,
        documentNumber: '41223344',
        firstName: 'LUIS',
        lastName: 'RAMIREZ SOTO',
        licenseNumber: 'Q41223344',
      ),
    ],
    items: [
      DespatchLineItem(
        lineNumber: 1,
        internalCode: 'EQ-01',
        unitCode: 'NIU',
        description: 'SERVIDOR RACK 2U',
        quantity: Decimal.fromInt(2),
      ),
    ],
  );

  final guiaTicket = (await provider.sendDespatchAdvice(guiaRemitente))
      .getOrThrow();
  print(
    'Guía de Remisión ${guiaTicket.referenceId?.ublId} registrada -> Ticket: ${guiaTicket.ticket}\n',
  );

  // ---------------------------------------------------------------------------
  // ESCENARIO 4: Comunicación de Baja (RA) + Polling Automático
  // ---------------------------------------------------------------------------
  print('--- [4] Comunicación de Baja (RA) y Polling Automático ---');
  final comunicacionBaja = VoidedDocument(
    id: const DocumentId(
      issuerRuc: '20100066603',
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
        series: 'FFF1',
        number: 15,
        voidReason: 'ERROR EN DATOS DEL ADQUIRENTE',
      ),
    ],
  );

  final bajaTicket = (await provider.sendVoidedDocument(comunicacionBaja))
      .getOrThrow();
  print('Ticket de Baja generado: ${bajaTicket.ticket}');

  final cdrBaja = (await provider.pollTicketUntilDone(
    bajaTicket.ticket,
    referenceId: bajaTicket.referenceId,
    config: const PollingConfig(
      initialDelay: Duration(milliseconds: 10),
      maxDelay: Duration(milliseconds: 50),
      maxAttempts: 4,
    ),
  )).getOrThrow();
  print(
    'Polling completado (`consultar_anulacion`): [${cdrBaja.responseCode}] ${cdrBaja.description}\n',
  );

  // ---------------------------------------------------------------------------
  // ESCENARIO 5: Consulta de Estado de Comprobante (consultar_comprobante)
  // ---------------------------------------------------------------------------
  print(
    '--- [5] Consulta de Estado de Comprobante (`consultar_comprobante`) ---',
  );
  final estadoComprobante = (await provider.queryDocumentStatus(
    const DocumentStatusQuery(
      issuerRuc: '20100066603',
      documentType: CpeDocumentType.factura,
      series: 'FFF1',
      number: 15,
    ),
  )).getOrThrow();
  print(
    'Estado FFF1-15: ${estadoComprobante.status} (Código ${estadoComprobante.statusCode}) - ${estadoComprobante.statusMessage}',
  );
  print('PDF disponible en: ${estadoComprobante.pdfDownloadUrl}\n');

  // ---------------------------------------------------------------------------
  // ESCENARIO 6: Manejo de Códigos de Error de Nubefact y Rechazos SUNAT
  // ---------------------------------------------------------------------------
  print('--- [6] Manejo de Errores (Códigos 10, 21 y Rechazo SUNAT 2000+) ---');

  // 6.1 Error código 10 -> OseAuthException
  simulatedClient
    ..forcedErrorCode = 10
    ..forcedHttpStatus = 401;
  final err10 = await provider.sendDocument(factura);
  print(
    'Código Nubefact 10 -> ${err10.errorOrNull.runtimeType}: ${err10.errorOrNull?.message}',
  );

  // 6.2 Error código 21 -> CpeValidationException
  simulatedClient
    ..forcedErrorCode = 21
    ..forcedHttpStatus = 400;
  final err21 = await provider.sendDocument(factura);
  print(
    'Código Nubefact 21 -> ${err21.errorOrNull.runtimeType}: ${err21.errorOrNull?.message}',
  );

  // 6.3 Rechazo SUNAT código 2017 -> SunatRejectionException
  simulatedClient.forcedErrorCode = 2017;
  final err2017 = await provider.sendDocument(factura);
  final rejection = err2017.errorOrNull as SunatRejectionException;
  print(
    'Código SUNAT ${rejection.sunatCode}  -> ${rejection.runtimeType}: ${rejection.message}',
  );
}
