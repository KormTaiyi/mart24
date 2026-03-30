import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mart24/core/state/profile_manager.dart';
import 'package:mart24/core/state/session_manager.dart';
import 'package:mart24/core/theme/app_color.dart';
import 'package:mart24/core/theme/app_text_style.dart';
import 'package:mart24/features/auth/screens/login_screen.dart';
import 'package:mart24/features/auth/screens/register_screen.dart';
import 'package:mart24/shared/widgets/user_avatar.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final ImagePicker _imagePicker = ImagePicker();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  String? _draftAvatarPath;
  TextEditingController? _nameController;
  TextEditingController? _shopController;
  TextEditingController? _phoneController;
  TextEditingController? _emailController;
  TextEditingController? _locationController;
  TextEditingController? _bioController;
  TextEditingController? _facebookController;
  TextEditingController? _telegramController;
  TextEditingController? _instagramController;
  TextEditingController? _tiktokController;
  static const int _maxPhoneLength = 15;
  static const int _maxBioLength = 220;

  TextEditingController get _safeNameController => _nameController ??=
      TextEditingController(text: ProfileManager.userName.value);

  TextEditingController get _safeShopController => _shopController ??=
      TextEditingController(text: ProfileManager.shopName.value);

  TextEditingController get _safePhoneController => _phoneController ??=
      TextEditingController(text: ProfileManager.phoneNumber.value);

  TextEditingController get _safeEmailController => _emailController ??=
      TextEditingController(text: ProfileManager.email.value);

  TextEditingController get _safeLocationController => _locationController ??=
      TextEditingController(text: ProfileManager.location.value);

  TextEditingController get _safeBioController =>
      _bioController ??= TextEditingController(text: ProfileManager.bio.value);

  TextEditingController get _safeFacebookController => _facebookController ??=
      TextEditingController(text: ProfileManager.facebookUrl.value);

  TextEditingController get _safeTelegramController => _telegramController ??=
      TextEditingController(text: ProfileManager.telegramUrl.value);

  TextEditingController get _safeInstagramController => _instagramController ??=
      TextEditingController(text: ProfileManager.instagramUrl.value);

  TextEditingController get _safeTiktokController => _tiktokController ??=
      TextEditingController(text: ProfileManager.tiktokUrl.value);

  Future<void> _pickProfileImage() async {
    final XFile? pickedFile = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );

    if (!mounted || pickedFile == null) {
      return;
    }

    setState(() {
      _draftAvatarPath = pickedFile.path;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Photo selected. Tap Save Changes to apply')),
    );
  }

  void _deleteProfileImage() {
    setState(() {
      _draftAvatarPath = null;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Photo removed from draft')),
    );
  }

  @override
  void initState() {
    super.initState();
    _draftAvatarPath = ProfileManager.avatarPath.value;
    _safeNameController;
    _safeShopController;
    _safePhoneController;
    _safeEmailController;
    _safeLocationController;
    _safeBioController;
    _safeFacebookController;
    _safeTelegramController;
    _safeInstagramController;
    _safeTiktokController;
  }

  @override
  void dispose() {
    _nameController?.dispose();
    _shopController?.dispose();
    _phoneController?.dispose();
    _emailController?.dispose();
    _locationController?.dispose();
    _bioController?.dispose();
    _facebookController?.dispose();
    _telegramController?.dispose();
    _instagramController?.dispose();
    _tiktokController?.dispose();
    super.dispose();
  }

  void _saveProfile() {
    final FormState? form = _formKey.currentState;
    if (form == null || !form.validate()) {
      return;
    }

    FocusScope.of(context).unfocus();

    ProfileManager.updateProfile(
      userNameValue: _safeNameController.text,
      shopNameValue: _safeShopController.text,
      phoneNumberValue: _safePhoneController.text,
      emailValue: _safeEmailController.text,
      locationValue: _safeLocationController.text,
      bioValue: _safeBioController.text,
      facebookUrlValue: _safeFacebookController.text,
      telegramUrlValue: _safeTelegramController.text,
      instagramUrlValue: _safeInstagramController.text,
      tiktokUrlValue: _safeTiktokController.text,
    );

    final String? originalAvatarPath = ProfileManager.avatarPath.value;
    final String normalizedOriginal = (originalAvatarPath ?? '').trim();
    final String normalizedDraft = (_draftAvatarPath ?? '').trim();

    if (normalizedDraft != normalizedOriginal) {
      if (normalizedDraft.isEmpty) {
        ProfileManager.removeAvatar();
      } else {
        ProfileManager.updateAvatar(normalizedDraft);
      }
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Profile updated successfully')),
    );

    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: SessionManager.isAuthenticated,
      builder: (context, isAuthenticated, _) {
        if (!isAuthenticated) {
          return Scaffold(
            backgroundColor: const Color(0xFFE8EEF1),
            appBar: AppBar(
              title: const Text('Edit Profile'),
              backgroundColor: Colors.transparent,
              elevation: 0,
            ),
            body: Stack(
              children: [
                Positioned(
                  top: -70,
                  right: -30,
                  child: Container(
                    width: 220,
                    height: 220,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Color(0x5521586E),
                    ),
                  ),
                ),
                Positioned(
                  bottom: -80,
                  left: -40,
                  child: Container(
                    width: 240,
                    height: 240,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Color(0x449FC7D4),
                    ),
                  ),
                ),
                Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(28),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(28),
                            color: Colors.white.withValues(alpha: 0.42),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.75),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.08),
                                blurRadius: 24,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'Login required',
                                style: AppTextStyles.subtitle.copyWith(
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Please login or register to edit your profile.',
                                textAlign: TextAlign.center,
                                style: AppTextStyles.body.copyWith(
                                  color: const Color(0xFF5F5A5A),
                                ),
                              ),
                              const SizedBox(height: 18),
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton(
                                  onPressed: () {
                                    Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (_) => const LoginScreen(
                                          returnResultOnSuccess: true,
                                        ),
                                      ),
                                    );
                                  },
                                  child: const Text('Login'),
                                ),
                              ),
                              const SizedBox(height: 10),
                              SizedBox(
                                width: double.infinity,
                                child: OutlinedButton(
                                  onPressed: () {
                                    Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (_) => const RegisterScreen(
                                          returnResultOnSuccess: true,
                                        ),
                                      ),
                                    );
                                  },
                                  child: const Text('Register'),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        }

        return Scaffold(
          backgroundColor: const Color(0xFFF6F3F3),
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            title: Text('Edit Profile', style: AppTextStyles.subtitle),
          ),
          body: SafeArea(
            top: false,
            child: Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: Column(
                      children: [
                        UserAvatar(
                          radius: 46,
                          backgroundColor: Color(0xFFF1EEEE),
                          bindToProfile: false,
                          imagePath: _draftAvatarPath,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Personal Branding',
                          style: AppTextStyles.subtitle.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Keep your store identity polished. Your photo and details will update across profile, settings, and post cards.',
                          textAlign: TextAlign.center,
                          style: AppTextStyles.body.copyWith(
                            color: Colors.white.withValues(alpha: 0.82),
                          ),
                        ),
                        const SizedBox(height: 20),
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: _pickProfileImage,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.white,
                                  foregroundColor: AppColors.primary,
                                  elevation: 0,
                                  minimumSize: const Size.fromHeight(50),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(18),
                                  ),
                                ),
                                icon: const Icon(Icons.upload_rounded),
                                label: const Text('Upload Photo'),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed:
                                    (_draftAvatarPath ?? '').trim().isNotEmpty
                                    ? _deleteProfileImage
                                    : null,
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: Colors.white,
                                  minimumSize: const Size.fromHeight(50),
                                  side: BorderSide(
                                    color: Colors.white.withValues(alpha: 0.85),
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(18),
                                  ),
                                ),
                                icon: const Icon(Icons.delete_outline_rounded),
                                label: const Text('Delete Photo'),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  _ProfileSection(
                    title: 'Public Profile',
                    subtitle:
                        'These details appear in your storefront and posts.',
                    children: [
                      TextFormField(
                        controller: _safeNameController,
                        keyboardType: TextInputType.name,
                        textCapitalization: TextCapitalization.words,
                        autofillHints: const [AutofillHints.name],
                        textInputAction: TextInputAction.next,
                        validator: _nameValidator,
                        decoration: _inputDecoration(
                          'Full Name',
                          hint: 'Enter your full name',
                          icon: Icons.person_outline_rounded,
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _safeShopController,
                        textCapitalization: TextCapitalization.words,
                        textInputAction: TextInputAction.next,
                        validator: _shopValidator,
                        decoration: _inputDecoration(
                          'Shop Name',
                          hint: 'Enter your shop name',
                          icon: Icons.storefront_outlined,
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _safeBioController,
                        maxLines: 4,
                        maxLength: _maxBioLength,
                        textCapitalization: TextCapitalization.sentences,
                        textInputAction: TextInputAction.newline,
                        validator: _bioValidator,
                        decoration: _inputDecoration(
                          'Bio',
                          hint:
                              'Tell buyers what you sell and why they trust your shop',
                          icon: Icons.notes_rounded,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  _ProfileSection(
                    title: 'Contact Information',
                    subtitle:
                        'Use business-ready contact details buyers can rely on.',
                    children: [
                      TextFormField(
                        controller: _safePhoneController,
                        keyboardType: TextInputType.phone,
                        autofillHints: const [AutofillHints.telephoneNumber],
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(_maxPhoneLength),
                        ],
                        textInputAction: TextInputAction.next,
                        validator: _phoneValidator,
                        decoration: _inputDecoration(
                          'Phone Number',
                          hint: '+855 12 345 678',
                          icon: Icons.phone_outlined,
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _safeEmailController,
                        keyboardType: TextInputType.emailAddress,
                        autofillHints: const [AutofillHints.email],
                        textInputAction: TextInputAction.next,
                        validator: _emailValidator,
                        decoration: _inputDecoration(
                          'Email Address',
                          hint: 'seller@shop.com',
                          icon: Icons.mail_outline_rounded,
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _safeLocationController,
                        textCapitalization: TextCapitalization.words,
                        textInputAction: TextInputAction.done,
                        validator: _locationValidator,
                        decoration: _inputDecoration(
                          'Location',
                          hint: 'Phnom Penh, Cambodia',
                          icon: Icons.location_on_outlined,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  _ProfileSection(
                    title: 'Social Links (Optional)',
                    subtitle:
                        'Add only the links you want to show on your profile.',
                    children: [
                      TextFormField(
                        controller: _safeFacebookController,
                        keyboardType: TextInputType.url,
                        textInputAction: TextInputAction.next,
                        decoration: _inputDecoration(
                          'Facebook Link',
                          hint: '',
                          icon: Icons.facebook_rounded,
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _safeTelegramController,
                        keyboardType: TextInputType.url,
                        textInputAction: TextInputAction.next,
                        decoration: _inputDecoration(
                          'Telegram Link',
                          hint: '',
                          icon: Icons.send_rounded,
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _safeInstagramController,
                        keyboardType: TextInputType.url,
                        textInputAction: TextInputAction.next,
                        decoration: _inputDecoration(
                          'Instagram Link',
                          hint: '',
                          icon: Icons.camera_alt_outlined,
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _safeTiktokController,
                        keyboardType: TextInputType.url,
                        textInputAction: TextInputAction.done,
                        decoration: _inputDecoration(
                          'TikTok Link',
                          hint: '',
                          icon: Icons.music_note_rounded,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _saveProfile,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        minimumSize: const Size.fromHeight(54),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      child: Text(
                        'Save Changes',
                        style: AppTextStyles.body.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  String? _emailValidator(String? value) {
    final String email = value?.trim() ?? '';
    if (email.isEmpty) {
      return null;
    }

    if (!_isValidEmail(email)) {
      return 'Enter a valid email address';
    }

    return null;
  }

  String? _phoneValidator(String? value) {
    final String input = value?.trim() ?? '';
    if (input.isEmpty) {
      return null;
    }

    final String digits = _digitsOnly(input);
    if (digits.length < 8 || digits.length > _maxPhoneLength) {
      return 'Enter a valid phone number';
    }

    return null;
  }

  String? _nameValidator(String? value) {
    final String trimmed = value?.trim() ?? '';
    if (trimmed.isEmpty) {
      return null;
    }

    if (trimmed.length < 2) {
      return 'Full name is too short';
    }

    if (!_hasNonDigitText(trimmed)) {
      return 'Full name cannot be only numbers';
    }

    return null;
  }

  String? _shopValidator(String? value) {
    final String trimmed = value?.trim() ?? '';
    if (trimmed.isEmpty) {
      return null;
    }

    if (trimmed.length < 2) {
      return 'Shop name is too short';
    }

    if (!_hasNonDigitText(trimmed)) {
      return 'Shop name cannot be only numbers';
    }

    return null;
  }

  String? _locationValidator(String? value) {
    final String trimmed = value?.trim() ?? '';
    if (trimmed.isEmpty) {
      return null;
    }

    if (trimmed.length < 3) {
      return 'Location is too short';
    }

    if (!_hasNonDigitText(trimmed)) {
      return 'Enter a valid location';
    }

    return null;
  }

  String? _bioValidator(String? value) {
    final String trimmed = value?.trim() ?? '';
    if (trimmed.isEmpty) {
      return null;
    }

    if (trimmed.length < 20) {
      return 'Bio should be at least 20 characters';
    }

    if (trimmed.length > _maxBioLength) {
      return 'Bio is too long';
    }

    return null;
  }

  String _digitsOnly(String value) {
    final StringBuffer buffer = StringBuffer();

    for (final int codeUnit in value.codeUnits) {
      if (codeUnit >= 48 && codeUnit <= 57) {
        buffer.writeCharCode(codeUnit);
      }
    }

    return buffer.toString();
  }

  bool _hasNonDigitText(String value) {
    for (final int codeUnit in value.codeUnits) {
      final bool isDigit = codeUnit >= 48 && codeUnit <= 57;
      final bool isSpace = codeUnit == 32;

      if (!isDigit && !isSpace) {
        return true;
      }
    }

    return false;
  }

  bool _isValidEmail(String email) {
    if (email.contains(' ')) {
      return false;
    }

    final int atIndex = email.indexOf('@');
    if (atIndex <= 0 || atIndex != email.lastIndexOf('@')) {
      return false;
    }

    final String localPart = email.substring(0, atIndex);
    final String domainPart = email.substring(atIndex + 1);

    if (localPart.isEmpty || domainPart.isEmpty) {
      return false;
    }

    if (domainPart.startsWith('.') || domainPart.endsWith('.')) {
      return false;
    }

    return domainPart.contains('.');
  }

  InputDecoration _inputDecoration(
    String label, {
    required String hint,
    required IconData icon,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: Icon(icon, color: const Color(0xFF7F7878)),
      filled: true,
      fillColor: const Color(0xFFF6F3F3),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(color: AppColors.primary),
      ),
    );
  }
}

class _ProfileSection extends StatelessWidget {
  final String title;
  final String subtitle;
  final List<Widget> children;

  const _ProfileSection({
    required this.title,
    required this.subtitle,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: AppTextStyles.subtitle.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: AppTextStyles.body.copyWith(color: const Color(0xFF777070)),
          ),
          const SizedBox(height: 18),
          ...children,
        ],
      ),
    );
  }
}
