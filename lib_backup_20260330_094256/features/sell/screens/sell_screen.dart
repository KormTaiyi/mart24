// import 'dart:typed_data';

// import 'package:flutter/material.dart';
// import 'package:image_picker/image_picker.dart';
// import 'package:mart24/core/network/api_exception.dart';
// import 'package:mart24/core/state/profile_manager.dart';
// import 'package:mart24/core/theme/app_color.dart';
// import 'package:mart24/core/theme/app_text_style.dart';
// import 'package:mart24/features/category/data/remote/category_api_service.dart';
// import 'package:mart24/features/category/models/post_category.dart';
// import 'package:mart24/features/sell/data/remote/create_post_api_service.dart';

// class SellScreen extends StatefulWidget {
//   const SellScreen({super.key});

//   @override
//   State<SellScreen> createState() => _SellScreenState();
// }

// class _SellScreenState extends State<SellScreen> {
//   final CategoryApiService _categoryApiService = CategoryApiService();
//   final CreatePostApiService _createPostApiService = CreatePostApiService();
//   final ImagePicker _imagePicker = ImagePicker();
//   final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

//   final TextEditingController _titleController = TextEditingController();
//   final TextEditingController _descriptionController = TextEditingController();
//   final TextEditingController _priceController = TextEditingController();
//   final TextEditingController _locationController = TextEditingController(
//     text: ProfileManager.location.value,
//   );
//   final TextEditingController _latitudeController = TextEditingController();
//   final TextEditingController _longitudeController = TextEditingController();

//   List<PostCategory> _categories = const <PostCategory>[];
//   List<PostSubCategory> _subCategories = const <PostSubCategory>[];
//   PostCategory? _selectedCategory;
//   PostSubCategory? _selectedSubCategory;
//   final List<XFile> _pickedImages = <XFile>[];

//   bool _isLoadingCategories = false;
//   bool _isLoadingSubCategories = false;
//   bool _isSaving = false;
//   String? _loadingError;

//   String _selectedStatus = 'active';
//   String? _selectedCondition;

//   @override
//   void initState() {
//     super.initState();
//     _loadCategories();
//   }

//   @override
//   void dispose() {
//     _titleController.dispose();
//     _descriptionController.dispose();
//     _priceController.dispose();
//     _locationController.dispose();
//     _latitudeController.dispose();
//     _longitudeController.dispose();
//     super.dispose();
//   }

//   Future<void> _loadCategories() async {
//     setState(() {
//       _isLoadingCategories = true;
//       _loadingError = null;
//     });

//     try {
//       final List<PostCategory> items = await _categoryApiService
//           .fetchCategories(page: 1, limit: 100);
//       if (!mounted) {
//         return;
//       }
//       setState(() {
//         _categories = items;
//         _isLoadingCategories = false;
//       });
//     } catch (_) {
//       if (!mounted) {
//         return;
//       }
//       setState(() {
//         _isLoadingCategories = false;
//         _loadingError = 'Unable to load categories.';
//       });
//     }
//   }

//   Future<void> _onCategoryChanged(PostCategory? selected) async {
//     if (selected == null) {
//       setState(() {
//         _selectedCategory = null;
//         _selectedSubCategory = null;
//         _subCategories = const <PostSubCategory>[];
//       });
//       return;
//     }

//     setState(() {
//       _selectedCategory = selected;
//       _selectedSubCategory = null;
//       _subCategories = selected.subCategories;
//       _isLoadingSubCategories = false;
//     });

//     if (_subCategories.isNotEmpty) {
//       return;
//     }

//     setState(() {
//       _isLoadingSubCategories = true;
//     });

//     try {
//       final List<PostSubCategory> remote = await _categoryApiService
//           .fetchSubCategories(categoryId: selected.id);
//       if (!mounted) {
//         return;
//       }
//       setState(() {
//         _subCategories = remote;
//         _isLoadingSubCategories = false;
//       });
//     } catch (_) {
//       if (!mounted) {
//         return;
//       }
//       setState(() {
//         _subCategories = const <PostSubCategory>[];
//         _isLoadingSubCategories = false;
//       });
//     }
//   }

//   Future<void> _pickImages() async {
//     try {
//       final List<XFile> images = await _imagePicker.pickMultiImage();
//       if (!mounted || images.isEmpty) {
//         return;
//       }

//       final Map<String, XFile> deduped = <String, XFile>{
//         for (final XFile file in _pickedImages) file.path: file,
//       };
//       for (final XFile file in images) {
//         deduped[file.path] = file;
//       }

//       setState(() {
//         _pickedImages
//           ..clear()
//           ..addAll(deduped.values);
//       });
//     } catch (_) {
//       _showSnack('Unable to pick images.');
//     }
//   }

//   Future<void> _submit() async {
//     if (_isSaving) {
//       return;
//     }

//     if (_selectedCategory == null) {
//       _showSnack('Please select a category first.');
//       return;
//     }

//     if (!(_formKey.currentState?.validate() ?? false)) {
//       return;
//     }

//     final int? categoryId = int.tryParse(_selectedCategory!.id);
//     if (categoryId == null) {
//       _showSnack('Invalid category selected.');
//       return;
//     }

//     final double? price = double.tryParse(_priceController.text.trim());
//     if (price == null || price <= 0) {
//       _showSnack('Please enter a valid price.');
//       return;
//     }

//     final double? latitude = _parseCoordinate(_latitudeController.text);
//     final double? longitude = _parseCoordinate(_longitudeController.text);
//     if ((latitude == null) != (longitude == null)) {
//       _showSnack('Please provide both latitude and longitude.');
//       return;
//     }

//     setState(() {
//       _isSaving = true;
//     });

//     try {
//       await _createPostApiService.createPost(
//         title: _titleController.text.trim(),
//         description: _normalizeDescription(_descriptionController.text),
//         price: price,
//         categoryId: categoryId,
//         status: _selectedStatus,
//         location: _locationController.text.trim(),
//         latitude: latitude,
//         longitude: longitude,
//         condition: _selectedCondition,
//         imagePaths: _pickedImages.map((item) => item.path).toList(),
//       );

//       if (!mounted) {
//         return;
//       }
//       _showSnack('Post created successfully.');
//       _resetFormKeepCategory();
//     } on ApiException catch (error) {
//       if (!mounted) {
//         return;
//       }
//       _showSnack(error.message);
//     } catch (_) {
//       if (!mounted) {
//         return;
//       }
//       _showSnack('Failed to create post.');
//     } finally {
//       if (mounted) {
//         setState(() {
//           _isSaving = false;
//         });
//       }
//     }
//   }

//   void _resetFormKeepCategory() {
//     _titleController.clear();
//     _descriptionController.clear();
//     _priceController.clear();
//     _locationController.text = ProfileManager.location.value;
//     _latitudeController.clear();
//     _longitudeController.clear();
//     _selectedStatus = 'active';
//     _selectedCondition = null;
//     _selectedSubCategory = null;
//     _pickedImages.clear();
//     setState(() {});
//   }

//   double? _parseCoordinate(String value) {
//     final String trimmed = value.trim();
//     if (trimmed.isEmpty) {
//       return null;
//     }
//     return double.tryParse(trimmed);
//   }

//   String _normalizeDescription(String raw) {
//     final String trimmed = raw.trim();
//     if (trimmed.isEmpty) {
//       return '';
//     }
//     if (trimmed.startsWith('<')) {
//       return trimmed;
//     }
//     return '<p>${trimmed.replaceAll('\n', '<br>')}</p>';
//   }

//   void _showSnack(String message) {
//     ScaffoldMessenger.of(context)
//       ..hideCurrentSnackBar()
//       ..showSnackBar(SnackBar(content: Text(message)));
//   }

//   @override
//   Widget build(BuildContext context) {
//     final bool isBusy = _isLoadingCategories || _isSaving;

//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Create Post'),
//         actions: [
//           if (_isLoadingCategories)
//             const Padding(
//               padding: EdgeInsets.only(right: 16),
//               child: SizedBox(
//                 width: 18,
//                 height: 18,
//                 child: CircularProgressIndicator(strokeWidth: 2),
//               ),
//             ),
//         ],
//       ),
//       body: Form(
//         key: _formKey,
//         child: SingleChildScrollView(
//           padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               Text(
//                 'Test mode: login gate is currently skipped for posting.',
//                 style: AppTextStyles.caption.copyWith(
//                   color: const Color(0xFF707070),
//                   fontSize: 12,
//                 ),
//               ),
//               const SizedBox(height: 12),
//               if (_loadingError != null)
//                 Padding(
//                   padding: const EdgeInsets.only(bottom: 12),
//                   child: Row(
//                     children: [
//                       Expanded(
//                         child: Text(
//                           _loadingError!,
//                           style: AppTextStyles.caption.copyWith(
//                             color: AppColors.error,
//                             fontSize: 12,
//                           ),
//                         ),
//                       ),
//                       TextButton(
//                         onPressed: _loadCategories,
//                         child: const Text('Retry'),
//                       ),
//                     ],
//                   ),
//                 ),
//               _buildDropdownField<PostCategory>(
//                 label: 'Category *',
//                 value: _selectedCategory,
//                 hintText: 'Select category',
//                 items: _categories
//                     .map(
//                       (item) => DropdownMenuItem<PostCategory>(
//                         value: item,
//                         child: Text(
//                           item.name.trim().isEmpty ? 'Category' : item.name,
//                         ),
//                       ),
//                     )
//                     .toList(),
//                 onChanged: isBusy ? null : _onCategoryChanged,
//               ),
//               const SizedBox(height: 12),
//               _buildDropdownField<PostSubCategory>(
//                 label: 'Sub Category (ignored for now)',
//                 value: _selectedSubCategory,
//                 hintText: _isLoadingSubCategories
//                     ? 'Loading sub categories...'
//                     : 'Optional',
//                 items: _subCategories
//                     .map(
//                       (item) => DropdownMenuItem<PostSubCategory>(
//                         value: item,
//                         child: Text(
//                           item.name.trim().isEmpty
//                               ? 'Sub category'
//                               : item.name.trim(),
//                         ),
//                       ),
//                     )
//                     .toList(),
//                 onChanged: isBusy || _isLoadingSubCategories
//                     ? null
//                     : (value) => setState(() => _selectedSubCategory = value),
//               ),
//               const SizedBox(height: 16),
//               TextFormField(
//                 controller: _titleController,
//                 enabled: !isBusy,
//                 decoration: const InputDecoration(
//                   labelText: 'Title *',
//                   hintText: 'e.g. iPhone 14 Pro Max',
//                   border: OutlineInputBorder(),
//                 ),
//                 validator: (value) {
//                   final String text = value?.trim() ?? '';
//                   if (text.isEmpty) {
//                     return 'Title is required';
//                   }
//                   return null;
//                 },
//               ),
//               const SizedBox(height: 12),
//               TextFormField(
//                 controller: _descriptionController,
//                 enabled: !isBusy,
//                 minLines: 4,
//                 maxLines: 6,
//                 decoration: const InputDecoration(
//                   labelText: 'Description *',
//                   hintText: 'Describe your product',
//                   alignLabelWithHint: true,
//                   border: OutlineInputBorder(),
//                 ),
//                 validator: (value) {
//                   final String text = value?.trim() ?? '';
//                   if (text.isEmpty) {
//                     return 'Description is required';
//                   }
//                   return null;
//                 },
//               ),
//               const SizedBox(height: 12),
//               Row(
//                 children: [
//                   Expanded(
//                     child: TextFormField(
//                       controller: _priceController,
//                       enabled: !isBusy,
//                       keyboardType: const TextInputType.numberWithOptions(
//                         decimal: true,
//                       ),
//                       decoration: const InputDecoration(
//                         labelText: 'Price (\$) *',
//                         hintText: '0.00',
//                         border: OutlineInputBorder(),
//                       ),
//                       validator: (value) {
//                         final String text = value?.trim() ?? '';
//                         if (text.isEmpty) {
//                           return 'Price required';
//                         }
//                         final double? parsed = double.tryParse(text);
//                         if (parsed == null || parsed <= 0) {
//                           return 'Invalid price';
//                         }
//                         return null;
//                       },
//                     ),
//                   ),
//                   const SizedBox(width: 12),
//                   Expanded(
//                     child: _buildDropdownField<String>(
//                       label: 'Status',
//                       value: _selectedStatus,
//                       hintText: 'Select status',
//                       items: const [
//                         DropdownMenuItem(
//                           value: 'active',
//                           child: Text('Active'),
//                         ),
//                         DropdownMenuItem(
//                           value: 'inactive',
//                           child: Text('Inactive'),
//                         ),
//                       ],
//                       onChanged: isBusy
//                           ? null
//                           : (value) {
//                               if (value == null) {
//                                 return;
//                               }
//                               setState(() {
//                                 _selectedStatus = value;
//                               });
//                             },
//                     ),
//                   ),
//                 ],
//               ),
//               const SizedBox(height: 12),
//               Row(
//                 children: [
//                   Expanded(
//                     child: TextFormField(
//                       controller: _locationController,
//                       enabled: !isBusy,
//                       decoration: const InputDecoration(
//                         labelText: 'Location',
//                         hintText: 'Phnom Penh',
//                         border: OutlineInputBorder(),
//                       ),
//                     ),
//                   ),
//                   const SizedBox(width: 12),
//                   Expanded(
//                     child: _buildDropdownField<String>(
//                       label: 'Condition',
//                       value: _selectedCondition,
//                       hintText: 'Optional',
//                       items: const [
//                         DropdownMenuItem(value: 'new', child: Text('New')),
//                         DropdownMenuItem(
//                           value: 'like_new',
//                           child: Text('Like New'),
//                         ),
//                         DropdownMenuItem(value: 'used', child: Text('Used')),
//                       ],
//                       onChanged: isBusy
//                           ? null
//                           : (value) =>
//                                 setState(() => _selectedCondition = value),
//                     ),
//                   ),
//                 ],
//               ),
//               const SizedBox(height: 12),
//               Row(
//                 children: [
//                   Expanded(
//                     child: TextFormField(
//                       controller: _latitudeController,
//                       enabled: !isBusy,
//                       keyboardType: const TextInputType.numberWithOptions(
//                         decimal: true,
//                         signed: true,
//                       ),
//                       decoration: const InputDecoration(
//                         labelText: 'Latitude',
//                         border: OutlineInputBorder(),
//                       ),
//                     ),
//                   ),
//                   const SizedBox(width: 12),
//                   Expanded(
//                     child: TextFormField(
//                       controller: _longitudeController,
//                       enabled: !isBusy,
//                       keyboardType: const TextInputType.numberWithOptions(
//                         decimal: true,
//                         signed: true,
//                       ),
//                       decoration: const InputDecoration(
//                         labelText: 'Longitude',
//                         border: OutlineInputBorder(),
//                       ),
//                     ),
//                   ),
//                 ],
//               ),
//               const SizedBox(height: 14),
//               Text(
//                 'Images (${_pickedImages.length})',
//                 style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w600),
//               ),
//               const SizedBox(height: 8),
//               OutlinedButton.icon(
//                 onPressed: isBusy ? null : _pickImages,
//                 icon: const Icon(Icons.add_a_photo_outlined),
//                 label: const Text('Add Image'),
//               ),
//               if (_pickedImages.isNotEmpty) ...[
//                 const SizedBox(height: 10),
//                 SizedBox(
//                   height: 78,
//                   child: ListView.separated(
//                     scrollDirection: Axis.horizontal,
//                     itemCount: _pickedImages.length,
//                     separatorBuilder: (_, _) => const SizedBox(width: 8),
//                     itemBuilder: (context, index) {
//                       final XFile image = _pickedImages[index];
//                       return Stack(
//                         children: [
//                           ClipRRect(
//                             borderRadius: BorderRadius.circular(10),
//                             child: FutureBuilder<Uint8List>(
//                               future: image.readAsBytes(),
//                               builder: (context, snapshot) {
//                                 if (snapshot.connectionState ==
//                                     ConnectionState.waiting) {
//                                   return Container(
//                                     width: 78,
//                                     height: 78,
//                                     color: const Color(0xFFE5E7EB),
//                                     alignment: Alignment.center,
//                                     child: const SizedBox(
//                                       width: 18,
//                                       height: 18,
//                                       child: CircularProgressIndicator(
//                                         strokeWidth: 2,
//                                       ),
//                                     ),
//                                   );
//                                 }

//                                 if (!snapshot.hasData) {
//                                   return Container(
//                                     width: 78,
//                                     height: 78,
//                                     color: const Color(0xFFE5E7EB),
//                                     alignment: Alignment.center,
//                                     child: const Icon(
//                                       Icons.image_not_supported_outlined,
//                                     ),
//                                   );
//                                 }

//                                 return Image.memory(
//                                   snapshot.data!,
//                                   width: 78,
//                                   height: 78,
//                                   fit: BoxFit.cover,
//                                 );
//                               },
//                             ),
//                           ),
//                           Positioned(
//                             top: 2,
//                             right: 2,
//                             child: GestureDetector(
//                               onTap: isBusy
//                                   ? null
//                                   : () {
//                                       setState(() {
//                                         _pickedImages.removeAt(index);
//                                       });
//                                     },
//                               child: Container(
//                                 decoration: const BoxDecoration(
//                                   shape: BoxShape.circle,
//                                   color: Colors.black54,
//                                 ),
//                                 padding: const EdgeInsets.all(3),
//                                 child: const Icon(
//                                   Icons.close,
//                                   size: 12,
//                                   color: Colors.white,
//                                 ),
//                               ),
//                             ),
//                           ),
//                         ],
//                       );
//                     },
//                   ),
//                 ),
//               ],
//               const SizedBox(height: 20),
//               Row(
//                 children: [
//                   Expanded(
//                     child: ElevatedButton(
//                       onPressed: isBusy ? null : _submit,
//                       style: ElevatedButton.styleFrom(
//                         backgroundColor: AppColors.primary,
//                         foregroundColor: Colors.white,
//                         padding: const EdgeInsets.symmetric(vertical: 14),
//                       ),
//                       child: _isSaving
//                           ? const SizedBox(
//                               width: 16,
//                               height: 16,
//                               child: CircularProgressIndicator(
//                                 strokeWidth: 2,
//                                 color: Colors.white,
//                               ),
//                             )
//                           : const Text('Save Post'),
//                     ),
//                   ),
//                   const SizedBox(width: 12),
//                   OutlinedButton(
//                     onPressed: isBusy
//                         ? null
//                         : () {
//                             if (Navigator.of(context).canPop()) {
//                               Navigator.of(context).maybePop();
//                               return;
//                             }
//                             _resetFormKeepCategory();
//                           },
//                     style: OutlinedButton.styleFrom(
//                       padding: const EdgeInsets.symmetric(
//                         horizontal: 16,
//                         vertical: 14,
//                       ),
//                     ),
//                     child: const Text('Cancel'),
//                   ),
//                 ],
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }

//   Widget _buildDropdownField<T>({
//     required String label,
//     required T? value,
//     required String hintText,
//     required List<DropdownMenuItem<T>> items,
//     required ValueChanged<T?>? onChanged,
//   }) {
//     return InputDecorator(
//       decoration: InputDecoration(
//         labelText: label,
//         border: const OutlineInputBorder(),
//         contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
//       ),
//       child: DropdownButtonHideUnderline(
//         child: DropdownButton<T>(
//           value: value,
//           hint: Text(hintText),
//           isExpanded: true,
//           items: items,
//           onChanged: onChanged,
//         ),
//       ),
//     );
//   }
// }
