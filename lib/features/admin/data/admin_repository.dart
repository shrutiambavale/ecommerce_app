import '../../auth/data/auth_repository.dart';
import '../../orders/data/order_repository.dart';
import '../../orders/domain/order_status.dart';
import '../../products/data/product_repository.dart';
import '../domain/sales_stats_model.dart';

class AdminRepository {
  final OrderRepository _orderRepository;
  final ProductRepository _productRepository;
  final AuthRepository _authRepository;

  AdminRepository({
    required OrderRepository orderRepository,
    required ProductRepository productRepository,
    required AuthRepository authRepository,
  })  : _orderRepository = orderRepository,
        _productRepository = productRepository,
        _authRepository = authRepository;

  Stream<SalesStatsModel> getSalesStats({String? adminId}) {
    return _orderRepository.getAllOrders().asyncMap((orders) async {
      final products = adminId != null
          ? await _productRepository.getProductsForOwnerOnce(adminId)
          : await _productRepository.getAllProductsOnce();
      final customers = await _authRepository.getAllCustomers();

      int pendingVerifications = 0;
      double totalVerifiedSales = 0.0;

      for (final order in orders) {
        if (order.status == OrderStatus.paymentVerificationPending) {
          pendingVerifications++;
        }
        // Only count sales where payment has been verified or order delivered/shipped/processing
        if (order.status == OrderStatus.paymentVerified ||
            order.status == OrderStatus.processing ||
            order.status == OrderStatus.shipped ||
            order.status == OrderStatus.delivered) {
          totalVerifiedSales += order.totalAmount;
        }
      }

      final recentOrders = orders.take(5).toList();

      return SalesStatsModel(
        totalOrders: orders.length,
        totalCustomers: customers.length,
        totalProducts: products.length,
        pendingPaymentVerifications: pendingVerifications,
        totalVerifiedSales: double.parse(totalVerifiedSales.toStringAsFixed(2)),
        recentOrders: recentOrders,
      );
    });
  }

  Future<SalesStatsModel> getSalesStatsOnce() async {
    final orders = await _orderRepository.getAllOrdersOnce();
    final products = await _productRepository.getAllProductsOnce();
    final customers = await _authRepository.getAllCustomers();

    int pendingVerifications = 0;
    double totalVerifiedSales = 0.0;

    for (final order in orders) {
      if (order.status == OrderStatus.paymentVerificationPending) {
        pendingVerifications++;
      }
      if (order.status == OrderStatus.paymentVerified ||
          order.status == OrderStatus.processing ||
          order.status == OrderStatus.shipped ||
          order.status == OrderStatus.delivered) {
        totalVerifiedSales += order.totalAmount;
      }
    }

    final recentOrders = orders.take(5).toList();

    return SalesStatsModel(
      totalOrders: orders.length,
      totalCustomers: customers.length,
      totalProducts: products.length,
      pendingPaymentVerifications: pendingVerifications,
      totalVerifiedSales: double.parse(totalVerifiedSales.toStringAsFixed(2)),
      recentOrders: recentOrders,
    );
  }
}
