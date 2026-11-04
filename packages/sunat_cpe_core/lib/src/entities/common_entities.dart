part of 'cpe_entities.dart';

/// Base sealed hierarchy for all SUNAT CPE documents.
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

/// Unique identifier for any SUNAT electronic document.
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

  /// Standard SUNAT file name base: `{RUC}-{TIPO}-{SERIE}-{NUMERO}`
  /// or `{RUC}-{TIPO}-{YYYYMMDD}-{NUMERO}` for RC/RA/RR when `series` is `RC-YYYYMMDD`.
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

  /// Formatted series and number inside the UBL `<cbc:ID>` tag (e.g. `F001-1`).
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

/// Physical or fiscal address with INEI Ubigeo and SUNAT annex establishment code.
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

/// Issuing company (Emisor electrónico).
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

/// Customer / Receiver party (Adquirente o Usuario).
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

/// Reference to a related or modified document (e.g. affected invoice in Credit/Debit Note, or Guide).
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

/// Allowance (discount) or Charge at item or global level (Catálogo 53).
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
