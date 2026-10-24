import 'package:ecommerce_app/features/cart/data/cart_repository.dart';
import 'package:ecommerce_app/features/cart/domain/cart_item_model.dart';
import 'package:ecommerce_app/features/checkout/data/address_repository.dart';
import 'package:ecommerce_app/features/checkout/domain/address_model.dart';
import 'package:ecommerce_app/features/orders/domain/order_model.dart';
import 'package:ecommerce_app/features/orders/domain/order_status.dart';
import 'package:ecommerce_app/features/payment/data/payment_repository.dart';
import 'package:ecommerce_app/features/payment/domain/payment_settings_model.dart';
import 'package:ecommerce_app/features/products/data/product_repository.dart';
import 'package:ecommerce_app/features/products/domain/product_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Phase 9: Account-Wise Data Isolation and Security Tests', () {
    late ProductRepository productRepo;
    late PaymentRepository paymentRepo;
    late CartRepository cartRepo;
    late AddressRepository addressRepo;

    setUp(() {
      productRepo = ProductRepository();
      paymentRepo = PaymentRepository();
      cartRepo = CartRepository();
      addressRepo = AddressRepository();
    });

    tearDown(() {
      productRepo.dispose();
      paymentRepo.dispose();
      cartRepo.dispose();
      addressRepo.dispose();
    });

    // 1. Product Isolation Tests
    test('1 & 2: Two separate admins create and manage products independently with strict isolation', () async {
      const adminA = 'admin_alpha_101';
      const adminB = 'admin_beta_202';

      // Admin A creates a product
      final productA = ProductModel(
        id: 'prod_alpha_01',
        name: 'Alpha Camera',
        description: 'Alpha Sony DSLR',
        categoryId: 'cat_electronics',
        categoryName: 'Electronics',
        sellingPrice: 55000.0,
        originalPrice: 60000.0,
        stockQuantity: 15,
        images: ['https://example.com/alpha.jpg'],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      await productRepo.addProduct(productA, ownerId: adminA);

      // Admin B creates a product
      final productB = ProductModel(
        id: 'prod_beta_01',
        name: 'Beta Headphones',
        description: 'Beta Noise Cancelling',
        categoryId: 'cat_electronics',
        categoryName: 'Electronics',
        sellingPrice: 12000.0,
        originalPrice: 15000.0,
        stockQuantity: 25,
        images: ['https://example.com/beta.jpg'],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      await productRepo.addProduct(productB, ownerId: adminB);

      // Admin A queries their products
      final adminAProducts = await productRepo.getProductsForOwnerOnce(adminA);
      expect(adminAProducts.any((p) => p.id == 'prod_alpha_01'), isTrue);
      expect(adminAProducts.any((p) => p.id == 'prod_beta_01'), isFalse,
          reason: "Admin B's product must NOT be visible in Admin A's management section");

      // Admin B queries their products
      final adminBProducts = await productRepo.getProductsForOwnerOnce(adminB);
      expect(adminBProducts.any((p) => p.id == 'prod_beta_01'), isTrue);
      expect(adminBProducts.any((p) => p.id == 'prod_alpha_01'), isFalse,
          reason: "Admin A's product must NOT be visible in Admin B's management section");
    });

    test('3 & 4: Unauthorized cross-account update and delete requests are rejected', () async {
      const adminA = 'admin_alpha_101';
      const adminB = 'admin_beta_202';

      final productA = ProductModel(
        id: 'prod_alpha_secure',
        name: 'Alpha Secure Gadget',
        description: 'Confidential product',
        categoryId: 'cat_electronics',
        categoryName: 'Electronics',
        sellingPrice: 2000.0,
        originalPrice: 2500.0,
        stockQuantity: 5,
        images: ['https://example.com/gadget.jpg'],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      await productRepo.addProduct(productA, ownerId: adminA);

      // Admin B tries to update Admin A's product -> MUST throw unauthorized exception
      final hackedProduct = productA.copyWith(name: 'Defaced Product Name');
      expect(
        () async => await productRepo.updateProduct(hackedProduct, ownerId: adminB),
        throwsA(predicate((e) => e.toString().contains('Unauthorized'))),
        reason: 'Cross-account product update must be blocked',
      );

      // Admin B tries to delete Admin A's product -> MUST throw unauthorized exception
      expect(
        () async => await productRepo.deleteProduct('prod_alpha_secure', ownerId: adminB),
        throwsA(predicate((e) => e.toString().contains('Unauthorized'))),
        reason: 'Cross-account product delete must be blocked',
      );

      // Verify product was not modified
      final verifiedProd = await productRepo.getProductById('prod_alpha_secure');
      expect(verifiedProd!.name, 'Alpha Secure Gadget');

      // Admin A (legitimate owner) can successfully update their product
      final validUpdate = productA.copyWith(name: 'Alpha Secure Gadget V2');
      await productRepo.updateProduct(validUpdate, ownerId: adminA);
      final updatedProd = await productRepo.getProductById('prod_alpha_secure');
      expect(updatedProd!.name, 'Alpha Secure Gadget V2');
    });

    // 2. UPI & Payment Settings Isolation Tests
    test('UPI Isolation: Admin A and Admin B save isolated UPI IDs without cross-account overwrite', () async {
      const adminA = 'admin_alpha_101';
      const adminB = 'admin_beta_202';

      // Admin A saves UPI ID A
      final settingsA = PaymentSettingsModel(
        upiId: 'merchant.alpha@okaxis',
        receiverName: 'Alpha Store Pvt Ltd',
        qrImageUrl: 'https://example.com/qr_alpha.png',
        instructions: 'Please enter Order ID in remarks',
        ownerId: adminA,
        updatedAt: DateTime.now(),
      );
      await paymentRepo.updatePaymentSettings(settingsA, adminId: adminA);

      // Admin B saves UPI ID B
      final settingsB = PaymentSettingsModel(
        upiId: 'merchant.beta@okhdfcbank',
        receiverName: 'Beta Retail Ventures',
        qrImageUrl: 'https://example.com/qr_beta.png',
        instructions: 'Send screenshot on WhatsApp',
        ownerId: adminB,
        updatedAt: DateTime.now(),
      );
      await paymentRepo.updatePaymentSettings(settingsB, adminId: adminB);

      // Verify Admin A retrieves only settings A
      final loadedA = await paymentRepo.getPaymentSettingsOnce(adminId: adminA);
      expect(loadedA.upiId, 'merchant.alpha@okaxis');
      expect(loadedA.receiverName, 'Alpha Store Pvt Ltd');
      expect(loadedA.ownerId, adminA);

      // Verify Admin B retrieves only settings B
      final loadedB = await paymentRepo.getPaymentSettingsOnce(adminId: adminB);
      expect(loadedB.upiId, 'merchant.beta@okhdfcbank');
      expect(loadedB.receiverName, 'Beta Retail Ventures');
      expect(loadedB.ownerId, adminB);

      // Re-verifying Admin A confirms Admin B did not overwrite Admin A
      final reloadedA = await paymentRepo.getPaymentSettingsOnce(adminId: adminA);
      expect(reloadedA.upiId, 'merchant.alpha@okaxis');
      expect(reloadedA.upiId, isNot(loadedB.upiId));
    });

    test('UPI URL Generation: Encodes exact payee UPI ID, order amount, and reference', () {
      final settings = PaymentSettingsModel(
        upiId: 'merchant.alpha@okaxis',
        receiverName: 'Alpha Store',
        qrImageUrl: '',
        instructions: '',
        updatedAt: DateTime.now(),
      );

      final totalAmount = 1499.50;
      final orderId = 'ORD-2026-9988';

      final uri = settings.buildUpiUri(
        amount: totalAmount,
        orderId: orderId,
        note: 'Order $orderId',
      );

      expect(uri, contains('pa=merchant.alpha%40okaxis'));
      expect(uri, contains('pn=Alpha%20Store'));
      expect(uri, contains('am=1499.50'));
      expect(uri, contains('cu=INR'));
      expect(uri, contains('tn=Order%20ORD-2026-9988'));
    });

    // 3. Cache and Account Switching Tests
    test('5: Account switching and logout wipes in-memory cart and prevents data leakage', () async {
      const userA = 'user_alice_101';
      const userB = 'user_bob_202';

      // User A logs in and adds items to cart
      cartRepo.setUserId(userA);
      await cartRepo.addItem(const CartItemModel(
        productId: 'prod_001',
        productName: 'Secret Item Alice',
        productImage: 'https://example.com/img.jpg',
        unitPrice: 500.0,
        quantity: 3,
        availableStock: 10,
        ownerId: 'admin_alpha_101',
      ));

      expect(cartRepo.currentItems.length, 1);
      expect(cartRepo.currentItems.first.productName, 'Secret Item Alice');

      // User A logs out
      cartRepo.setUserId(null);
      expect(cartRepo.currentItems.isEmpty, isTrue,
          reason: 'Cart must be immediately emptied upon user logout');

      // User B logs in
      cartRepo.setUserId(userB);
      expect(cartRepo.currentItems.isEmpty, isTrue,
          reason: "User B must NOT see User A's previous in-memory cart items");
    });

    test('Address isolation prevents cross-account address leaks', () async {
      const userA = 'user_alice_101';
      const userB = 'user_bob_202';

      // User A adds an address
      final addrA = AddressModel(
        id: 'addr_alice_01',
        userId: userA,
        fullName: 'Alice Smith',
        phoneNumber: '9876543210',
        streetAddress: '123 Baker Street',
        city: 'Mumbai',
        state: 'Maharashtra',
        pinCode: '400001',
        isDefault: true,
      );
      await addressRepo.addAddress(userA, addrA);

      final addressesA = await addressRepo.getAddressesOnce(userA);
      expect(addressesA.any((a) => a.id == 'addr_alice_01'), isTrue);

      // User B should have an empty address list initially
      final addressesB = await addressRepo.getAddressesOnce(userB);
      expect(addressesB.any((a) => a.id == 'addr_alice_01'), isFalse,
          reason: "User B must NOT see User A's private addresses");
    });

    // 4. Order IDOR Protection
    test('Order model stores merchantId and frozen ownerId in order items', () {
      final order = OrderModel(
        id: 'ord_123',
        customerId: 'customer_alice',
        customerName: 'Alice',
        customerEmail: 'alice@example.com',
        customerPhone: '9876543210',
        merchantId: 'admin_alpha_101',
        shippingAddress: const AddressModel(
          id: 'addr_1',
          userId: 'customer_alice',
          fullName: 'Alice',
          phoneNumber: '9876543210',
          streetAddress: 'Road 1',
          city: 'Delhi',
          state: 'Delhi',
          pinCode: '110001',
        ),
        items: const [
          OrderItemModel(
            productId: 'prod_001',
            productName: 'Camera',
            productImage: 'https://example.com/cam.jpg',
            unitPrice: 50000.0,
            quantity: 1,
            ownerId: 'admin_alpha_101',
          ),
        ],
        subtotal: 50000.0,
        gstAmount: 0.0,
        deliveryFee: 0.0,
        totalAmount: 50000.0,
        paymentMethod: 'UPI_QR',
        status: OrderStatus.pendingPayment,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final map = order.toMap();
      expect(map['merchantId'], 'admin_alpha_101');
      expect(map['customerId'], 'customer_alice');
      final itemsMap = map['items'] as List;
      expect(itemsMap.first['ownerId'], 'admin_alpha_101');

      // Test deserialization preserves merchantId
      final deserialized = OrderModel.fromMap(map, 'ord_123');
      expect(deserialized.merchantId, 'admin_alpha_101');
      expect(deserialized.items.first.ownerId, 'admin_alpha_101');
    });
  });
}
