// Copyright (c) 2026, César A Vergara Buenaventura <cesarvergarab@gmail.com>.
// Todos los derechos reservados. Uso sujeto a la licencia en el archivo LICENSE.

/// Catálogo N° 07 de SUNAT: Códigos de Tipo de Afectación al IGV.
enum CPE_Catalogo07_AfectacionIgv {
  gravadoOperacionOnerosa(
    '10',
    'Gravado - Operación Onerosa',
    esGravado: true,
    esOneroso: true,
  ),
  gravadoRetiroPremio('11', 'Gravado - Retiro por premio', esGravado: true),
  gravadoRetiroDonacion('12', 'Gravado - Retiro por donación', esGravado: true),
  gravadoRetiro('13', 'Gravado - Retiro', esGravado: true),
  gravadoRetiroPublicidad(
    '14',
    'Gravado - Retiro por publicidad',
    esGravado: true,
  ),
  gravadoBonificaciones('15', 'Gravado - Bonificaciones', esGravado: true),
  gravadoRetiroEntregaTrabajadores(
    '16',
    'Gravado - Retiro por entrega a trabajadores',
    esGravado: true,
  ),
  gravadoIvap('17', 'Gravado - IVAP', esGravado: true),
  exoneradoOperacionOnerosa(
    '20',
    'Exonerado - Operación Onerosa',
    esExonerado: true,
  ),
  exoneradoTransferenciaGratuita(
    '21',
    'Exonerado - Transferencia Gratuita',
    esExonerado: true,
  ),
  inafectoOperacionOnerosa(
    '30',
    'Inafecto - Operación Onerosa',
    esInafecto: true,
  ),
  inafectoRetiroBonificacion(
    '31',
    'Inafecto - Retiro por Bonificación',
    esInafecto: true,
  ),
  inafectoRetiro('32', 'Inafecto - Retiro', esInafecto: true),
  inafectoRetiroMuestras(
    '33',
    'Inafecto - Retiro por Muestras Médicas',
    esInafecto: true,
  ),
  inafectoRetiroConvenioColectivo(
    '34',
    'Inafecto - Retiro por Convenio Colectivo',
    esInafecto: true,
  ),
  inafectoRetiroPremio('35', 'Inafecto - Retiro por premio', esInafecto: true),
  inafectoRetiroPublicidad(
    '36',
    'Inafecto - Retiro por publicidad',
    esInafecto: true,
  ),
  exportacion('40', 'Exportación de Bienes o Servicios', esExportacion: true);

  final String codigo;
  final String descripcion;
  final bool esGravado;
  final bool esExonerado;
  final bool esInafecto;
  final bool esExportacion;
  final bool esOneroso;

  const CPE_Catalogo07_AfectacionIgv(
    this.codigo,
    this.descripcion, {
    this.esGravado = false,
    this.esExonerado = false,
    this.esInafecto = false,
    this.esExportacion = false,
    this.esOneroso = false,
  });

  static CPE_Catalogo07_AfectacionIgv? desdeCodigo(String codigo) {
    for (final a in values) {
      if (a.codigo == codigo) return a;
    }
    return null;
  }
}
