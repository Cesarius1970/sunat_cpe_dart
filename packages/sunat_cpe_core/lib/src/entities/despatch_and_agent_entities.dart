part of 'cpe_entities.dart';

/// Guía de Remisión Electrónica (09 Remitente y 31 Transportista) - UBL 2.1.
final class DespatchAdviceDocument extends CpeDocument {
  final CustomerParty recipient;
  final CustomerParty? buyerOrSupplier;
  final DespatchReasonCode transferReason;
  final String? transferDescription;
  final TransportModeCode transportMode;
  final DateTime transferStartDate;
  final Decimal grossWeight;
  final String weightUnitCode; // 'KGM' or 'TNE'
  final int? packageCount;
  final bool isM1OrLVehicle;

  final Address originAddress;
  final Address deliveryAddress;

  final CarrierParty? carrier;
  final List<TransportVehicle> vehicles;
  final List<DriverPerson> drivers;
  final List<DocumentReference> relatedDocuments;
  final List<DespatchLineItem> items;
  final String? observations;

  const DespatchAdviceDocument({
    required super.id,
    required super.issuer,
    required super.issueDate,
    super.issueTime,
    required this.recipient,
    this.buyerOrSupplier,
    required this.transferReason,
    this.transferDescription,
    required this.transportMode,
    required this.transferStartDate,
    required this.grossWeight,
    this.weightUnitCode = 'KGM',
    this.packageCount,
    this.isM1OrLVehicle = false,
    required this.originAddress,
    required this.deliveryAddress,
    this.carrier,
    this.vehicles = const [],
    this.drivers = const [],
    this.relatedDocuments = const [],
    required this.items,
    this.observations,
  });
}

final class CarrierParty {
  final String ruc;
  final String legalName;
  final String? mtcRegistrationNumber;

  const CarrierParty({
    required this.ruc,
    required this.legalName,
    this.mtcRegistrationNumber,
  });
}

final class TransportVehicle {
  final String plateNumber;
  final bool isPrincipal;
  final String? tucCertificateNumber;
  final String? specialAuthorizationNumber;
  final String? authorizationEntityCode;

  const TransportVehicle({
    required this.plateNumber,
    this.isPrincipal = true,
    this.tucCertificateNumber,
    this.specialAuthorizationNumber,
    this.authorizationEntityCode,
  });
}

final class DriverPerson {
  final IdentityDocumentType documentType;
  final String documentNumber;
  final String firstName;
  final String lastName;
  final String licenseNumber;
  final bool isPrincipal;

  const DriverPerson({
    this.documentType = IdentityDocumentType.dni,
    required this.documentNumber,
    required this.firstName,
    required this.lastName,
    required this.licenseNumber,
    this.isPrincipal = true,
  });
}

final class DespatchLineItem {
  final int lineNumber;
  final String? internalCode;
  final String? sunatProductCode;
  final String unitCode;
  final String description;
  final Decimal quantity;

  const DespatchLineItem({
    required this.lineNumber,
    this.internalCode,
    this.sunatProductCode,
    this.unitCode = 'NIU',
    required this.description,
    required this.quantity,
  });
}

/// Clase base sellada para Comprobantes de Retención (20) y Percepción (40).
sealed class AgentCpeDocument extends CpeDocument {
  final CustomerParty partner;
  final CurrencyCode currency;
  final Decimal totalAmountInPen;
  final Decimal totalPaidOrCollectedInPen;
  final List<AgentDocumentLine> lines;
  final String? observations;

  const AgentCpeDocument({
    required super.id,
    required super.issuer,
    required super.issueDate,
    super.issueTime,
    required this.partner,
    this.currency = CurrencyCode.pen,
    required this.totalAmountInPen,
    required this.totalPaidOrCollectedInPen,
    required this.lines,
    this.observations,
  });
}

/// Comprobante de Retención Electrónico (20).
final class RetentionDocument extends AgentCpeDocument {
  final RetentionRegimeCode regime;
  final Decimal ratePercentage;

  const RetentionDocument({
    required super.id,
    required super.issuer,
    required super.issueDate,
    super.issueTime,
    required super.partner,
    required super.totalAmountInPen,
    required super.totalPaidOrCollectedInPen,
    required super.lines,
    super.observations,
    this.regime = RetentionRegimeCode.tasaTresPorCiento,
    required this.ratePercentage,
  });
}

/// Comprobante de Percepción Electrónico (40).
final class PerceptionDocument extends AgentCpeDocument {
  final PerceptionRegimeCode regime;
  final Decimal ratePercentage;

  const PerceptionDocument({
    required super.id,
    required super.issuer,
    required super.issueDate,
    super.issueTime,
    required super.partner,
    required super.totalAmountInPen,
    required super.totalPaidOrCollectedInPen,
    required super.lines,
    super.observations,
    this.regime = PerceptionRegimeCode.ventaInterna,
    required this.ratePercentage,
  });
}

/// Ítem de detalle dentro de un Comprobante de Retención o de Percepción.
final class AgentDocumentLine {
  final CpeDocumentType relatedDocumentType;
  final String relatedSeriesAndNumber;
  final DateTime relatedIssueDate;
  final CurrencyCode relatedCurrency;
  final Decimal relatedTotalAmount;

  final DateTime paymentOrCollectionDate;
  final int paymentInstallmentNumber;
  final Decimal paymentAmountBeforeTax;

  final Decimal retainedOrPerceivedAmountInPen;
  final Decimal netPaidOrCollectedAmountInPen;
  final Decimal? exchangeRate;
  final DateTime? exchangeRateDate;

  const AgentDocumentLine({
    required this.relatedDocumentType,
    required this.relatedSeriesAndNumber,
    required this.relatedIssueDate,
    this.relatedCurrency = CurrencyCode.pen,
    required this.relatedTotalAmount,
    required this.paymentOrCollectionDate,
    this.paymentInstallmentNumber = 1,
    required this.paymentAmountBeforeTax,
    required this.retainedOrPerceivedAmountInPen,
    required this.netPaidOrCollectedAmountInPen,
    this.exchangeRate,
    this.exchangeRateDate,
  });
}
