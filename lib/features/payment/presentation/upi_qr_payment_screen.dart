import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/app_cached_image.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../core/widgets/custom_text_field.dart';
import '../../orders/domain/order_model.dart';
import '../../orders/presentation/order_provider.dart';
import '../domain/payment_settings_model.dart';
import 'payment_provider.dart';
import 'payment_status_screen.dart';

class UpiQrPaymentScreen extends ConsumerStatefulWidget {
  final OrderModel order;

  const UpiQrPaymentScreen({super.key, required this.order});

  @override
  ConsumerState<UpiQrPaymentScreen> createState() => _UpiQrPaymentScreenState();
}

class _UpiQrPaymentScreenState extends ConsumerState<UpiQrPaymentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _utrController = TextEditingController();
  final _imagePicker = ImagePicker();

  Uint8List? _screenshotBytes;
  String? _screenshotFileName;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _utrController.dispose();
    super.dispose();
  }

  Future<void> _pickScreenshot(ImageSource source) async {
    try {
      final file = await _imagePicker.pickImage(
        source: source,
        maxWidth: 1600,
        imageQuality: 85,
      );
      if (file != null) {
        final bytes = await file.readAsBytes();
        setState(() {
          _screenshotBytes = bytes;
          _screenshotFileName = file.name;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to pick screenshot: $e')),
        );
      }
    }
  }

  Future<void> _submitVerification() async {
    if (_formKey.currentState?.validate() != true) return;

    setState(() => _isSubmitting = true);

    try {
      String? screenshotUrl;
      if (_screenshotBytes != null) {
        screenshotUrl = await ref
            .read(paymentControllerProvider.notifier)
            .uploadScreenshot(
              _screenshotBytes!,
              _screenshotFileName ?? 'screenshot.jpg',
            );
      }

      final success = await ref
          .read(orderControllerProvider.notifier)
          .submitPaymentProof(
            orderId: widget.order.id,
            utrNumber: _utrController.text.trim(),
            screenshotUrl: screenshotUrl,
            customerId: widget.order.customerId,
            customerName: widget.order.customerName,
            amount: widget.order.totalAmount,
          );

      if (success && mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => PaymentStatusScreen(
              orderId: widget.order.id,
              totalAmount: widget.order.totalAmount,
              utrNumber: _utrController.text.trim(),
            ),
          ),
        );
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to submit verification. Please try again.'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final settingsAsync =
        ref.watch(merchantPaymentSettingsProvider(widget.order.merchantId));
    final settings = settingsAsync.valueOrNull ??
        PaymentSettingsModel.defaultSettings(widget.order.merchantId);
    final upiId = settings.upiId;
    final receiver = settings.receiverName;
    final instructions = settings.instructions;
    final qrUrl = settings.qrImageUrl;

    // Dynamically encode exact payee UPI ID and exact order amount into QR payload
    final dynamicUpiString = settings.buildUpiUri(
      amount: widget.order.totalAmount,
      orderId: widget.order.id,
    );
    final effectiveQrUrl = qrUrl.isNotEmpty
        ? qrUrl
        : 'https://api.qrserver.com/v1/create-qr-code/?size=300x300&data=${Uri.encodeComponent(dynamicUpiString)}';

    return Scaffold(
      appBar: AppBar(
        title: const Text('UPI QR Payment'),
      ),
      body: Column(
        children: [
          if (settingsAsync.isLoading)
            const LinearProgressIndicator(minHeight: 2),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                  // Order Details Banner
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Column(
                      children: [
                        Text(
                          'Order ID: ${widget.order.id}',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Exact Amount to Pay',
                          style: TextStyle(
                            fontSize: 13,
                            color: AppColors.textTertiary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          CurrencyFormatter.format(widget.order.totalAmount),
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w800,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // UPI QR Code Card
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.border, width: 1.5),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.04),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        // Official UPI Badges
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
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
                              child: const Text(
                                'BHIM UPI',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              'Scan with any UPI App',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 16),

                        // QR Code Image
                        Container(
                          width: 220,
                          height: 220,
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: AppCachedImage(
                            imageUrl: effectiveQrUrl,
                            fit: BoxFit.contain,
                            placeholderIcon: Icons.qr_code_2_rounded,
                          ),
                        ),

                        const SizedBox(height: 16),

                        // Payee Details & Copy
                        Text(
                          receiver,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceVariant,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                upiId,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(width: 8),
                              InkWell(
                                onTap: () {
                                  Clipboard.setData(ClipboardData(text: upiId));
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('UPI ID copied to clipboard!'),
                                      duration: Duration(milliseconds: 1400),
                                    ),
                                  );
                                },
                                child: const Icon(
                                  Icons.copy_rounded,
                                  size: 16,
                                  color: AppColors.accent,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Payment Instructions Card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.infoBackground,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppColors.info.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.info_outline_rounded,
                                size: 18, color: AppColors.info),
                            SizedBox(width: 8),
                            Text(
                              'Payment Instructions',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: AppColors.info,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          instructions,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Verification Form Section
                  Container(
                    width: double.infinity,
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
                          'Payment Proof & Verification',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 14),

                        // UTR Input
                        CustomTextField(
                          label: '12-Digit UPI Reference / UTR Number *',
                          hint: 'e.g. 429810829103',
                          controller: _utrController,
                          keyboardType: TextInputType.text,
                          prefixIcon: const Icon(Icons.receipt_long_outlined, size: 20),
                          validator: Validators.validateUtrNumber,
                        ),

                        const SizedBox(height: 16),

                        // Screenshot Upload (Optional)
                        const Text(
                          'Payment Screenshot (Optional)',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 8),

                        if (_screenshotBytes != null)
                          Stack(
                            alignment: Alignment.topRight,
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: Image.memory(
                                  _screenshotBytes!,
                                  width: double.infinity,
                                  height: 140,
                                  fit: BoxFit.cover,
                                ),
                              ),
                              IconButton(
                                icon: const CircleAvatar(
                                  radius: 14,
                                  backgroundColor: Colors.black54,
                                  child: Icon(Icons.close, size: 16, color: Colors.white),
                                ),
                                onPressed: () {
                                  setState(() {
                                    _screenshotBytes = null;
                                    _screenshotFileName = null;
                                  });
                                },
                              ),
                            ],
                          )
                        else
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton.icon(
                                  icon: const Icon(Icons.photo_library_outlined, size: 18),
                                  label: const Text('Choose from Gallery'),
                                  onPressed: () =>
                                      _pickScreenshot(ImageSource.gallery),
                                ),
                              ),
                              const SizedBox(width: 10),
                              IconButton.outlined(
                                icon: const Icon(Icons.camera_alt_outlined, size: 18),
                                tooltip: 'Take Photo',
                                onPressed: () =>
                                    _pickScreenshot(ImageSource.camera),
                              ),
                            ],
                          ),

                        const SizedBox(height: 24),

                        // Submit Button
                        CustomButton(
                          text: 'Submit Payment for Verification',
                          icon: Icons.send_rounded,
                          isLoading: _isSubmitting,
                          onPressed: _submitVerification,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 30),
                ],
              ),
            ),
          ),
        ),
      ],
    ),
  );
}
}
