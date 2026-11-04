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

import 'sunat_provider_descriptor.dart';

/// Fábrica estática que construye una instancia de [OseProvider] a partir de cualquier [SunatProviderDescriptor].
abstract final class SunatProviderFactory {
  /// Instancia el [OseProvider] concreto descrito por [descriptor].
  static OseProvider create(SunatProviderDescriptor descriptor) {
    return switch (descriptor) {
      DirectSunatDescriptor(
        :final config,
        :final soapHttpClient,
        :final restHttpClient,
        :final validator,
      ) =>
        SunatDirectProvider(
          config: config,
          soapHttpClient: soapHttpClient,
          restHttpClient: restHttpClient,
          validator: validator,
        ),
      NubefactDescriptor(:final config, :final httpClient, :final validator) =>
        NubefactProvider(
          config: config,
          httpClient: httpClient,
          validator: validator,
        ),
      EfactDescriptor(:final config, :final httpClient, :final validator) =>
        EfactProvider(
          config: config,
          httpClient: httpClient,
          validator: validator,
        ),
      MifactDescriptor(:final config, :final httpClient, :final validator) =>
        MifactProvider(
          config: config,
          httpClient: httpClient,
          validator: validator,
        ),
      BizlinksDescriptor(:final config, :final httpClient, :final validator) =>
        BizlinksProvider(
          config: config,
          httpClient: httpClient,
          validator: validator,
        ),
      DigiflowDescriptor(:final config, :final httpClient, :final validator) =>
        DigiflowProvider(
          config: config,
          httpClient: httpClient,
          validator: validator,
        ),
      SovosDescriptor(:final config, :final httpClient, :final validator) =>
        SovosProvider(
          config: config,
          httpClient: httpClient,
          validator: validator,
        ),
      FacturaloDescriptor(:final config, :final httpClient, :final validator) =>
        FacturaloProvider(
          config: config,
          httpClient: httpClient,
          validator: validator,
        ),
      TciDescriptor(:final config, :final httpClient, :final validator) =>
        TciProvider(
          config: config,
          httpClient: httpClient,
          validator: validator,
        ),
      CavaliDescriptor(
        :final config,
        :final oseHttpClient,
        :final factrackHttpClient,
        :final validator,
      ) =>
        CavaliProvider(
          config: config,
          oseHttpClient: oseHttpClient,
          factrackHttpClient: factrackHttpClient,
          validator: validator,
        ),
    };
  }
}
