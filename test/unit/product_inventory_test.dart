import 'package:ecommerce_app/features/cart/domain/cart_item_model.dart';
import 'package:ecommerce_app/features/products/data/product_repository.dart';
import 'package:ecommerce_app/features/products/domain/product_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Product and Inventory Unit Tests', () {
    test('Product stock getters evaluate accurately', () {
      final productInStock = ProductModel(
        id: 'p1',
        name: 'Item 1',
        description: 'Desc',
        categoryId: 'c1',
        categoryName: 'Cat',
        sellingPrice: 100.0,
        originalPrice: 150.0,
        stockQuantity: 10,
        images: ['https://example.com/p.jpg'],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      expect(productInStock.inStock, true);
      expect(productInStock.isLowStock, false);
      expect(productInStock.discountPercentage, 33);

      final productLowStock = productInStock.copyWith(stockQuantity: 3);
      expect(productLowStock.inStock, true);
      expect(productLowStock.isLowStock, true);

      final productOutOfStock = productInStock.copyWith(stockQuantity: 0);
      expect(productOutOfStock.inStock, false);
      expect(productOutOfStock.isLowStock, false);
    });

    test('Atomic stock deduction prevents negative stock', () async {
      final repo = ProductRepository();

      await repo.addProduct(
        ProductModel(
          id: 'prod_001',
          name: 'Test Product 1',
          description: 'Testing stock deduction',
          categoryId: 'cat_electronics',
          categoryName: 'Electronics',
          sellingPrice: 1000.0,
          originalPrice: 1200.0,
          stockQuantity: 10,
          images: ['https://example.com/test.jpg'],
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
        ownerId: 'admin_test',
      );

      // Check initial stock of prod_001
      final p1 = await repo.getProductById('prod_001');
      expect(p1, isNotNull);
      final initialStock = p1!.stockQuantity;

      // Deduct valid quantity
      final item = CartItemModel(
        productId: 'prod_001',
        productName: p1.name,
        productImage: p1.primaryImage,
        unitPrice: p1.sellingPrice,
        quantity: 2,
        availableStock: initialStock,
      );

      final success = await repo.checkAndDeductStock([item]);
      expect(success, true);

      final p1After = await repo.getProductById('prod_001');
      expect(p1After!.stockQuantity, initialStock - 2);

      // Attempt to deduct more than remaining stock -> must throw exception
      final excessiveItem = item.copyWith(quantity: 99999);
      expect(
        () async => await repo.checkAndDeductStock([excessiveItem]),
        throwsA(isA<String>()),
      );
    });
  });
}
