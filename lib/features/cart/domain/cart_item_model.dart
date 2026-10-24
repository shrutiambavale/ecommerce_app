import '../../../core/utils/parse_helpers.dart';

class CartItemModel {
  final String productId;
  final String productName;
  final String productImage;
  final double unitPrice;
  final int quantity;
  final int availableStock;
  final String? ownerId;

  const CartItemModel({
    required this.productId,
    required this.productName,
    required this.productImage,
    required this.unitPrice,
    required this.quantity,
    required this.availableStock,
    this.ownerId,
  });

  double get totalPrice => unitPrice * quantity;

  factory CartItemModel.fromMap(Map<String, dynamic> map) {
    return CartItemModel(
      productId: ParseHelpers.parseString(map['productId']),
      productName: ParseHelpers.parseString(map['productName']),
      productImage: ParseHelpers.parseString(map['productImage']),
      unitPrice: ParseHelpers.parseDouble(map['unitPrice']),
      quantity: ParseHelpers.parseInt(map['quantity'], 1),
      availableStock: ParseHelpers.parseInt(map['availableStock'], 999),
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
      'availableStock': availableStock,
      'ownerId': ownerId,
    };
  }

  CartItemModel copyWith({
    int? quantity,
    int? availableStock,
    double? unitPrice,
    String? ownerId,
  }) {
    return CartItemModel(
      productId: productId,
      productName: productName,
      productImage: productImage,
      unitPrice: unitPrice ?? this.unitPrice,
      quantity: quantity ?? this.quantity,
      availableStock: availableStock ?? this.availableStock,
      ownerId: ownerId ?? this.ownerId,
    );
  }
}
