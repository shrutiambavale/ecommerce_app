import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/widgets/app_cached_image.dart';
import '../../../core/widgets/custom_button.dart';
import '../../auth/domain/user_model.dart';
import '../../auth/domain/user_role.dart';
import '../../auth/presentation/auth_provider.dart';
import '../../cart/presentation/cart_provider.dart';
import '../../orders/presentation/order_provider.dart';
import '../../payment/presentation/upi_qr_payment_screen.dart';
import 'add_edit_address_screen.dart';
import 'address_provider.dart';

class CheckoutScreen extends ConsumerStatefulWidget {
  const CheckoutScreen({super.key});

  @override
  ConsumerState<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends ConsumerState<CheckoutScreen> {
  bool _isPlacingOrder = false;

  @override
  Widget build(BuildContext context) {
    final cartItemsAsync = ref.watch(cartItemsProvider);
    final summary = ref.watch(cartSummaryProvider);
    final addressesAsync = ref.watch(userAddressesProvider);
    final selectedAddress = ref.watch(selectedAddressProvider);
    final currentUser = ref.watch(currentUserProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Checkout & Review'),
      ),
      body: cartItemsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Error: $err')),
        data: (items) {
          if (items.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('No items in cart to checkout.'),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Back to Store'),
                  ),
                ],
              ),
            );
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Delivery Address Section
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Delivery Address',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    TextButton.icon(
                      icon: const Icon(Icons.add, size: 16),
                      label: const Text('Add New'),
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => const AddEditAddressScreen(),
                          ),
                        );
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                addressesAsync.when(
                  loading: () => const LinearProgressIndicator(),
                  error: (e, _) => Text('Failed to load addresses: $e'),
                  data: (addresses) {
                    if (addresses.isEmpty) {
                      return Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.warningBackground,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.warning),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.location_off_rounded,
                                color: AppColors.warning),
                            const SizedBox(width: 12),
                            const Expanded(
                              child: Text(
                                'No address saved. Please add a delivery address to proceed.',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ),
                            TextButton(
                              onPressed: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        const AddEditAddressScreen(),
                                  ),
                                );
                              },
                              child: const Text('Add'),
                            ),
                          ],
                        ),
                      );
                    }

                    return Column(
                      children: addresses.map((addr) {
                        final isSelected = selectedAddress?.id == addr.id;
                        return GestureDetector(
                          onTap: () {
                            ref.read(selectedAddressProvider.notifier).state = addr;
                          },
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isSelected
                                    ? AppColors.primary
                                    : AppColors.border,
                                width: isSelected ? 2 : 1,
                              ),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(
                                  isSelected
                                      ? Icons.radio_button_checked
                                      : Icons.radio_button_off,
                                  color: isSelected
                                      ? AppColors.primary
                                      : AppColors.textTertiary,
                                  size: 20,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Flexible(
                                            child: Text(
                                              addr.fullName,
                                              overflow: TextOverflow.ellipsis,
                                              style: const TextStyle(
                                                fontSize: 14,
                                                fontWeight: FontWeight.w700,
                                                color: AppColors.textPrimary,
                                              ),
                                            ),
                                          ),
                                          if (addr.isDefault) ...[
                                            const SizedBox(width: 8),
                                            Container(
                                              padding: const EdgeInsets.symmetric(
                                                horizontal: 6,
                                                vertical: 2,
                                              ),
                                              decoration: BoxDecoration(
                                                color: AppColors.surfaceVariant,
                                                borderRadius:
                                                    BorderRadius.circular(4),
                                              ),
                                              child: const Text(
                                                'DEFAULT',
                                                style: TextStyle(
                                                  fontSize: 9,
                                                  fontWeight: FontWeight.w700,
                                                  color: AppColors.textSecondary,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        addr.fullAddress,
                                        style: const TextStyle(
                                          fontSize: 13,
                                          color: AppColors.textSecondary,
                                          height: 1.3,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Mobile: ${addr.phoneNumber}',
                                        style: const TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w500,
                                          color: AppColors.textTertiary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    );
                  },
                ),

                const SizedBox(height: 24),

                // 2. Ordered Products Review
                const Text(
                  'Order Items Review',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 12),

                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Column(
                    children: items.map((item) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Row(
                          children: [
                            AppCachedImage(
                              imageUrl: item.productImage,
                              width: 50,
                              height: 50,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item.productName,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Qty: ${item.quantity} x ${CurrencyFormatter.format(item.unitPrice)}',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              CurrencyFormatter.format(item.totalPrice),
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),

                const SizedBox(height: 24),

                // 3. Complete Price Breakdown
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Payment Summary',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _buildSummaryRow('Items Subtotal', summary.subtotal),
                      const SizedBox(height: 8),
                      _buildSummaryRow(
                        'GST (${summary.gstPercentage.toStringAsFixed(0)}%)',
                        summary.gstAmount,
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Expanded(
                            child: Text(
                              'Delivery Charges',
                              style: TextStyle(
                                fontSize: 13,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ),
                          Text(
                            summary.isFreeDelivery
                                ? 'FREE'
                                : CurrencyFormatter.format(summary.deliveryFee),
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: summary.isFreeDelivery
                                  ? AppColors.success
                                  : AppColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 10),
                        child: Divider(),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Expanded(
                            child: Text(
                              'Total Payable Amount',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                          Text(
                            CurrencyFormatter.format(summary.totalAmount),
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // Manual UPI QR Notice
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceVariant,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.qr_code_scanner_rounded,
                          size: 20, color: AppColors.accent),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Payment is processed manually via direct UPI QR scan with independent admin verification.',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                            height: 1.3,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Place Order Button
                CustomButton(
                  text: 'Place Order & Pay with UPI QR',
                  icon: Icons.qr_code_2_rounded,
                  isLoading: _isPlacingOrder,
                  onPressed: () async {
                    if (selectedAddress == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Please select or add a delivery address first.',
                          ),
                          backgroundColor: AppColors.error,
                        ),
                      );
                      return;
                    }

                    setState(() => _isPlacingOrder = true);

                    final messenger = ScaffoldMessenger.of(context);
                    final navigator = Navigator.of(context);

                    final authRepo = ref.read(authRepositoryProvider);
                    final effectiveCustomer = currentUser ??
                        authRepo.currentUser ??
                        UserModel(
                          id: selectedAddress.userId.isNotEmpty
                              ? selectedAddress.userId
                              : 'cust_${DateTime.now().millisecondsSinceEpoch}',
                          email: 'customer@luxestore.com',
                          fullName: selectedAddress.fullName.isNotEmpty
                              ? selectedAddress.fullName
                              : 'Customer',
                          phoneNumber: selectedAddress.phoneNumber,
                          role: UserRole.customer,
                          createdAt: DateTime.now(),
                        );

                    final order =
                        await ref.read(orderControllerProvider.notifier).placeOrder(
                              customer: effectiveCustomer,
                              items: items,
                              shippingAddress: selectedAddress,
                              summary: summary,
                            );

                    if (!mounted) return;
                    setState(() => _isPlacingOrder = false);

                    if (order != null) {
                      // Clear the cart once order is securely recorded
                      await ref.read(cartControllerProvider.notifier).clearCart();
                      if (!mounted) return;

                      // Direct to UPI QR Payment screen
                      navigator.pushReplacement(
                        MaterialPageRoute(
                          builder: (context) =>
                              UpiQrPaymentScreen(order: order),
                        ),
                      );
                    } else {
                      messenger.showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Failed to place order. An item might be out of stock.',
                          ),
                          backgroundColor: AppColors.error,
                        ),
                      );
                    }
                  },
                ),
                const SizedBox(height: 24),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSummaryRow(String label, double amount) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          CurrencyFormatter.format(amount),
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}
