import 'dart:convert';
import 'dart:typed_data';

import 'package:sunat_cpe_core/sunat_cpe_core.dart';
import 'package:sunat_cpe_facturaloperu/sunat_cpe_facturaloperu.dart';

/// Cliente HTTP simulado 100% offline para demostrar todos los flujos de FacturaloPeru / Facturador PRO.
final class _SimulatedFacturaloHttpClient implements CpeHttpClient {
  int _summaryStatusAttempts = 0;

  @override
  Future<CpeHttpResponse> send(CpeHttpRequest request) async {
    final path = request.uri.path;

    // 1. Emisión de Factura (/api/documents)
    if (path.endsWith('/api/documents')) {
      final body = jsonDecode(request.body as String) as Map<String, dynamic>;
      final serie = body['serie_documento'];
      final numero = body['numero_documento'];
      final assignedNumber = numero == '#' ? '00000125' : numero.toString();

      return _jsonResponse({
        'success': true,
        'data': {
          'number': '$serie-$assignedNumber',
          'filename': '20100066603-01-$serie-$assignedNumber',
          'external_id': 'f81d4fae-7dec-11d0-a765-00a0c91e6bf6',
          'state_type_id': '05',
          'state_type_description': 'Aceptado',
          'hash': 'kL9mN2pQ4rS6tU8vW0xY2zA4bC6=',
          'qr':
              '20100066603|01|$serie|$assignedNumber|180.00|1180.00|2026-11-04|6|20600695771|',
          'cdr_response': {
            'code': '0',
            'description':
                'La Factura numero $serie-$assignedNumber, ha sido aceptada',
            'notes': <String>[],
          },
        },
        'links': {
          'xml': 'https://demo.facturaloperu.com/downloads/xml/f81d4fae',
          'pdf': 'https://demo.facturaloperu.com/downloads/pdf/f81d4fae',
          'cdr': 'https://demo.facturaloperu.com/downloads/cdr/f81d4fae',
        },
      });
    }

    // 2. Resumen Diario (/api/summaries) y Polling (/api/summaries/status)
    if (path.endsWith('/api/summaries')) {
      return _jsonResponse({
        'success': true,
        'data': {
          'external_id': 'ext-rc-20261104-01',
          'ticket': '202600998877665',
        },
      });
    }

    if (path.endsWith('/api/summaries/status')) {
      _summaryStatusAttempts++;
      if (_summaryStatusAttempts == 1) {
        return _jsonResponse({
          'success': true,
          'data': {
            'state_type_id': '03',
            'state_type_description': 'Enviado a SUNAT (En Proceso)',
          },
        });
      }
      return _jsonResponse({
        'success': true,
        'data': {
          'filename': 'R-20100066603-RC-20261104-1',
          'state_type_id': '05',
          'state_type_description': 'Aceptado',
          'cdr_response': {
            'code': '0',
            'description': 'El Resumen Diario RC-20261104-1 ha sido aceptado',
          },
        },
      });
    }

    // 3. Comunicación de Baja (/api/voided) y Guía de Remisión (/api/dispatches)
    if (path.endsWith('/api/voided')) {
      return _jsonResponse({
        'success': true,
        'data': {
          'external_id': 'ext-ra-20261104-01',
          'ticket': '202600112233445',
        },
      });
    }

    if (path.endsWith('/api/dispatches')) {
      return _jsonResponse({
        'success': true,
        'data': {
          'external_id': 'ext-gre-t001-01',
          'ticket': 'GRE-TICKET-998877',
        },
      });
    }

    // 4. Consulta de Padrón SUNAT (RUC) y RENIEC (DNI)
    if (path.endsWith('/api/service/ruc/20100066603')) {
      return _jsonResponse({
        'success': true,
        'data': {
          'ruc': '20100066603',
          'nombre_o_razon_social': 'CORPORACION TECNOLOGICA DEL PERU S.A.C.',
          'estado': 'ACTIVO',
          'condicion': 'HABIDO',
          'direccion': 'AV. JAVIER PRADO ESTE 4500, SANTIAGO DE SURCO',
          'ubigeo': '150140',
        },
      });
    }

    if (path.endsWith('/api/service/dni/45678912')) {
      return _jsonResponse({
        'success': true,
        'data': {
          'numero': '45678912',
          'name': 'CARLOS ALBERTO MENDOZA VARGAS',
          'estado': 'ACTIVO',
          'condicion': 'HABIDO',
          'direccion': 'JR. LAS CAMELIAS 320, SAN ISIDRO',
          'ubigeo': '150131',
        },
      });
    }

    return _jsonResponse({
      'success': false,
      'message': 'Ruta no simulada: $path',
    });
  }

  CpeHttpResponse _jsonResponse(Map<String, dynamic> map) {
    return CpeHttpResponse(
      statusCode: 200,
      headers: const {'content-type': 'application/json; charset=utf-8'},
      bodyBytes: Uint8List.fromList(utf8.encode(jsonEncode(map))),
    );
  }

  @override
  void close() {}
}

Future<void> main() async {
  print('===================================================================');
  print(' DEMO OFFLINE: sunat_cpe_facturaloperu (Facturador PRO / Smart)');
  print(
    '===================================================================\n',
  );

  final provider = FacturaloProvider(
    config: FacturaloConfig(
      baseUri: Uri.parse('https://demo.facturaloperu.com'),
      apiToken: 'BEARER_TOKEN_DEMO_PRO_5',
      pdfFormat: 'a4',
      sendEmail: true,
      allowServerAutoIncrement: true,
    ),
    httpClient: _SimulatedFacturaloHttpClient(),
  );

  const issuer = CompanyParty(
    ruc: '20100066603',
    legalName: 'CORPORACION TECNOLOGICA DEL PERU S.A.C.',
    address: Address(
      ubigeo: '150140',
      streetLine: 'AV. JAVIER PRADO ESTE 4500',
    ),
  );

  // ---------------------------------------------------------------------------
  // 1. Emisión de Factura (01) con FacturaloProvider.sendDocument (/api/documents)
  //    y demostración de allowServerAutoIncrement: true (number: "#")
  // ---------------------------------------------------------------------------
  print('1. Emisión de Factura (01) en /api/documents y modo correlativo "#"');
  final invoice = InvoiceDocument(
    id: const DocumentId(
      issuerRuc: '20100066603',
      type: CpeDocumentType.factura,
      series: 'F001',
      number: 125,
    ),
    issueDate: DateTime(2026, 11, 4),
    issuer: issuer,
    customer: const CustomerParty(
      documentType: IdentityDocumentType.ruc,
      documentNumber: '20600695771',
      legalName: 'INVERSIONES INDUSTRIALES ANDINAS S.A.C.',
      email: 'facturacion@andinas.pe',
    ),
    currency: CurrencyCode.pen,
    items: [
      CpeLineItem(
        lineNumber: 1,
        internalCode: 'SRV-CLOUD-01',
        sunatProductCode: '81112105',
        unitCode: 'ZZ',
        description: 'SUSCRIPCION ANUAL SERVIDOR DEDICADO',
        quantity: Decimal.fromInt(1),
        unitValue: Decimal.parse('1000.00'),
        unitPrice: Decimal.parse('1180.00'),
        lineExtensionAmount: Decimal.parse('1000.00'),
        taxableBaseAmount: Decimal.parse('1000.00'),
        igvAffectation: IgvAffectationType.gravadoOperacionOnerosa,
        igvPercentage: Decimal.parse('18.00'),
        igvAmount: Decimal.parse('180.00'),
        totalLineTaxAmount: Decimal.parse('180.00'),
        totalLineAmount: Decimal.parse('1180.00'),
      ),
    ],
    totals: MonetaryTotals(
      totalGravadas: Decimal.parse('1000.00'),
      totalIgv: Decimal.parse('180.00'),
      totalValorVenta: Decimal.parse('1000.00'),
      totalImpuestos: Decimal.parse('180.00'),
      totalPrecioVenta: Decimal.parse('1180.00'),
      importeTotalPagar: Decimal.parse('1180.00'),
    ),
  );

  // Demostración de allowServerAutoIncrement: true cuando el correlativo es 0:
  final draftWithAutoIncrement = InvoiceDocument(
    id: invoice.id.copyWith(number: 0),
    issueDate: invoice.issueDate,
    issuer: invoice.issuer,
    customer: invoice.customer,
    currency: invoice.currency,
    items: invoice.items,
    totals: invoice.totals,
  );
  final mappedAutoJson = provider.documentMapper.mapSalesDocument(
    draftWithAutoIncrement,
    provider.config,
  );
  print(
    '   -> Modo allowServerAutoIncrement (number=0) mapea numero_documento: '
    '"${mappedAutoJson['numero_documento']}"',
  );

  final invoiceResponse = (await provider.sendDocument(invoice)).getOrThrow();
  print('   -> Estado SUNAT: ${invoiceResponse.status.name}');
  print('   -> Descripción CDR: ${invoiceResponse.cdr?.description}');
  print('   -> External ID: ${invoiceResponse.ticket}');
  print('   -> URL descarga PDF: ${invoiceResponse.pdfDownloadUrl}\n');

  // ---------------------------------------------------------------------------
  // 2. Emisión de Resumen Diario (/api/summaries) y Polling (/api/summaries/status)
  // ---------------------------------------------------------------------------
  print('2. Emisión de Resumen Diario (RC) y Polling Asíncrono');
  final summary = DailySummaryDocument(
    id: const DocumentId(
      issuerRuc: '20100066603',
      type: CpeDocumentType.resumenDiario,
      series: 'RC-20261104',
      number: 1,
    ),
    issueDate: DateTime(2026, 11, 4),
    referenceDate: DateTime(2026, 11, 4),
    issuer: issuer,
    lines: [
      DailySummaryLine(
        lineNumber: 1,
        documentType: CpeDocumentType.boleta,
        series: 'B001',
        number: 10,
        status: SummaryLineStatus.adicionar,
        customerDocumentType: IdentityDocumentType.dni,
        customerDocumentNumber: '45678912',
        totalGravadas: Decimal.parse('100.00'),
        totalIgv: Decimal.parse('18.00'),
        totalSaleAmount: Decimal.parse('118.00'),
      ),
    ],
  );

  final summaryTicket = (await provider.sendDailySummary(summary)).getOrThrow();
  print('   -> Ticket RC generado: ${summaryTicket.ticket}');

  final polledSummary = (await provider.pollTicketUntilDone(
    summaryTicket.ticket,
    referenceId: summary.id,
    config: const PollingConfig(
      initialDelay: Duration(milliseconds: 10),
      maxAttempts: 3,
    ),
  )).getOrThrow();
  print('   -> Código CDR tras polling: ${polledSummary.responseCode}');
  print('   -> Mensaje CDR: ${polledSummary.description}\n');

  // ---------------------------------------------------------------------------
  // 3. Comunicación de Baja (/api/voided) y Guía de Remisión (/api/dispatches)
  // ---------------------------------------------------------------------------
  print('3. Comunicación de Baja (RA) y Guía de Remisión Remitente (09)');
  final voided = VoidedDocument(
    id: const DocumentId(
      issuerRuc: '20100066603',
      type: CpeDocumentType.comunicacionBaja,
      series: 'RA-20261104',
      number: 1,
    ),
    issueDate: DateTime(2026, 11, 4),
    referenceDate: DateTime(2026, 11, 3),
    issuer: issuer,
    lines: const [
      VoidedLine(
        lineNumber: 1,
        documentType: CpeDocumentType.factura,
        series: 'F001',
        number: 99,
        voidReason: 'ERROR EN RUC DEL RECEPTOR',
      ),
    ],
  );
  final voidedTicket = (await provider.sendVoidedDocument(voided)).getOrThrow();
  print('   -> Ticket Baja (/api/voided): ${voidedTicket.ticket}');

  final guide = DespatchAdviceDocument(
    id: const DocumentId(
      issuerRuc: '20100066603',
      type: CpeDocumentType.guiaRemisionRemitente,
      series: 'T001',
      number: 15,
    ),
    issueDate: DateTime(2026, 11, 4),
    issuer: issuer,
    recipient: const CustomerParty(
      documentType: IdentityDocumentType.ruc,
      documentNumber: '20600695771',
      legalName: 'INVERSIONES INDUSTRIALES ANDINAS S.A.C.',
    ),
    transferReason: DespatchReasonCode.venta,
    transportMode: TransportModeCode.transportePublico,
    transferStartDate: DateTime(2026, 11, 5),
    grossWeight: Decimal.parse('120.50'),
    originAddress: const Address(
      ubigeo: '150140',
      streetLine: 'AV. JAVIER PRADO ESTE 4500',
    ),
    deliveryAddress: const Address(
      ubigeo: '150101',
      streetLine: 'AV. ARGENTINA 1250, LIMA',
    ),
    items: [
      DespatchLineItem(
        lineNumber: 1,
        internalCode: 'EQ-RACK-01',
        description: 'GABINETE DE SERVIDORES 42U',
        quantity: Decimal.fromInt(2),
      ),
    ],
  );
  final guideTicket = (await provider.sendDespatchAdvice(guide)).getOrThrow();
  print('   -> Ticket Guía (/api/dispatches): ${guideTicket.ticket}\n');

  // ---------------------------------------------------------------------------
  // 4. Consulta de Padrón SUNAT (RUC) y RENIEC (DNI)
  // ---------------------------------------------------------------------------
  print('4. Consulta de Padrón SUNAT (RUC) y RENIEC (DNI)');
  final rucInfo = (await provider.lookupTaxpayer(
    documentNumber: '20100066603',
    isRuc: true,
  )).getOrThrow();
  print(
    '   -> RUC ${rucInfo.documentNumber}: ${rucInfo.nameOrLegalName} '
    '[Estado: ${rucInfo.status}, Condición: ${rucInfo.condition}, '
    'Dirección: ${rucInfo.address}, Ubigeo: ${rucInfo.ubigeo}]',
  );

  final dniInfo = (await provider.lookupTaxpayer(
    documentNumber: '45678912',
    isRuc: false,
  )).getOrThrow();
  print(
    '   -> DNI ${dniInfo.documentNumber}: ${dniInfo.nameOrLegalName} '
    '[Estado: ${dniInfo.status}, Condición: ${dniInfo.condition}, '
    'Dirección: ${dniInfo.address}, Ubigeo: ${dniInfo.ubigeo}]',
  );
}
