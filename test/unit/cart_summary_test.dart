import 'package:ecommerce_app/features/cart/domain/cart_item_model.dart';
import 'package:ecommerce_app/features/cart/domain/cart_summary.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('CartSummary Calculations Unit Tests', () {
    test('Empty cart returns 0 totals and standard delivery fee threshold', () {
      final summary = CartSummary.calculate([]);

      expect(summary.subtotal, 0.0);
      expect(summary.gstAmount, 0.0);
      expect(summary.deliveryFee, 0.0);
      expect(summary.totalAmount, 0.0);
      expect(summary.totalItems, 0);
      expect(summary.isFreeDelivery, false);
      expect(summary.amountForFreeDelivery, 999.0);
    });

    test('Single item below free delivery threshold applies standard delivery fee', () {
      final items = [
        const CartItemModel(
          productId: 'prod_1',
          productName: 'T-Shirt',
          productImage: 'https://example.com/item.jpg',
          unitPrice: 500.0,
          quantity: 1,
          availableStock: 10,
        ),
      ];

      final summary = CartSummary.calculate(items);

      expect(summary.subtotal, 500.0);
      expect(summary.totalItems, 1);
      // 18% of 500 = 90.0
      expect(summary.gstAmount, 90.0);
      // Standard delivery fee = 49.0
      expect(summary.deliveryFee, 49.0);
      // Total = 500 + 90 + 49 = 639.0
      expect(summary.totalAmount, 639.0);
      expect(summary.isFreeDelivery, false);
      // Remaining for free delivery = 999 - 500 = 499.0
      expect(summary.amountForFreeDelivery, 499.0);
    });

    test('Items reaching or exceeding threshold get free delivery', () {
      final items = [
        const CartItemModel(
          productId: 'prod_1',
          productName: 'Headphones',
          productImage: 'https://example.com/headphones.jpg',
          unitPrice: 2000.0,
          quantity: 1,
          availableStock: 5,
        ),
        const CartItemModel(
          productId: 'prod_2',
          productName: 'Cable',
          productImage: 'https://example.com/cable.jpg',
          unitPrice: 300.0,
          quantity: 2,
          availableStock: 20,
        ),
      ];

      final summary = CartSummary.calculate(items);

      // Subtotal = 2000 + (300 * 2) = 2600.0
      expect(summary.subtotal, 2600.0);
      expect(summary.totalItems, 3);
      // 18% of 2600 = 468.0
      expect(summary.gstAmount, 468.0);
      // Free delivery because subtotal >= 999
      expect(summary.deliveryFee, 0.0);
      expect(summary.isFreeDelivery, true);
      // Total = 2600 + 468 + 0 = 3068.0
      expect(summary.totalAmount, 3068.0);
      expect(summary.amountForFreeDelivery, 0.0);
    });
  });
}
