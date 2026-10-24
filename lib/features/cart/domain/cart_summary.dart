import '../../../core/constants/app_constants.dart';
import 'cart_item_model.dart';

class CartSummary {
  final double subtotal;
  final double gstPercentage;
  final double gstAmount;
  final double deliveryFee;
  final double totalAmount;
  final int totalItems;
  final double amountForFreeDelivery;
  final bool isFreeDelivery;

  const CartSummary({
    required this.subtotal,
    required this.gstPercentage,
    required this.gstAmount,
    required this.deliveryFee,
    required this.totalAmount,
    required this.totalItems,
    required this.amountForFreeDelivery,
    required this.isFreeDelivery,
  });

  factory CartSummary.calculate(
    List<CartItemModel> items, {
    double gstPercentage = AppConstants.gstPercentage,
    double standardDeliveryFee = AppConstants.standardDeliveryFee,
    double freeDeliveryThreshold = AppConstants.freeDeliveryThreshold,
  }) {
    if (items.isEmpty) {
      return CartSummary(
        subtotal: 0.0,
        gstPercentage: gstPercentage,
        gstAmount: 0.0,
        deliveryFee: 0.0,
        totalAmount: 0.0,
        totalItems: 0,
        amountForFreeDelivery: freeDeliveryThreshold,
        isFreeDelivery: false,
      );
    }

    double subtotal = 0.0;
    int totalItems = 0;

    for (final item in items) {
      subtotal += item.totalPrice;
      totalItems += item.quantity;
    }

    final double gstAmount = double.parse(
      ((subtotal * gstPercentage) / 100.0).toStringAsFixed(2),
    );

    final bool isFreeDelivery = subtotal >= freeDeliveryThreshold;
    final double deliveryFee = isFreeDelivery ? 0.0 : standardDeliveryFee;
    final double totalAmount = double.parse(
      (subtotal + gstAmount + deliveryFee).toStringAsFixed(2),
    );
    final double amountForFreeDelivery = isFreeDelivery
        ? 0.0
        : double.parse((freeDeliveryThreshold - subtotal).toStringAsFixed(2));

    return CartSummary(
      subtotal: subtotal,
      gstPercentage: gstPercentage,
      gstAmount: gstAmount,
      deliveryFee: deliveryFee,
      totalAmount: totalAmount,
      totalItems: totalItems,
      amountForFreeDelivery: amountForFreeDelivery,
      isFreeDelivery: isFreeDelivery,
    );
  }
}
