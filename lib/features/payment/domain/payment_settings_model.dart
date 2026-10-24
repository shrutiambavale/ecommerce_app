import '../../../core/utils/parse_helpers.dart';

class PaymentSettingsModel {
  final String upiId;
  final String receiverName;
  final String qrImageUrl;
  final String instructions;
  final DateTime updatedAt;
  final String updatedBy;
  final String? ownerId;

  const PaymentSettingsModel({
    required this.upiId,
    required this.receiverName,
    required this.qrImageUrl,
    required this.instructions,
    required this.updatedAt,
    this.updatedBy = 'admin',
    this.ownerId,
  });

  factory PaymentSettingsModel.defaultSettings([String? ownerId]) {
    return PaymentSettingsModel(
      upiId: 'luxestore@upi',
      receiverName: 'LuxeStore Essentials Pvt Ltd',
      qrImageUrl: '',
      instructions:
          '1. Scan this QR code using Google Pay, PhonePe, Paytm, or any UPI app.\n'
          '2. Verify that the receiver name matches "LuxeStore Essentials Pvt Ltd".\n'
          '3. Complete payment for the exact order total.\n'
          '4. Copy the 12-digit UPI Reference / UTR Number from your payment receipt.\n'
          '5. Paste the UTR number below and submit for verification.',
      updatedAt: DateTime.now(),
      ownerId: ownerId,
    );
  }

  factory PaymentSettingsModel.fromMap(Map<String, dynamic> map, [String? id]) {
    return PaymentSettingsModel(
      upiId: ParseHelpers.parseString(map['upiId'], 'luxestore@upi'),
      receiverName: ParseHelpers.parseString(
          map['receiverName'], 'LuxeStore Essentials Pvt Ltd'),
      qrImageUrl: ParseHelpers.parseString(map['qrImageUrl']),
      instructions: ParseHelpers.parseString(map['instructions']),
      updatedAt: ParseHelpers.parseDateTime(map['updatedAt']),
      updatedBy: ParseHelpers.parseString(map['updatedBy'], 'admin'),
      ownerId: ParseHelpers.parseNullableString(
        map['ownerId'] ?? map['adminId'] ?? id,
      ),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'upiId': upiId,
      'receiverName': receiverName,
      'qrImageUrl': qrImageUrl,
      'instructions': instructions,
      'updatedAt': updatedAt.toIso8601String(),
      'updatedBy': updatedBy,
      'ownerId': ownerId,
    };
  }

  PaymentSettingsModel copyWith({
    String? upiId,
    String? receiverName,
    String? qrImageUrl,
    String? instructions,
    String? updatedBy,
    String? ownerId,
  }) {
    return PaymentSettingsModel(
      upiId: upiId ?? this.upiId,
      receiverName: receiverName ?? this.receiverName,
      qrImageUrl: qrImageUrl ?? this.qrImageUrl,
      instructions: instructions ?? this.instructions,
      updatedAt: DateTime.now(),
      updatedBy: updatedBy ?? this.updatedBy,
      ownerId: ownerId ?? this.ownerId,
    );
  }

  /// Generates a standardized UPI payment URI containing payee details,
  /// verified merchant name, exact order amount, and transaction reference.
  String buildUpiUri({
    required double amount,
    required String orderId,
    String? note,
  }) {
    final cleanUpi = Uri.encodeComponent(upiId.trim());
    final cleanReceiver = Uri.encodeComponent(receiverName.trim());
    final formattedAmount = amount.toStringAsFixed(2);
    final cleanNote = Uri.encodeComponent(note ?? 'Order $orderId');
    return 'upi://pay?pa=$cleanUpi&pn=$cleanReceiver&am=$formattedAmount&cu=INR&tn=$cleanNote';
  }
}
