import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mart24/core/network/api_exception.dart';
import 'package:mart24/core/state/profile_manager.dart';
import 'package:mart24/core/theme/app_color.dart';
import 'package:mart24/core/utils/price_input_utils.dart';
import 'package:mart24/features/category/data/remote/category_api_service.dart';
import 'package:mart24/features/category/models/post_category.dart';
import 'package:mart24/features/sell/data/remote/create_post_api_service.dart';
import 'package:mart24/shared/widgets/forms/form_layout.dart';
import 'package:url_launcher/url_launcher.dart';

class _SelectOption<T> {
  const _SelectOption({required this.value, required this.label});

  final T value;
  final String label;
}

List<DropdownMenuItem<T>> _buildSelectMenuItems<T>(
  List<_SelectOption<T>> items,
) {
  return items
      .map(
        (item) =>
            DropdownMenuItem<T>(value: item.value, child: Text(item.label)),
      )
      .toList(growable: false);
}

class CreatePostForm extends StatefulWidget {
  final String? initialCategoryId;
  final String? initialSubCategoryId;

  const CreatePostForm({
    super.key,
    this.initialCategoryId,
    this.initialSubCategoryId,
  });

  @override
  State<CreatePostForm> createState() => _CreatePostFormState();
}

class _CreatePostFormState extends State<CreatePostForm> {
  final CategoryApiService _categoryApiService = CategoryApiService();
  final CreatePostApiService _createPostApiService = CreatePostApiService();
  final ImagePicker _imagePicker = ImagePicker();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _locationController = TextEditingController(
    text: ProfileManager.location.value,
  );

  List<PostCategory> _categories = const <PostCategory>[];
  List<PostSubCategory> _subCategories = const <PostSubCategory>[];
  PostCategory? _selectedCategory;
  PostSubCategory? _selectedSubCategory;
  final List<XFile> _pickedImages = <XFile>[];

  bool _isLoadingCategories = false;
  bool _isLoadingSubCategories = false;
  bool _isSaving = false;
  String? _loadingError;

  String _selectedStatus = 'active';
  String? _selectedCondition;
  bool _initialSelectionApplied = false;

  static const Color _accentColor = Color(0xFF6F63FF);
  static const Color _fieldBorderColor = Color(0xFFD6DBEE);
  static const Color _fieldHintColor = Color(0xFF8E95B1);
  static const int _maxImageSizeMb = 5;
  static const int _maxImageSizeBytes = _maxImageSizeMb * 1024 * 1024;
  static const List<_SelectOption<String>> _statusOptions =
      <_SelectOption<String>>[
        _SelectOption<String>(value: 'active', label: 'Active'),
        _SelectOption<String>(value: 'pending', label: 'Pending'),
        _SelectOption<String>(value: 'sold', label: 'Sold'),
      ];
  static const List<_SelectOption<String>> _conditionOptions =
      <_SelectOption<String>>[
        _SelectOption<String>(value: 'new', label: 'New'),
        _SelectOption<String>(value: 'like_new', label: 'Like New'),
        _SelectOption<String>(value: 'good', label: 'Good'),
        _SelectOption<String>(value: 'fair', label: 'Fair'),
        _SelectOption<String>(value: 'poor', label: 'Poor'),
      ];
  static final List<DropdownMenuItem<String>> _statusDropdownItems =
      _buildSelectMenuItems(_statusOptions);
  static final List<DropdownMenuItem<String>> _conditionDropdownItems =
      _buildSelectMenuItems(_conditionOptions);

  bool get _isBusy => _isLoadingCategories || _isSaving;

  bool get _hasSelectedCategory => _selectedCategory != null;

  bool get _hasSubCategoryItems => _subCategories.isNotEmpty;

  bool get _canSelectSubCategory =>
      _hasSelectedCategory &&
      _hasSubCategoryItems &&
      !_isLoadingSubCategories &&
      !_isBusy;

  String get _subCategoryHint {
    if (!_hasSelectedCategory) {
      return 'Select category first';
    }
    if (_isLoadingSubCategories) {
      return 'Loading sub categories...';
    }
    if (_hasSubCategoryItems) {
      return 'Select sub category';
    }
    return 'No sub categories available';
  }

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  Future<void> _loadCategories() async {
    setState(() {
      _isLoadingCategories = true;
      _loadingError = null;
    });

    try {
      final List<PostCategory> items = await _categoryApiService
          .fetchCategories(page: 1, limit: 100);
      if (!mounted) {
        return;
      }
      setState(() {
        _categories = items;
        _isLoadingCategories = false;
      });
      await _applyInitialSelectionIfNeeded(items);
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _isLoadingCategories = false;
        _loadingError = 'Unable to load categories.';
      });
    }
  }

  Future<void> _applyInitialSelectionIfNeeded(
    List<PostCategory> categories,
  ) async {
    if (_initialSelectionApplied) {
      return;
    }

    final String categoryId = (widget.initialCategoryId ?? '').trim();
    if (categoryId.isEmpty) {
      _initialSelectionApplied = true;
      return;
    }

    PostCategory? matchedCategory;
    for (final PostCategory category in categories) {
      if (category.id.trim() == categoryId) {
        matchedCategory = category;
        break;
      }
    }

    if (matchedCategory == null) {
      return;
    }

    _initialSelectionApplied = true;
    await _onCategoryChanged(matchedCategory);

    if (!mounted) {
      return;
    }

    final String subCategoryId = (widget.initialSubCategoryId ?? '').trim();
    if (subCategoryId.isEmpty) {
      return;
    }

    PostSubCategory? matchedSubCategory;
    for (final PostSubCategory subCategory in _subCategories) {
      if (subCategory.id.trim() == subCategoryId) {
        matchedSubCategory = subCategory;
        break;
      }
    }

    if (matchedSubCategory != null) {
      setState(() {
        _selectedSubCategory = matchedSubCategory;
      });
    }
  }

  Future<void> _onCategoryChanged(PostCategory? selected) async {
    if (selected == null) {
      setState(() {
        _selectedCategory = null;
        _selectedSubCategory = null;
        _subCategories = const <PostSubCategory>[];
      });
      return;
    }

    setState(() {
      _selectedCategory = selected;
      _selectedSubCategory = null;
      _subCategories = selected.subCategories;
      _isLoadingSubCategories = false;
    });

    if (_subCategories.isNotEmpty) {
      return;
    }

    setState(() {
      _isLoadingSubCategories = true;
    });

    try {
      final List<PostSubCategory> remote = await _categoryApiService
          .fetchSubCategories(categoryId: selected.id);
      if (!mounted) {
        return;
      }
      setState(() {
        _subCategories = remote;
        _isLoadingSubCategories = false;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _subCategories = const <PostSubCategory>[];
        _isLoadingSubCategories = false;
      });
    }
  }

  Future<void> _pickImages() async {
    try {
      final List<XFile> images = await _imagePicker.pickMultiImage();
      if (!mounted || images.isEmpty) {
        return;
      }

      final List<XFile> validImages = await _filterImagesBySize(
        images,
        notifyOnInvalid: true,
      );
      if (!mounted || validImages.isEmpty) {
        return;
      }

      final Map<String, XFile> deduped = <String, XFile>{
        for (final XFile file in _pickedImages) file.path: file,
      };
      for (final XFile file in validImages) {
        deduped[file.path] = file;
      }

      setState(() {
        _pickedImages
          ..clear()
          ..addAll(deduped.values);
      });
    } catch (_) {
      _showSnack('Unable to pick images.');
    }
  }

  Future<List<XFile>> _filterImagesBySize(
    List<XFile> files, {
    bool notifyOnInvalid = false,
  }) async {
    final List<XFile> validFiles = <XFile>[];
    int invalidCount = 0;

    for (final XFile file in files) {
      try {
        final int size = await file.length();
        if (size <= _maxImageSizeBytes) {
          validFiles.add(file);
          continue;
        }
      } catch (_) {
        // Treat unreadable files as invalid so we avoid uploading bad files.
      }
      invalidCount++;
    }

    if (notifyOnInvalid && invalidCount > 0) {
      _showSnack(
        '$invalidCount image(s) skipped. Each image must be $_maxImageSizeMb MB or smaller.',
      );
    }

    return validFiles;
  }

  Future<void> _submit() async {
    if (_isSaving) {
      return;
    }

    if (_selectedCategory == null) {
      _showSnack('Please select a category first.');
      return;
    }

    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    final int? categoryId = int.tryParse(_selectedCategory!.id);
    if (categoryId == null) {
      _showSnack('Invalid category selected.');
      return;
    }

    final double? price = PriceInputUtils.tryParseNumber(_priceController.text);
    if (price == null || price <= 0) {
      _showSnack('Please enter a valid price.');
      return;
    }

    final String normalizedLocation = _locationController.text.trim();
    if (normalizedLocation.isEmpty) {
      _showSnack('Please choose your location.');
      return;
    }

    final List<XFile> validPickedImages = await _filterImagesBySize(
      _pickedImages,
    );
    if (!mounted) {
      return;
    }
    if (validPickedImages.length != _pickedImages.length) {
      setState(() {
        _pickedImages
          ..clear()
          ..addAll(validPickedImages);
      });
      _showSnack(
        'Some images were removed because they are larger than $_maxImageSizeMb MB.',
      );
    }

    setState(() {
      _isSaving = true;
    });

    try {
      await _createPostApiService.createPost(
        title: _titleController.text.trim(),
        description: _normalizeDescription(_descriptionController.text),
        price: price,
        categoryId: categoryId,
        status: _selectedStatus,
        location: normalizedLocation,
        latitude: null,
        longitude: null,
        condition: _selectedCondition,
        imagePaths: validPickedImages.map((item) => item.path).toList(),
      );

      if (!mounted) {
        return;
      }
      _showSnack('Post created successfully.');
      _resetFormToDefaults();
    } on ApiException catch (error) {
      if (!mounted) {
        return;
      }
      _showSnack(error.message);
    } catch (_) {
      if (!mounted) {
        return;
      }
      _showSnack('Failed to create post.');
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  void _resetFormToDefaults() {
    _titleController.clear();
    _descriptionController.clear();
    _priceController.clear();
    _locationController.text = ProfileManager.location.value;
    _selectedStatus = 'active';
    _selectedCondition = null;
    _selectedCategory = null;
    _selectedSubCategory = null;
    _subCategories = const <PostSubCategory>[];
    _pickedImages.clear();
    setState(() {});
  }

  Future<void> _useCurrentLocation() async {
    try {
      final bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _showSnack('Please enable location services.');
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied) {
        _showSnack('Location permission denied.');
        return;
      }

      if (permission == LocationPermission.deniedForever) {
        _showSnack('Location permission permanently denied.');
        return;
      }

      final Position position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );

      final String label =
          '${position.latitude.toStringAsFixed(6)}, ${position.longitude.toStringAsFixed(6)}';

      if (!mounted) {
        return;
      }

      setState(() {
        _locationController.text = label;
      });
      _showSnack('Current location selected.');
    } catch (_) {
      _showSnack('Unable to get current location.');
    }
  }

  Future<void> _showLocationPickerActions() async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (BuildContext sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(8, 12, 8, 10),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 2),
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE1E4F2),
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                const SizedBox(height: 12),
                ListTile(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  leading: const Icon(Icons.map_outlined, color: _accentColor),
                  title: const Text('Open Google Maps'),
                  onTap: () {
                    Navigator.of(sheetContext).pop();
                    _openGoogleMaps();
                  },
                ),
                ListTile(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  leading: const Icon(
                    Icons.my_location_rounded,
                    color: _accentColor,
                  ),
                  title: const Text('Use Current Location'),
                  onTap: () {
                    Navigator.of(sheetContext).pop();
                    _useCurrentLocation();
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _openGoogleMaps() async {
    final String query = _locationController.text.trim().isEmpty
        ? 'near me'
        : _locationController.text.trim();
    final Uri mapsUri = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(query)}',
    );
    try {
      if (!await launchUrl(mapsUri, mode: LaunchMode.externalApplication)) {
        _showSnack('Unable to open Google Maps.');
      }
    } catch (_) {
      _showSnack('Unable to open Google Maps.');
    }
  }

  String _normalizeDescription(String raw) {
    final String trimmed = raw.trim();
    if (trimmed.isEmpty) {
      return '';
    }
    if (trimmed.startsWith('<')) {
      return trimmed;
    }
    return '<p>${trimmed.replaceAll('\n', '<br>')}</p>';
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FD),
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        centerTitle: true,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: const Text(
          'Create Post',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        actions: [
          if (_isLoadingCategories)
            const Padding(
              padding: EdgeInsets.only(right: 16),
              child: SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 26),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_loadingError != null) ...[
                Container(
                  margin: const EdgeInsets.only(bottom: 14),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF1F1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFF2CBCB)),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.warning_amber_rounded,
                        color: AppColors.error,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _loadingError!,
                          style: const TextStyle(
                            color: AppColors.error,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: _loadCategories,
                        style: TextButton.styleFrom(
                          foregroundColor: AppColors.error,
                        ),
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
              ],
              const AppFormSectionLabel(text: 'TITLE *'),
              TextFormField(
                controller: _titleController,
                enabled: !_isBusy,
                decoration: _fieldDecoration(
                  hintText: 'e.g. iPhone 14 Pro Max',
                ),
                validator: (value) {
                  final String text = value?.trim() ?? '';
                  if (text.isEmpty) {
                    return 'Title is required';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 10),
              const AppFormSectionLabel(text: 'DESCRIPTION'),
              _buildDescriptionField(isBusy: _isBusy),
              const SizedBox(height: 10),
              AppTwoColumnFormRow(
                gap: 10,
                left: AppLabeledFormField(
                  label: 'PRICE (\$) *',
                  child: TextFormField(
                    controller: _priceController,
                    enabled: !_isBusy,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                      signed: false,
                    ),
                    inputFormatters: <TextInputFormatter>[
                      PriceInputUtils.decimalFormatter,
                    ],
                    decoration: _fieldDecoration(hintText: '0.00'),
                    validator: (value) =>
                        PriceInputUtils.validatePositiveRequired(
                          value,
                          requiredMessage: 'Price required',
                          invalidMessage: 'Price must be greater than 0',
                        ),
                  ),
                ),
                right: AppLabeledFormField(
                  label: 'STATUS',
                  child: _buildDropdownField<String>(
                    value: _selectedStatus,
                    hintText: 'Active',
                    items: _statusDropdownItems,
                    onChanged: _isBusy
                        ? null
                        : (value) {
                            if (value == null) {
                              return;
                            }
                            setState(() {
                              _selectedStatus = value;
                            });
                          },
                  ),
                ),
              ),
              const SizedBox(height: 14),
              AppTwoColumnFormRow(
                left: AppLabeledFormField(
                  label: 'CATEGORY',
                  child: _buildDropdownField<PostCategory>(
                    value: _selectedCategory,
                    hintText: '— None —',
                    items: _buildCategoryItems(),
                    onChanged: _isBusy ? null : _onCategoryChanged,
                  ),
                ),
                right: AppLabeledFormField(
                  label: 'SUBCATEGORY',
                  child: _buildDropdownField<PostSubCategory>(
                    value: _selectedSubCategory,
                    hintText: _subCategoryHint,
                    items: _buildSubCategoryItems(),
                    onChanged: !_canSelectSubCategory
                        ? null
                        : (value) =>
                              setState(() => _selectedSubCategory = value),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              AppTwoColumnFormRow(
                left: AppLabeledFormField(
                  label: 'LOCATION',
                  child: TextFormField(
                    controller: _locationController,
                    enabled: !_isBusy,
                    decoration: _fieldDecoration(hintText: 'Phnom Penh'),
                    validator: (value) {
                      if ((value?.trim() ?? '').isEmpty) {
                        return 'Location required';
                      }
                      return null;
                    },
                  ),
                ),
                right: AppLabeledFormField(
                  label: 'CONDITION',
                  child: _buildDropdownField<String>(
                    value: _selectedCondition,
                    hintText: '— Select —',
                    items: _conditionDropdownItems,
                    onChanged: _isBusy
                        ? null
                        : (value) => setState(() => _selectedCondition = value),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _isBusy ? null : _showLocationPickerActions,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: _accentColor,
                    backgroundColor: const Color(0xFFF1F0FF),
                    side: const BorderSide(color: Color(0xFFD4D1FF)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 13),
                  ),
                  icon: const Icon(Icons.place_outlined, size: 18),
                  label: const Text(
                    'Pick on Map',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  const AppFormSectionLabel(text: 'IMAGES'),
                  const Spacer(),
                  Text(
                    '${_pickedImages.length} UPLOADED',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 0.5,
                      color: Color(0xFF9AA0B8),
                    ),
                  ),
                ],
              ),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _isBusy ? null : _pickImages,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF2F3552),
                    backgroundColor: const Color(0xFFF6F7FD),
                    side: const BorderSide(color: _fieldBorderColor),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 13),
                  ),
                  icon: const Icon(Icons.upload_outlined, size: 18),
                  label: const Text(
                    'Add Image',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Center(
                child: Text(
                  'JPEG, PNG, WebP — max $_maxImageSizeMb MB each',
                  style: const TextStyle(
                    color: Color(0xFF9AA0B8),
                    fontSize: 12,
                  ),
                ),
              ),
              if (_pickedImages.isNotEmpty) ...[
                const SizedBox(height: 12),
                _buildImagePreviewStrip(),
              ],
              const SizedBox(height: 22),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isBusy ? null : _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _accentColor,
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: _accentColor.withValues(
                          alpha: 0.45,
                        ),
                        elevation: 0,
                        shadowColor: Colors.transparent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 15),
                      ),
                      child: _isSaving
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text(
                              'Create Post',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  SizedBox(
                    width: 120,
                    child: OutlinedButton(
                      onPressed: _isBusy
                          ? null
                          : () {
                              if (Navigator.of(context).canPop()) {
                                Navigator.of(context).maybePop();
                                return;
                              }
                              _resetFormToDefaults();
                            },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF2F3552),
                        side: const BorderSide(color: _fieldBorderColor),
                        backgroundColor: const Color(0xFFF0F1F8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 15),
                      ),
                      child: const Text(
                        'Cancel',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<DropdownMenuItem<PostCategory>> _buildCategoryItems() {
    return _categories
        .map(
          (item) => DropdownMenuItem<PostCategory>(
            value: item,
            child: Text(
              item.name.trim().isEmpty ? 'Category' : item.name.trim(),
            ),
          ),
        )
        .toList(growable: false);
  }

  List<DropdownMenuItem<PostSubCategory>> _buildSubCategoryItems() {
    return _subCategories
        .map(
          (item) => DropdownMenuItem<PostSubCategory>(
            value: item,
            child: Text(
              item.name.trim().isEmpty ? 'Sub category' : item.name.trim(),
            ),
          ),
        )
        .toList(growable: false);
  }

  Widget _buildImagePreviewStrip() {
    return SizedBox(
      height: 82,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _pickedImages.length,
        separatorBuilder: (_, _) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final XFile image = _pickedImages[index];
          return _buildImageThumbnail(image: image, index: index);
        },
      ),
    );
  }

  Widget _buildImageThumbnail({required XFile image, required int index}) {
    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Container(
            width: 82,
            height: 82,
            decoration: BoxDecoration(
              color: const Color(0xFFE5E7EB),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFD3D9DF)),
            ),
            child: Image.file(
              File(image.path),
              width: 82,
              height: 82,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) =>
                  const Icon(Icons.image_not_supported_outlined),
            ),
          ),
        ),
        Positioned(
          top: 3,
          right: 3,
          child: GestureDetector(
            onTap: _isBusy
                ? null
                : () {
                    setState(() {
                      _pickedImages.removeAt(index);
                    });
                  },
            child: Container(
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.black54,
              ),
              padding: const EdgeInsets.all(3),
              child: const Icon(Icons.close, size: 12, color: Colors.white),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDescriptionField({required bool isBusy}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: _fieldBorderColor),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          TextFormField(
            controller: _descriptionController,
            enabled: !isBusy,
            minLines: 5,
            maxLines: 8,
            decoration: const InputDecoration(
              hintText: 'Describe your product',
              hintStyle: TextStyle(color: _fieldHintColor),
              border: InputBorder.none,
              contentPadding: EdgeInsets.fromLTRB(14, 12, 14, 14),
            ),
            validator: (value) {
              final String text = value?.trim() ?? '';
              if (text.isEmpty) {
                return 'Description is required';
              }
              return null;
            },
          ),
        ],
      ),
    );
  }

  InputDecoration _fieldDecoration({
    required String hintText,
    Widget? suffixIcon,
    EdgeInsetsGeometry? contentPadding,
  }) {
    return InputDecoration(
      hintText: hintText,
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: Colors.white,
      hintStyle: const TextStyle(color: _fieldHintColor, fontSize: 15),
      contentPadding:
          contentPadding ??
          const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: _fieldBorderColor),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: _fieldBorderColor),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: _accentColor, width: 1.2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.error),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.error, width: 1.2),
      ),
    );
  }

  Widget _buildDropdownField<T>({
    required T? value,
    required String hintText,
    required List<DropdownMenuItem<T>> items,
    required ValueChanged<T?>? onChanged,
  }) {
    final bool isEnabled = onChanged != null;
    return DropdownButtonFormField<T>(
      initialValue: value,
      isExpanded: true,
      icon: const Icon(
        Icons.keyboard_arrow_down_rounded,
        color: Color(0xFF7E86A4),
      ),
      decoration: _fieldDecoration(
        hintText: hintText,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      ).copyWith(fillColor: isEnabled ? Colors.white : const Color(0xFFF2F4FA)),
      borderRadius: BorderRadius.circular(14),
      dropdownColor: Colors.white,
      hint: Text(hintText, style: const TextStyle(color: _fieldHintColor)),
      style: const TextStyle(
        color: Color(0xFF303854),
        fontSize: 16,
        fontWeight: FontWeight.w500,
      ),
      items: items,
      onChanged: onChanged,
    );
  }
}
