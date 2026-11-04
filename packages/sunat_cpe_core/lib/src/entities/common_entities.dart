part of 'cpe_entities.dart';

/// Jerarquía sellada base para todos los Comprobantes de Pago Electrónicos (CPE) de SUNAT.
sealed class CpeDocument {
  final DocumentId id;
  final CompanyParty issuer;
  final DateTime issueDate;
  final String? issueTime; // HH:mm:ss

  const CpeDocument({
    required this.id,
    required this.issuer,
    required this.issueDate,
    this.issueTime,
  });
}

/// Identificador único para cualquier documento electrónico de SUNAT.
final class DocumentId {
  final String issuerRuc;
  final CpeDocumentType type;
  final String series;
  final int number;

  const DocumentId({
    required this.issuerRuc,
    required this.type,
    required this.series,
    required this.number,
  });

  /// Nombre base estándar de archivo SUNAT: `{RUC}-{TIPO}-{SERIE}-{NUMERO}`
  /// o `{RUC}-{TIPO}-{YYYYMMDD}-{NUMERO}` para RC/RA/RR cuando `series` tiene el formato `RC-YYYYMMDD`.
  String get fileNameBase {
    if (type == CpeDocumentType.resumenDiario ||
        type == CpeDocumentType.comunicacionBaja ||
        type == CpeDocumentType.reversion) {
      if (series.startsWith('${type.code}-')) {
        return '$issuerRuc-$series-$number';
      }
    }
    return '$issuerRuc-${type.code}-$series-$number';
  }

  /// Serie y correlativo formateados dentro de la etiqueta UBL `<cbc:ID>` (ej. `F001-1`).
  String get ublId {
    if (type == CpeDocumentType.resumenDiario ||
        type == CpeDocumentType.comunicacionBaja ||
        type == CpeDocumentType.reversion) {
      if (series.startsWith('${type.code}-')) {
        return '$series-$number';
      }
      return '${type.code}-$series-$number';
    }
    return '$series-$number';
  }

  DocumentId copyWith({
    String? issuerRuc,
    CpeDocumentType? type,
    String? series,
    int? number,
  }) {
    return DocumentId(
      issuerRuc: issuerRuc ?? this.issuerRuc,
      type: type ?? this.type,
      series: series ?? this.series,
      number: number ?? this.number,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DocumentId &&
          issuerRuc == other.issuerRuc &&
          type == other.type &&
          series == other.series &&
          number == other.number;

  @override
  int get hashCode => Object.hash(issuerRuc, type, series, number);

  @override
  String toString() => fileNameBase;
}

/// Dirección física o domicilio fiscal con código de Ubigeo INEI y código de establecimiento anexo SUNAT.
final class Address {
  final String? ubigeo;
  final String streetLine;
  final String? urbanization;
  final String? district;
  final String? province;
  final String? department;
  final String countryCode;
  final String establishmentCode;

  const Address({
    this.ubigeo,
    required this.streetLine,
    this.urbanization,
    this.district,
    this.province,
    this.department,
    this.countryCode = 'PE',
    this.establishmentCode = '0000',
  });

  Address copyWith({
    String? ubigeo,
    String? streetLine,
    String? urbanization,
    String? district,
    String? province,
    String? department,
    String? countryCode,
    String? establishmentCode,
  }) {
    return Address(
      ubigeo: ubigeo ?? this.ubigeo,
      streetLine: streetLine ?? this.streetLine,
      urbanization: urbanization ?? this.urbanization,
      district: district ?? this.district,
      province: province ?? this.province,
      department: department ?? this.department,
      countryCode: countryCode ?? this.countryCode,
      establishmentCode: establishmentCode ?? this.establishmentCode,
    );
  }
}

/// Empresa emisora (Emisor electrónico).
final class CompanyParty {
  final String ruc;
  final String legalName;
  final String? tradeName;
  final Address address;
  final String? email;
  final String? phone;

  const CompanyParty({
    required this.ruc,
    required this.legalName,
    this.tradeName,
    required this.address,
    this.email,
    this.phone,
  });
}

/// Cliente o receptor del comprobante (Adquirente o Usuario).
final class CustomerParty {
  final IdentityDocumentType documentType;
  final String documentNumber;
  final String legalName;
  final Address? address;
  final String? email;
  final String? phone;

  const CustomerParty({
    required this.documentType,
    required this.documentNumber,
    required this.legalName,
    this.address,
    this.email,
    this.phone,
  });
}

/// Referencia a un documento relacionado o modificado (ej. factura afectada en Nota de Crédito/Débito o Guía de Remisión).
final class DocumentReference {
  final CpeDocumentType documentType;
  final String series;
  final int number;
  final DateTime? issueDate;

  const DocumentReference({
    required this.documentType,
    required this.series,
    required this.number,
    this.issueDate,
  });

  String get formattedId => '$series-$number';
}

/// Descuento o cargo a nivel de ítem o global (Catálogo 53).
final class AllowanceCharge {
  final bool isCharge;
  final String reasonCode; // '00', '01', '02', '03', etc.
  final Decimal factor; // Multiplier (e.g. 0.10 for 10%)
  final Decimal amount;
  final Decimal baseAmount;

  const AllowanceCharge({
    required this.isCharge,
    required this.reasonCode,
    required this.factor,
    required this.amount,
    required this.baseAmount,
  });
}
