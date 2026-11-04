import 'dart:convert';
import 'dart:typed_data';

import 'package:pointycastle/export.dart';
import 'package:sunat_cpe_core/sunat_cpe_core.dart';

void main() {
  print('===================================================================');
  print('  DEMOSTRACIÓN INTEGRAL DE SUNAT_CPE_CORE (100 % OFFLINE)          ');
  print(
    '===================================================================\n',
  );

  const emisor = CompanyParty(
    ruc: '20100066603',
    legalName: 'CORPORACIÓN TECNOLÓGICA ANDINA S.A.C.',
    tradeName: 'ANDINA TECH',
    address: Address(
      ubigeo: '150101',
      streetLine: 'AV. JAVIER PRADO ESTE 4560',
      district: 'SANTIAGO DE SURCO',
      province: 'LIMA',
      department: 'LIMA',
      establishmentCode: '0000',
    ),
  );

  const clienteCorporativo = CustomerParty(
    documentType: IdentityDocumentType.ruc,
    documentNumber: '20600695771',
    legalName: 'IMPORTACIONES DEL PACÍFICO S.A.C.',
    address: Address(
      ubigeo: '150122',
      streetLine: 'CALLE LOS LIBERTADORES 789',
    ),
  );

  final validador = CpeMathValidator();
  const constructorUbl = UblXmlBuilder();

  // ===========================================================================
  // ESCENARIO 1: Factura Electrónica (01) compleja
  // (Ítem gravado, retiro gratuito por premio, bolsa plástica ICBPER,
  //  pago al crédito en cuotas y detracción SPOT según RS 000193-2020)
  // ===========================================================================
  print('--- ESCENARIO 1: Factura Electrónica (01) Compleja ---');

  final facturaCompleja = InvoiceDocument(
    id: const DocumentId(
      issuerRuc: '20100066603',
      type: CpeDocumentType.factura,
      series: 'F001',
      number: 101,
    ),
    issuer: emisor,
    customer: clienteCorporativo,
    issueDate: DateTime(2026, 11, 4),
    issueTime: '10:15:30',
    currency: CurrencyCode.pen,
    operationType: OperationType.operacionSujetaDetraccion,
    detraction: DetractionInfo(
      code: '022', // Otros servicios empresariales
      paymentMethodCode: '001', // Depósito en cuenta Banco de la Nación
      bankAccountNumber: '00-000-987654',
      percentage: Decimal.parse('12.00'),
      amountInPen: Decimal.parse('141.75'),
    ),
    // Según RS 000193-2020: monto neto pendiente = 1181.24 - 141.75 = 1039.49
    paymentTerms: CreditPaymentTerms(
      netPendingAmount: Decimal.parse('1039.49'),
      installments: [
        PaymentInstallment(
          number: 1,
          amount: Decimal.parse('519.75'),
          dueDate: DateTime(2026, 12, 4),
        ),
        PaymentInstallment(
          number: 2,
          amount: Decimal.parse('519.74'),
          dueDate: DateTime(2027, 1, 4),
        ),
      ],
    ),
    items: [
      // 1. Ítem gravado oneroso (Catálogo 07: código 10)
      CpeLineItem(
        lineNumber: 1,
        internalCode: 'SRV-CLOUD-01',
        sunatProductCode: '81112105',
        unitCode: 'ZZ',
        description: 'SERVICIO DE ARQUITECTURA CLOUD EMPRESARIAL',
        quantity: Decimal.fromInt(2),
        unitValue: Decimal.parse('500.00'),
        unitPrice: Decimal.parse('590.00'),
        lineExtensionAmount: Decimal.parse('1000.00'),
        taxableBaseAmount: Decimal.parse('1000.00'),
        igvAffectation: IgvAffectationType.gravadoOperacionOnerosa,
        igvPercentage: Decimal.parse('18.00'),
        igvAmount: Decimal.parse('180.00'),
        totalLineTaxAmount: Decimal.parse('180.00'),
        totalLineAmount: Decimal.parse('1180.00'),
      ),
      // 2. Ítem gratuito: Retiro por premio (Catálogo 07: código 11)
      CpeLineItem(
        lineNumber: 2,
        internalCode: 'PRM-MERCH-01',
        unitCode: 'NIU',
        description: 'KIT CORPORATIVO DE BIENVENIDA (PREMIO PROMOCIONAL)',
        quantity: Decimal.one,
        unitValue: Decimal.zero,
        unitPrice: Decimal.parse('50.00'),
        isReferencePrice: true,
        lineExtensionAmount: Decimal.parse('50.00'),
        taxableBaseAmount: Decimal.parse('50.00'),
        igvAffectation: IgvAffectationType.gravadoRetiroPremio,
        igvPercentage: Decimal.parse('18.00'),
        igvAmount: Decimal.parse('9.00'),
        totalLineTaxAmount: Decimal.parse('9.00'),
        totalLineAmount: Decimal.parse('50.00'),
      ),
      // 3. Bolsa plástica gravada con ICBPER (Catálogo 05: tributo 7152)
      CpeLineItem(
        lineNumber: 3,
        internalCode: 'BOL-BIO-01',
        unitCode: 'NIU',
        description: 'BOLSA PLÁSTICA REUTILIZABLE',
        quantity: Decimal.fromInt(2),
        unitValue: Decimal.parse('0.10'),
        unitPrice: Decimal.parse('0.12'),
        lineExtensionAmount: Decimal.parse('0.20'),
        taxableBaseAmount: Decimal.parse('0.20'),
        igvAffectation: IgvAffectationType.gravadoOperacionOnerosa,
        igvPercentage: Decimal.parse('18.00'),
        igvAmount: Decimal.parse('0.04'),
        icbperQuantity: 2,
        icbperUnitTax: Decimal.parse('0.50'),
        icbperAmount: Decimal.parse('1.00'),
        totalLineTaxAmount: Decimal.parse('1.04'),
        totalLineAmount: Decimal.parse('1.24'),
      ),
    ],
    totals: MonetaryTotals(
      totalGravadas: Decimal.parse('1000.20'),
      totalGratuitas: Decimal.parse('50.00'),
      totalIgv: Decimal.parse('180.04'),
      totalIcbper: Decimal.parse('1.00'),
      totalImpuestosGratuitas: Decimal.parse('9.00'),
      totalValorVenta: Decimal.parse('1000.20'),
      totalImpuestos: Decimal.parse('181.04'),
      totalPrecioVenta: Decimal.parse('1181.24'),
      importeTotalPagar: Decimal.parse('1181.24'),
      amountInWords: 'SON MIL CIENTO OCHENTA Y UNO CON 24/100 SOLES',
    ),
  );

  validador.validate(facturaCompleja).getOrThrow();
  print('Factura compleja validada: ${facturaCompleja.id.fileNameBase}');
  print(
    '  Total a pagar: S/ ${facturaCompleja.totals.importeTotalPagar} | '
    'Detracción (12%): S/ ${facturaCompleja.detraction!.amountInPen} | '
    'Neto al crédito: S/ ${(facturaCompleja.paymentTerms as CreditPaymentTerms).netPendingAmount}\n',
  );

  // ===========================================================================
  // ESCENARIO 2: Nota de Crédito (07), Nota de Débito (08) y Liquidación de Compra (04)
  // ===========================================================================
  print(
    '--- ESCENARIO 2: Nota de Crédito (07), Nota de Débito (08) y Liquidación (04) ---',
  );

  final notaCredito = CreditNoteDocument(
    id: const DocumentId(
      issuerRuc: '20100066603',
      type: CpeDocumentType.notaCredito,
      series: 'FC01',
      number: 15,
    ),
    issuer: emisor,
    customer: clienteCorporativo,
    issueDate: DateTime(2026, 11, 5),
    currency: CurrencyCode.pen,
    reasonCode: CreditNoteReasonCode.descuentoGlobal,
    reasonDescription: 'DESCUENTO COMERCIAL POR VOLUMEN DE COMPRA',
    affectedDocument: DocumentReference(
      documentType: CpeDocumentType.factura,
      series: 'F001',
      number: 101,
      issueDate: DateTime(2026, 11, 4),
    ),
    items: [
      CpeLineItem(
        lineNumber: 1,
        unitCode: 'ZZ',
        description: 'DESCUENTO GLOBAL APLICADO A FACTURA F001-101',
        quantity: Decimal.one,
        unitValue: Decimal.parse('100.00'),
        unitPrice: Decimal.parse('118.00'),
        lineExtensionAmount: Decimal.parse('100.00'),
        taxableBaseAmount: Decimal.parse('100.00'),
        igvAffectation: IgvAffectationType.gravadoOperacionOnerosa,
        igvPercentage: Decimal.parse('18.00'),
        igvAmount: Decimal.parse('18.00'),
        totalLineTaxAmount: Decimal.parse('18.00'),
        totalLineAmount: Decimal.parse('118.00'),
      ),
    ],
    totals: MonetaryTotals(
      totalGravadas: Decimal.parse('100.00'),
      totalIgv: Decimal.parse('18.00'),
      totalValorVenta: Decimal.parse('100.00'),
      totalImpuestos: Decimal.parse('18.00'),
      totalPrecioVenta: Decimal.parse('118.00'),
      importeTotalPagar: Decimal.parse('118.00'),
    ),
  );

  final notaDebito = DebitNoteDocument(
    id: const DocumentId(
      issuerRuc: '20100066603',
      type: CpeDocumentType.notaDebito,
      series: 'FD01',
      number: 4,
    ),
    issuer: emisor,
    customer: clienteCorporativo,
    issueDate: DateTime(2026, 11, 6),
    currency: CurrencyCode.pen,
    reasonCode: DebitNoteReasonCode.interesesPorMora,
    reasonDescription: 'INTERESES MORATORIOS POR PAGO EXTEMPORÁNEO',
    affectedDocument: const DocumentReference(
      documentType: CpeDocumentType.factura,
      series: 'F001',
      number: 101,
    ),
    items: [
      CpeLineItem(
        lineNumber: 1,
        unitCode: 'ZZ',
        description: 'CARGO POR INTERÉS MORATORIO',
        quantity: Decimal.one,
        unitValue: Decimal.parse('50.00'),
        unitPrice: Decimal.parse('59.00'),
        lineExtensionAmount: Decimal.parse('50.00'),
        taxableBaseAmount: Decimal.parse('50.00'),
        igvAffectation: IgvAffectationType.gravadoOperacionOnerosa,
        igvPercentage: Decimal.parse('18.00'),
        igvAmount: Decimal.parse('9.00'),
        totalLineTaxAmount: Decimal.parse('9.00'),
        totalLineAmount: Decimal.parse('59.00'),
      ),
    ],
    totals: MonetaryTotals(
      totalGravadas: Decimal.parse('50.00'),
      totalIgv: Decimal.parse('9.00'),
      totalValorVenta: Decimal.parse('50.00'),
      totalImpuestos: Decimal.parse('9.00'),
      totalPrecioVenta: Decimal.parse('59.00'),
      importeTotalPagar: Decimal.parse('59.00'),
    ),
  );

  final liquidacionCompra = PurchaseSettlementDocument(
    id: const DocumentId(
      issuerRuc: '20100066603',
      type: CpeDocumentType.liquidacionCompra,
      series: 'E001',
      number: 7,
    ),
    issuer: emisor,
    customer: const CustomerParty(
      documentType: IdentityDocumentType.dni,
      documentNumber: '45891230',
      legalName: 'QUISPE MAMANI JUAN CARLOS',
    ),
    issueDate: DateTime(2026, 11, 6),
    currency: CurrencyCode.pen,
    operationLocation: const Address(
      ubigeo: '080101',
      streetLine: 'SECTOR VALLE SAGRADO KM 14 - CUSCO',
    ),
    items: [
      CpeLineItem(
        lineNumber: 1,
        unitCode: 'KGM',
        description: 'CAFÉ PERGAMINO ORGÁNICO DE ALTURA',
        quantity: Decimal.fromInt(100),
        unitValue: Decimal.parse('12.00'),
        unitPrice: Decimal.parse('14.16'),
        lineExtensionAmount: Decimal.parse('1200.00'),
        taxableBaseAmount: Decimal.parse('1200.00'),
        igvAffectation: IgvAffectationType.gravadoOperacionOnerosa,
        igvPercentage: Decimal.parse('18.00'),
        igvAmount: Decimal.parse('216.00'),
        totalLineTaxAmount: Decimal.parse('216.00'),
        totalLineAmount: Decimal.parse('1416.00'),
      ),
    ],
    totals: MonetaryTotals(
      totalGravadas: Decimal.parse('1200.00'),
      totalIgv: Decimal.parse('216.00'),
      totalValorVenta: Decimal.parse('1200.00'),
      totalImpuestos: Decimal.parse('216.00'),
      totalPrecioVenta: Decimal.parse('1416.00'),
      importeTotalPagar: Decimal.parse('1416.00'),
    ),
  );

  for (final doc in [notaCredito, notaDebito, liquidacionCompra]) {
    validador.validate(doc).getOrThrow();
    final xml = constructorUbl.buildUnsignedXml(doc);
    print(
      '  [${doc.id.type.code}] ${doc.id.ublId} -> XML generado (${xml.length} bytes)',
    );
  }
  print('');

  // ===========================================================================
  // ESCENARIO 3: Resumen Diario (RC), Comunicación de Baja (RA),
  //              Guía de Remisión (09), Retención (20) y Percepción (40)
  // ===========================================================================
  print(
    '--- ESCENARIO 3: RC, RA, Guía de Remisión (09), Retención (20) y Percepción (40) ---',
  );

  final resumenDiario = DailySummaryDocument(
    id: const DocumentId(
      issuerRuc: '20100066603',
      type: CpeDocumentType.resumenDiario,
      series: 'RC-20261104',
      number: 1,
    ),
    issuer: emisor,
    referenceDate: DateTime(2026, 11, 4),
    issueDate: DateTime(2026, 11, 4),
    lines: [
      DailySummaryLine(
        lineNumber: 1,
        documentType: CpeDocumentType.boleta,
        series: 'B001',
        number: 501,
        status: SummaryLineStatus.adicionar,
        customerDocumentType: IdentityDocumentType.dni,
        customerDocumentNumber: '41223344',
        totalGravadas: Decimal.parse('100.00'),
        totalIgv: Decimal.parse('18.00'),
        totalSaleAmount: Decimal.parse('118.00'),
      ),
    ],
  );

  final comunicacionBaja = VoidedDocument(
    id: const DocumentId(
      issuerRuc: '20100066603',
      type: CpeDocumentType.comunicacionBaja,
      series: 'RA-20261104',
      number: 1,
    ),
    issuer: emisor,
    referenceDate: DateTime(2026, 11, 4),
    issueDate: DateTime(2026, 11, 4),
    lines: const [
      VoidedLine(
        lineNumber: 1,
        documentType: CpeDocumentType.factura,
        series: 'F001',
        number: 99,
        voidReason: 'ERROR EN DIGITACIÓN DE RUC DEL CLIENTE',
      ),
    ],
  );

  final guiaRemision = DespatchAdviceDocument(
    id: const DocumentId(
      issuerRuc: '20100066603',
      type: CpeDocumentType.guiaRemisionRemitente,
      series: 'T001',
      number: 32,
    ),
    issuer: emisor,
    recipient: clienteCorporativo,
    issueDate: DateTime(2026, 11, 4),
    issueTime: '08:30:00',
    transferReason: DespatchReasonCode.venta,
    transportMode: TransportModeCode.transportePrivado,
    transferStartDate: DateTime(2026, 11, 5),
    grossWeight: Decimal.parse('125.500'),
    weightUnitCode: 'KGM',
    packageCount: 5,
    originAddress: const Address(
      ubigeo: '150101',
      streetLine: 'ALMACÉN CENTRAL LIMA - AV. INDUSTRIAL 300',
    ),
    deliveryAddress: const Address(
      ubigeo: '150122',
      streetLine: 'CALLE LOS LIBERTADORES 789 - MIRAFLORES',
    ),
    vehicles: const [TransportVehicle(plateNumber: 'ABC-123')],
    drivers: const [
      DriverPerson(
        documentNumber: '40506070',
        firstName: 'MIGUEL',
        lastName: 'RODRIGUEZ',
        licenseNumber: 'Q40506070',
      ),
    ],
    items: [
      DespatchLineItem(
        lineNumber: 1,
        internalCode: 'SRV-RACK-02',
        unitCode: 'NIU',
        description: 'SERVIDOR RACK 2U EMPRESARIAL',
        quantity: Decimal.fromInt(5),
      ),
    ],
  );

  final comprobanteRetencion = RetentionDocument(
    id: const DocumentId(
      issuerRuc: '20100066603',
      type: CpeDocumentType.comprobanteRetencion,
      series: 'R001',
      number: 12,
    ),
    issuer: emisor,
    partner: clienteCorporativo,
    issueDate: DateTime(2026, 11, 4),
    regime: RetentionRegimeCode.tasaTresPorCiento,
    ratePercentage: Decimal.parse('3.00'),
    totalAmountInPen: Decimal.parse('30.00'),
    totalPaidOrCollectedInPen: Decimal.parse('970.00'),
    lines: [
      AgentDocumentLine(
        relatedDocumentType: CpeDocumentType.factura,
        relatedSeriesAndNumber: 'F002-880',
        relatedIssueDate: DateTime(2026, 10, 25),
        relatedTotalAmount: Decimal.parse('1000.00'),
        paymentOrCollectionDate: DateTime(2026, 11, 4),
        paymentAmountBeforeTax: Decimal.parse('1000.00'),
        retainedOrPerceivedAmountInPen: Decimal.parse('30.00'),
        netPaidOrCollectedAmountInPen: Decimal.parse('970.00'),
      ),
    ],
  );

  final comprobantePercepcion = PerceptionDocument(
    id: const DocumentId(
      issuerRuc: '20100066603',
      type: CpeDocumentType.comprobantePercepcion,
      series: 'P001',
      number: 8,
    ),
    issuer: emisor,
    partner: clienteCorporativo,
    issueDate: DateTime(2026, 11, 4),
    regime: PerceptionRegimeCode.ventaInterna,
    ratePercentage: Decimal.parse('2.00'),
    totalAmountInPen: Decimal.parse('20.00'),
    totalPaidOrCollectedInPen: Decimal.parse('1020.00'),
    lines: [
      AgentDocumentLine(
        relatedDocumentType: CpeDocumentType.factura,
        relatedSeriesAndNumber: 'F001-55',
        relatedIssueDate: DateTime(2026, 10, 28),
        relatedTotalAmount: Decimal.parse('1000.00'),
        paymentOrCollectionDate: DateTime(2026, 11, 4),
        paymentAmountBeforeTax: Decimal.parse('1000.00'),
        retainedOrPerceivedAmountInPen: Decimal.parse('20.00'),
        netPaidOrCollectedAmountInPen: Decimal.parse('1020.00'),
      ),
    ],
  );

  for (final doc in [
    resumenDiario,
    comunicacionBaja,
    guiaRemision,
    comprobanteRetencion,
    comprobantePercepcion,
  ]) {
    validador.validate(doc).getOrThrow();
    final xml = constructorUbl.buildUnsignedXml(doc);
    print(
      '  [${doc.id.type.code}] ${doc.id.fileNameBase} -> XML (${xml.length} bytes)',
    );
  }
  print('');

  // ===========================================================================
  // ESCENARIO 4: Validación matemática passthrough (CpeMathValidator)
  //              Documento válido vs detección exacta de errores aritméticos
  // ===========================================================================
  print('--- ESCENARIO 4: Validación Matemática Strict Passthrough ---');

  final validacionExitosa = validador.validate(facturaCompleja);
  print('  ¿Factura F001-101 válida?: ${validacionExitosa.isSuccess}');

  // Creamos una factura con errores matemáticos deliberados para demostrar la detección
  final facturaInconsistente = InvoiceDocument(
    id: const DocumentId(
      issuerRuc: '20100066603',
      type: CpeDocumentType.factura,
      series: 'F001',
      number: 102,
    ),
    issuer: emisor,
    customer: clienteCorporativo,
    issueDate: DateTime(2026, 11, 4),
    currency: CurrencyCode.pen,
    items: [
      CpeLineItem(
        lineNumber: 1,
        description: 'LAPTOP CORPORATIVA',
        quantity: Decimal.fromInt(2),
        unitValue: Decimal.parse('1000.00'),
        unitPrice: Decimal.parse('1180.00'),
        lineExtensionAmount: Decimal.parse('1500.00'), // Error: 2 * 1000 = 2000
        taxableBaseAmount: Decimal.parse('2000.00'),
        igvPercentage: Decimal.parse('18.00'),
        igvAmount: Decimal.parse('250.00'), // Error: 18% de 2000 = 360.00
        totalLineTaxAmount: Decimal.parse('250.00'),
        totalLineAmount: Decimal.parse('1750.00'),
      ),
    ],
    totals: MonetaryTotals(
      totalGravadas: Decimal.parse('2000.00'),
      totalIgv: Decimal.parse('360.00'),
      totalValorVenta: Decimal.parse('2000.00'),
      totalImpuestos: Decimal.parse('360.00'),
      totalPrecioVenta: Decimal.parse('2360.00'),
      importeTotalPagar: Decimal.parse('2360.00'),
    ),
  );

  final validacionFallida = validador.validate(facturaInconsistente);
  if (validacionFallida case CpeFailure(:final error)) {
    final ex = error as CpeValidationException;
    print(
      '  Errores detectados en F001-102 (${ex.issues.length} incidencias):',
    );
    for (final issue in ex.issues) {
      print('    - $issue');
    }
  }
  print('');

  // ===========================================================================
  // ESCENARIO 5: Generación XML UBL 2.1, Firma Digital XAdES-BES en Dart puro,
  //              Compresión ZIP y Lectura de XML CDR (<ApplicationResponse>)
  // ===========================================================================
  print(
    '--- ESCENARIO 5: UBL 2.1 + Firma XAdES-BES + ZIP + Lectura de CDR ---',
  );

  final credencialesDemo = _generarCertificadoRsaDemo();
  const firmador = XadesBesSigner();
  const zipCodec = CpeZipCodec();

  // 1. Generar XML UBL 2.1 sin firmar
  final xmlSinFirmar = constructorUbl.buildUnsignedXml(facturaCompleja);

  // 2. Firmar digitalmente con RSA-SHA256 (C14N en Dart puro)
  final resultadoFirma = firmador.signXml(xmlSinFirmar, credencialesDemo);
  print('  DigestValue (Hash QR): ${resultadoFirma.digestValue}');

  // 3. Empaquetar en archivo .zip en memoria y obtener Base64
  final paqueteZip = zipCodec.encodeXmlToZip(
    fileNameBase: facturaCompleja.id.fileNameBase,
    xmlContent: resultadoFirma.signedXml,
  );
  print(
    '  Archivo ZIP generado: ${facturaCompleja.id.fileNameBase}.zip '
    '(${paqueteZip.zipBytes.length} bytes | Base64: ${paqueteZip.base64Zip.length} chars)',
  );

  // 4. Analizar una Constancia de Recepción (CDR) XML con observaciones SUNAT
  final xmlCdrSimulado =
      '<?xml version="1.0" encoding="UTF-8"?>'
      '<ar:ApplicationResponse xmlns:ar="urn:oasis:names:specification:ubl:schema:xsd:ApplicationResponse-2" '
      'xmlns:cac="urn:oasis:names:specification:ubl:schema:xsd:CommonAggregateComponents-2" '
      'xmlns:cbc="urn:oasis:names:specification:ubl:schema:xsd:CommonBasicComponents-2">'
      '<cbc:ID>R-20100066603-01-F001-101</cbc:ID>'
      '<cbc:ResponseDate>2026-11-04</cbc:ResponseDate>'
      '<cbc:ResponseTime>10:15:35</cbc:ResponseTime>'
      '<cbc:Note>4252 - El codigo de ubigeo del cliente es referencial</cbc:Note>'
      '<cac:DocumentResponse>'
      '<cac:Response>'
      '<cbc:ReferenceID>F001-101</cbc:ReferenceID>'
      '<cbc:ResponseCode>0</cbc:ResponseCode>'
      '<cbc:Description>La Factura numero F001-101, ha sido aceptada</cbc:Description>'
      '</cac:Response>'
      '</cac:DocumentResponse>'
      '</ar:ApplicationResponse>';

  final cdr = zipCodec.parseCdrFromXmlString(xmlCdrSimulado);
  print(
    '  CDR leído -> Estado aceptado: ${cdr.isAccepted} | '
    'Código: ${cdr.responseCode} | Mensaje: "${cdr.description}"',
  );
  print('  Observaciones CDR: ${cdr.warnings}\n');

  // ===========================================================================
  // ESCENARIO 6: Patrones de consumo de CpeResult<T>
  //              (Funcional con fold / switch e imperativo con getOrThrow)
  // ===========================================================================
  print('--- ESCENARIO 6: Patrones de Consumo de CpeResult<T> ---');

  final CpeResult<CdrData> resultadoExitoso = CpeSuccess(cdr);
  final CpeResult<CdrData> resultadoRechazo = CpeFailure(
    SunatRejectionException(
      sunatCode: 2017,
      message: 'El RUC del receptor no se encuentra activo',
    ),
  );

  // 1. Consumo funcional mediante .fold()
  final resumenFold = resultadoExitoso.fold(
    (data) => '[fold] Éxito -> CDR ${data.id} (${data.description})',
    (err) => '[fold] Error -> ${err.message}',
  );
  print('  $resumenFold');

  // 2. Consumo exhaustivo mediante switch (Pattern Matching de Dart 3)
  switch (resultadoRechazo) {
    case CpeSuccess(:final data):
      print('  [switch] Aceptado: ${data.id}');
    case CpeFailure(:final error):
      print(
        '  [switch] Rechazo tipado capturado -> '
        'Código SUNAT: ${error.code} | Detalle: ${error.message}',
      );
  }

  // 3. Consumo imperativo mediante .getOrThrow()
  try {
    final datosCdr = resultadoExitoso.getOrThrow();
    print('  [getOrThrow] CDR desempaquetado directamente: ${datosCdr.id}');
  } on CpeException catch (e) {
    print('  [getOrThrow] Excepción: $e');
  }
}

/// Genera un par de claves RSA de 1024 bits determinista en memoria para pruebas offline.
CpeCertificateCredentials _generarCertificadoRsaDemo() {
  final keyParams = RSAKeyGeneratorParameters(BigInt.parse('65537'), 1024, 12);
  final secureRandom = FortunaRandom()
    ..seed(KeyParameter(Uint8List.fromList(List.generate(32, (i) => i + 1))));
  final generator = RSAKeyGenerator()
    ..init(ParametersWithRandom(keyParams, secureRandom));
  final pair = generator.generateKeyPair();

  return CpeCertificateCredentials(
    privateKey: pair.privateKey,
    base64X509Certificate: base64.encode(
      utf8.encode('CERTIFICADO-X509-DEMO-SUNAT-CPE-CORE'),
    ),
  );
}
