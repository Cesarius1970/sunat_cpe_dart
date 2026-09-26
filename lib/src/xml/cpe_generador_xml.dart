// Copyright (c) 2026, César A Vergara Buenaventura <cesarvergarab@gmail.com>.
// Todos los derechos reservados. Uso sujeto a la licencia en el archivo LICENSE.

import 'package:decimal/decimal.dart';
import 'package:xml/xml.dart';

import '../modelos/cpe_boleta.dart';
import '../modelos/cpe_comprobante.dart';
import '../modelos/cpe_comunicacion_baja.dart';
import '../modelos/cpe_factura.dart';
import '../modelos/cpe_guia_remision.dart';
import '../modelos/cpe_item.dart';
import '../modelos/cpe_nota_credito.dart';
import '../modelos/cpe_nota_debito.dart';
import '../modelos/cpe_resumen_diario.dart';

/// Generador de documentos XML UBL 2.1 y UBL 2.0 conformes con los estándares de SUNAT.
class CPE_GeneradorXml {
  const CPE_GeneradorXml();

  /// Genera el XML UBL 2.1 para Factura Electrónica (01).
  String generarFactura(CPE_Factura factura) {
    return _generarInvoice(factura);
  }

  /// Genera el XML UBL 2.1 para Boleta de Venta Electrónica (03).
  String generarBoleta(CPE_Boleta boleta) {
    return _generarInvoice(boleta);
  }

  /// Genera el XML UBL 2.1 para Nota de Crédito (07).
  String generarNotaCredito(CPE_NotaCredito nota) {
    final builder = XmlBuilder();
    builder.processing('xml', 'version="1.0" encoding="utf-8"');
    builder.element(
      'CreditNote',
      nest: () {
        builder.attribute(
          'xmlns',
          'urn:oasis:names:specification:ubl:schema:xsd:CreditNote-2',
        );
        builder.attribute(
          'xmlns:cac',
          'urn:oasis:names:specification:ubl:schema:xsd:CommonAggregateComponents-2',
        );
        builder.attribute(
          'xmlns:cbc',
          'urn:oasis:names:specification:ubl:schema:xsd:CommonBasicComponents-2',
        );
        builder.attribute('xmlns:ds', 'http://www.w3.org/2000/09/xmldsig#');
        builder.attribute(
          'xmlns:ext',
          'urn:oasis:names:specification:ubl:schema:xsd:CommonExtensionComponents-2',
        );

        _construirExtensionFirma(builder);

        builder.element('cbc:UBLVersionID', nest: '2.1');
        builder.element('cbc:CustomizationID', nest: '2.0');
        builder.element('cbc:ID', nest: nota.identificadorComprobante);
        builder.element('cbc:IssueDate', nest: nota.fechaEmisionFormatoUbl);
        builder.element(
          'cbc:DocumentCurrencyCode',
          nest: nota.moneda.codigoIso,
        );

        // DiscrepancyResponse (Catálogo 09)
        builder.element(
          'cac:DiscrepancyResponse',
          nest: () {
            builder.element(
              'cbc:ReferenceID',
              nest: nota.numeroDocumentoAfectado,
            );
            builder.element(
              'cbc:ResponseCode',
              nest: nota.tipoNotaCredito.codigo,
            );
            builder.element('cbc:Description', nest: nota.sustentoMotivo);
          },
        );

        // BillingReference
        builder.element(
          'cac:BillingReference',
          nest: () {
            builder.element(
              'cac:InvoiceDocumentReference',
              nest: () {
                builder.element('cbc:ID', nest: nota.numeroDocumentoAfectado);
                builder.element(
                  'cbc:DocumentTypeCode',
                  nest: nota.tipoDocumentoAfectado.codigo,
                );
              },
            );
          },
        );

        _construirFirmaMetadata(builder, nota);
        _construirEmisor(builder, nota);
        _construirReceptor(builder, nota);
        _construirTaxTotal(builder, nota);
        _construirLegalMonetaryTotal(builder, nota);

        // CreditNoteLines
        for (final item in nota.items) {
          builder.element(
            'cac:CreditNoteLine',
            nest: () {
              builder.element('cbc:ID', nest: item.numeroLinea.toString());
              builder.element(
                'cbc:CreditedQuantity',
                nest: () {
                  builder.attribute('unitCode', item.unidadMedida);
                  builder.text(item.cantidad.toString());
                },
              );
              builder.element(
                'cbc:LineExtensionAmount',
                nest: () {
                  builder.attribute('currencyID', nota.moneda.codigoIso);
                  builder.text(item.valorVenta.aFormatoUbl());
                },
              );
              _construirItemLinea(builder, item, nota.moneda.codigoIso);
            },
          );
        }
      },
    );

    return builder.buildDocument().toXmlString(pretty: true);
  }

  /// Genera el XML UBL 2.1 para Nota de Débito (08).
  String generarNotaDebito(CPE_NotaDebito nota) {
    final builder = XmlBuilder();
    builder.processing('xml', 'version="1.0" encoding="utf-8"');
    builder.element(
      'DebitNote',
      nest: () {
        builder.attribute(
          'xmlns',
          'urn:oasis:names:specification:ubl:schema:xsd:DebitNote-2',
        );
        builder.attribute(
          'xmlns:cac',
          'urn:oasis:names:specification:ubl:schema:xsd:CommonAggregateComponents-2',
        );
        builder.attribute(
          'xmlns:cbc',
          'urn:oasis:names:specification:ubl:schema:xsd:CommonBasicComponents-2',
        );
        builder.attribute('xmlns:ds', 'http://www.w3.org/2000/09/xmldsig#');
        builder.attribute(
          'xmlns:ext',
          'urn:oasis:names:specification:ubl:schema:xsd:CommonExtensionComponents-2',
        );

        _construirExtensionFirma(builder);

        builder.element('cbc:UBLVersionID', nest: '2.1');
        builder.element('cbc:CustomizationID', nest: '2.0');
        builder.element('cbc:ID', nest: nota.identificadorComprobante);
        builder.element('cbc:IssueDate', nest: nota.fechaEmisionFormatoUbl);
        builder.element(
          'cbc:DocumentCurrencyCode',
          nest: nota.moneda.codigoIso,
        );

        builder.element(
          'cac:DiscrepancyResponse',
          nest: () {
            builder.element(
              'cbc:ReferenceID',
              nest: nota.numeroDocumentoAfectado,
            );
            builder.element(
              'cbc:ResponseCode',
              nest: nota.tipoNotaDebito.codigo,
            );
            builder.element('cbc:Description', nest: nota.sustentoMotivo);
          },
        );

        builder.element(
          'cac:BillingReference',
          nest: () {
            builder.element(
              'cac:InvoiceDocumentReference',
              nest: () {
                builder.element('cbc:ID', nest: nota.numeroDocumentoAfectado);
                builder.element(
                  'cbc:DocumentTypeCode',
                  nest: nota.tipoDocumentoAfectado.codigo,
                );
              },
            );
          },
        );

        _construirFirmaMetadata(builder, nota);
        _construirEmisor(builder, nota);
        _construirReceptor(builder, nota);
        _construirTaxTotal(builder, nota);

        // RequestedMonetaryTotal
        builder.element(
          'cac:RequestedMonetaryTotal',
          nest: () {
            builder.element(
              'cbc:PayableAmount',
              nest: () {
                builder.attribute('currencyID', nota.moneda.codigoIso);
                builder.text(nota.totales.importeTotalPagar.aFormatoUbl());
              },
            );
          },
        );

        // DebitNoteLines
        for (final item in nota.items) {
          builder.element(
            'cac:DebitNoteLine',
            nest: () {
              builder.element('cbc:ID', nest: item.numeroLinea.toString());
              builder.element(
                'cbc:DebitedQuantity',
                nest: () {
                  builder.attribute('unitCode', item.unidadMedida);
                  builder.text(item.cantidad.toString());
                },
              );
              builder.element(
                'cbc:LineExtensionAmount',
                nest: () {
                  builder.attribute('currencyID', nota.moneda.codigoIso);
                  builder.text(item.valorVenta.aFormatoUbl());
                },
              );
              _construirItemLinea(builder, item, nota.moneda.codigoIso);
            },
          );
        }
      },
    );

    return builder.buildDocument().toXmlString(pretty: true);
  }

  /// Genera el XML UBL 2.1 para Guía de Remisión Remitente (09) o Transportista (31).
  String generarGuiaRemision(CPE_GuiaRemision guia) {
    final builder = XmlBuilder();
    builder.processing('xml', 'version="1.0" encoding="utf-8"');
    builder.element(
      'DespatchAdvice',
      nest: () {
        builder.attribute(
          'xmlns',
          'urn:oasis:names:specification:ubl:schema:xsd:DespatchAdvice-2',
        );
        builder.attribute(
          'xmlns:cac',
          'urn:oasis:names:specification:ubl:schema:xsd:CommonAggregateComponents-2',
        );
        builder.attribute(
          'xmlns:cbc',
          'urn:oasis:names:specification:ubl:schema:xsd:CommonBasicComponents-2',
        );
        builder.attribute('xmlns:ds', 'http://www.w3.org/2000/09/xmldsig#');
        builder.attribute(
          'xmlns:ext',
          'urn:oasis:names:specification:ubl:schema:xsd:CommonExtensionComponents-2',
        );

        _construirExtensionFirma(builder);

        builder.element('cbc:UBLVersionID', nest: '2.1');
        builder.element('cbc:CustomizationID', nest: '2.0');
        builder.element('cbc:ID', nest: guia.identificadorComprobante);
        builder.element(
          'cbc:IssueDate',
          nest: _formatearFecha(guia.fechaEmision),
        );
        builder.element(
          'cbc:DespatchAdviceTypeCode',
          nest: guia.tipoDocumento.codigo,
        );

        // DespatchSupplierParty (Remitente)
        builder.element(
          'cac:DespatchSupplierParty',
          nest: () {
            builder.element(
              'cac:Party',
              nest: () {
                builder.element(
                  'cac:PartyIdentification',
                  nest: () {
                    builder.element(
                      'cbc:ID',
                      nest: () {
                        builder.attribute(
                          'schemeID',
                          guia.remitente.tipoDocumento.codigo,
                        );
                        builder.text(guia.remitente.numeroDocumento);
                      },
                    );
                  },
                );
                builder.element(
                  'cac:PartyLegalEntity',
                  nest: () {
                    builder.element(
                      'cbc:RegistrationName',
                      nest: guia.remitente.razonSocial,
                    );
                  },
                );
              },
            );
          },
        );

        // DeliveryCustomerParty (Destinatario)
        builder.element(
          'cac:DeliveryCustomerParty',
          nest: () {
            builder.element(
              'cac:Party',
              nest: () {
                builder.element(
                  'cac:PartyIdentification',
                  nest: () {
                    builder.element(
                      'cbc:ID',
                      nest: () {
                        builder.attribute(
                          'schemeID',
                          guia.destinatario.tipoDocumento.codigo,
                        );
                        builder.text(guia.destinatario.numeroDocumento);
                      },
                    );
                  },
                );
                builder.element(
                  'cac:PartyLegalEntity',
                  nest: () {
                    builder.element(
                      'cbc:RegistrationName',
                      nest: guia.destinatario.razonSocial,
                    );
                  },
                );
              },
            );
          },
        );

        // Shipment (Datos de transporte y traslado)
        builder.element(
          'cac:Shipment',
          nest: () {
            builder.element('cbc:ID', nest: '1');
            builder.element(
              'cbc:HandlingCode',
              nest: guia.motivoTraslado.codigo,
            );
            if (guia.descripcionMotivoTraslado != null) {
              builder.element(
                'cbc:Information',
                nest: guia.descripcionMotivoTraslado,
              );
            }
            builder.element(
              'cbc:GrossWeightMeasure',
              nest: () {
                builder.attribute('unitCode', guia.unidadMedidaPeso);
                builder.text(guia.pesoBrutoTotal.toStringAsFixed(2));
              },
            );
            if (guia.numeroBultos != null) {
              builder.element(
                'cbc:TotalTransportHandlingUnitQuantity',
                nest: guia.numeroBultos.toString(),
              );
            }

            // ShipmentStage (Modalidad)
            builder.element(
              'cac:ShipmentStage',
              nest: () {
                builder.element(
                  'cbc:TransportModeCode',
                  nest: guia.modalidadTraslado.codigo,
                );
                builder.element(
                  'cac:TransitPeriod',
                  nest: () {
                    builder.element(
                      'cbc:StartDate',
                      nest: _formatearFecha(guia.fechaInicioTraslado),
                    );
                  },
                );
                if (guia.transportista != null) {
                  builder.element(
                    'cac:CarrierParty',
                    nest: () {
                      builder.element(
                        'cac:PartyIdentification',
                        nest: () {
                          builder.element(
                            'cbc:ID',
                            nest: () {
                              builder.attribute(
                                'schemeID',
                                guia.transportista!.tipoDocumento.codigo,
                              );
                              builder.text(guia.transportista!.numeroDocumento);
                            },
                          );
                        },
                      );
                      builder.element(
                        'cac:PartyLegalEntity',
                        nest: () {
                          builder.element(
                            'cbc:RegistrationName',
                            nest: guia.transportista!.razonSocial,
                          );
                        },
                      );
                    },
                  );
                }
              },
            );

            // Delivery (Direcciones)
            builder.element(
              'cac:Delivery',
              nest: () {
                // Dirección de llegada
                builder.element(
                  'cac:DeliveryAddress',
                  nest: () {
                    if (guia.puntoLlegada.ubigeo != null) {
                      builder.element('cbc:ID', nest: guia.puntoLlegada.ubigeo);
                    }
                    builder.element(
                      'cac:AddressLine',
                      nest: () {
                        builder.element(
                          'cbc:Line',
                          nest: guia.puntoLlegada.direccion,
                        );
                      },
                    );
                  },
                );
                // Dirección de partida
                builder.element(
                  'cac:Despatch',
                  nest: () {
                    builder.element(
                      'cac:DespatchAddress',
                      nest: () {
                        if (guia.puntoPartida.ubigeo != null) {
                          builder.element(
                            'cbc:ID',
                            nest: guia.puntoPartida.ubigeo,
                          );
                        }
                        builder.element(
                          'cac:AddressLine',
                          nest: () {
                            builder.element(
                              'cbc:Line',
                              nest: guia.puntoPartida.direccion,
                            );
                          },
                        );
                      },
                    );
                  },
                );
              },
            );
          },
        );

        // DespatchLines
        for (final item in guia.items) {
          builder.element(
            'cac:DespatchLine',
            nest: () {
              builder.element('cbc:ID', nest: item.numeroLinea.toString());
              builder.element(
                'cbc:DeliveredQuantity',
                nest: () {
                  builder.attribute('unitCode', item.unidadMedida);
                  builder.text(item.cantidad.toString());
                },
              );
              builder.element(
                'cac:OrderLineReference',
                nest: () {
                  builder.element(
                    'cbc:LineID',
                    nest: item.numeroLinea.toString(),
                  );
                },
              );
              builder.element(
                'cac:Item',
                nest: () {
                  builder.element('cbc:Name', nest: item.descripcion);
                  builder.element(
                    'cac:SellersItemIdentification',
                    nest: () {
                      builder.element('cbc:ID', nest: item.codigo);
                    },
                  );
                },
              );
            },
          );
        }
      },
    );

    return builder.buildDocument().toXmlString(pretty: true);
  }

  /// Genera el XML UBL para Resumen Diario de Boletas y Notas (RC).
  String generarResumenDiario(CPE_ResumenDiario resumen) {
    final builder = XmlBuilder();
    builder.processing('xml', 'version="1.0" encoding="utf-8"');
    builder.element(
      'SummaryDocuments',
      nest: () {
        builder.attribute(
          'xmlns',
          'urn:sunat:names:specification:ubl:peru:schema:xsd:SummaryDocuments-1',
        );
        builder.attribute(
          'xmlns:cac',
          'urn:oasis:names:specification:ubl:schema:xsd:CommonAggregateComponents-2',
        );
        builder.attribute(
          'xmlns:cbc',
          'urn:oasis:names:specification:ubl:schema:xsd:CommonBasicComponents-2',
        );
        builder.attribute('xmlns:ds', 'http://www.w3.org/2000/09/xmldsig#');
        builder.attribute(
          'xmlns:ext',
          'urn:oasis:names:specification:ubl:schema:xsd:CommonExtensionComponents-2',
        );
        builder.attribute(
          'xmlns:sac',
          'urn:sunat:names:specification:ubl:peru:schema:xsd:SunatAggregateComponents-1',
        );

        _construirExtensionFirma(builder);

        builder.element('cbc:UBLVersionID', nest: '2.0');
        builder.element('cbc:CustomizationID', nest: '1.1');
        builder.element('cbc:ID', nest: resumen.identificadorResumen);
        builder.element(
          'cbc:ReferenceDate',
          nest: _formatearFecha(resumen.fechaEmisionComprobantes),
        );
        builder.element(
          'cbc:IssueDate',
          nest: _formatearFecha(resumen.fechaGeneracionResumen),
        );

        // Emisor
        builder.element(
          'cac:AccountingSupplierParty',
          nest: () {
            builder.element(
              'cbc:CustomerAssignedAccountID',
              nest: resumen.emisor.numeroDocumento,
            );
            builder.element(
              'cbc:AdditionalAccountID',
              nest: resumen.emisor.tipoDocumento.codigo,
            );
            builder.element(
              'cac:Party',
              nest: () {
                builder.element(
                  'cac:PartyLegalEntity',
                  nest: () {
                    builder.element(
                      'cbc:RegistrationName',
                      nest: resumen.emisor.razonSocial,
                    );
                  },
                );
              },
            );
          },
        );

        // Líneas del resumen
        for (final doc in resumen.comprobantes) {
          builder.element(
            'sac:SummaryDocumentsLine',
            nest: () {
              builder.element('cbc:LineID', nest: doc.numeroFila.toString());
              builder.element(
                'cbc:DocumentTypeCode',
                nest: doc.tipoDocumento.codigo,
              );
              builder.element(
                'cbc:ID',
                nest: '${doc.serie}-${doc.correlativo}',
              );
              builder.element(
                'sac:AccountingCustomerParty',
                nest: () {
                  builder.element(
                    'cbc:CustomerAssignedAccountID',
                    nest: doc.receptor.numeroDocumento,
                  );
                  builder.element(
                    'cbc:AdditionalAccountID',
                    nest: doc.receptor.tipoDocumento.codigo,
                  );
                },
              );
              builder.element(
                'sac:Status',
                nest: () {
                  builder.element(
                    'cbc:ConditionCode',
                    nest: doc.estadoItem.toString(),
                  );
                },
              );
              builder.element(
                'sac:TotalAmount',
                nest: () {
                  builder.attribute('currencyID', resumen.moneda.codigoIso);
                  builder.text(doc.totales.importeTotalPagar.aFormatoUbl());
                },
              );
            },
          );
        }
      },
    );

    return builder.buildDocument().toXmlString(pretty: true);
  }

  /// Genera el XML UBL para Comunicación de Baja (RA).
  String generarComunicacionBaja(CPE_ComunicacionBaja baja) {
    final builder = XmlBuilder();
    builder.processing('xml', 'version="1.0" encoding="utf-8"');
    builder.element(
      'VoidedDocuments',
      nest: () {
        builder.attribute(
          'xmlns',
          'urn:sunat:names:specification:ubl:peru:schema:xsd:VoidedDocuments-1',
        );
        builder.attribute(
          'xmlns:cac',
          'urn:oasis:names:specification:ubl:schema:xsd:CommonAggregateComponents-2',
        );
        builder.attribute(
          'xmlns:cbc',
          'urn:oasis:names:specification:ubl:schema:xsd:CommonBasicComponents-2',
        );
        builder.attribute('xmlns:ds', 'http://www.w3.org/2000/09/xmldsig#');
        builder.attribute(
          'xmlns:ext',
          'urn:oasis:names:specification:ubl:schema:xsd:CommonExtensionComponents-2',
        );
        builder.attribute(
          'xmlns:sac',
          'urn:sunat:names:specification:ubl:peru:schema:xsd:SunatAggregateComponents-1',
        );

        _construirExtensionFirma(builder);

        builder.element('cbc:UBLVersionID', nest: '2.0');
        builder.element('cbc:CustomizationID', nest: '1.0');
        builder.element('cbc:ID', nest: baja.identificadorBaja);
        builder.element(
          'cbc:ReferenceDate',
          nest: _formatearFecha(baja.fechaEmisionComprobantes),
        );
        builder.element(
          'cbc:IssueDate',
          nest: _formatearFecha(baja.fechaGeneracionBaja),
        );

        builder.element(
          'cac:AccountingSupplierParty',
          nest: () {
            builder.element(
              'cbc:CustomerAssignedAccountID',
              nest: baja.emisor.numeroDocumento,
            );
            builder.element(
              'cbc:AdditionalAccountID',
              nest: baja.emisor.tipoDocumento.codigo,
            );
            builder.element(
              'cac:Party',
              nest: () {
                builder.element(
                  'cac:PartyLegalEntity',
                  nest: () {
                    builder.element(
                      'cbc:RegistrationName',
                      nest: baja.emisor.razonSocial,
                    );
                  },
                );
              },
            );
          },
        );

        for (final doc in baja.comprobantesBaja) {
          builder.element(
            'sac:VoidedDocumentsLine',
            nest: () {
              builder.element('cbc:LineID', nest: doc.numeroFila.toString());
              builder.element(
                'cbc:DocumentTypeCode',
                nest: doc.tipoDocumento.codigo,
              );
              builder.element('sac:DocumentSerialID', nest: doc.serie);
              builder.element(
                'sac:DocumentNumberID',
                nest: doc.correlativo.toString(),
              );
              builder.element(
                'sac:VoidReasonDescription',
                nest: doc.motivoBaja,
              );
            },
          );
        }
      },
    );

    return builder.buildDocument().toXmlString(pretty: true);
  }

  // --- MÉTODOS PRIVADOS AUXILIARES ---

  String _generarInvoice(CPE_Comprobante comprobante) {
    final builder = XmlBuilder();
    builder.processing('xml', 'version="1.0" encoding="utf-8"');
    builder.element(
      'Invoice',
      nest: () {
        builder.attribute(
          'xmlns',
          'urn:oasis:names:specification:ubl:schema:xsd:Invoice-2',
        );
        builder.attribute(
          'xmlns:cac',
          'urn:oasis:names:specification:ubl:schema:xsd:CommonAggregateComponents-2',
        );
        builder.attribute(
          'xmlns:cbc',
          'urn:oasis:names:specification:ubl:schema:xsd:CommonBasicComponents-2',
        );
        builder.attribute('xmlns:ds', 'http://www.w3.org/2000/09/xmldsig#');
        builder.attribute(
          'xmlns:ext',
          'urn:oasis:names:specification:ubl:schema:xsd:CommonExtensionComponents-2',
        );

        _construirExtensionFirma(builder);

        builder.element('cbc:UBLVersionID', nest: '2.1');
        builder.element('cbc:CustomizationID', nest: '2.0');
        builder.element('cbc:ID', nest: comprobante.identificadorComprobante);
        builder.element(
          'cbc:IssueDate',
          nest: comprobante.fechaEmisionFormatoUbl,
        );
        if (comprobante.horaEmision != null) {
          builder.element('cbc:IssueTime', nest: comprobante.horaEmision);
        }
        builder.element(
          'cbc:InvoiceTypeCode',
          nest: () {
            builder.attribute('listAgencyName', 'PE:SUNAT');
            builder.attribute('listID', '0101');
            builder.attribute('listName', 'Tipo de Documento');
            builder.text(comprobante.tipoDocumento.codigo);
          },
        );
        builder.element(
          'cbc:DocumentCurrencyCode',
          nest: comprobante.moneda.codigoIso,
        );

        _construirFirmaMetadata(builder, comprobante);
        _construirEmisor(builder, comprobante);
        _construirReceptor(builder, comprobante);
        _construirTaxTotal(builder, comprobante);
        _construirLegalMonetaryTotal(builder, comprobante);

        // Líneas de la factura
        for (final item in comprobante.items) {
          builder.element(
            'cac:InvoiceLine',
            nest: () {
              builder.element('cbc:ID', nest: item.numeroLinea.toString());
              builder.element(
                'cbc:InvoicedQuantity',
                nest: () {
                  builder.attribute('unitCode', item.unidadMedida);
                  builder.text(item.cantidad.toString());
                },
              );
              builder.element(
                'cbc:LineExtensionAmount',
                nest: () {
                  builder.attribute('currencyID', comprobante.moneda.codigoIso);
                  builder.text(item.valorVenta.aFormatoUbl());
                },
              );

              // PricingReference (precio unitario comercial con tributos)
              builder.element(
                'cac:PricingReference',
                nest: () {
                  builder.element(
                    'cac:AlternativeConditionPrice',
                    nest: () {
                      builder.element(
                        'cbc:PriceAmount',
                        nest: () {
                          builder.attribute(
                            'currencyID',
                            comprobante.moneda.codigoIso,
                          );
                          builder.text(
                            item.precioUnitario.aFormatoPrecioUnitario(),
                          );
                        },
                      );
                      builder.element('cbc:PriceTypeCode', nest: '01');
                    },
                  );
                },
              );

              _construirTaxTotalItem(
                builder,
                item,
                comprobante.moneda.codigoIso,
              );

              // Item
              builder.element(
                'cac:Item',
                nest: () {
                  builder.element('cbc:Description', nest: item.descripcion);
                  builder.element(
                    'cac:SellersItemIdentification',
                    nest: () {
                      builder.element('cbc:ID', nest: item.codigo);
                    },
                  );
                  if (item.codigoSunat != null) {
                    builder.element(
                      'cac:CommodityClassification',
                      nest: () {
                        builder.element(
                          'cbc:ItemClassificationCode',
                          nest: item.codigoSunat,
                        );
                      },
                    );
                  }
                },
              );

              // Price (valor unitario sin impuestos)
              builder.element(
                'cac:Price',
                nest: () {
                  builder.element(
                    'cbc:PriceAmount',
                    nest: () {
                      builder.attribute(
                        'currencyID',
                        comprobante.moneda.codigoIso,
                      );
                      builder.text(
                        item.valorUnitario.aFormatoPrecioUnitario(decimales: 4),
                      );
                    },
                  );
                },
              );
            },
          );
        }
      },
    );

    return builder.buildDocument().toXmlString(pretty: true);
  }

  void _construirExtensionFirma(XmlBuilder builder) {
    builder.element(
      'ext:UBLExtensions',
      nest: () {
        builder.element(
          'ext:UBLExtension',
          nest: () {
            builder.element('ext:ExtensionContent', nest: () {});
          },
        );
      },
    );
  }

  void _construirFirmaMetadata(XmlBuilder builder, CPE_Comprobante cpe) {
    builder.element(
      'cac:Signature',
      nest: () {
        builder.element('cbc:ID', nest: 'SignatureSUNAT');
        builder.element(
          'cac:SignatoryParty',
          nest: () {
            builder.element(
              'cac:PartyIdentification',
              nest: () {
                builder.element('cbc:ID', nest: cpe.emisor.numeroDocumento);
              },
            );
            builder.element(
              'cac:PartyName',
              nest: () {
                builder.element('cbc:Name', nest: cpe.emisor.razonSocial);
              },
            );
          },
        );
        builder.element(
          'cac:DigitalSignatureAttachment',
          nest: () {
            builder.element(
              'cac:ExternalReference',
              nest: () {
                builder.element('cbc:URI', nest: '#SignatureSUNAT');
              },
            );
          },
        );
      },
    );
  }

  void _construirEmisor(XmlBuilder builder, CPE_Comprobante cpe) {
    builder.element(
      'cac:AccountingSupplierParty',
      nest: () {
        builder.element(
          'cac:Party',
          nest: () {
            builder.element(
              'cac:PartyIdentification',
              nest: () {
                builder.element(
                  'cbc:ID',
                  nest: () {
                    builder.attribute(
                      'schemeID',
                      cpe.emisor.tipoDocumento.codigo,
                    );
                    builder.text(cpe.emisor.numeroDocumento);
                  },
                );
              },
            );
            if (cpe.emisor.nombreComercial != null) {
              builder.element(
                'cac:PartyName',
                nest: () {
                  builder.element('cbc:Name', nest: cpe.emisor.nombreComercial);
                },
              );
            }
            builder.element(
              'cac:PartyLegalEntity',
              nest: () {
                builder.element(
                  'cbc:RegistrationName',
                  nest: cpe.emisor.razonSocial,
                );
                if (cpe.emisor.direccion != null) {
                  builder.element(
                    'cac:RegistrationAddress',
                    nest: () {
                      if (cpe.emisor.direccion!.ubigeo != null) {
                        builder.element(
                          'cbc:ID',
                          nest: cpe.emisor.direccion!.ubigeo,
                        );
                      }
                      builder.element(
                        'cac:AddressLine',
                        nest: () {
                          builder.element(
                            'cbc:Line',
                            nest: cpe.emisor.direccion!.direccion,
                          );
                        },
                      );
                      builder.element(
                        'cac:Country',
                        nest: () {
                          builder.element(
                            'cbc:IdentificationCode',
                            nest: cpe.emisor.direccion!.codigoPais,
                          );
                        },
                      );
                    },
                  );
                }
              },
            );
          },
        );
      },
    );
  }

  void _construirReceptor(XmlBuilder builder, CPE_Comprobante cpe) {
    builder.element(
      'cac:AccountingCustomerParty',
      nest: () {
        builder.element(
          'cac:Party',
          nest: () {
            builder.element(
              'cac:PartyIdentification',
              nest: () {
                builder.element(
                  'cbc:ID',
                  nest: () {
                    builder.attribute(
                      'schemeID',
                      cpe.receptor.tipoDocumento.codigo,
                    );
                    builder.text(cpe.receptor.numeroDocumento);
                  },
                );
              },
            );
            builder.element(
              'cac:PartyLegalEntity',
              nest: () {
                builder.element(
                  'cbc:RegistrationName',
                  nest: cpe.receptor.razonSocial,
                );
              },
            );
          },
        );
      },
    );
  }

  void _construirTaxTotal(XmlBuilder builder, CPE_Comprobante cpe) {
    builder.element(
      'cac:TaxTotal',
      nest: () {
        builder.element(
          'cbc:TaxAmount',
          nest: () {
            builder.attribute('currencyID', cpe.moneda.codigoIso);
            builder.text(cpe.totales.totalIgv.aFormatoUbl());
          },
        );

        // Subtotal de IGV gravado
        if (cpe.totales.totalGravado.valor > Decimal.zero) {
          builder.element(
            'cac:TaxSubtotal',
            nest: () {
              builder.element(
                'cbc:TaxableAmount',
                nest: () {
                  builder.attribute('currencyID', cpe.moneda.codigoIso);
                  builder.text(cpe.totales.totalGravado.aFormatoUbl());
                },
              );
              builder.element(
                'cbc:TaxAmount',
                nest: () {
                  builder.attribute('currencyID', cpe.moneda.codigoIso);
                  builder.text(cpe.totales.totalIgv.aFormatoUbl());
                },
              );
              builder.element(
                'cac:TaxCategory',
                nest: () {
                  builder.element(
                    'cac:TaxScheme',
                    nest: () {
                      builder.element('cbc:ID', nest: '1000');
                      builder.element('cbc:Name', nest: 'IGV');
                      builder.element('cbc:TaxTypeCode', nest: 'VAT');
                    },
                  );
                },
              );
            },
          );
        }
      },
    );
  }

  void _construirTaxTotalItem(
    XmlBuilder builder,
    CPE_Item item,
    String moneda,
  ) {
    builder.element(
      'cac:TaxTotal',
      nest: () {
        builder.element(
          'cbc:TaxAmount',
          nest: () {
            builder.attribute('currencyID', moneda);
            builder.text(item.igv.aFormatoUbl());
          },
        );
        builder.element(
          'cac:TaxSubtotal',
          nest: () {
            builder.element(
              'cbc:TaxableAmount',
              nest: () {
                builder.attribute('currencyID', moneda);
                builder.text(item.valorVenta.aFormatoUbl());
              },
            );
            builder.element(
              'cbc:TaxAmount',
              nest: () {
                builder.attribute('currencyID', moneda);
                builder.text(item.igv.aFormatoUbl());
              },
            );
            builder.element(
              'cac:TaxCategory',
              nest: () {
                builder.element(
                  'cbc:Percent',
                  nest: item.porcentajeIgv.toString(),
                );
                builder.element(
                  'cbc:TaxExemptionReasonCode',
                  nest: item.tipoAfectacionIgv.codigo,
                );
                builder.element(
                  'cac:TaxScheme',
                  nest: () {
                    builder.element('cbc:ID', nest: '1000');
                    builder.element('cbc:Name', nest: 'IGV');
                    builder.element('cbc:TaxTypeCode', nest: 'VAT');
                  },
                );
              },
            );
          },
        );
      },
    );
  }

  void _construirLegalMonetaryTotal(XmlBuilder builder, CPE_Comprobante cpe) {
    builder.element(
      'cac:LegalMonetaryTotal',
      nest: () {
        builder.element(
          'cbc:LineExtensionAmount',
          nest: () {
            builder.attribute('currencyID', cpe.moneda.codigoIso);
            builder.text(cpe.totales.totalGravado.aFormatoUbl());
          },
        );
        builder.element(
          'cbc:TaxInclusiveAmount',
          nest: () {
            builder.attribute('currencyID', cpe.moneda.codigoIso);
            builder.text(cpe.totales.importeTotalPagar.aFormatoUbl());
          },
        );
        builder.element(
          'cbc:PayableAmount',
          nest: () {
            builder.attribute('currencyID', cpe.moneda.codigoIso);
            builder.text(cpe.totales.importeTotalPagar.aFormatoUbl());
          },
        );
      },
    );
  }

  void _construirItemLinea(XmlBuilder builder, CPE_Item item, String moneda) {
    _construirTaxTotalItem(builder, item, moneda);
    builder.element(
      'cac:Item',
      nest: () {
        builder.element('cbc:Description', nest: item.descripcion);
        builder.element(
          'cac:SellersItemIdentification',
          nest: () {
            builder.element('cbc:ID', nest: item.codigo);
          },
        );
      },
    );
    builder.element(
      'cac:Price',
      nest: () {
        builder.element(
          'cbc:PriceAmount',
          nest: () {
            builder.attribute('currencyID', moneda);
            builder.text(
              item.valorUnitario.aFormatoPrecioUnitario(decimales: 4),
            );
          },
        );
      },
    );
  }

  String _formatearFecha(DateTime fecha) {
    final y = fecha.year.toString().padLeft(4, '0');
    final m = fecha.month.toString().padLeft(2, '0');
    final d = fecha.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }
}
