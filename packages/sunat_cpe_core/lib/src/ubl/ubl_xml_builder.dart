import 'package:decimal/decimal.dart';
import 'package:xml/xml.dart';

import '../catalogs/sunat_catalogs.dart';
import '../entities/cpe_entities.dart';

/// Generates official SUNAT UBL 2.1 and UBL 2.0 XML documents ready for XAdES-BES signing.
final class UblXmlBuilder {
  const UblXmlBuilder();

  static const String _nsCac =
      'urn:oasis:names:specification:ubl:schema:xsd:CommonAggregateComponents-2';
  static const String _nsCbc =
      'urn:oasis:names:specification:ubl:schema:xsd:CommonBasicComponents-2';
  static const String _nsDs = 'http://www.w3.org/2000/09/xmldsig#';
  static const String _nsExt =
      'urn:oasis:names:specification:ubl:schema:xsd:CommonExtensionComponents-2';
  static const String _nsSac =
      'urn:sunat:names:specification:ubl:peru:schema:xsd:SunatAggregateComponents-1';

  /// Builds the unsigned UBL XML string with an empty `<ext:ExtensionContent/>` placeholder.
  String buildUnsignedXml(CpeDocument document) {
    final builder = XmlBuilder();
    builder.processing('xml', 'version="1.0" encoding="UTF-8" standalone="no"');

    switch (document) {
      case InvoiceDocument():
      case PurchaseSettlementDocument():
        _buildInvoiceOrSettlement(builder, document as SalesCpeDocument);
      case CreditNoteDocument():
        _buildCreditNote(builder, document);
      case DebitNoteDocument():
        _buildDebitNote(builder, document);
      case DailySummaryDocument():
        _buildDailySummary(builder, document);
      case VoidedDocument():
        _buildVoidedDocument(builder, document);
      case DespatchAdviceDocument():
        _buildDespatchAdvice(builder, document);
      case RetentionDocument():
        _buildRetention(builder, document);
      case PerceptionDocument():
        _buildPerception(builder, document);
    }

    return builder.buildDocument().toXmlString(pretty: false);
  }

  void _buildInvoiceOrSettlement(XmlBuilder b, SalesCpeDocument doc) {
    final rootNs = 'urn:oasis:names:specification:ubl:schema:xsd:Invoice-2';
    b.element(
      'Invoice',
      namespaceUris: {
        null: rootNs,
        'cac': _nsCac,
        'cbc': _nsCbc,
        'ds': _nsDs,
        'ext': _nsExt,
      },
      nest: () {
        _buildUblExtensionsPlaceholder(b);
        b.element('cbc:UBLVersionID', nest: '2.1');
        b.element(
          'cbc:CustomizationID',
          attributes: {'schemeAgencyName': 'PE:SUNAT'},
          nest: '2.0',
        );

        final opType = doc is InvoiceDocument ? doc.operationType.code : '0101';
        b.element(
          'cbc:ProfileID',
          attributes: {
            'schemeName': 'Tipo de Operacion',
            'schemeAgencyName': 'PE:SUNAT',
            'schemeURI': 'urn:pe:gob:sunat:cpe:see:gem:catalogos:catalogo51',
          },
          nest: opType,
        );

        b.element('cbc:ID', nest: doc.id.ublId);
        b.element('cbc:IssueDate', nest: _formatDate(doc.issueDate));
        b.element('cbc:IssueTime', nest: doc.issueTime ?? '00:00:00');
        if (doc.dueDate != null) {
          b.element('cbc:DueDate', nest: _formatDate(doc.dueDate!));
        }

        b.element(
          'cbc:InvoiceTypeCode',
          attributes: {
            'listAgencyName': 'PE:SUNAT',
            'listName': 'Tipo de Documento',
            'listURI': 'urn:pe:gob:sunat:cpe:see:gem:catalogos:catalogo01',
            'listID': opType,
          },
          nest: doc.id.type.code,
        );

        if (doc.totals.amountInWords != null) {
          b.element(
            'cbc:Note',
            attributes: {'languageLocaleID': '1000'},
            nest: doc.totals.amountInWords,
          );
        }

        b.element(
          'cbc:DocumentCurrencyCode',
          attributes: {
            'listID': 'ISO 4217 Alpha',
            'listName': 'Currency',
            'listAgencyName': 'United Nations Economic Commission for Europe',
          },
          nest: doc.currency.code,
        );

        b.element('cbc:LineCountNumeric', nest: doc.items.length.toString());

        if (doc.purchaseOrder != null && doc.purchaseOrder!.isNotEmpty) {
          b.element(
            'cac:OrderReference',
            nest: () => b.element('cbc:ID', nest: doc.purchaseOrder),
          );
        }

        for (final guide in doc.relatedGuides) {
          b.element(
            'cac:DespatchDocumentReference',
            nest: () {
              b.element('cbc:ID', nest: guide.formattedId);
              b.element('cbc:DocumentTypeCode', nest: guide.documentType.code);
            },
          );
        }

        _buildSignatureReference(b, doc.issuer);
        _buildSupplierParty(b, doc.issuer);
        _buildCustomerParty(b, doc.customer);

        if (doc is InvoiceDocument) {
          _buildPaymentTerms(b, doc.paymentTerms, doc.currency);
        }

        _buildTaxTotals(b, doc.totals, doc.currency);
        _buildLegalMonetaryTotal(b, doc.totals, doc.currency);

        for (final item in doc.items) {
          _buildLineItem(
            b,
            item,
            doc.currency,
            lineTag: 'cac:InvoiceLine',
            qtyTag: 'cbc:InvoicedQuantity',
          );
        }
      },
    );
  }

  void _buildCreditNote(XmlBuilder b, CreditNoteDocument doc) {
    final rootNs = 'urn:oasis:names:specification:ubl:schema:xsd:CreditNote-2';
    b.element(
      'CreditNote',
      namespaceUris: {
        null: rootNs,
        'cac': _nsCac,
        'cbc': _nsCbc,
        'ds': _nsDs,
        'ext': _nsExt,
      },
      nest: () {
        _buildUblExtensionsPlaceholder(b);
        b.element('cbc:UBLVersionID', nest: '2.1');
        b.element('cbc:CustomizationID', nest: '2.0');
        b.element('cbc:ID', nest: doc.id.ublId);
        b.element('cbc:IssueDate', nest: _formatDate(doc.issueDate));
        b.element('cbc:IssueTime', nest: doc.issueTime ?? '00:00:00');
        b.element('cbc:DocumentCurrencyCode', nest: doc.currency.code);

        b.element(
          'cac:DiscrepancyResponse',
          nest: () {
            b.element(
              'cbc:ReferenceID',
              nest: doc.affectedDocument.formattedId,
            );
            b.element('cbc:ResponseCode', nest: doc.reasonCode.code);
            b.element('cbc:Description', nest: doc.reasonDescription);
          },
        );

        b.element(
          'cac:BillingReference',
          nest: () {
            b.element(
              'cac:InvoiceDocumentReference',
              nest: () {
                b.element('cbc:ID', nest: doc.affectedDocument.formattedId);
                b.element(
                  'cbc:DocumentTypeCode',
                  nest: doc.affectedDocument.documentType.code,
                );
              },
            );
          },
        );

        _buildSignatureReference(b, doc.issuer);
        _buildSupplierParty(b, doc.issuer);
        _buildCustomerParty(b, doc.customer);

        if (doc.updatedPaymentTerms != null) {
          _buildPaymentTerms(b, doc.updatedPaymentTerms!, doc.currency);
        }

        _buildTaxTotals(b, doc.totals, doc.currency);
        _buildLegalMonetaryTotal(b, doc.totals, doc.currency);

        for (final item in doc.items) {
          _buildLineItem(
            b,
            item,
            doc.currency,
            lineTag: 'cac:CreditNoteLine',
            qtyTag: 'cbc:CreditedQuantity',
          );
        }
      },
    );
  }

  void _buildDebitNote(XmlBuilder b, DebitNoteDocument doc) {
    final rootNs = 'urn:oasis:names:specification:ubl:schema:xsd:DebitNote-2';
    b.element(
      'DebitNote',
      namespaceUris: {
        null: rootNs,
        'cac': _nsCac,
        'cbc': _nsCbc,
        'ds': _nsDs,
        'ext': _nsExt,
      },
      nest: () {
        _buildUblExtensionsPlaceholder(b);
        b.element('cbc:UBLVersionID', nest: '2.1');
        b.element('cbc:CustomizationID', nest: '2.0');
        b.element('cbc:ID', nest: doc.id.ublId);
        b.element('cbc:IssueDate', nest: _formatDate(doc.issueDate));
        b.element('cbc:IssueTime', nest: doc.issueTime ?? '00:00:00');
        b.element('cbc:DocumentCurrencyCode', nest: doc.currency.code);

        b.element(
          'cac:DiscrepancyResponse',
          nest: () {
            b.element(
              'cbc:ReferenceID',
              nest: doc.affectedDocument.formattedId,
            );
            b.element('cbc:ResponseCode', nest: doc.reasonCode.code);
            b.element('cbc:Description', nest: doc.reasonDescription);
          },
        );

        b.element(
          'cac:BillingReference',
          nest: () {
            b.element(
              'cac:InvoiceDocumentReference',
              nest: () {
                b.element('cbc:ID', nest: doc.affectedDocument.formattedId);
                b.element(
                  'cbc:DocumentTypeCode',
                  nest: doc.affectedDocument.documentType.code,
                );
              },
            );
          },
        );

        _buildSignatureReference(b, doc.issuer);
        _buildSupplierParty(b, doc.issuer);
        _buildCustomerParty(b, doc.customer);
        _buildTaxTotals(b, doc.totals, doc.currency);
        _buildLegalMonetaryTotal(
          b,
          doc.totals,
          doc.currency,
          tagName: 'cac:RequestedMonetaryTotal',
        );

        for (final item in doc.items) {
          _buildLineItem(
            b,
            item,
            doc.currency,
            lineTag: 'cac:DebitNoteLine',
            qtyTag: 'cbc:DebitedQuantity',
          );
        }
      },
    );
  }

  void _buildDailySummary(XmlBuilder b, DailySummaryDocument doc) {
    final rootNs =
        'urn:sunat:names:specification:ubl:peru:schema:xsd:SummaryDocuments-1';
    b.element(
      'SummaryDocuments',
      namespaceUris: {
        null: rootNs,
        'cac': _nsCac,
        'cbc': _nsCbc,
        'ds': _nsDs,
        'ext': _nsExt,
        'sac': _nsSac,
      },
      nest: () {
        _buildUblExtensionsPlaceholder(b);
        b.element('cbc:UBLVersionID', nest: '2.0');
        b.element('cbc:CustomizationID', nest: '1.1');
        b.element('cbc:ID', nest: doc.id.ublId);
        b.element('cbc:ReferenceDate', nest: _formatDate(doc.referenceDate));
        b.element('cbc:IssueDate', nest: _formatDate(doc.issueDate));
        _buildSignatureReference(b, doc.issuer);
        _buildSupplierParty(b, doc.issuer);

        for (final line in doc.lines) {
          b.element(
            'sac:SummaryDocumentsLine',
            nest: () {
              b.element('cbc:LineID', nest: line.lineNumber.toString());
              b.element('cbc:DocumentTypeCode', nest: line.documentType.code);
              b.element('cbc:ID', nest: '${line.series}-${line.number}');
              if (line.customerDocumentType != null &&
                  line.customerDocumentNumber != null) {
                b.element(
                  'cac:AccountingCustomerParty',
                  nest: () {
                    b.element(
                      'cbc:CustomerAssignedAccountID',
                      nest: line.customerDocumentNumber,
                    );
                    b.element(
                      'cbc:AdditionalAccountID',
                      nest: line.customerDocumentType!.code,
                    );
                  },
                );
              }
              b.element(
                'cac:Status',
                nest: () =>
                    b.element('cbc:ConditionCode', nest: line.status.code),
              );
              b.element(
                'sac:TotalAmount',
                attributes: {'currencyID': line.currency.code},
                nest: _fmt2(line.totalSaleAmount),
              );
            },
          );
        }
      },
    );
  }

  void _buildVoidedDocument(XmlBuilder b, VoidedDocument doc) {
    final rootNs =
        'urn:sunat:names:specification:ubl:peru:schema:xsd:VoidedDocuments-1';
    b.element(
      'VoidedDocuments',
      namespaceUris: {
        null: rootNs,
        'cac': _nsCac,
        'cbc': _nsCbc,
        'ds': _nsDs,
        'ext': _nsExt,
        'sac': _nsSac,
      },
      nest: () {
        _buildUblExtensionsPlaceholder(b);
        b.element('cbc:UBLVersionID', nest: '2.0');
        b.element('cbc:CustomizationID', nest: '1.0');
        b.element('cbc:ID', nest: doc.id.ublId);
        b.element('cbc:ReferenceDate', nest: _formatDate(doc.referenceDate));
        b.element('cbc:IssueDate', nest: _formatDate(doc.issueDate));
        _buildSignatureReference(b, doc.issuer);
        _buildSupplierParty(b, doc.issuer);

        for (final line in doc.lines) {
          b.element(
            'sac:VoidedDocumentsLine',
            nest: () {
              b.element('cbc:LineID', nest: line.lineNumber.toString());
              b.element('cbc:DocumentTypeCode', nest: line.documentType.code);
              b.element('sac:DocumentSerialID', nest: line.series);
              b.element('sac:DocumentNumberID', nest: line.number.toString());
              b.element('sac:VoidReasonDescription', nest: line.voidReason);
            },
          );
        }
      },
    );
  }

  void _buildDespatchAdvice(XmlBuilder b, DespatchAdviceDocument doc) {
    final rootNs =
        'urn:oasis:names:specification:ubl:schema:xsd:DespatchAdvice-2';
    b.element(
      'DespatchAdvice',
      namespaceUris: {
        null: rootNs,
        'cac': _nsCac,
        'cbc': _nsCbc,
        'ds': _nsDs,
        'ext': _nsExt,
      },
      nest: () {
        _buildUblExtensionsPlaceholder(b);
        b.element('cbc:UBLVersionID', nest: '2.1');
        b.element('cbc:CustomizationID', nest: '2.0');
        b.element('cbc:ID', nest: doc.id.ublId);
        b.element('cbc:IssueDate', nest: _formatDate(doc.issueDate));
        b.element('cbc:IssueTime', nest: doc.issueTime ?? '00:00:00');
        b.element('cbc:DespatchAdviceTypeCode', nest: doc.id.type.code);
        _buildSignatureReference(b, doc.issuer);

        b.element(
          'cac:DespatchSupplierParty',
          nest: () => _buildPartyNode(
            b,
            IdentityDocumentType.ruc.code,
            doc.issuer.ruc,
            doc.issuer.legalName,
            doc.issuer.address,
          ),
        );

        b.element(
          'cac:DeliveryCustomerParty',
          nest: () => _buildPartyNode(
            b,
            doc.recipient.documentType.code,
            doc.recipient.documentNumber,
            doc.recipient.legalName,
            doc.recipient.address,
          ),
        );

        b.element(
          'cac:Shipment',
          nest: () {
            b.element('cbc:ID', nest: 'SUNAT_Envio');
            b.element('cbc:HandlingCode', nest: doc.transferReason.code);
            if (doc.transferDescription != null) {
              b.element(
                'cbc:HandlingInstructions',
                nest: doc.transferDescription,
              );
            }
            b.element(
              'cbc:GrossWeightMeasure',
              attributes: {'unitCode': doc.weightUnitCode},
              nest: doc.grossWeight.toStringAsFixed(3),
            );
            b.element(
              'cac:ShipmentStage',
              nest: () {
                b.element(
                  'cbc:TransportModeCode',
                  nest: doc.transportMode.code,
                );
                b.element(
                  'cac:TransitPeriod',
                  nest: () => b.element(
                    'cbc:StartDate',
                    nest: _formatDate(doc.transferStartDate),
                  ),
                );
              },
            );
            b.element(
              'cac:Delivery',
              nest: () {
                b.element(
                  'cac:DeliveryAddress',
                  nest: () {
                    if (doc.deliveryAddress.ubigeo != null) {
                      b.element('cbc:ID', nest: doc.deliveryAddress.ubigeo);
                    }
                    b.element(
                      'cac:AddressLine',
                      nest: () => b.element(
                        'cbc:Line',
                        nest: doc.deliveryAddress.streetLine,
                      ),
                    );
                  },
                );
                b.element(
                  'cac:Despatch',
                  nest: () {
                    b.element(
                      'cac:DespatchAddress',
                      nest: () {
                        if (doc.originAddress.ubigeo != null) {
                          b.element('cbc:ID', nest: doc.originAddress.ubigeo);
                        }
                        b.element(
                          'cac:AddressLine',
                          nest: () => b.element(
                            'cbc:Line',
                            nest: doc.originAddress.streetLine,
                          ),
                        );
                      },
                    );
                  },
                );
              },
            );
          },
        );

        for (final item in doc.items) {
          b.element(
            'cac:DespatchLine',
            nest: () {
              b.element('cbc:ID', nest: item.lineNumber.toString());
              b.element(
                'cbc:DeliveredQuantity',
                attributes: {'unitCode': item.unitCode},
                nest: item.quantity.toString(),
              );
              b.element(
                'cac:OrderLineReference',
                nest: () =>
                    b.element('cbc:LineID', nest: item.lineNumber.toString()),
              );
              b.element(
                'cac:Item',
                nest: () {
                  b.element('cbc:Description', nest: item.description);
                  if (item.internalCode != null) {
                    b.element(
                      'cac:SellersItemIdentification',
                      nest: () => b.element('cbc:ID', nest: item.internalCode),
                    );
                  }
                },
              );
            },
          );
        }
      },
    );
  }

  void _buildRetention(XmlBuilder b, RetentionDocument doc) {
    final rootNs =
        'urn:sunat:names:specification:ubl:peru:schema:xsd:Retention-1';
    b.element(
      'Retention',
      namespaceUris: {
        null: rootNs,
        'cac': _nsCac,
        'cbc': _nsCbc,
        'ds': _nsDs,
        'ext': _nsExt,
        'sac': _nsSac,
      },
      nest: () {
        _buildUblExtensionsPlaceholder(b);
        b.element('cbc:UBLVersionID', nest: '2.0');
        b.element('cbc:CustomizationID', nest: '1.0');
        _buildSignatureReference(b, doc.issuer);
        b.element('cbc:ID', nest: doc.id.ublId);
        b.element('cbc:IssueDate', nest: _formatDate(doc.issueDate));
        _buildSupplierParty(b, doc.issuer, wrapperTag: 'cac:AgentParty');
        _buildCustomerParty(b, doc.partner, wrapperTag: 'cac:ReceiverParty');
        b.element('sac:SUNATRetentionSystemCode', nest: doc.regime.code);
        b.element('sac:SUNATRetentionPercent', nest: _fmt2(doc.ratePercentage));
        b.element(
          'cbc:TotalInvoiceAmount',
          attributes: {'currencyID': 'PEN'},
          nest: _fmt2(doc.totalAmountInPen),
        );
        b.element(
          'sac:SUNATTotalPaid',
          attributes: {'currencyID': 'PEN'},
          nest: _fmt2(doc.totalPaidOrCollectedInPen),
        );
      },
    );
  }

  void _buildPerception(XmlBuilder b, PerceptionDocument doc) {
    final rootNs =
        'urn:sunat:names:specification:ubl:peru:schema:xsd:Perception-1';
    b.element(
      'Perception',
      namespaceUris: {
        null: rootNs,
        'cac': _nsCac,
        'cbc': _nsCbc,
        'ds': _nsDs,
        'ext': _nsExt,
        'sac': _nsSac,
      },
      nest: () {
        _buildUblExtensionsPlaceholder(b);
        b.element('cbc:UBLVersionID', nest: '2.0');
        b.element('cbc:CustomizationID', nest: '1.0');
        _buildSignatureReference(b, doc.issuer);
        b.element('cbc:ID', nest: doc.id.ublId);
        b.element('cbc:IssueDate', nest: _formatDate(doc.issueDate));
        _buildSupplierParty(b, doc.issuer, wrapperTag: 'cac:AgentParty');
        _buildCustomerParty(b, doc.partner, wrapperTag: 'cac:ReceiverParty');
        b.element('sac:SUNATPerceptionSystemCode', nest: doc.regime.code);
        b.element(
          'sac:SUNATPerceptionPercent',
          nest: _fmt2(doc.ratePercentage),
        );
        b.element(
          'cbc:TotalInvoiceAmount',
          attributes: {'currencyID': 'PEN'},
          nest: _fmt2(doc.totalAmountInPen),
        );
        b.element(
          'sac:SUNATTotalCashed',
          attributes: {'currencyID': 'PEN'},
          nest: _fmt2(doc.totalPaidOrCollectedInPen),
        );
      },
    );
  }

  void _buildUblExtensionsPlaceholder(XmlBuilder b) {
    b.element(
      'ext:UBLExtensions',
      nest: () {
        b.element(
          'ext:UBLExtension',
          nest: () {
            b.element('ext:ExtensionContent');
          },
        );
      },
    );
  }

  void _buildSignatureReference(XmlBuilder b, CompanyParty issuer) {
    b.element(
      'cac:Signature',
      nest: () {
        b.element('cbc:ID', nest: 'IDSignSUNAT');
        b.element(
          'cac:SignatoryParty',
          nest: () {
            b.element(
              'cac:PartyIdentification',
              nest: () => b.element('cbc:ID', nest: issuer.ruc),
            );
            b.element(
              'cac:PartyName',
              nest: () => b.element('cbc:Name', nest: issuer.legalName),
            );
          },
        );
        b.element(
          'cac:DigitalSignatureAttachment',
          nest: () {
            b.element(
              'cac:ExternalReference',
              nest: () => b.element('cbc:URI', nest: '#SignSUNAT'),
            );
          },
        );
      },
    );
  }

  void _buildSupplierParty(
    XmlBuilder b,
    CompanyParty issuer, {
    String wrapperTag = 'cac:AccountingSupplierParty',
  }) {
    b.element(
      wrapperTag,
      nest: () => _buildPartyNode(
        b,
        IdentityDocumentType.ruc.code,
        issuer.ruc,
        issuer.legalName,
        issuer.address,
        tradeName: issuer.tradeName,
      ),
    );
  }

  void _buildCustomerParty(
    XmlBuilder b,
    CustomerParty customer, {
    String wrapperTag = 'cac:AccountingCustomerParty',
  }) {
    b.element(
      wrapperTag,
      nest: () => _buildPartyNode(
        b,
        customer.documentType.code,
        customer.documentNumber,
        customer.legalName,
        customer.address,
      ),
    );
  }

  void _buildPartyNode(
    XmlBuilder b,
    String docTypeCode,
    String docNumber,
    String legalName,
    Address? address, {
    String? tradeName,
  }) {
    b.element(
      'cac:Party',
      nest: () {
        b.element(
          'cac:PartyIdentification',
          nest: () {
            b.element(
              'cbc:ID',
              attributes: {
                'schemeID': docTypeCode,
                'schemeName': 'Documento de Identidad',
                'schemeAgencyName': 'PE:SUNAT',
                'schemeURI':
                    'urn:pe:gob:sunat:cpe:see:gem:catalogos:catalogo06',
              },
              nest: docNumber,
            );
          },
        );
        if (tradeName != null && tradeName.isNotEmpty) {
          b.element(
            'cac:PartyName',
            nest: () => b.element('cbc:Name', nest: tradeName),
          );
        }
        b.element(
          'cac:PartyLegalEntity',
          nest: () {
            b.element('cbc:RegistrationName', nest: legalName);
            if (address != null) {
              b.element(
                'cac:RegistrationAddress',
                nest: () {
                  if (address.ubigeo != null) {
                    b.element('cbc:ID', nest: address.ubigeo);
                  }
                  b.element(
                    'cbc:AddressTypeCode',
                    nest: address.establishmentCode,
                  );
                  b.element(
                    'cac:AddressLine',
                    nest: () => b.element('cbc:Line', nest: address.streetLine),
                  );
                  b.element(
                    'cac:Country',
                    nest: () => b.element(
                      'cbc:IdentificationCode',
                      nest: address.countryCode,
                    ),
                  );
                },
              );
            }
          },
        );
      },
    );
  }

  void _buildPaymentTerms(
    XmlBuilder b,
    PaymentTerms terms,
    CurrencyCode currency,
  ) {
    switch (terms) {
      case CashPaymentTerms():
        b.element(
          'cac:PaymentTerms',
          nest: () {
            b.element('cbc:ID', nest: 'FormaPago');
            b.element('cbc:PaymentMeansID', nest: 'Contado');
          },
        );
      case CreditPaymentTerms():
        b.element(
          'cac:PaymentTerms',
          nest: () {
            b.element('cbc:ID', nest: 'FormaPago');
            b.element('cbc:PaymentMeansID', nest: 'Credito');
            b.element(
              'cbc:Amount',
              attributes: {'currencyID': currency.code},
              nest: _fmt2(terms.netPendingAmount),
            );
          },
        );
        for (final quota in terms.installments) {
          b.element(
            'cac:PaymentTerms',
            nest: () {
              b.element('cbc:ID', nest: 'FormaPago');
              b.element('cbc:PaymentMeansID', nest: quota.formattedQuotaId);
              b.element(
                'cbc:Amount',
                attributes: {'currencyID': currency.code},
                nest: _fmt2(quota.amount),
              );
              b.element('cbc:PaymentDueDate', nest: _formatDate(quota.dueDate));
            },
          );
        }
    }
  }

  void _buildTaxTotals(
    XmlBuilder b,
    MonetaryTotals totals,
    CurrencyCode currency,
  ) {
    b.element(
      'cac:TaxTotal',
      nest: () {
        b.element(
          'cbc:TaxAmount',
          attributes: {'currencyID': currency.code},
          nest: _fmt2(totals.totalImpuestos),
        );

        if (totals.totalGravadas > Decimal.zero ||
            totals.totalIgv > Decimal.zero) {
          _buildTaxSubtotal(
            b,
            currency,
            totals.totalGravadas,
            totals.totalIgv,
            TaxCategoryCode.s,
          );
        }
        if (totals.totalExoneradas > Decimal.zero) {
          _buildTaxSubtotal(
            b,
            currency,
            totals.totalExoneradas,
            Decimal.zero,
            TaxCategoryCode.e,
          );
        }
        if (totals.totalInafectas > Decimal.zero) {
          _buildTaxSubtotal(
            b,
            currency,
            totals.totalInafectas,
            Decimal.zero,
            TaxCategoryCode.o,
          );
        }
        if (totals.totalGratuitas > Decimal.zero) {
          _buildTaxSubtotal(
            b,
            currency,
            totals.totalGratuitas,
            totals.totalImpuestosGratuitas,
            TaxCategoryCode.z,
          );
        }
        if (totals.totalExportacion > Decimal.zero) {
          _buildTaxSubtotal(
            b,
            currency,
            totals.totalExportacion,
            Decimal.zero,
            TaxCategoryCode.g,
          );
        }
        if (totals.totalIcbper > Decimal.zero) {
          _buildTaxSubtotal(
            b,
            currency,
            null,
            totals.totalIcbper,
            TaxCategoryCode.icbper,
          );
        }
      },
    );
  }

  void _buildTaxSubtotal(
    XmlBuilder b,
    CurrencyCode currency,
    Decimal? taxableAmount,
    Decimal taxAmount,
    TaxCategoryCode cat,
  ) {
    b.element(
      'cac:TaxSubtotal',
      nest: () {
        if (taxableAmount != null) {
          b.element(
            'cbc:TaxableAmount',
            attributes: {'currencyID': currency.code},
            nest: _fmt2(taxableAmount),
          );
        }
        b.element(
          'cbc:TaxAmount',
          attributes: {'currencyID': currency.code},
          nest: _fmt2(taxAmount),
        );
        b.element(
          'cac:TaxCategory',
          nest: () {
            b.element('cbc:ID', nest: cat.categoryId);
            b.element(
              'cac:TaxScheme',
              nest: () {
                b.element('cbc:ID', nest: cat.schemeId);
                b.element('cbc:Name', nest: cat.schemeName);
                b.element('cbc:TaxTypeCode', nest: cat.taxTypeCode);
              },
            );
          },
        );
      },
    );
  }

  void _buildLegalMonetaryTotal(
    XmlBuilder b,
    MonetaryTotals totals,
    CurrencyCode currency, {
    String tagName = 'cac:LegalMonetaryTotal',
  }) {
    b.element(
      tagName,
      nest: () {
        b.element(
          'cbc:LineExtensionAmount',
          attributes: {'currencyID': currency.code},
          nest: _fmt2(totals.totalValorVenta),
        );
        b.element(
          'cbc:TaxInclusiveAmount',
          attributes: {'currencyID': currency.code},
          nest: _fmt2(totals.totalPrecioVenta),
        );
        if (totals.descuentoGlobalNoAfectaBase > Decimal.zero) {
          b.element(
            'cbc:AllowanceTotalAmount',
            attributes: {'currencyID': currency.code},
            nest: _fmt2(totals.descuentoGlobalNoAfectaBase),
          );
        }
        if (totals.totalOtrosCargos > Decimal.zero) {
          b.element(
            'cbc:ChargeTotalAmount',
            attributes: {'currencyID': currency.code},
            nest: _fmt2(totals.totalOtrosCargos),
          );
        }
        if (totals.totalAnticipos > Decimal.zero) {
          b.element(
            'cbc:PrepaidAmount',
            attributes: {'currencyID': currency.code},
            nest: _fmt2(totals.totalAnticipos),
          );
        }
        b.element(
          'cbc:PayableAmount',
          attributes: {'currencyID': currency.code},
          nest: _fmt2(totals.importeTotalPagar),
        );
      },
    );
  }

  void _buildLineItem(
    XmlBuilder b,
    CpeLineItem item,
    CurrencyCode currency, {
    required String lineTag,
    required String qtyTag,
  }) {
    b.element(
      lineTag,
      nest: () {
        b.element('cbc:ID', nest: item.lineNumber.toString());
        b.element(
          qtyTag,
          attributes: {'unitCode': item.unitCode},
          nest: item.quantity.toString(),
        );
        b.element(
          'cbc:LineExtensionAmount',
          attributes: {'currencyID': currency.code},
          nest: _fmt2(item.lineExtensionAmount),
        );

        b.element(
          'cac:PricingReference',
          nest: () {
            b.element(
              'cac:AlternativeConditionPrice',
              nest: () {
                b.element(
                  'cbc:PriceAmount',
                  attributes: {'currencyID': currency.code},
                  nest: item.unitPrice.toString(),
                );
                b.element(
                  'cbc:PriceTypeCode',
                  nest: item.isReferencePrice ? '02' : '01',
                );
              },
            );
          },
        );

        b.element(
          'cac:TaxTotal',
          nest: () {
            b.element(
              'cbc:TaxAmount',
              attributes: {'currencyID': currency.code},
              nest: _fmt2(item.totalLineTaxAmount),
            );
            b.element(
              'cac:TaxSubtotal',
              nest: () {
                b.element(
                  'cbc:TaxableAmount',
                  attributes: {'currencyID': currency.code},
                  nest: _fmt2(item.taxableBaseAmount),
                );
                b.element(
                  'cbc:TaxAmount',
                  attributes: {'currencyID': currency.code},
                  nest: _fmt2(item.igvAmount),
                );
                b.element(
                  'cac:TaxCategory',
                  nest: () {
                    b.element(
                      'cbc:ID',
                      nest: item.igvAffectation.taxCategory.categoryId,
                    );
                    b.element('cbc:Percent', nest: _fmt2(item.igvPercentage));
                    b.element(
                      'cbc:TaxExemptionReasonCode',
                      nest: item.igvAffectation.code,
                    );
                    b.element(
                      'cac:TaxScheme',
                      nest: () {
                        b.element(
                          'cbc:ID',
                          nest: item.igvAffectation.taxCategory.schemeId,
                        );
                        b.element(
                          'cbc:Name',
                          nest: item.igvAffectation.taxCategory.schemeName,
                        );
                        b.element(
                          'cbc:TaxTypeCode',
                          nest: item.igvAffectation.taxCategory.taxTypeCode,
                        );
                      },
                    );
                  },
                );
              },
            );
          },
        );

        b.element(
          'cac:Item',
          nest: () {
            b.element('cbc:Description', nest: item.description);
            if (item.internalCode != null) {
              b.element(
                'cac:SellersItemIdentification',
                nest: () => b.element('cbc:ID', nest: item.internalCode),
              );
            }
            if (item.sunatProductCode != null) {
              b.element(
                'cac:CommodityClassification',
                nest: () => b.element(
                  'cbc:ItemClassificationCode',
                  nest: item.sunatProductCode,
                ),
              );
            }
          },
        );

        b.element(
          'cac:Price',
          nest: () {
            b.element(
              'cbc:PriceAmount',
              attributes: {'currencyID': currency.code},
              nest: item.unitValue.toString(),
            );
          },
        );
      },
    );
  }

  static String _formatDate(DateTime date) {
    final y = date.year.toString().padLeft(4, '0');
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  static String _fmt2(Decimal value) => value.toStringAsFixed(2);
}
