import 'package:ecommerce_app/core/utils/parse_helpers.dart';
import 'package:ecommerce_app/features/orders/domain/order_model.dart';
import 'package:ecommerce_app/features/products/domain/product_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ParseHelpers and Resilient Deserialization Unit Tests', () {
    test('ParseHelpers.parseDouble parses numbers and string numbers gracefully', () {
      expect(ParseHelpers.parseDouble(100), 100.0);
      expect(ParseHelpers.parseDouble(99.95), 99.95);
      expect(ParseHelpers.parseDouble('4999'), 4999.0);
      expect(ParseHelpers.parseDouble(' 1299.50 '), 1299.50);
      expect(ParseHelpers.parseDouble(null, 50.0), 50.0);
      expect(ParseHelpers.parseDouble('invalid_string', 10.0), 10.0);
    });

    test('ParseHelpers.parseInt parses numbers and string integers gracefully', () {
      expect(ParseHelpers.parseInt(50), 50);
      expect(ParseHelpers.parseInt(45.9), 45);
      expect(ParseHelpers.parseInt('25'), 25);
      expect(ParseHelpers.parseInt(null, 1), 1);
      expect(ParseHelpers.parseInt('invalid', 0), 0);
    });

    test('ParseHelpers.parseBool parses bool, string, and numbers', () {
      expect(ParseHelpers.parseBool(true), true);
      expect(ParseHelpers.parseBool(false), false);
      expect(ParseHelpers.parseBool('true'), true);
      expect(ParseHelpers.parseBool('TRUE'), true);
      expect(ParseHelpers.parseBool('false'), false);
      expect(ParseHelpers.parseBool(1), true);
      expect(ParseHelpers.parseBool(0), false);
      expect(ParseHelpers.parseBool(null, false), false);
    });

    test('ParseHelpers.parseStringList handles Lists and single strings', () {
      expect(ParseHelpers.parseStringList(['a', 'b']), ['a', 'b']);
      expect(ParseHelpers.parseStringList('single_url'), ['single_url']);
      expect(ParseHelpers.parseStringList(null), []);
    });

    test('ProductModel.fromMap correctly parses string numeric fields without crashing', () {
      // Simulates real Firestore document where numbers were stored as strings
      final firestoreData = {
        'name': 'Wireless Headphones',
        'description': 'Premium sound',
        'categoryId': 'cat_audio',
        'categoryName': 'Audio',
        'sellingPrice': '4999.0', // String from Firestore!
        'originalPrice': '5999', // String from Firestore!
        'stockQuantity': '15', // String from Firestore!
        'images': ['https://example.com/img.jpg'],
        'isFeatured': 'true',
        'isActive': 1,
        'createdAt': '2026-10-24T12:00:00Z',
        'updatedAt': '2026-10-24T12:30:00Z',
      };

      final product = ProductModel.fromMap(firestoreData, 'prod_test_01');

      expect(product.id, 'prod_test_01');
      expect(product.sellingPrice, 4999.0);
      expect(product.originalPrice, 5999.0);
      expect(product.stockQuantity, 15);
      expect(product.isFeatured, true);
      expect(product.isActive, true);
    });

    test('OrderModel.fromMap parses nested dynamic maps and string prices', () {
      final firestoreOrderData = {
        'customerId': 'cust_01',
        'customerName': 'Test Customer',
        'customerEmail': 'test@example.com',
        'customerPhone': '9876543210',
        'items': [
          {
            'productId': 'prod_01',
            'productName': 'Item 1',
            'productImage': 'https://example.com/item.jpg',
            'unitPrice': '999.0',
            'quantity': '2',
          }
        ],
        'shippingAddress': {
          'id': 'addr_01',
          'userId': 'cust_01',
          'fullName': 'Test Customer',
          'phoneNumber': '9876543210',
          'streetAddress': '123 Test St',
          'landmark': 'Near Park',
          'city': 'Mumbai',
          'state': 'Maharashtra',
          'pinCode': '400001',
          'isDefault': 'true',
        },
        'subtotal': '1998.0',
        'gstAmount': '359.64',
        'deliveryFee': '0',
        'totalAmount': '2357.64',
        'status': 'payment_pending',
        'paymentMethod': 'UPI_QR',
        'createdAt': '2026-10-24T10:00:00Z',
        'updatedAt': '2026-10-24T10:05:00Z',
      };

      final order = OrderModel.fromMap(firestoreOrderData, 'ord_test_01');

      expect(order.id, 'ord_test_01');
      expect(order.subtotal, 1998.0);
      expect(order.totalAmount, 2357.64);
      expect(order.items.length, 1);
      expect(order.items.first.unitPrice, 999.0);
      expect(order.items.first.quantity, 2);
      expect(order.shippingAddress.isDefault, true);
    });
  });
}
