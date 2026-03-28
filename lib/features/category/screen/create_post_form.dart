import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mart24/core/network/api_exception.dart';
import 'package:mart24/core/theme/app_color.dart';
import 'package:mart24/core/utils/post_location_requirement.dart';
import 'package:mart24/core/utils/price_input_utils.dart';
import 'package:mart24/features/sell/data/remote/create_post_api_service.dart';
import 'package:mart24/shared/widgets/forms/form_layout.dart';

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
  final CreatePostApiService _createPostApiService = CreatePostApiService();
  final ImagePicker _imagePicker = ImagePicker();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();

  final List<XFile> _pickedImages = <XFile>[];
  int? _resolvedCategoryId;

  bool _isSaving = false;
  bool _isResolvingLocation = false;
  String? _imageErrorText;
  AutovalidateMode _autoValidateMode = AutovalidateMode.disabled;

  String _selectedStatus = 'active';
  String? _selectedCondition;

  static const Color _accentColor = Color(0xFF6F63FF);
  static const Color _fieldBorderColor = Color(0xFFD6DBEE);
  static const Color _fieldHintColor = Color(0xFF8E95B1);
  static const int _bytesPerMb = 1024 * 1024;
  static const int _defaultMaxImageSizeMb = 5;
  static const int _defaultMaxTotalImageUploadMb = 10;
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
  int _maxImageSizeBytes = _defaultMaxImageSizeMb * _bytesPerMb;
  int _maxTotalImageUploadBytes = _defaultMaxTotalImageUploadMb * _bytesPerMb;

  bool get _isBusy => _isSaving || _isResolvingLocation;
  String get _maxImageSizeMbLabel => _formatMbLabel(_maxImageSizeBytes);
  String get _maxTotalImageUploadMbLabel =>
      _formatMbLabel(_maxTotalImageUploadBytes);

  @override
  void initState() {
    super.initState();
    _resolvedCategoryId = int.tryParse((widget.initialCategoryId ?? '').trim());
    _loadUploadLimitsFromApi();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  Future<void> _pickImages() async {
    try {
      final List<XFile> images = await _imagePicker.pickMultiImage(
        imageQuality: 85,
        maxWidth: 1920,
        maxHeight: 1920,
      );
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
        _imageErrorText = null;
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
        '$invalidCount image(s) skipped. Each image must be $_maxImageSizeMbLabel MB or smaller.',
      );
    }

    return validFiles;
  }

  Future<int> _totalImageBytes(Iterable<XFile> files) async {
    int totalBytes = 0;
    for (final XFile file in files) {
      try {
        totalBytes += await file.length();
      } catch (_) {
        // Ignore unreadable files; size validation already handles these.
      }
    }
    return totalBytes;
  }

  Future<void> _submit() async {
    if (_isSaving) {
      return;
    }

    final int? categoryId = _resolvedCategoryId;
    if (categoryId == null) {
      _showSnack(
        'Missing selected category. Please choose from category page.',
      );
      return;
    }

    final bool hasPickedImages = _pickedImages.isNotEmpty;
    setState(() {
      _autoValidateMode = AutovalidateMode.onUserInteraction;
      _imageErrorText = hasPickedImages ? null : 'Image is required';
    });

    final bool isFormValid = _formKey.currentState?.validate() ?? false;
    if (!isFormValid || !hasPickedImages) {
      return;
    }

    final double? price = PriceInputUtils.tryParseNumber(_priceController.text);
    if (price == null || price <= 0) {
      _showSnack('Please enter a valid price.');
      return;
    }

    final Position? position = await _resolveRequiredLocation(
      openAppSettingsOnFailure: false,
      openLocationSettingsOnFailure: false,
    );
    if (position == null) {
      return;
    }

    final double latitude = position.latitude;
    final double longitude = position.longitude;
    final String normalizedLocation = _locationLabel(
      latitude: latitude,
      longitude: longitude,
    );

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
        'Some images were removed because they are larger than $_maxImageSizeMbLabel MB.',
      );
    }
    if (validPickedImages.isEmpty) {
      setState(() {
        _imageErrorText = 'Image is required';
      });
      return;
    }

    final int totalImageBytes = await _totalImageBytes(validPickedImages);
    if (!mounted) {
      return;
    }
    if (totalImageBytes > _maxTotalImageUploadBytes) {
      _showSnack(
        'Images are too large to upload. Keep total under $_maxTotalImageUploadMbLabel MB.',
      );
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
        latitude: latitude,
        longitude: longitude,
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
      if (error.statusCode == 413) {
        _applyUploadLimitsFromApiError(error);
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
    _locationController.clear();
    _selectedStatus = 'active';
    _selectedCondition = null;
    _pickedImages.clear();
    _imageErrorText = null;
    _autoValidateMode = AutovalidateMode.disabled;
    setState(() {});
  }

  String _locationLabel({required double latitude, required double longitude}) {
    return '${latitude.toStringAsFixed(6)}, ${longitude.toStringAsFixed(6)}';
  }

  Future<void> _loadUploadLimitsFromApi() async {
    final PostUploadLimits? limits = await _createPostApiService
        .fetchUploadLimits();
    if (!mounted || limits == null) {
      return;
    }
    _applyUploadLimits(limits);
  }

  void _applyUploadLimitsFromApiError(ApiException error) {
    final Object? raw = error.rawError;
    if (raw is! DioException) {
      return;
    }
    final PostUploadLimits? limits = _createPostApiService
        .extractUploadLimitsFromDioError(raw);
    if (limits == null) {
      return;
    }
    _applyUploadLimits(limits);
  }

  void _applyUploadLimits(PostUploadLimits limits) {
    int nextPerImageBytes = _maxImageSizeBytes;
    int nextTotalBytes = _maxTotalImageUploadBytes;

    final int? apiPerImage = limits.perImageBytes;
    if (apiPerImage != null && apiPerImage > 0) {
      nextPerImageBytes = apiPerImage;
    }

    final int? apiTotal = limits.totalBytes;
    if (apiTotal != null && apiTotal > 0) {
      nextTotalBytes = apiTotal;
    }

    if (nextTotalBytes < nextPerImageBytes) {
      nextTotalBytes = nextPerImageBytes;
    }

    if (nextPerImageBytes == _maxImageSizeBytes &&
        nextTotalBytes == _maxTotalImageUploadBytes) {
      return;
    }

    setState(() {
      _maxImageSizeBytes = nextPerImageBytes;
      _maxTotalImageUploadBytes = nextTotalBytes;
    });
  }

  String _formatMbLabel(int bytes) {
    final double value = bytes / _bytesPerMb;
    final int rounded = value.round();
    if ((value - rounded).abs() < 0.05) {
      return rounded.toString();
    }
    return value.toStringAsFixed(1);
  }

  Future<Position?> _resolveRequiredLocation({
    required bool openAppSettingsOnFailure,
    required bool openLocationSettingsOnFailure,
  }) async {
    if (_isResolvingLocation) {
      return null;
    }

    if (mounted) {
      setState(() {
        _isResolvingLocation = true;
      });
    }

    try {
      final PostLocationResult result =
          await PostLocationRequirement.ensureCurrentPosition(
            openAppSettingsOnDeniedForever: openAppSettingsOnFailure,
            openLocationSettingsOnServicesDisabled:
                openLocationSettingsOnFailure,
          );

      if (!mounted) {
        return null;
      }

      final Position? position = result.position;
      if (position == null) {
        _clearCurrentLocation();
        return null;
      }

      setState(() {
        _locationController.text = _locationLabel(
          latitude: position.latitude,
          longitude: position.longitude,
        );
      });
      return position;
    } finally {
      if (mounted) {
        setState(() {
          _isResolvingLocation = false;
        });
      }
    }
  }

  void _clearCurrentLocation() {
    if (mounted) {
      _locationController.clear();
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
      ),
      body: Form(
        key: _formKey,
        autovalidateMode: _autoValidateMode,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(15),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const AppFormSectionLabel(text: 'IMAGES *'),
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
                    side: BorderSide(
                      color: _imageErrorText == null
                          ? _fieldBorderColor
                          : AppColors.error,
                    ),
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
              Center(
                child: Text(
                  'JPEG, PNG, WebP — max $_maxImageSizeMbLabel MB each ($_maxTotalImageUploadMbLabel MB total)',
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
              const SizedBox(height: 10),
              if (_resolvedCategoryId == null) ...[
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
                        child: const Text(
                          'Missing selected category. Go back and choose a category first.',
                          style: TextStyle(
                            color: AppColors.error,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
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
              const SizedBox(height: 8),
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
                    decoration: _fieldDecoration(
                      hintText: '0.00',
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 4,
                      ),
                    ),
                    validator: (value) =>
                        PriceInputUtils.validatePositiveRequired(
                          value,
                          requiredMessage: 'Price is required',
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
              AppLabeledFormField(
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
              const SizedBox(height: 20),
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
    return TextFormField(
      controller: _descriptionController,
      enabled: !isBusy,
      minLines: 5,
      maxLines: 8,
      decoration: _fieldDecoration(
        hintText: 'Describe your product',
        contentPadding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
      ),
      validator: (value) {
        final String text = value?.trim() ?? '';
        if (text.isEmpty) {
          return 'Description is required';
        }
        return null;
      },
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
