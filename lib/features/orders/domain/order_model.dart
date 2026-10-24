import '../../../core/utils/parse_helpers.dart';
import '../../checkout/domain/address_model.dart';
import 'order_status.dart';

class OrderItemModel {
  final String productId;
  final String productName;
  final String productImage;
  final double unitPrice; // Frozen price at purchase time
  final int quantity;
  final String? ownerId;

  const OrderItemModel({
    required this.productId,
    required this.productName,
    required this.productImage,
    required this.unitPrice,
    required this.quantity,
    this.ownerId,
  });

  double get totalPrice => unitPrice * quantity;

  factory OrderItemModel.fromMap(Map<String, dynamic> map) {
    return OrderItemModel(
      productId: ParseHelpers.parseString(map['productId']),
      productName: ParseHelpers.parseString(map['productName']),
      productImage: ParseHelpers.parseString(map['productImage']),
      unitPrice: ParseHelpers.parseDouble(map['unitPrice']),
      quantity: ParseHelpers.parseInt(map['quantity'], 1),
      ownerId: ParseHelpers.parseNullableString(
        map['ownerId'] ?? map['sellerId'],
      ),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'productId': productId,
      'productName': productName,
      'productImage': productImage,
      'unitPrice': unitPrice,
      'quantity': quantity,
      'ownerId': ownerId,
    };
  }
}

class OrderModel {
  final String id;
  final String customerId;
  final String customerName;
  final String customerEmail;
  final String customerPhone;
  final List<OrderItemModel> items;
  final AddressModel shippingAddress;
  final double subtotal;
  final double gstAmount;
  final double deliveryFee;
  final double totalAmount;
  final OrderStatus status;
  final String paymentMethod;
  final String? utrNumber;
  final String? paymentScreenshotUrl;
  final String? paymentRejectionReason;
  final String? merchantId;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? verifiedAt;

  const OrderModel({
    required this.id,
    required this.customerId,
    required this.customerName,
    required this.customerEmail,
    required this.customerPhone,
    required this.items,
    required this.shippingAddress,
    required this.subtotal,
    required this.gstAmount,
    required this.deliveryFee,
    required this.totalAmount,
    required this.status,
    this.paymentMethod = 'UPI_QR',
    this.utrNumber,
    this.paymentScreenshotUrl,
    this.paymentRejectionReason,
    this.merchantId,
    required this.createdAt,
    required this.updatedAt,
    this.verifiedAt,
  });

  factory OrderModel.fromMap(Map<String, dynamic> map, String id) {
    final rawItems = map['items'] as List<dynamic>? ?? [];
    final items = <OrderItemModel>[];
    for (final item in rawItems) {
      if (item is Map) {
        items.add(OrderItemModel.fromMap(ParseHelpers.parseMap(item)));
      }
    }

    final rawAddress = ParseHelpers.parseMap(map['shippingAddress']);
    final shippingAddress = AddressModel.fromMap(
      rawAddress,
      ParseHelpers.parseString(rawAddress['id']),
    );

    return OrderModel(
      id: id,
      customerId: ParseHelpers.parseString(map['customerId']),
      customerName: ParseHelpers.parseString(map['customerName']),
      customerEmail: ParseHelpers.parseString(map['customerEmail']),
      customerPhone: ParseHelpers.parseString(map['customerPhone']),
      items: items,
      shippingAddress: shippingAddress,
      subtotal: ParseHelpers.parseDouble(map['subtotal']),
      gstAmount: ParseHelpers.parseDouble(map['gstAmount']),
      deliveryFee: ParseHelpers.parseDouble(map['deliveryFee']),
      totalAmount: ParseHelpers.parseDouble(map['totalAmount']),
      status: OrderStatus.fromString(map['status']?.toString()),
      paymentMethod: ParseHelpers.parseString(map['paymentMethod'], 'UPI_QR'),
      utrNumber: map['utrNumber']?.toString(),
      paymentScreenshotUrl: map['paymentScreenshotUrl']?.toString(),
      paymentRejectionReason: map['paymentRejectionReason']?.toString(),
      merchantId: ParseHelpers.parseNullableString(
        map['merchantId'] ?? map['sellerId'] ?? map['adminId'],
      ),
      createdAt: ParseHelpers.parseDateTime(map['createdAt']),
      updatedAt: ParseHelpers.parseDateTime(map['updatedAt']),
      verifiedAt: ParseHelpers.parseNullableDateTime(map['verifiedAt']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'customerId': customerId,
      'customerName': customerName,
      'customerEmail': customerEmail,
      'customerPhone': customerPhone,
      'items': items.map((e) => e.toMap()).toList(),
      'shippingAddress': shippingAddress.toMap(),
      'subtotal': subtotal,
      'gstAmount': gstAmount,
      'deliveryFee': deliveryFee,
      'totalAmount': totalAmount,
      'status': status.toDbString(),
      'paymentMethod': paymentMethod,
      'utrNumber': utrNumber,
      'paymentScreenshotUrl': paymentScreenshotUrl,
      'paymentRejectionReason': paymentRejectionReason,
      'merchantId': merchantId,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'verifiedAt': verifiedAt?.toIso8601String(),
    };
  }

  OrderModel copyWith({
    OrderStatus? status,
    String? utrNumber,
    String? paymentScreenshotUrl,
    String? paymentRejectionReason,
    String? merchantId,
    DateTime? verifiedAt,
  }) {
    return OrderModel(
      id: id,
      customerId: customerId,
      customerName: customerName,
      customerEmail: customerEmail,
      customerPhone: customerPhone,
      items: items,
      shippingAddress: shippingAddress,
      subtotal: subtotal,
      gstAmount: gstAmount,
      deliveryFee: deliveryFee,
      totalAmount: totalAmount,
      status: status ?? this.status,
      paymentMethod: paymentMethod,
      utrNumber: utrNumber ?? this.utrNumber,
      paymentScreenshotUrl: paymentScreenshotUrl ?? this.paymentScreenshotUrl,
      paymentRejectionReason: paymentRejectionReason ?? this.paymentRejectionReason,
      merchantId: merchantId ?? this.merchantId,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
      verifiedAt: verifiedAt ?? this.verifiedAt,
    );
  }
}
