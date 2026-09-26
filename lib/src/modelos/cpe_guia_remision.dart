// Copyright (c) 2026, César A Vergara Buenaventura <cesarvergarab@gmail.com>.
// Todos los derechos reservados. Uso sujeto a la licencia en el archivo LICENSE.

import 'package:decimal/decimal.dart';

import '../catalogos/cpe_catalogo_01_tipo_documento.dart';
import '../catalogos/cpe_catalogo_18_modalidad_traslado.dart';
import '../catalogos/cpe_catalogo_20_motivo_traslado.dart';
import 'cpe_contribuyente.dart';
import 'cpe_direccion.dart';

/// Ítem de carga en una Guía de Remisión Electrónica.
class CPE_ItemGuia {
  final int numeroLinea;
  final String codigo;
  final String descripcion;
  final Decimal cantidad;
  final String unidadMedida;

  const CPE_ItemGuia({
    required this.numeroLinea,
    required this.codigo,
    required this.descripcion,
    required this.cantidad,
    this.unidadMedida = 'NIU',
  });
}

/// Guía de Remisión Electrónica (Remitente 09 o Transportista 31).
class CPE_GuiaRemision {
  final CPE_Catalogo01_TipoDocumento tipoDocumento;
  final String serie;
  final int correlativo;
  final DateTime fechaEmision;
  final DateTime fechaInicioTraslado;
  final CPE_Contribuyente remitente;
  final CPE_Contribuyente destinatario;
  final CPE_Catalogo18_ModalidadTraslado modalidadTraslado;
  final CPE_Catalogo20_MotivoTraslado motivoTraslado;
  final String? descripcionMotivoTraslado;
  final Decimal pesoBrutoTotal;
  final String unidadMedidaPeso;
  final int? numeroBultos;
  final CPE_Direccion puntoPartida;
  final CPE_Direccion puntoLlegada;
  final CPE_Contribuyente? transportista;
  final String? numeroPlacaVehiculo;
  final String? numeroLicenciaConductor;
  final String? documentoIdentidadConductor;
  final List<CPE_ItemGuia> items;
  final String? observaciones;

  const CPE_GuiaRemision({
    required this.tipoDocumento,
    required this.serie,
    required this.correlativo,
    required this.fechaEmision,
    required this.fechaInicioTraslado,
    required this.remitente,
    required this.destinatario,
    required this.modalidadTraslado,
    required this.motivoTraslado,
    required this.pesoBrutoTotal,
    required this.puntoPartida,
    required this.puntoLlegada,
    required this.items,
    this.unidadMedidaPeso = 'KGM',
    this.numeroBultos,
    this.descripcionMotivoTraslado,
    this.transportista,
    this.numeroPlacaVehiculo,
    this.numeroLicenciaConductor,
    this.documentoIdentidadConductor,
    this.observaciones,
  });

  String get identificadorComprobante =>
      '$serie-${correlativo.toString().padLeft(8, '0')}';

  String get nombreArchivoSunat =>
      '${remitente.numeroDocumento}-${tipoDocumento.codigo}-$serie-${correlativo.toString().padLeft(8, '0')}';
}
