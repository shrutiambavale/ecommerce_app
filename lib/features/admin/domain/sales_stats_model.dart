import '../../orders/domain/order_model.dart';

class SalesStatsModel {
  final int totalOrders;
  final int totalCustomers;
  final int totalProducts;
  final int pendingPaymentVerifications;
  final double totalVerifiedSales;
  final List<OrderModel> recentOrders;

  const SalesStatsModel({
    required this.totalOrders,
    required this.totalCustomers,
    required this.totalProducts,
    required this.pendingPaymentVerifications,
    required this.totalVerifiedSales,
    required this.recentOrders,
  });

  factory SalesStatsModel.empty() {
    return const SalesStatsModel(
      totalOrders: 0,
      totalCustomers: 0,
      totalProducts: 0,
      pendingPaymentVerifications: 0,
      totalVerifiedSales: 0.0,
      recentOrders: [],
    );
  }
}
