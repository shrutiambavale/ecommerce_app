import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/widgets/app_cached_image.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../core/widgets/error_state_view.dart';
import '../../../core/widgets/loading_view.dart';
import '../../cart/presentation/cart_provider.dart';
import '../../cart/presentation/cart_screen.dart';
import '../../checkout/presentation/checkout_screen.dart';
import 'product_provider.dart';

class ProductDetailScreen extends ConsumerStatefulWidget {
  final String productId;

  const ProductDetailScreen({super.key, required this.productId});

  @override
  ConsumerState<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends ConsumerState<ProductDetailScreen> {
  int _selectedImageIndex = 0;
  int _quantity = 1;

  @override
  Widget build(BuildContext context) {
    final productAsync = ref.watch(productDetailProvider(widget.productId));
    final cartItemCount = ref.watch(cartItemCountProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Product Details'),
        actions: [
          Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.shopping_bag_outlined),
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (context) => const CartScreen()),
                  );
                },
              ),
              if (cartItemCount > 0)
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: AppColors.accent,
                      shape: BoxShape.circle,
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 16,
                      minHeight: 16,
                    ),
                    child: Text(
                      '$cartItemCount',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: productAsync.when(
        loading: () => const LoadingView(message: 'Loading product details...'),
        error: (err, _) => ErrorStateView(
          message: err.toString(),
          onRetry: () => ref.refresh(productDetailProvider(widget.productId)),
        ),
        data: (product) {
          if (product == null) {
            return const ErrorStateView(
              title: 'Product Not Found',
              message: 'This product may have been removed or is unavailable.',
            );
          }

          final images = product.images.isNotEmpty
              ? product.images
              : ['https://images.unsplash.com/photo-1505740420928-5e560c06d30e?w=800&q=80'];

          return Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Image Gallery
                      SizedBox(
                        height: 320,
                        child: Stack(
                          children: [
                            PageView.builder(
                              itemCount: images.length,
                              onPageChanged: (index) {
                                setState(() {
                                  _selectedImageIndex = index;
                                });
                              },
                              itemBuilder: (context, index) {
                                return AppCachedImage(
                                  imageUrl: images[index],
                                  fit: BoxFit.cover,
                                  width: double.infinity,
                                );
                              },
                            ),
                            if (images.length > 1)
                              Positioned(
                                bottom: 16,
                                left: 0,
                                right: 0,
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: List.generate(
                                    images.length,
                                    (index) => Container(
                                      width: _selectedImageIndex == index ? 20 : 6,
                                      height: 6,
                                      margin: const EdgeInsets.symmetric(horizontal: 3),
                                      decoration: BoxDecoration(
                                        color: _selectedImageIndex == index
                                            ? AppColors.primary
                                            : AppColors.textTertiary.withValues(alpha: 0.5),
                                        borderRadius: BorderRadius.circular(3),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            if (product.discountPercentage > 0)
                              Positioned(
                                top: 16,
                                left: 16,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 5,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.error,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    '${product.discountPercentage}% OFF',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),

                      Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Category & Stock Status
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.surfaceVariant,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    product.categoryName.toUpperCase(),
                                    style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.textSecondary,
                                      letterSpacing: 0.8,
                                    ),
                                  ),
                                ),
                                if (product.inStock)
                                  Row(
                                    children: [
                                      Container(
                                        width: 8,
                                        height: 8,
                                        decoration: const BoxDecoration(
                                          color: AppColors.success,
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        'In Stock (${product.stockQuantity})',
                                        style: const TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: AppColors.success,
                                        ),
                                      ),
                                    ],
                                  )
                                else
                                  const Text(
                                    'Out of Stock',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.error,
                                    ),
                                  ),
                              ],
                            ),

                            const SizedBox(height: 12),

                            // Product Name
                            Text(
                              product.name,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                                color: AppColors.textPrimary,
                                height: 1.3,
                              ),
                            ),

                            const SizedBox(height: 16),

                            // Pricing Row
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.baseline,
                              textBaseline: TextBaseline.alphabetic,
                              children: [
                                Text(
                                  CurrencyFormatter.format(product.sellingPrice),
                                  style: const TextStyle(
                                    fontSize: 26,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                if (product.originalPrice > product.sellingPrice) ...[
                                  const SizedBox(width: 10),
                                  Text(
                                    CurrencyFormatter.format(product.originalPrice),
                                    style: const TextStyle(
                                      fontSize: 16,
                                      color: AppColors.textTertiary,
                                      decoration: TextDecoration.lineThrough,
                                    ),
                                  ),
                                ],
                              ],
                            ),

                            const SizedBox(height: 20),
                            const Divider(),
                            const SizedBox(height: 16),

                            // Quantity Selector
                            if (product.inStock) ...[
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    'Select Quantity',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                  Container(
                                    decoration: BoxDecoration(
                                      border: Border.all(color: AppColors.border),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Row(
                                      children: [
                                        IconButton(
                                          icon: const Icon(Icons.remove, size: 18),
                                          onPressed: _quantity > 1
                                              ? () => setState(() => _quantity--)
                                              : null,
                                        ),
                                        Text(
                                          '$_quantity',
                                          style: const TextStyle(
                                            fontSize: 15,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.add, size: 18),
                                          onPressed: _quantity < product.stockQuantity
                                              ? () => setState(() => _quantity++)
                                              : null,
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 20),
                              const Divider(),
                              const SizedBox(height: 16),
                            ],

                            // Description
                            const Text(
                              'Product Description',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              product.description,
                              style: const TextStyle(
                                fontSize: 14,
                                color: AppColors.textSecondary,
                                height: 1.6,
                              ),
                            ),
                            const SizedBox(height: 30),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Bottom Sticky Action Bar
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.06),
                      blurRadius: 10,
                      offset: const Offset(0, -4),
                    ),
                  ],
                ),
                child: SafeArea(
                  top: false,
                  child: Row(
                    children: [
                      Expanded(
                        child: CustomButton(
                          text: 'Add to Cart',
                          variant: ButtonVariant.outline,
                          icon: Icons.add_shopping_cart_rounded,
                          onPressed: product.inStock
                              ? () {
                                  ref
                                      .read(cartControllerProvider.notifier)
                                      .addToCart(product, quantity: _quantity);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        '$_quantity x ${product.name} added to cart',
                                      ),
                                      behavior: SnackBarBehavior.floating,
                                      action: SnackBarAction(
                                        label: 'VIEW CART',
                                        textColor: Colors.white,
                                        onPressed: () {
                                          Navigator.of(context).push(
                                            MaterialPageRoute(
                                              builder: (context) => const CartScreen(),
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                  );
                                }
                              : null,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: CustomButton(
                          text: 'Buy Now',
                          icon: Icons.flash_on_rounded,
                          onPressed: product.inStock
                              ? () async {
                                  await ref
                                      .read(cartControllerProvider.notifier)
                                      .addToCart(product, quantity: _quantity);
                                  if (context.mounted) {
                                    Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (context) => const CheckoutScreen(),
                                      ),
                                    );
                                  }
                                }
                              : null,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
