// Copyright (c) 2026, César A Vergara Buenaventura <cesarvergarab@gmail.com>.
// Todos los derechos reservados. Uso sujeto a la licencia en el archivo LICENSE.

import '../catalogos/cpe_catalogo_01_tipo_documento.dart';
import '../catalogos/cpe_catalogo_17_tipo_operacion.dart';
import 'cpe_comprobante.dart';

/// Boleta de Venta Electrónica (Tipo de Documento 03 de SUNAT).
class CPE_Boleta extends CPE_Comprobante {
  @override
  CPE_Catalogo01_TipoDocumento get tipoDocumento =>
      CPE_Catalogo01_TipoDocumento.boletaVenta;

  /// Tipo de operación según Catálogo 17/51 (por defecto Venta Interna '0101').
  final CPE_Catalogo17_TipoOperacion tipoOperacion;

  /// Forma de pago (por defecto 'Contado').
  final String formaPago;

  const CPE_Boleta({
    required super.serie,
    required super.correlativo,
    required super.fechaEmision,
    required super.emisor,
    required super.receptor,
    required super.moneda,
    required super.items,
    required super.totales,
    super.horaEmision,
    super.observaciones,
    this.tipoOperacion = CPE_Catalogo17_TipoOperacion.ventaInterna,
    this.formaPago = 'Contado',
  });
}
