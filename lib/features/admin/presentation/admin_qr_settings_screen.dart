import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/app_cached_image.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../core/widgets/custom_text_field.dart';
import '../../auth/presentation/auth_provider.dart';
import '../../payment/domain/payment_settings_model.dart';
import '../../payment/presentation/payment_provider.dart';

class AdminQrSettingsScreen extends ConsumerStatefulWidget {
  const AdminQrSettingsScreen({super.key});

  @override
  ConsumerState<AdminQrSettingsScreen> createState() =>
      _AdminQrSettingsScreenState();
}

class _AdminQrSettingsScreenState extends ConsumerState<AdminQrSettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _imagePicker = ImagePicker();

  late TextEditingController _upiIdController;
  late TextEditingController _receiverController;
  late TextEditingController _instructionsController;

  Uint8List? _newQrBytes;
  String? _newQrFileName;
  String _currentQrUrl = '';
  bool _isSaving = false;
  bool _isInitialized = false;
  String? _loadedAdminId;

  @override
  void initState() {
    super.initState();
    final defaultSettings = PaymentSettingsModel.defaultSettings();
    _upiIdController = TextEditingController(text: defaultSettings.upiId);
    _receiverController =
        TextEditingController(text: defaultSettings.receiverName);
    _instructionsController =
        TextEditingController(text: defaultSettings.instructions);
    _currentQrUrl = defaultSettings.qrImageUrl;
  }

  @override
  void dispose() {
    _upiIdController.dispose();
    _receiverController.dispose();
    _instructionsController.dispose();
    super.dispose();
  }

  void _syncWithSettings(PaymentSettingsModel settings) {
    if (_isInitialized && _loadedAdminId == settings.ownerId) return;
    _upiIdController.text = settings.upiId;
    _receiverController.text = settings.receiverName;
    _instructionsController.text = settings.instructions;
    _currentQrUrl = settings.qrImageUrl;
    _loadedAdminId = settings.ownerId;
    _isInitialized = true;
  }

  Future<void> _pickNewQrImage() async {
    try {
      final file = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1000,
        imageQuality: 90,
      );
      if (file != null) {
        final bytes = await file.readAsBytes();
        setState(() {
          _newQrBytes = bytes;
          _newQrFileName = file.name;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to pick QR image: $e')),
        );
      }
    }
  }

  Future<void> _saveSettings() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      String finalQrUrl = _currentQrUrl;

      if (_newQrBytes != null) {
        final uploadedUrl = await ref
            .read(paymentControllerProvider.notifier)
            .uploadQrImage(_newQrBytes!, _newQrFileName ?? 'upi_qr.jpg');

        if (uploadedUrl != null) {
          finalQrUrl = uploadedUrl;
        }
      }

      final user = ref.read(currentUserProvider);
      final updated = PaymentSettingsModel(
        upiId: _upiIdController.text.trim(),
        receiverName: _receiverController.text.trim(),
        qrImageUrl: finalQrUrl,
        instructions: _instructionsController.text.trim(),
        updatedAt: DateTime.now(),
        updatedBy: user?.fullName ?? 'Admin',
        ownerId: user?.id,
      );

      final success = await ref
          .read(paymentControllerProvider.notifier)
          .updateSettings(updated);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              success
                  ? 'UPI QR payment configuration saved successfully!'
                  : 'Failed to save payment configuration.',
            ),
            backgroundColor: success ? AppColors.success : AppColors.error,
          ),
        );
        if (success) {
          setState(() {
            _currentQrUrl = finalQrUrl;
            _newQrBytes = null;
          });
        }
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final settingsAsync = ref.watch(paymentSettingsProvider);

    if (settingsAsync.hasValue) {
      _syncWithSettings(settingsAsync.value!);
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('UPI QR Configuration'),
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
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                  const Text(
                    'Merchant UPI QR Code',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Upload your store official UPI QR code image from your gallery. This will be shown to customers during checkout.',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // QR Code Preview Box
                  Center(
                    child: Container(
                      width: 220,
                      height: 220,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.border, width: 1.5),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.04),
                            blurRadius: 10,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: _newQrBytes != null
                          ? Image.memory(_newQrBytes!, fit: BoxFit.contain)
                          : AppCachedImage(
                              imageUrl: _currentQrUrl,
                              fit: BoxFit.contain,
                              placeholderIcon: Icons.qr_code_2_rounded,
                            ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      OutlinedButton.icon(
                        icon: const Icon(Icons.upload_file_rounded, size: 18),
                        label: Text(_currentQrUrl.isNotEmpty
                            ? 'Replace QR Code'
                            : 'Upload QR Image'),
                        onPressed: _pickNewQrImage,
                      ),
                      if (_currentQrUrl.isNotEmpty || _newQrBytes != null) ...[
                        const SizedBox(width: 10),
                        TextButton(
                          onPressed: () {
                            setState(() {
                              _newQrBytes = null;
                              _currentQrUrl = '';
                            });
                          },
                          style: TextButton.styleFrom(
                            foregroundColor: AppColors.error,
                          ),
                          child: const Text('Remove Image'),
                        ),
                      ],
                    ],
                  ),

                  const SizedBox(height: 24),
                  const Divider(),
                  const SizedBox(height: 20),

                  // UPI ID
                  CustomTextField(
                    label: 'Merchant UPI ID *',
                    hint: 'e.g. yourstore@okhdfcbank',
                    controller: _upiIdController,
                    prefixIcon: const Icon(Icons.alternate_email_rounded, size: 20),
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) {
                        return 'UPI ID is required';
                      }
                      if (!val.contains('@')) {
                        return 'Enter a valid UPI ID (e.g. name@bank)';
                      }
                      return null;
                    },
                  ),

                  const SizedBox(height: 16),

                  // Receiver Name
                  CustomTextField(
                    label: 'Payment Receiver Name *',
                    hint: 'e.g. LuxeStore Essentials Pvt Ltd',
                    controller: _receiverController,
                    prefixIcon: const Icon(Icons.business_rounded, size: 20),
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) {
                        return 'Receiver name is required';
                      }
                      return null;
                    },
                  ),

                  const SizedBox(height: 16),

                  // Payment Instructions
                  CustomTextField(
                    label: 'Payment Instructions for Customer *',
                    hint: 'Step by step instructions for the customer...',
                    controller: _instructionsController,
                    maxLines: 5,
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) {
                        return 'Instructions are required';
                      }
                      return null;
                    },
                  ),

                  const SizedBox(height: 28),

                  CustomButton(
                    text: 'Save Payment Configuration',
                    icon: Icons.save_rounded,
                    isLoading: _isSaving,
                    onPressed: _saveSettings,
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
