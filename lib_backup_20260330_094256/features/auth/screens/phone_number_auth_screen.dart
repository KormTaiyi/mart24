import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import 'package:intl_phone_field/phone_number.dart' as intl_phone;
import 'package:mart24/core/theme/app_color.dart';
import 'package:mart24/features/auth/controllers/phone_number_auth_controller.dart';
import 'package:mart24/features/auth/screens/otp_screen.dart';
import 'package:mart24/features/auth/services/phone_auth_service.dart';
import 'package:mart24/features/auth/widgets/auth_background.dart';
import 'package:mart24/features/auth/widgets/auth_submit_button.dart';

class PhoneNumberAuthScreen extends StatefulWidget {
  final bool returnResultOnSuccess;

  const PhoneNumberAuthScreen({super.key, this.returnResultOnSuccess = false});

  @override
  State<PhoneNumberAuthScreen> createState() => _PhoneNumberAuthScreenState();
}

class _PhoneNumberAuthScreenState extends State<PhoneNumberAuthScreen> {
  final PhoneNumberAuthController _controller = PhoneNumberAuthController();
  final TextEditingController _phoneController = TextEditingController();
  final FocusNode _phoneFocusNode = FocusNode();

  String _completePhoneNumber = '';
  String _initialCountryCode = 'KH';
  int _phoneFieldVersion = 0;

  @override
  void initState() {
    super.initState();
    unawaited(_initializeFlow());
  }

  @override
  void dispose() {
    _controller.dispose();
    _phoneController.dispose();
    _phoneFocusNode.dispose();
    super.dispose();
  }

  Future<void> _initializeFlow() async {
    final String? autoPhoneNumber = await _controller.initialize();
    _applyInitialPhone(_controller.initialPhoneNumber);

    if (!mounted) {
      return;
    }

    if (autoPhoneNumber != null) {
      await _openOtpScreen(autoPhoneNumber);
      return;
    }

    if (_controller.showManualEntry) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _phoneFocusNode.requestFocus();
        }
      });
    }
  }

  void _applyInitialPhone(String? phoneNumber) {
    final String normalized =
        PhoneAuthService.normalizePhoneNumber(phoneNumber ?? '') ??
        (phoneNumber?.trim() ?? '');
    if (normalized.isEmpty) {
      return;
    }

    final intl_phone.PhoneNumber parsed =
        intl_phone.PhoneNumber.fromCompleteNumber(completeNumber: normalized);

    setState(() {
      _completePhoneNumber = normalized.startsWith('+')
          ? normalized
          : '+$normalized';
      if (parsed.countryISOCode.isNotEmpty) {
        _initialCountryCode = parsed.countryISOCode;
        _phoneController.text = parsed.number;
      } else {
        _phoneController.text = normalized.startsWith('+')
            ? normalized.substring(1)
            : normalized;
      }
      _phoneFieldVersion += 1;
    });
  }

  Future<void> _retryPhoneHint() async {
    final String? autoPhoneNumber = await _controller.initialize();
    _applyInitialPhone(_controller.initialPhoneNumber);

    if (!mounted) {
      return;
    }

    if (autoPhoneNumber != null) {
      await _openOtpScreen(autoPhoneNumber);
      return;
    }

    _phoneFocusNode.requestFocus();
  }

  Future<void> _submitManualNumber() async {
    final String candidate = _completePhoneNumber.trim().isNotEmpty
        ? _completePhoneNumber.trim()
        : _phoneController.text.trim();
    final String? phoneNumber = await _controller.submitManualNumber(candidate);

    if (!mounted || phoneNumber == null) {
      return;
    }

    await _openOtpScreen(phoneNumber);
  }

  Future<void> _openOtpScreen(String phoneNumber) async {
    final bool? didVerify = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => OtpScreen(
          phoneNumber: phoneNumber,
          returnResultOnSuccess: widget.returnResultOnSuccess,
        ),
      ),
    );

    if (!mounted) {
      return;
    }

    if (didVerify == true) {
      Navigator.of(context).pop(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final bool isBusy =
            _controller.isCheckingDevicePhone || _controller.isSubmitting;
        final bool canContinue =
            !isBusy &&
            (_completePhoneNumber.trim().isNotEmpty ||
                _phoneController.text.trim().isNotEmpty);

        return AuthBackground(
          titlePrefix: 'Continue with',
          titleHighlight: 'Phone Number',
          description:
              'We will try to read your number automatically. If that is not available, you can enter it manually and we will send a real verification code.',
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _InfoCard(
                isLoading: _controller.isCheckingDevicePhone,
                message:
                    _controller.infoMessage ??
                    'Enter your phone number to continue.',
              ),
              if (_controller.errorMessage != null) ...[
                const SizedBox(height: 12),
                _ErrorCard(message: _controller.errorMessage!),
              ],
              const SizedBox(height: 18),
              if (_controller.showManualEntry) ...[
                const Text(
                  'Mobile number',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                IntlPhoneField(
                  key: ValueKey<int>(_phoneFieldVersion),
                  controller: _phoneController,
                  focusNode: _phoneFocusNode,
                  initialCountryCode: _initialCountryCode,
                  keyboardType: TextInputType.number,
                  autofocus: false,
                  textInputAction: TextInputAction.done,
                  autovalidateMode: AutovalidateMode.disabled,
                  disableLengthCheck: true,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                  dropdownTextStyle: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                  cursorColor: Colors.white,
                  decoration: InputDecoration(
                    hintText: 'Phone number',
                    hintStyle: const TextStyle(color: Colors.white70),
                    filled: true,
                    fillColor: Colors.white12,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(22),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(22),
                      borderSide: BorderSide(
                        color: Colors.white.withValues(alpha: 0.14),
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(22),
                      borderSide: const BorderSide(color: Colors.white),
                    ),
                  ),
                  onChanged: (phone) {
                    _controller.clearError();
                    setState(() {
                      _completePhoneNumber = '+${phone.completeNumber}';
                    });
                  },
                  onSubmitted: (_) {
                    if (canContinue) {
                      unawaited(_submitManualNumber());
                    }
                  },
                ),
                const SizedBox(height: 12),
                if (_controller.canRetryPhoneHint)
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton(
                      onPressed: isBusy ? null : _retryPhoneHint,
                      child: const Text(
                        'Try device number again',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
              ],
              const SizedBox(height: 8),
              AuthSubmitButton(
                label: _controller.isSubmitting
                    ? 'Preparing verification...'
                    : 'Continue',
                isLoading: _controller.isSubmitting,
                onPressed: canContinue ? _submitManualNumber : null,
              ),
              const SizedBox(height: 12),
              Text(
                'By continuing, you agree to receive a one-time verification code by SMS.',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.78),
                  fontSize: 12.5,
                  height: 1.4,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _InfoCard extends StatelessWidget {
  final bool isLoading;
  final String message;

  const _InfoCard({required this.isLoading, required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
      ),
      child: Row(
        children: [
          if (isLoading)
            const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            )
          else
            const Icon(Icons.sim_card_rounded, size: 20, color: Colors.white),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorCard extends StatelessWidget {
  final String message;

  const _ErrorCard({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.error.withValues(alpha: 0.45)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded, color: Colors.white),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(color: Colors.white, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }
}
