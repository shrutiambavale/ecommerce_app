import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../core/widgets/status_badge.dart';
import '../../customer/presentation/customer_main_nav_screen.dart';
import '../../orders/domain/order_status.dart';
import '../../orders/presentation/order_details_screen.dart';

class PaymentStatusScreen extends StatelessWidget {
  final String orderId;
  final double totalAmount;
  final String utrNumber;

  const PaymentStatusScreen({
    super.key,
    required this.orderId,
    required this.totalAmount,
    required this.utrNumber,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('Payment Submitted'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(),

              // Verification Pending Icon
              Container(
                width: 90,
                height: 90,
                decoration: const BoxDecoration(
                  color: Color(0xFFF3E8FF), // Purple 100
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.hourglass_top_rounded,
                  size: 48,
                  color: AppColors.statusPendingVerification,
                ),
              ),

              const SizedBox(height: 24),

              const Text(
                'Payment Under Verification',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),

              const SizedBox(height: 10),

              const Text(
                'Your payment details have been submitted. Our admin team will verify the transaction with our bank and update your order fulfillment status.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                  height: 1.5,
                ),
              ),

              const SizedBox(height: 24),

              // Summary Card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  children: [
                    _buildRow('Order ID', orderId),
                    const Divider(height: 16),
                    _buildRow(
                      'Amount Paid',
                      CurrencyFormatter.format(totalAmount),
                      isHighlight: true,
                    ),
                    const Divider(height: 16),
                    _buildRow('Submitted UTR', utrNumber),
                    const Divider(height: 16),
                    const Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            'Payment Status',
                            style: TextStyle(
                              fontSize: 13,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ),
                        SizedBox(width: 8),
                        StatusBadge(
                          status: OrderStatus.paymentVerificationPending,
                          fontSize: 11,
                          useShortName: true,
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const Spacer(),

              CustomButton(
                text: 'Track Order Status',
                icon: Icons.timeline_rounded,
                onPressed: () {
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(
                      builder: (context) => OrderDetailsScreen(orderId: orderId),
                    ),
                  );
                },
              ),

              const SizedBox(height: 12),

              CustomButton(
                text: 'Continue Shopping',
                variant: ButtonVariant.outline,
                onPressed: () {
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(
                      builder: (context) => const CustomerMainNavScreen(),
                    ),
                    (route) => false,
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRow(String label, String value, {bool isHighlight = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            color: AppColors.textSecondary,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            fontWeight: isHighlight ? FontWeight.w800 : FontWeight.w600,
            color: isHighlight ? AppColors.primary : AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}
