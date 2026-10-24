import '../../../core/utils/parse_helpers.dart';

class PaymentSubmissionModel {
  final String id;
  final String orderId;
  final String customerId;
  final String customerName;
  final double amount;
  final String utrNumber;
  final String screenshotUrl;
  final String status; // 'pending', 'approved', 'rejected'
  final String? rejectionReason;
  final DateTime submittedAt;
  final DateTime? verifiedAt;
  final String? verifiedBy;

  const PaymentSubmissionModel({
    required this.id,
    required this.orderId,
    required this.customerId,
    required this.customerName,
    required this.amount,
    required this.utrNumber,
    this.screenshotUrl = '',
    this.status = 'pending',
    this.rejectionReason,
    required this.submittedAt,
    this.verifiedAt,
    this.verifiedBy,
  });

  bool get isPending => status == 'pending';
  bool get isApproved => status == 'approved';
  bool get isRejected => status == 'rejected';

  factory PaymentSubmissionModel.fromMap(Map<String, dynamic> map, String id) {
    return PaymentSubmissionModel(
      id: id,
      orderId: ParseHelpers.parseString(map['orderId']),
      customerId: ParseHelpers.parseString(map['customerId']),
      customerName: ParseHelpers.parseString(map['customerName']),
      amount: ParseHelpers.parseDouble(map['amount']),
      utrNumber: ParseHelpers.parseString(map['utrNumber']),
      screenshotUrl: ParseHelpers.parseString(map['screenshotUrl']),
      status: ParseHelpers.parseString(map['status'], 'pending'),
      rejectionReason: map['rejectionReason']?.toString(),
      submittedAt: ParseHelpers.parseDateTime(map['submittedAt']),
      verifiedAt: ParseHelpers.parseNullableDateTime(map['verifiedAt']),
      verifiedBy: map['verifiedBy']?.toString(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'orderId': orderId,
      'customerId': customerId,
      'customerName': customerName,
      'amount': amount,
      'utrNumber': utrNumber,
      'screenshotUrl': screenshotUrl,
      'status': status,
      'rejectionReason': rejectionReason,
      'submittedAt': submittedAt.toIso8601String(),
      'verifiedAt': verifiedAt?.toIso8601String(),
      'verifiedBy': verifiedBy,
    };
  }
}
