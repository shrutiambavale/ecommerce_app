import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/widgets/app_cached_image.dart';
import '../../../core/widgets/confirmation_dialog.dart';
import '../../../core/widgets/empty_state_view.dart';
import '../../products/domain/product_model.dart';
import '../../products/presentation/product_provider.dart';
import 'admin_product_edit_screen.dart';

class AdminProductsScreen extends ConsumerWidget {
  const AdminProductsScreen({super.key});

  Future<void> _updateQuickStock(
    BuildContext context,
    WidgetRef ref,
    ProductModel product,
  ) async {
    final controller =
        TextEditingController(text: product.stockQuantity.toString());

    final newStockStr = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Adjust Stock for ${product.name}'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'New Stock Quantity',
            hintText: 'e.g. 25',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text('Save Stock'),
          ),
        ],
      ),
    );

    if (newStockStr != null && newStockStr.isNotEmpty) {
      final stockVal = int.tryParse(newStockStr);
      if (stockVal != null && stockVal >= 0) {
        await ref
            .read(productAdminControllerProvider.notifier)
            .updateStock(product.id, stockVal);
      }
    }
  }

  Future<void> _deleteProduct(
    BuildContext context,
    WidgetRef ref,
    ProductModel product,
  ) async {
    final confirm = await ConfirmationDialog.show(
      context,
      title: 'Delete Product?',
      message: 'Are you sure you want to remove "${product.name}" from catalog?',
      confirmText: 'Delete',
      confirmColor: AppColors.error,
    );

    if (confirm == true) {
      await ref
          .read(productAdminControllerProvider.notifier)
          .deleteProduct(product.id);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final productsAsync = ref.watch(adminProductsStreamProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Inventory & Products'),
      ),
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.add),
        label: const Text('Add Product'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => const AdminProductEditScreen(),
            ),
          );
        },
      ),
      body: productsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Error: $err')),
        data: (products) {
          if (products.isEmpty) {
            return const EmptyStateView(
              icon: Icons.inventory_2_outlined,
              title: 'No Products Yet',
              message: 'Add products to start selling in your store.',
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
            itemCount: products.length,
            separatorBuilder: (context, index) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final product = products[index];

              return Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    AppCachedImage(
                      imageUrl: product.primaryImage,
                      width: 68,
                      height: 68,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    const SizedBox(width: 14),

                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Wrap(
                            spacing: 6,
                            runSpacing: 4,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.surfaceVariant,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  product.categoryName.toUpperCase(),
                                  style: const TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ),
                              if (product.isFeatured)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.warningBackground,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: const Text(
                                    'FEATURED',
                                    style: TextStyle(
                                      fontSize: 9,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.warning,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            product.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Wrap(
                            spacing: 8,
                            runSpacing: 4,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              Text(
                                CurrencyFormatter.format(product.sellingPrice),
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.primary,
                                ),
                              ),
                              GestureDetector(
                                onTap: () =>
                                    _updateQuickStock(context, ref, product),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: product.stockQuantity <= 5
                                        ? AppColors.errorBackground
                                        : AppColors.successBackground,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    'Stock: ${product.stockQuantity}',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: product.stockQuantity <= 5
                                          ? AppColors.error
                                          : AppColors.success,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    // Actions
                    IconButton(
                      icon: const Icon(Icons.edit_outlined, size: 19),
                      padding: const EdgeInsets.all(4),
                      constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => AdminProductEditScreen(
                              product: product,
                            ),
                          ),
                        );
                      },
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.delete_outline_rounded,
                        size: 19,
                        color: AppColors.error,
                      ),
                      padding: const EdgeInsets.all(4),
                      constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                      onPressed: () => _deleteProduct(context, ref, product),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
