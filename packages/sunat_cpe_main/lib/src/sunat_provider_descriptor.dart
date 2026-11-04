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

/// Declarative sealed hierarchy describing how to instantiate either the
/// direct SUNAT SOL adapter (`sunat_cpe_direct`) or any of the 9 OSE/PSE adapters.
sealed class SunatProviderDescriptor {
  const SunatProviderDescriptor();
}

/// Descriptor for direct emission to SUNAT SOL (SOAP + REST OAuth2 GRE).
final class DirectSunatDescriptor extends SunatProviderDescriptor {
  final SunatDirectConfig config;
  final CpeHttpClient? soapHttpClient;
  final CpeHttpClient? restHttpClient;
  final CpeMathValidator? validator;

  const DirectSunatDescriptor(
    this.config, {
    this.soapHttpClient,
    this.restHttpClient,
    this.validator,
  });
}

/// Descriptor for Nubefact (REST JSON PSE/OSE).
final class NubefactDescriptor extends SunatProviderDescriptor {
  final NubefactConfig config;
  final CpeHttpClient? httpClient;
  final CpeMathValidator? validator;

  const NubefactDescriptor(
    this.config, {
    this.httpClient,
    this.validator,
  });
}

/// Descriptor for EFACT (REST OAuth2 XML/JSON + SOAP 1.1 OSE/PSE).
final class EfactDescriptor extends SunatProviderDescriptor {
  final EfactConfig config;
  final CpeHttpClient? httpClient;
  final CpeMathValidator? validator;

  const EfactDescriptor(
    this.config, {
    this.httpClient,
    this.validator,
  });
}

/// Descriptor for Mifact (REST JSON PSE/OSE).
final class MifactDescriptor extends SunatProviderDescriptor {
  final MifactConfig config;
  final CpeHttpClient? httpClient;
  final CpeMathValidator? validator;

  const MifactDescriptor(
    this.config, {
    this.httpClient,
    this.validator,
  });
}

/// Descriptor for Bizlinks (SOAP 1.1 WS-Security OSE).
final class BizlinksDescriptor extends SunatProviderDescriptor {
  final BizlinksConfig config;
  final CpeHttpClient? httpClient;
  final CpeMathValidator? validator;

  const BizlinksDescriptor(
    this.config, {
    this.httpClient,
    this.validator,
  });
}

/// Descriptor for Digiflow (SOAP 1.1 WS-Security OSE).
final class DigiflowDescriptor extends SunatProviderDescriptor {
  final DigiflowConfig config;
  final CpeHttpClient? httpClient;
  final CpeMathValidator? validator;

  const DigiflowDescriptor(
    this.config, {
    this.httpClient,
    this.validator,
  });
}

/// Descriptor for Sovos / Paperless (SOAP 1.1 OSE/PSE).
final class SovosDescriptor extends SunatProviderDescriptor {
  final SovosConfig config;
  final CpeHttpClient? httpClient;
  final CpeMathValidator? validator;

  const SovosDescriptor(
    this.config, {
    this.httpClient,
    this.validator,
  });
}

/// Descriptor for FacturaloPeru / Facturador PRO (REST JSON Bearer PSE).
final class FacturaloDescriptor extends SunatProviderDescriptor {
  final FacturaloConfig config;
  final CpeHttpClient? httpClient;
  final CpeMathValidator? validator;

  const FacturaloDescriptor(
    this.config, {
    this.httpClient,
    this.validator,
  });
}

/// Descriptor for TCI (SOAP 1.1 WS-Security OSE).
final class TciDescriptor extends SunatProviderDescriptor {
  final TciConfig config;
  final CpeHttpClient? httpClient;
  final CpeMathValidator? validator;

  const TciDescriptor(
    this.config, {
    this.httpClient,
    this.validator,
  });
}

/// Descriptor for Cavali / Gosocket OSE + Factrack Factoring REST OAuth2.
final class CavaliDescriptor extends SunatProviderDescriptor {
  final CavaliConfig config;
  final CpeHttpClient? oseHttpClient;
  final CpeHttpClient? factrackHttpClient;
  final CpeMathValidator? validator;

  const CavaliDescriptor(
    this.config, {
    this.oseHttpClient,
    this.factrackHttpClient,
    this.validator,
  });
}
