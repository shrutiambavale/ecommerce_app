import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/app_cached_image.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../core/widgets/custom_text_field.dart';
import '../../../core/widgets/empty_state_view.dart';
import '../../auth/presentation/auth_provider.dart';
import '../../products/domain/category_model.dart';
import '../../products/domain/product_model.dart';
import '../../products/presentation/product_provider.dart';

class _LocalImage {
  final Uint8List bytes;
  final String fileName;

  const _LocalImage({required this.bytes, required this.fileName});
}

class AdminProductEditScreen extends ConsumerStatefulWidget {
  final ProductModel? product;

  const AdminProductEditScreen({super.key, this.product});

  @override
  ConsumerState<AdminProductEditScreen> createState() =>
      _AdminProductEditScreenState();
}

class _AdminProductEditScreenState
    extends ConsumerState<AdminProductEditScreen> {
  final _formKey = GlobalKey<FormState>();
  final _picker = ImagePicker();

  late TextEditingController _nameController;
  late TextEditingController _descController;
  late TextEditingController _sellingPriceController;
  late TextEditingController _originalPriceController;
  late TextEditingController _stockController;

  String? _selectedCategoryId;
  String _selectedCategoryName = 'General';
  bool _isFeatured = false;
  bool _isActive = true;
  bool _isSaving = false;
  String? _uploadStatusMessage;

  // Existing remote URLs
  final List<String> _remoteImages = [];
  // Newly picked local images awaiting upload
  final List<_LocalImage> _localImages = [];

  @override
  void initState() {
    super.initState();
    final p = widget.product;
    _nameController = TextEditingController(text: p?.name ?? '');
    _descController = TextEditingController(text: p?.description ?? '');
    _sellingPriceController =
        TextEditingController(text: p != null ? p.sellingPrice.toString() : '');
    _originalPriceController =
        TextEditingController(text: p != null ? p.originalPrice.toString() : '');
    _stockController =
        TextEditingController(text: p?.stockQuantity.toString() ?? '10');

    if (p != null && p.images.isNotEmpty) {
      _remoteImages.addAll(p.images);
    }

    _selectedCategoryId = p?.categoryId;
    _selectedCategoryName = p?.categoryName ?? 'General';
    _isFeatured = p?.isFeatured ?? false;
    _isActive = p?.isActive ?? true;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    _sellingPriceController.dispose();
    _originalPriceController.dispose();
    _stockController.dispose();
    super.dispose();
  }

  int get _totalImagesCount => _remoteImages.length + _localImages.length;

  // Pick multiple images from device gallery
  Future<void> _pickFromGallery() async {
    try {
      final pickedFiles = await _picker.pickMultiImage(
        imageQuality: 85,
        maxWidth: 1600,
        maxHeight: 1600,
      );

      if (pickedFiles.isNotEmpty) {
        for (final file in pickedFiles) {
          final bytes = await file.readAsBytes();
          setState(() {
            _localImages.add(_LocalImage(bytes: bytes, fileName: file.name));
          });
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error selecting images: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  // Take photo with camera
  Future<void> _pickFromCamera() async {
    try {
      final photo = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
        maxWidth: 1600,
        maxHeight: 1600,
      );

      if (photo != null) {
        final bytes = await photo.readAsBytes();
        setState(() {
          _localImages.add(_LocalImage(bytes: bytes, fileName: photo.name));
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Camera error: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  // Enter image URL via dialog
  Future<void> _addImageUrlDialog() async {
    final urlController = TextEditingController();
    final url = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Image URL'),
        content: TextField(
          controller: urlController,
          decoration: const InputDecoration(
            labelText: 'Image Web URL',
            hintText: 'https://images.unsplash.com/...',
            prefixIcon: Icon(Icons.link),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final text = urlController.text.trim();
              if (text.isNotEmpty) {
                Navigator.pop(context, text);
              }
            },
            child: const Text('Add URL'),
          ),
        ],
      ),
    );

    if (url != null && url.isNotEmpty) {
      setState(() => _remoteImages.add(url));
    }
  }

  // Quick category creation
  Future<void> _showAddCategoryDialog() async {
    final nameController = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create New Category'),
        content: TextField(
          controller: nameController,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Category Name',
            hintText: 'e.g. Footwear, Watches',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final text = nameController.text.trim();
              if (text.isNotEmpty) Navigator.pop(context, text);
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );

    if (result != null && result.isNotEmpty) {
      final slug = result.toLowerCase().replaceAll(RegExp(r'\s+'), '_');
      final newCat = CategoryModel(
        id: 'cat_$slug',
        name: result,
        slug: slug,
        createdAt: DateTime.now(),
      );

      final success = await ref
          .read(productAdminControllerProvider.notifier)
          .saveCategory(newCat, isNew: true);

      if (success) {
        setState(() {
          _selectedCategoryId = newCat.id;
          _selectedCategoryName = newCat.name;
        });
      }
    }
  }

  Future<void> _saveProduct() async {
    if (!_formKey.currentState!.validate()) return;

    if (_totalImagesCount == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please upload at least one product photo or image URL.'),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }

    setState(() {
      _isSaving = true;
      _uploadStatusMessage = 'Preparing product assets...';
    });

    try {
      final isNew = widget.product == null;
      final id = widget.product?.id ??
          'prod_${DateTime.now().millisecondsSinceEpoch}';

      final finalImageUrls = <String>[..._remoteImages];

      // Upload local images to Firebase Storage
      if (_localImages.isNotEmpty) {
        for (var i = 0; i < _localImages.length; i++) {
          final local = _localImages[i];
          setState(() {
            _uploadStatusMessage =
                'Uploading image ${i + 1} of ${_localImages.length} to Cloud Storage...';
          });

          final uploadedUrl = await ref
              .read(productAdminControllerProvider.notifier)
              .uploadImage(local.bytes, local.fileName);

          if (uploadedUrl != null && uploadedUrl.isNotEmpty) {
            finalImageUrls.add(uploadedUrl);
          }
        }
      }

      setState(() {
        _uploadStatusMessage = 'Publishing product to store database...';
      });

      final selling = double.parse(_sellingPriceController.text.trim());
      final origStr = _originalPriceController.text.trim();
      final original = origStr.isNotEmpty ? double.parse(origStr) : selling;
      final stock = int.parse(_stockController.text.trim());

      final productToSave = ProductModel(
        id: id,
        name: _nameController.text.trim(),
        description: _descController.text.trim(),
        categoryId: _selectedCategoryId ?? 'cat_electronics',
        categoryName: _selectedCategoryName,
        sellingPrice: selling,
        originalPrice: original,
        stockQuantity: stock,
        images: finalImageUrls.isNotEmpty
            ? finalImageUrls
            : ['https://images.unsplash.com/photo-1523275335684-37898b6baf30?w=800&q=80'],
        ownerId: widget.product?.ownerId,
        isFeatured: _isFeatured,
        isActive: _isActive,
        createdAt: widget.product?.createdAt ?? DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final success = await ref
          .read(productAdminControllerProvider.notifier)
          .saveProduct(productToSave, isNew: isNew);

      setState(() {
        _isSaving = false;
        _uploadStatusMessage = null;
      });

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle_rounded, color: Colors.white),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    isNew
                        ? 'Product "${productToSave.name}" published to live store!'
                        : 'Product "${productToSave.name}" updated successfully!',
                  ),
                ),
              ],
            ),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      setState(() {
        _isSaving = false;
        _uploadStatusMessage = null;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save product: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(categoriesStreamProvider);
    final isEditing = widget.product != null;

    final sellingVal = double.tryParse(_sellingPriceController.text.trim()) ?? 0.0;
    final origVal = double.tryParse(_originalPriceController.text.trim()) ?? 0.0;
    final hasDiscount = origVal > sellingVal && sellingVal > 0;
    final discountPercent = hasDiscount
        ? (((origVal - sellingVal) / origVal) * 100).round()
        : 0;

    final currentUser = ref.watch(currentUserProvider);
    final p = widget.product;
    final isUnauthorized = p != null &&
        p.ownerId != null &&
        currentUser != null &&
        p.ownerId != currentUser.id;

    if (isUnauthorized) {
      return Scaffold(
        appBar: AppBar(title: const Text('Access Denied')),
        body: const Center(
          child: EmptyStateView(
            icon: Icons.lock_outline_rounded,
            title: 'Unauthorized Access',
            message: 'You do not have permission to view or edit products owned by another account.',
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Product' : 'Add New Product'),
        actions: [
          if (!_isSaving)
            TextButton.icon(
              icon: const Icon(Icons.check, color: AppColors.primary),
              label: Text(
                isEditing ? 'Save' : 'Publish',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
              onPressed: _saveProduct,
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.primary.withValues(alpha: 0.08),
                      AppColors.accent.withValues(alpha: 0.05),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.15),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.cloud_upload_outlined,
                        color: AppColors.primary,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isEditing ? 'Update Catalog Product' : 'Upload Product to Store',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                          const SizedBox(height: 2),
                          const Text(
                            'Upload high-quality images and real inventory details.',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Product Photos Section
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Product Photos & Assets',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  Text(
                    '$_totalImagesCount image${_totalImagesCount == 1 ? '' : 's'}',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Photos Carousel / Grid
              if (_totalImagesCount > 0) ...[
                SizedBox(
                  height: 140,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      // Remote Images
                      for (var i = 0; i < _remoteImages.length; i++)
                        _buildImageTile(
                          isCover: i == 0 && _localImages.isEmpty,
                          preview: AppCachedImage(
                            imageUrl: _remoteImages[i],
                            fit: BoxFit.cover,
                            height: 140,
                            width: 130,
                          ),
                          onRemove: () => setState(() => _remoteImages.removeAt(i)),
                          onSetCover: () => setState(() {
                            final item = _remoteImages.removeAt(i);
                            _remoteImages.insert(0, item);
                          }),
                        ),

                      // Local Picked Images
                      for (var j = 0; j < _localImages.length; j++)
                        _buildImageTile(
                          isCover: j == 0 && _remoteImages.isEmpty,
                          preview: Image.memory(
                            _localImages[j].bytes,
                            fit: BoxFit.cover,
                            height: 140,
                            width: 130,
                          ),
                          isLocalNew: true,
                          onRemove: () => setState(() => _localImages.removeAt(j)),
                          onSetCover: () => setState(() {
                            final item = _localImages.removeAt(j);
                            _localImages.insert(0, item);
                          }),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
              ] else ...[
                // Empty State Upload Card
                InkWell(
                  onTap: _pickFromGallery,
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    width: double.infinity,
                    height: 130,
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: AppColors.primary.withValues(alpha: 0.4),
                        style: BorderStyle.solid,
                        width: 1.5,
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.add_photo_alternate_outlined,
                          size: 38,
                          color: AppColors.primary.withValues(alpha: 0.8),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Tap to select photos from device',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        const Text(
                          'Upload multiple photos (JPG, PNG, WebP up to 10MB)',
                          style: TextStyle(
                            fontSize: 11,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 10),
              ],

              // Upload Action Buttons Row
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.photo_library_outlined, size: 18),
                      label: const Text('Gallery'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      onPressed: _pickFromGallery,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.camera_alt_outlined, size: 18),
                      label: const Text('Camera'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      onPressed: _pickFromCamera,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.link_outlined, size: 18),
                      label: const Text('Web URL'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      onPressed: _addImageUrlDialog,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Title Field
              CustomTextField(
                label: 'Product Title',
                hint: 'e.g. Wireless Noise-Cancelling Headphones',
                controller: _nameController,
                validator: (val) => Validators.validateRequired(val, 'Product Title'),
              ),
              const SizedBox(height: 16),

              // Category Selector with quick "+ New Category" button
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Category',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  InkWell(
                    onTap: _showAddCategoryDialog,
                    child: const Padding(
                      padding: EdgeInsets.symmetric(vertical: 2, horizontal: 4),
                      child: Text(
                        '+ New Category',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              categoriesAsync.when(
                loading: () => const LinearProgressIndicator(),
                error: (error, _) => const Text('Error loading categories'),
                data: (categories) {
                  if (categories.isEmpty) {
                    return OutlinedButton.icon(
                      icon: const Icon(Icons.add),
                      label: const Text('Create First Category'),
                      onPressed: _showAddCategoryDialog,
                    );
                  }

                  _selectedCategoryId ??= categories.first.id;

                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        isExpanded: true,
                        value: _selectedCategoryId,
                        items: categories.map((cat) {
                          return DropdownMenuItem<String>(
                            value: cat.id,
                            child: Row(
                              children: [
                                const Icon(Icons.label_outline, size: 16, color: AppColors.primary),
                                const SizedBox(width: 8),
                                Text(cat.name),
                              ],
                            ),
                          );
                        }).toList(),
                        onChanged: (newId) {
                          if (newId != null) {
                            final match =
                                categories.firstWhere((c) => c.id == newId);
                            setState(() {
                              _selectedCategoryId = newId;
                              _selectedCategoryName = match.name;
                            });
                          }
                        },
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 16),

              // Pricing Row
              Row(
                children: [
                  Expanded(
                    child: CustomTextField(
                      label: 'Selling Price (₹)',
                      hint: 'e.g. 2999',
                      controller: _sellingPriceController,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      validator: Validators.validatePrice,
                      onChanged: (_) => setState(() {}),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: CustomTextField(
                      label: 'Original Price / MRP (₹)',
                      hint: 'e.g. 3999',
                      controller: _originalPriceController,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      onChanged: (_) => setState(() {}),
                    ),
                  ),
                ],
              ),

              // Dynamic Discount Badge Preview
              if (hasDiscount) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: AppColors.success.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.success.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.local_offer, size: 14, color: AppColors.success),
                      const SizedBox(width: 6),
                      Text(
                        'Customer saves ${CurrencyFormatter.format(origVal - sellingVal)} ($discountPercent% OFF)',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: AppColors.success,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 16),

              // Stock Quantity Field with Quick Add Chips
              CustomTextField(
                label: 'Stock Quantity (Units)',
                hint: 'e.g. 25',
                controller: _stockController,
                keyboardType: TextInputType.number,
                validator: Validators.validateStock,
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  const Text('Quick set: ', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                  for (final qty in [10, 25, 50, 100]) ...[
                    InkWell(
                      onTap: () => setState(() => _stockController.text = qty.toString()),
                      borderRadius: BorderRadius.circular(6),
                      child: Container(
                        margin: const EdgeInsets.only(right: 6),
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Text(
                          '$qty',
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 16),

              // Description Field
              CustomTextField(
                label: 'Detailed Description',
                hint: 'Provide full specifications, features, warranty, and highlights...',
                controller: _descController,
                maxLines: 4,
                validator: (val) =>
                    Validators.validateRequired(val, 'Description'),
              ),
              const SizedBox(height: 16),

              // Switches
              Container(
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  children: [
                    SwitchListTile(
                      activeThumbColor: AppColors.primary,
                      secondary: const Icon(Icons.star_rounded, color: Colors.amber),
                      title: const Text(
                        'Featured on Homepage',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                      ),
                      subtitle: const Text(
                        'Displays prominently in customer highlights',
                        style: TextStyle(fontSize: 11),
                      ),
                      value: _isFeatured,
                      onChanged: (val) => setState(() => _isFeatured = val),
                    ),
                    const Divider(height: 1),
                    SwitchListTile(
                      activeThumbColor: AppColors.primary,
                      secondary: const Icon(Icons.visibility_outlined, color: AppColors.primary),
                      title: const Text(
                        'Active / Listed in Store',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                      ),
                      subtitle: const Text(
                        'Visible and purchasable by customers',
                        style: TextStyle(fontSize: 11),
                      ),
                      value: _isActive,
                      onChanged: (val) => setState(() => _isActive = val),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Upload status / progress message
              if (_uploadStatusMessage != null) ...[
                Center(
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Text(
                      _uploadStatusMessage!,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ),
              ],

              // Publish / Save Button
              CustomButton(
                text: isEditing ? 'Save Product Changes' : 'Publish Product to Store',
                isLoading: _isSaving,
                icon: Icons.cloud_upload_outlined,
                onPressed: _saveProduct,
              ),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImageTile({
    required Widget preview,
    required VoidCallback onRemove,
    required VoidCallback onSetCover,
    bool isCover = false,
    bool isLocalNew = false,
  }) {
    return Container(
      width: 130,
      margin: const EdgeInsets.only(right: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isCover ? AppColors.primary : AppColors.border,
          width: isCover ? 2.0 : 1.0,
        ),
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: preview,
            ),
          ),

          // Cover Badge
          if (isCover)
            Positioned(
              top: 6,
              left: 6,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  'COVER',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),

          // Local / New Upload Badge
          if (isLocalNew && !isCover)
            Positioned(
              top: 6,
              left: 6,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.65),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  'NEW',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),

          // Remove Button
          Positioned(
            top: 4,
            right: 4,
            child: InkWell(
              onTap: onRemove,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  color: Colors.black54,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.close,
                  size: 14,
                  color: Colors.white,
                ),
              ),
            ),
          ),

          // Set as Cover Button (if not already cover)
          if (!isCover)
            Positioned(
              bottom: 4,
              left: 4,
              right: 4,
              child: InkWell(
                onTap: onSetCover,
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.7),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    'Set as Cover',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
