import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mart24/core/network/api_exception.dart';
import 'package:mart24/core/state/profile_manager.dart';
import 'package:mart24/core/theme/app_color.dart';
import 'package:mart24/core/theme/app_text_style.dart';
import 'package:mart24/features/category/data/remote/category_api_service.dart';
import 'package:mart24/features/category/models/post_category.dart';
import 'package:mart24/features/sell/data/remote/create_post_api_service.dart';
import 'package:url_launcher/url_launcher.dart';

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
  double? _selectedLatitude;
  double? _selectedLongitude;

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

      final Map<String, XFile> deduped = <String, XFile>{
        for (final XFile file in _pickedImages) file.path: file,
      };
      for (final XFile file in images) {
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

    final double? price = double.tryParse(_priceController.text.trim());
    if (price == null || price <= 0) {
      _showSnack('Please enter a valid price.');
      return;
    }

    final String normalizedLocation = _locationController.text.trim();
    if (normalizedLocation.isEmpty) {
      _showSnack('Please choose your location.');
      return;
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
        latitude: _selectedLatitude,
        longitude: _selectedLongitude,
        condition: _selectedCondition,
        imagePaths: _pickedImages.map((item) => item.path).toList(),
      );

      if (!mounted) {
        return;
      }
      _showSnack('Post created successfully.');
      _resetFormKeepCategory();
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

  void _resetFormKeepCategory() {
    _titleController.clear();
    _descriptionController.clear();
    _priceController.clear();
    _locationController.text = ProfileManager.location.value;
    _selectedLatitude = null;
    _selectedLongitude = null;
    _selectedStatus = 'active';
    _selectedCondition = null;
    _selectedSubCategory = null;
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
        desiredAccuracy: LocationAccuracy.high,
      );

      final String label =
          '${position.latitude.toStringAsFixed(6)}, ${position.longitude.toStringAsFixed(6)}';

      if (!mounted) {
        return;
      }

      setState(() {
        _selectedLatitude = position.latitude;
        _selectedLongitude = position.longitude;
        _locationController.text = label;
      });
      _showSnack('Current location selected.');
    } catch (_) {
      _showSnack('Unable to get current location.');
    }
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
    final bool isBusy = _isLoadingCategories || _isSaving;
    final bool hasSelectedCategory = _selectedCategory != null;
    final bool hasSubCategoryItems = _subCategories.isNotEmpty;
    final bool canSelectSubCategory =
        hasSelectedCategory &&
        hasSubCategoryItems &&
        !_isLoadingSubCategories &&
        !isBusy;
    final String subCategoryHint = !hasSelectedCategory
        ? 'Select category first'
        : _isLoadingSubCategories
        ? 'Loading sub categories...'
        : (hasSubCategoryItems
              ? 'Select sub category'
              : 'No sub categories available');

    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FB),
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
        flexibleSpace: const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: <Color>[Color(0xFF1F5B74), Color(0xFF2D6F87)],
            ),
          ),
        ),
        actions: [
          if (_isLoadingCategories)
            const Padding(
              padding: EdgeInsets.only(right: 16),
              child: SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              ),
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Container(
              //   width: double.infinity,
              //   padding: const EdgeInsets.symmetric(
              //     horizontal: 14,
              //     vertical: 12,
              //   ),
              //   decoration: BoxDecoration(
              //     color: const Color(0xFFEFF6FB),
              //     borderRadius: BorderRadius.circular(16),
              //     border: Border.all(color: const Color(0xFFD4E7F4)),
              //   ),
              //   child: Row(
              //     crossAxisAlignment: CrossAxisAlignment.start,
              //     children: [
              //       const Padding(
              //         padding: EdgeInsets.only(top: 1),
              //         child: Icon(
              //           Icons.info_outline_rounded,
              //           color: Color(0xFF2D6F87),
              //           size: 18,
              //         ),
              //       ),
              //       const SizedBox(width: 10),
              //       Expanded(
              //         child: Text(
              //           'Test mode: login gate is currently skipped for posting.',
              //           style: AppTextStyles.caption.copyWith(
              //             color: const Color(0xFF4A6577),
              //             fontSize: 12,
              //             fontWeight: FontWeight.w500,
              //           ),
              //         ),
              //       ),
              //     ],
              //   ),
              // ),
              // const SizedBox(height: 12),
              if (_loadingError != null) ...[
                Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF1F1),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFF3C8C8)),
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
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.error,
                            fontSize: 12,
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
              _buildSectionCard(
                child: Column(
                  children: [
                    _buildDropdownField<PostCategory>(
                      label: 'Category *',
                      value: _selectedCategory,
                      hintText: 'Select category',
                      icon: Icons.grid_view_rounded,
                      items: _categories
                          .map(
                            (item) => DropdownMenuItem<PostCategory>(
                              value: item,
                              child: Text(
                                item.name.trim().isEmpty
                                    ? 'Category'
                                    : item.name,
                              ),
                            ),
                          )
                          .toList(),
                      onChanged: isBusy ? null : _onCategoryChanged,
                    ),
                    const SizedBox(height: 12),
                    _buildDropdownField<PostSubCategory>(
                      label: 'Sub Category',
                      value: _selectedSubCategory,
                      hintText: subCategoryHint,
                      icon: Icons.widgets_outlined,
                      items: _subCategories
                          .map(
                            (item) => DropdownMenuItem<PostSubCategory>(
                              value: item,
                              child: Text(
                                item.name.trim().isEmpty
                                    ? 'Sub category'
                                    : item.name.trim(),
                              ),
                            ),
                          )
                          .toList(),
                      onChanged: !canSelectSubCategory
                          ? null
                          : (value) =>
                                setState(() => _selectedSubCategory = value),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              _buildSectionCard(
                child: Column(
                  children: [
                    TextFormField(
                      controller: _titleController,
                      enabled: !isBusy,
                      decoration: _fieldDecoration(
                        label: 'Title *',
                        hintText: 'e.g. iPhone 14 Pro Max',
                        icon: Icons.title_rounded,
                      ),
                      validator: (value) {
                        final String text = value?.trim() ?? '';
                        if (text.isEmpty) {
                          return 'Title is required';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _descriptionController,
                      enabled: !isBusy,
                      minLines: 4,
                      maxLines: 6,
                      decoration: _fieldDecoration(
                        label: 'Description *',
                        hintText: 'Describe your product',
                        icon: Icons.notes_rounded,
                        alignLabelWithHint: true,
                      ),
                      validator: (value) {
                        final String text = value?.trim() ?? '';
                        if (text.isEmpty) {
                          return 'Description is required';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _priceController,
                            enabled: !isBusy,
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                              signed: false,
                            ),
                            inputFormatters: <TextInputFormatter>[
                              TextInputFormatter.withFunction((
                                oldValue,
                                newValue,
                              ) {
                                final String text = newValue.text;
                                if (text.isEmpty) {
                                  return newValue;
                                }
                                for (final int codeUnit in text.codeUnits) {
                                  final bool isDigit =
                                      codeUnit >= 48 && codeUnit <= 57;
                                  final bool isDot = codeUnit == 46;
                                  if (!isDigit && !isDot) {
                                    return oldValue;
                                  }
                                }
                                if (text.startsWith('.')) {
                                  return oldValue;
                                }
                                if ('.'.allMatches(text).length > 1) {
                                  return oldValue;
                                }
                                final List<String> parts = text.split('.');
                                if (parts.length > 1 && parts[1].length > 2) {
                                  return oldValue;
                                }
                                return newValue;
                              }),
                            ],
                            decoration: _fieldDecoration(
                              label: 'Price (\$) *',
                              hintText: '0.00',
                              icon: Icons.attach_money_rounded,
                            ),
                            validator: (value) {
                              final String text = value?.trim() ?? '';
                              if (text.isEmpty) {
                                return 'Price required';
                              }
                              final double? parsed = double.tryParse(text);
                              if (parsed == null || parsed <= 0) {
                                return 'Price must be greater than 0';
                              }
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildDropdownField<String>(
                            label: 'Status',
                            value: _selectedStatus,
                            hintText: 'Select status',
                            icon: Icons.toggle_on_rounded,
                            items: const [
                              DropdownMenuItem(
                                value: 'active',
                                child: Text('Active'),
                              ),
                              DropdownMenuItem(
                                value: 'inactive',
                                child: Text('Inactive'),
                              ),
                            ],
                            onChanged: isBusy
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
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              _buildSectionCard(
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _locationController,
                            readOnly: true,
                            onTap: isBusy ? null : _openGoogleMaps,
                            enabled: !isBusy,
                            decoration: _fieldDecoration(
                              label: 'Location',
                              hintText: 'Choose from map or current location',
                              icon: Icons.location_on_outlined,
                              suffixIcon: const Icon(
                                Icons.open_in_new_rounded,
                                size: 18,
                                color: Color(0xFF6B8292),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildDropdownField<String>(
                            label: 'Condition',
                            value: _selectedCondition,
                            hintText: 'Optional',
                            icon: Icons.verified_outlined,
                            items: const [
                              DropdownMenuItem(
                                value: 'new',
                                child: Text('New'),
                              ),
                              DropdownMenuItem(
                                value: 'like_new',
                                child: Text('Like New'),
                              ),
                              DropdownMenuItem(
                                value: 'used',
                                child: Text('Used'),
                              ),
                            ],
                            onChanged: isBusy
                                ? null
                                : (value) => setState(
                                    () => _selectedCondition = value,
                                  ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: isBusy ? null : _openGoogleMaps,
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.primary,
                              backgroundColor: const Color(0xFFF6FAFD),
                              side: const BorderSide(color: Color(0xFFCCE0ED)),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                            icon: const Icon(Icons.map_outlined, size: 18),
                            label: const Text('Open Google Maps'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: isBusy ? null : _useCurrentLocation,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                            icon: const Icon(
                              Icons.my_location_rounded,
                              size: 18,
                            ),
                            label: const Text('Use Current Location'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              _buildSectionCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          'Images',
                          style: AppTextStyles.body.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEAF2F8),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '${_pickedImages.length}',
                            style: AppTextStyles.caption.copyWith(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    OutlinedButton.icon(
                      onPressed: isBusy ? null : _pickImages,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.primary,
                        backgroundColor: const Color(0xFFF6FAFD),
                        side: const BorderSide(color: Color(0xFFCCE0ED)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 12,
                        ),
                      ),
                      icon: const Icon(Icons.add_a_photo_outlined, size: 20),
                      label: const Text('Add Image'),
                    ),
                    if (_pickedImages.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      SizedBox(
                        height: 82,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: _pickedImages.length,
                          separatorBuilder: (_, _) => const SizedBox(width: 10),
                          itemBuilder: (context, index) {
                            final XFile image = _pickedImages[index];
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
                                      border: Border.all(
                                        color: const Color(0xFFD3D9DF),
                                      ),
                                    ),
                                    child: FutureBuilder<Uint8List>(
                                      future: image.readAsBytes(),
                                      builder: (context, snapshot) {
                                        if (snapshot.connectionState ==
                                            ConnectionState.waiting) {
                                          return const Center(
                                            child: SizedBox(
                                              width: 18,
                                              height: 18,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                              ),
                                            ),
                                          );
                                        }

                                        if (!snapshot.hasData) {
                                          return const Icon(
                                            Icons.image_not_supported_outlined,
                                          );
                                        }

                                        return Image.memory(
                                          snapshot.data!,
                                          width: 82,
                                          height: 82,
                                          fit: BoxFit.cover,
                                        );
                                      },
                                    ),
                                  ),
                                ),
                                Positioned(
                                  top: 3,
                                  right: 3,
                                  child: GestureDetector(
                                    onTap: isBusy
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
                                      child: const Icon(
                                        Icons.close,
                                        size: 12,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: isBusy ? null : _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shadowColor: Colors.transparent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
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
                          : const Text('Save Post'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  OutlinedButton(
                    onPressed: isBusy
                        ? null
                        : () {
                            if (Navigator.of(context).canPop()) {
                              Navigator.of(context).maybePop();
                              return;
                            }
                            _resetFormKeepCategory();
                          },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      side: const BorderSide(color: Color(0xFFD5E1EA)),
                      backgroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                    ),
                    child: const Text('Cancel'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionCard({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE3EAF0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: child,
    );
  }

  InputDecoration _fieldDecoration({
    required String label,
    required String hintText,
    IconData? icon,
    Widget? suffixIcon,
    bool alignLabelWithHint = false,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hintText,
      alignLabelWithHint: alignLabelWithHint,
      prefixIcon: icon == null
          ? null
          : Icon(icon, size: 20, color: const Color(0xFF6B8292)),
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: const Color(0xFFF8FAFC),
      labelStyle: const TextStyle(
        color: Color(0xFF5C6B77),
        fontWeight: FontWeight.w600,
      ),
      hintStyle: const TextStyle(color: Color(0xFF95A2AE)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFFDCE5EC)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFFDCE5EC)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.primary, width: 1.3),
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
    required String label,
    required T? value,
    required String hintText,
    required List<DropdownMenuItem<T>> items,
    required ValueChanged<T?>? onChanged,
    IconData? icon,
  }) {
    return InputDecorator(
      decoration: _fieldDecoration(label: label, hintText: hintText, icon: icon)
          .copyWith(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 4,
            ),
          ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          hint: Text(
            hintText,
            style: const TextStyle(color: Color(0xFF95A2AE)),
          ),
          isExpanded: true,
          icon: Icon(
            Icons.keyboard_arrow_down_rounded,
            color: AppColors.primary.withValues(alpha: 0.75),
          ),
          borderRadius: BorderRadius.circular(14),
          items: items,
          onChanged: onChanged,
        ),
      ),
    );
  }
}
