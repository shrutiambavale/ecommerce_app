import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/confirmation_dialog.dart';
import '../../../core/widgets/empty_state_view.dart';
import '../../products/domain/category_model.dart';
import '../../products/presentation/product_provider.dart';

class AdminCategoriesScreen extends ConsumerWidget {
  const AdminCategoriesScreen({super.key});

  Future<void> _showCategoryDialog(
    BuildContext context,
    WidgetRef ref, {
    CategoryModel? existing,
  }) async {
    final nameController =
        TextEditingController(text: existing?.name ?? '');
    final formKey = GlobalKey<FormState>();

    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(existing == null ? 'Add Category' : 'Edit Category'),
        content: Form(
          key: formKey,
          child: TextFormField(
            controller: nameController,
            autofocus: true,
            validator: (val) {
              if (val == null || val.trim().isEmpty) {
                return 'Category name is required';
              }
              return null;
            },
            decoration: const InputDecoration(
              labelText: 'Category Name',
              hintText: 'e.g. Footwear, Watches',
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                Navigator.pop(context, nameController.text.trim());
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (result != null && result.isNotEmpty) {
      final slug = result.toLowerCase().replaceAll(RegExp(r'\s+'), '_');
      final category = CategoryModel(
        id: existing?.id ?? 'cat_${DateTime.now().millisecondsSinceEpoch}',
        name: result,
        slug: slug,
        productCount: existing?.productCount ?? 0,
        createdAt: existing?.createdAt ?? DateTime.now(),
      );

      await ref
          .read(productAdminControllerProvider.notifier)
          .saveCategory(category, isNew: existing == null);
    }
  }

  Future<void> _deleteCategory(
    BuildContext context,
    WidgetRef ref,
    CategoryModel category,
  ) async {
    final confirm = await ConfirmationDialog.show(
      context,
      title: 'Delete Category?',
      message:
          'Are you sure you want to remove "${category.name}"? Products under this category should be reassigned.',
      confirmText: 'Delete',
      confirmColor: AppColors.error,
    );

    if (confirm == true) {
      await ref
          .read(productAdminControllerProvider.notifier)
          .deleteCategory(category.id);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoriesAsync = ref.watch(categoriesStreamProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Category Management'),
      ),
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.add),
        label: const Text('Add Category'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        onPressed: () => _showCategoryDialog(context, ref),
      ),
      body: categoriesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Error: $err')),
        data: (categories) {
          if (categories.isEmpty) {
            return const EmptyStateView(
              icon: Icons.category_outlined,
              title: 'No Categories',
              message: 'Add product categories to organize your store.',
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
            itemCount: categories.length,
            separatorBuilder: (context, index) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final cat = categories[index];

              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceVariant,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.category_rounded,
                        color: AppColors.primary,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 14),

                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            cat.name,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Slug: ${cat.slug} • ${cat.productCount} products',
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textTertiary,
                            ),
                          ),
                        ],
                      ),
                    ),

                    IconButton(
                      icon: const Icon(Icons.edit_outlined, size: 20),
                      onPressed: () =>
                          _showCategoryDialog(context, ref, existing: cat),
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.delete_outline_rounded,
                        size: 20,
                        color: AppColors.error,
                      ),
                      onPressed: () => _deleteCategory(context, ref, cat),
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
