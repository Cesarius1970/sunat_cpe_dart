import 'package:sunat_cpe_bizlinks/sunat_cpe_bizlinks.dart';
import 'package:sunat_cpe_cavali/sunat_cpe_cavali.dart';
import 'package:sunat_cpe_core/sunat_cpe_core.dart';
import 'package:sunat_cpe_digiflow/sunat_cpe_digiflow.dart';
import 'package:sunat_cpe_direct/sunat_cpe_direct.dart';
import 'package:sunat_cpe_efact/sunat_cpe_efact.dart';
import 'package:sunat_cpe_facturaloperu/sunat_cpe_facturaloperu.dart';
import 'package:sunat_cpe_mifact/sunat_cpe_mifact.dart';
import 'package:sunat_cpe_nubefact/sunat_cpe_nubefact.dart';
import 'package:sunat_cpe_sovos/sunat_cpe_sovos.dart';
import 'package:sunat_cpe_tci/sunat_cpe_tci.dart';

/// Jerarquía sellada declarativa que describe cómo instanciar tanto el
/// adaptador directo a SUNAT SOL (`sunat_cpe_direct`) como cualquiera de los 9 adaptadores OSE/PSE.
sealed class SunatProviderDescriptor {
  /// Constructor base constante para descriptores de proveedor.
  const SunatProviderDescriptor();
}

/// Descriptor para emisión directa a SUNAT SOL (SOAP + API REST OAuth2 GRE).
final class DirectSunatDescriptor extends SunatProviderDescriptor {
  /// Configuración y credenciales SOL / OAuth2 de SUNAT.
  final SunatDirectConfig config;

  /// Cliente HTTP opcional para los canales SOAP de SUNAT.
  final CpeHttpClient? soapHttpClient;

  /// Cliente HTTP opcional para el canal REST GRE de SUNAT.
  final CpeHttpClient? restHttpClient;

  /// Validador aritmético opcional.
  final CpeMathValidator? validator;

  /// Crea un descriptor para [SunatDirectProvider].
  const DirectSunatDescriptor(
    this.config, {
    this.soapHttpClient,
    this.restHttpClient,
    this.validator,
  });
}

/// Descriptor para Nubefact (PSE/OSE REST JSON).
final class NubefactDescriptor extends SunatProviderDescriptor {
  /// Configuración y credenciales de Nubefact.
  final NubefactConfig config;

  /// Cliente HTTP opcional.
  final CpeHttpClient? httpClient;

  /// Validador aritmético opcional.
  final CpeMathValidator? validator;

  /// Crea un descriptor para [NubefactProvider].
  const NubefactDescriptor(this.config, {this.httpClient, this.validator});
}

/// Descriptor para EFACT (OSE/PSE REST OAuth2 XML/JSON + SOAP 1.1).
final class EfactDescriptor extends SunatProviderDescriptor {
  /// Configuración y credenciales de EFACT.
  final EfactConfig config;

  /// Cliente HTTP opcional.
  final CpeHttpClient? httpClient;

  /// Validador aritmético opcional.
  final CpeMathValidator? validator;

  /// Crea un descriptor para [EfactProvider].
  const EfactDescriptor(this.config, {this.httpClient, this.validator});
}

/// Descriptor para Mifact (PSE/OSE REST JSON).
final class MifactDescriptor extends SunatProviderDescriptor {
  /// Configuración y credenciales de Mifact.
  final MifactConfig config;

  /// Cliente HTTP opcional.
  final CpeHttpClient? httpClient;

  /// Validador aritmético opcional.
  final CpeMathValidator? validator;

  /// Crea un descriptor para [MifactProvider].
  const MifactDescriptor(this.config, {this.httpClient, this.validator});
}

/// Descriptor para Bizlinks (OSE SOAP 1.1 WS-Security).
final class BizlinksDescriptor extends SunatProviderDescriptor {
  /// Configuración y credenciales de Bizlinks.
  final BizlinksConfig config;

  /// Cliente HTTP opcional.
  final CpeHttpClient? httpClient;

  /// Validador aritmético opcional.
  final CpeMathValidator? validator;

  /// Crea un descriptor para [BizlinksProvider].
  const BizlinksDescriptor(this.config, {this.httpClient, this.validator});
}

/// Descriptor para Digiflow (OSE SOAP 1.1 WS-Security).
final class DigiflowDescriptor extends SunatProviderDescriptor {
  /// Configuración y credenciales de Digiflow.
  final DigiflowConfig config;

  /// Cliente HTTP opcional.
  final CpeHttpClient? httpClient;

  /// Validador aritmético opcional.
  final CpeMathValidator? validator;

  /// Crea un descriptor para [DigiflowProvider].
  const DigiflowDescriptor(this.config, {this.httpClient, this.validator});
}

/// Descriptor para Sovos / Paperless (OSE/PSE SOAP 1.1).
final class SovosDescriptor extends SunatProviderDescriptor {
  /// Configuración y credenciales de Sovos Paperless.
  final SovosConfig config;

  /// Cliente HTTP opcional.
  final CpeHttpClient? httpClient;

  /// Validador aritmético opcional.
  final CpeMathValidator? validator;

  /// Crea un descriptor para [SovosProvider].
  const SovosDescriptor(this.config, {this.httpClient, this.validator});
}

/// Descriptor para FacturaloPeru / Facturador PRO (PSE REST JSON Bearer).
final class FacturaloDescriptor extends SunatProviderDescriptor {
  /// Configuración y credenciales de FacturaloPeru.
  final FacturaloConfig config;

  /// Cliente HTTP opcional.
  final CpeHttpClient? httpClient;

  /// Validador aritmético opcional.
  final CpeMathValidator? validator;

  /// Crea un descriptor para [FacturaloProvider].
  const FacturaloDescriptor(this.config, {this.httpClient, this.validator});
}

/// Descriptor para TCI (OSE SOAP 1.1 WS-Security).
final class TciDescriptor extends SunatProviderDescriptor {
  /// Configuración y credenciales de TCI.
  final TciConfig config;

  /// Cliente HTTP opcional.
  final CpeHttpClient? httpClient;

  /// Validador aritmético opcional.
  final CpeMathValidator? validator;

  /// Crea un descriptor para [TciProvider].
  const TciDescriptor(this.config, {this.httpClient, this.validator});
}

/// Descriptor para Cavali / Gosocket OSE + Factrack Factoring REST OAuth2.
final class CavaliDescriptor extends SunatProviderDescriptor {
  /// Configuración y credenciales de Cavali / Gosocket y Factrack.
  final CavaliConfig config;

  /// Cliente HTTP opcional para el servicio SOAP OSE Gosocket.
  final CpeHttpClient? oseHttpClient;

  /// Cliente HTTP opcional para la API REST Cavali Factrack.
  final CpeHttpClient? factrackHttpClient;

  /// Validador aritmético opcional.
  final CpeMathValidator? validator;

  /// Crea un descriptor para [CavaliProvider].
  const CavaliDescriptor(
    this.config, {
    this.oseHttpClient,
    this.factrackHttpClient,
    this.validator,
  });
}
