import 'package:ecommerce_app/features/products/domain/product_model.dart';
import 'package:ecommerce_app/features/products/presentation/widgets/product_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('ProductCard displays title, category, and price correctly', (WidgetTester tester) async {
    final product = ProductModel(
      id: 'test_1',
      name: 'Wireless Pro Headphones',
      description: 'Noise cancelling test item',
      categoryId: 'cat_electronics',
      categoryName: 'Electronics',
      sellingPrice: 4999.0,
      originalPrice: 6999.0,
      stockQuantity: 15,
      images: ['https://example.com/test.jpg'],
      isFeatured: true,
      isActive: true,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 200,
              height: 300,
              child: ProductCard(product: product),
            ),
          ),
        ),
      ),
    );

    // Verify product name and category
    expect(find.text('Wireless Pro Headphones'), findsOneWidget);
    expect(find.text('ELECTRONICS'), findsOneWidget);
    // Verify discount badge (-29% OFF)
    expect(find.text('29% OFF'), findsOneWidget);
  });
}
