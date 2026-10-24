class AppConstants {
  AppConstants._();

  static const String appName = 'LuxeStore';
  static const String appTagline = 'Premium Everyday Essentials';

  // Financial & Cart Configurations
  static const double gstPercentage = 18.0; // 18% standard GST
  static const double standardDeliveryFee = 49.0; // INR 49
  static const double freeDeliveryThreshold = 999.0; // Free delivery above INR 999

  // Order Expiration & Locks
  static const int pendingPaymentTimeoutMinutes = 60;

  // Firebase Collections
  static const String usersCollection = 'users';
  static const String categoriesCollection = 'categories';
  static const String productsCollection = 'products';
  static const String cartsCollection = 'carts';
  static const String addressesCollection = 'addresses';
  static const String ordersCollection = 'orders';
  static const String paymentSubmissionsCollection = 'payment_submissions';
  static const String paymentSettingsCollection = 'payment_settings';
  static const String auditLogsCollection = 'audit_logs';

  // Firebase Storage Paths
  static const String productImagesPath = 'product_images';
  static const String qrImagesPath = 'payment_qr';
  static const String paymentReceiptsPath = 'payment_receipts';
  static const String userAvatarsPath = 'user_avatars';
}
