import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/domain/user_model.dart';
import '../../auth/presentation/auth_provider.dart';
import '../../orders/presentation/order_provider.dart';
import '../../products/presentation/product_provider.dart';
import '../data/admin_repository.dart';
import '../domain/sales_stats_model.dart';

final adminRepositoryProvider = Provider<AdminRepository>((ref) {
  final orderRepo = ref.watch(orderRepositoryProvider);
  final productRepo = ref.watch(productRepositoryProvider);
  final authRepo = ref.watch(authRepositoryProvider);

  return AdminRepository(
    orderRepository: orderRepo,
    productRepository: productRepo,
    authRepository: authRepo,
  );
});

final adminStatsProvider = StreamProvider<SalesStatsModel>((ref) {
  final repo = ref.watch(adminRepositoryProvider);
  final user = ref.watch(currentUserProvider);
  return repo.getSalesStats(adminId: user?.id);
});

final allCustomersProvider = FutureProvider<List<UserModel>>((ref) {
  final repo = ref.watch(authRepositoryProvider);
  return repo.getAllCustomers();
});
