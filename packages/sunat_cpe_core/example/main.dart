import 'package:sunat_cpe_core/sunat_cpe_core.dart';

void main() {
  final invoice = InvoiceDocument(
    id: const DocumentId(
      issuerRuc: '20100066603',
      type: CpeDocumentType.factura,
      series: 'F001',
      number: 1,
    ),
    issueDate: DateTime(2026, 11, 4),
    issuer: const CompanyParty(
      ruc: '20100066603',
      legalName: 'EMPRESA DEMO S.A.C.',
      address: Address(ubigeo: '150101', streetLine: 'AV. CENTRAL 123'),
    ),
    customer: const CustomerParty(
      documentType: IdentityDocumentType.ruc,
      documentNumber: '20600055519',
      legalName: 'CLIENTE CORPORATIVO S.A.C.',
    ),
    currency: CurrencyCode.pen,
    items: [
      CpeLineItem(
        lineNumber: 1,
        description: 'SERVICIO DE CONSULTORIA',
        quantity: Decimal.one,
        unitValue: Decimal.fromInt(100),
        unitPrice: Decimal.fromInt(118),
        lineExtensionAmount: Decimal.fromInt(100),
        taxableBaseAmount: Decimal.fromInt(100),
        igvAffectation: IgvAffectationType.gravadoOperacionOnerosa,
        igvPercentage: Decimal.fromInt(18),
        igvAmount: Decimal.fromInt(18),
        totalLineTaxAmount: Decimal.fromInt(18),
        totalLineAmount: Decimal.fromInt(118),
      ),
    ],
    totals: MonetaryTotals(
      totalGravadas: Decimal.fromInt(100),
      totalIgv: Decimal.fromInt(18),
      totalValorVenta: Decimal.fromInt(100),
      totalImpuestos: Decimal.fromInt(18),
      totalPrecioVenta: Decimal.fromInt(118),
      importeTotalPagar: Decimal.fromInt(118),
    ),
  );

  final validator = CpeMathValidator();
  final validationResult = validator.validate(invoice);
  if (validationResult.isSuccess) {
    final xml = const UblXmlBuilder().buildUnsignedXml(invoice);
    print(
      'Generated UBL 2.1 XML (${xml.length} chars) for ${invoice.id.ublId}',
    );
  }
}
