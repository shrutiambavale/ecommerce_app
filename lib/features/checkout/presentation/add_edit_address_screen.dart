import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../core/widgets/custom_text_field.dart';
import '../../auth/presentation/auth_provider.dart';
import '../domain/address_model.dart';
import 'address_provider.dart';

class AddEditAddressScreen extends ConsumerStatefulWidget {
  final AddressModel? existingAddress;

  const AddEditAddressScreen({super.key, this.existingAddress});

  @override
  ConsumerState<AddEditAddressScreen> createState() =>
      _AddEditAddressScreenState();
}

class _AddEditAddressScreenState extends ConsumerState<AddEditAddressScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _streetController;
  late TextEditingController _landmarkController;
  late TextEditingController _cityController;
  late TextEditingController _stateController;
  late TextEditingController _pinController;
  bool _isDefault = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final addr = widget.existingAddress;
    final currentUser = ref.read(currentUserProvider);

    _nameController = TextEditingController(
      text: addr?.fullName ?? currentUser?.fullName ?? '',
    );
    _phoneController = TextEditingController(
      text: addr?.phoneNumber ?? currentUser?.phoneNumber ?? '',
    );
    _streetController = TextEditingController(text: addr?.streetAddress ?? '');
    _landmarkController = TextEditingController(text: addr?.landmark ?? '');
    _cityController = TextEditingController(text: addr?.city ?? '');
    _stateController = TextEditingController(text: addr?.state ?? '');
    _pinController = TextEditingController(text: addr?.pinCode ?? '');
    _isDefault = addr?.isDefault ?? true;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _streetController.dispose();
    _landmarkController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _pinController.dispose();
    super.dispose();
  }

  Future<void> _saveAddress() async {
    if (_formKey.currentState?.validate() != true) return;

    setState(() => _isLoading = true);
    final user = ref.read(currentUserProvider);
    final userId = user?.id ?? 'customer_001';

    final addressId = widget.existingAddress?.id ??
        'addr_${DateTime.now().millisecondsSinceEpoch}';

    final address = AddressModel(
      id: addressId,
      userId: userId,
      fullName: _nameController.text.trim(),
      phoneNumber: _phoneController.text.trim(),
      streetAddress: _streetController.text.trim(),
      landmark: _landmarkController.text.trim(),
      city: _cityController.text.trim(),
      state: _stateController.text.trim(),
      pinCode: _pinController.text.trim(),
      isDefault: _isDefault,
    );

    final success = await ref
        .read(addressControllerProvider.notifier)
        .saveAddress(userId, address, isNew: widget.existingAddress == null);

    setState(() => _isLoading = false);

    if (success && mounted) {
      ref.read(selectedAddressProvider.notifier).state = address;
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.existingAddress != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Address' : 'Add Delivery Address'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CustomTextField(
                label: 'Full Name',
                hint: 'e.g. Rahul Sharma',
                controller: _nameController,
                validator: (val) => Validators.validateName(val, fieldName: 'Full Name'),
              ),
              const SizedBox(height: 16),
              CustomTextField(
                label: 'Phone Number',
                hint: '10-digit mobile number',
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                validator: Validators.validatePhone,
              ),
              const SizedBox(height: 16),
              CustomTextField(
                label: 'Flat, House No., Building, Street',
                hint: 'e.g. Flat 402, Signature Palms, 100ft Road',
                controller: _streetController,
                maxLines: 2,
                validator: (val) => Validators.validateRequired(val, 'Street Address'),
              ),
              const SizedBox(height: 16),
              CustomTextField(
                label: 'Landmark (Optional)',
                hint: 'e.g. Opposite Metro Station',
                controller: _landmarkController,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: CustomTextField(
                      label: 'City',
                      hint: 'e.g. Bengaluru',
                      controller: _cityController,
                      validator: (val) => Validators.validateRequired(val, 'City'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: CustomTextField(
                      label: 'State',
                      hint: 'e.g. Karnataka',
                      controller: _stateController,
                      validator: (val) => Validators.validateRequired(val, 'State'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              CustomTextField(
                label: 'Postal PIN Code',
                hint: '6-digit PIN code',
                controller: _pinController,
                keyboardType: TextInputType.number,
                validator: Validators.validatePinCode,
              ),
              const SizedBox(height: 16),
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                activeColor: AppColors.primary,
                value: _isDefault,
                title: const Text(
                  'Set as default delivery address',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                onChanged: (val) {
                  setState(() => _isDefault = val ?? false);
                },
              ),
              const SizedBox(height: 28),
              CustomButton(
                text: isEditing ? 'Update Address' : 'Save Address',
                isLoading: _isLoading,
                onPressed: _saveAddress,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
