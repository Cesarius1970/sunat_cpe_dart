// Copyright (c) 2026, César A Vergara Buenaventura <cesarvergarab@gmail.com>.
// Todos los derechos reservados. Uso sujeto a la licencia en el archivo LICENSE.

import 'package:decimal/decimal.dart';
import 'package:sunat_cpe_dart/sunat_cpe_dart.dart';

void main() async {
  print(
    '=== EJEMPLO COMPLETO: EMISIÓN DE FACTURA ELECTRÓNICA SUNAT UBL 2.1 ===\n',
  );

  // 1. Configuración de credenciales (Entorno Beta de pruebas de SUNAT)
  final credenciales = const CPE_Credenciales(
    ruc: '20100070970',
    usuarioSol: 'MODDATOS',
    claveSol: 'moddatos',
    entorno: CPE_Entorno.beta,
  );

  // 2. Datos del Emisor (Empresa contribuyente)
  final emisor = CPE_Contribuyente.emisorRuc(
    ruc: credenciales.ruc,
    razonSocial: 'SUPERMERCADOS Y SERVICIOS PERU S.A.C.',
    nombreComercial: 'SUPER PERU',
    direccion: const CPE_Direccion(
      direccion: 'AV. JAVIER PRADO ESTE 4500',
      urbanizacion: 'URB. MONTERRICO',
      distrito: 'SANTIAGO DE SURCO',
      provincia: 'LIMA',
      departamento: 'LIMA',
      ubigeo: '150140',
    ),
  );

  // 3. Datos del Receptor (Cliente con RUC)
  final receptor = const CPE_Contribuyente(
    numeroDocumento: '20601234566',
    tipoDocumento: CPE_Catalogo06_TipoDocumentoIdentidad.ruc,
    razonSocial: 'CORPORACION DE SERVICIOS DIGITALES S.A.C.',
    direccion: CPE_Direccion(
      direccion: 'CALLE LAS CAMELIAS 780',
      distrito: 'SAN ISIDRO',
      provincia: 'LIMA',
      departamento: 'LIMA',
      ubigeo: '150131',
    ),
  );

  // 4. Detalle de Ítems facturados (Aritmética decimal exacta, sin punto flotante)
  final item1 = CPE_Item.calcularDesdeValorUnitario(
    numeroLinea: 1,
    codigo: 'SRV-001',
    descripcion: 'Desarrollo e Integración de Facturación Electrónica SUNAT',
    cantidad: Decimal.parse('1'),
    valorUnitario: CPE_Monto.desdeTexto('3500.00'),
    afectacion: CPE_Catalogo07_AfectacionIgv.gravadoOperacionOnerosa,
  );

  final item2 = CPE_Item.calcularDesdeValorUnitario(
    numeroLinea: 2,
    codigo: 'LIC-002',
    descripcion: 'Licencia de Software Servidor Cloud Anual',
    cantidad: Decimal.parse('2'),
    valorUnitario: CPE_Monto.desdeTexto('750.00'),
    afectacion: CPE_Catalogo07_AfectacionIgv.gravadoOperacionOnerosa,
  );

  final items = [item1, item2];

  // 5. Cálculo automático y validación de totales fiscales
  final totales = CPE_Totales.calcularDesdeItems(items);

  // 6. Construcción de la Factura Electrónica
  final factura = CPE_Factura(
    serie: 'F001',
    correlativo: 245,
    fechaEmision: DateTime.now(),
    emisor: emisor,
    receptor: receptor,
    moneda: CPE_Catalogo02_Moneda.sol,
    items: items,
    totales: totales,
    observaciones: 'Pago a 15 días calendario.',
  );

  print('Comprobante: ${factura.identificadorComprobante}');
  print('Nombre Archivo SUNAT: ${factura.nombreArchivoSunat}.xml');
  print('Base Gravada: ${totales.totalGravado}');
  print('IGV (18%): ${totales.totalIgv}');
  print('Total a Pagar: ${totales.importeTotalPagar}');

  // 7. Generación de XML UBL 2.1
  final generador = const CPE_GeneradorXml();
  final xmlUbl = generador.generarFactura(factura);

  // 8. Firma Digital XML-DSig
  final firmador = CPE_FirmadorXml.paraPruebas();
  final firma = await firmador.firmarXml(xmlUbl);
  print('Resumen Digital (Hash QR / DigestValue): ${firma.digestValue}');

  // 9. Empaquetado ZIP
  const empaquetador = CPE_EmpaquetadorZip();
  final zipBytes = empaquetador.empaquetarXml(
    nombreXml: factura.nombreArchivoSunat,
    contenidoXml: firma.xmlFirmado,
  );
  print('Tamaño ZIP comprimido: ${zipBytes.length} bytes');
  print('\n=== Factura generada y validada con total éxito ===');
}
