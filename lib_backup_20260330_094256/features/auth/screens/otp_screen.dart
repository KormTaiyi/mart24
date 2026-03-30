import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mart24/core/routes/app_routes.dart';
import 'package:mart24/core/state/session_manager.dart';
import 'package:mart24/core/theme/app_color.dart';
import 'package:mart24/features/auth/controllers/otp_verification_controller.dart';
import 'package:mart24/features/auth/services/phone_auth_service.dart';
import 'package:mart24/features/auth/widgets/auth_background.dart';
import 'package:mart24/features/auth/widgets/auth_submit_button.dart';

class OtpScreen extends StatefulWidget {
  final String phoneNumber;
  final bool returnResultOnSuccess;

  const OtpScreen({
    super.key,
    this.phoneNumber = '',
    this.returnResultOnSuccess = false,
  });

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  late final OtpVerificationController _controller;
  final TextEditingController _otpController = TextEditingController();
  final FocusNode _otpFocusNode = FocusNode();
  StreamSubscription<OtpVerificationEvent>? _eventSubscription;

  @override
  void initState() {
    super.initState();
    _controller = OtpVerificationController(phoneNumber: widget.phoneNumber);
    _controller.addListener(_syncOtpText);
    _eventSubscription = _controller.events.listen(_handleOtpEvent);

    if (widget.phoneNumber.trim().isNotEmpty) {
      unawaited(_controller.initialize());
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _otpFocusNode.requestFocus();
        }
      });
    }
  }

  @override
  void dispose() {
    _eventSubscription?.cancel();
    _controller.removeListener(_syncOtpText);
    _controller.dispose();
    _otpController.dispose();
    _otpFocusNode.dispose();
    super.dispose();
  }

  void _syncOtpText() {
    if (_otpController.text == _controller.otpCode) {
      return;
    }

    _otpController.value = TextEditingValue(
      text: _controller.otpCode,
      selection: TextSelection.collapsed(offset: _controller.otpCode.length),
    );
  }

  Future<void> _handleOtpEvent(OtpVerificationEvent event) async {
    if (event is! OtpVerificationSucceeded || !mounted) {
      return;
    }

    SessionManager.login(identifier: event.phoneNumber);

    if (widget.returnResultOnSuccess) {
      Navigator.of(context).pop(true);
      return;
    }

    Navigator.pushNamedAndRemoveUntil(
      context,
      AppRoutes.home,
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final String maskedPhone = widget.phoneNumber.trim().isEmpty
        ? 'your phone number'
        : PhoneAuthService.maskPhoneNumber(widget.phoneNumber);

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final bool sessionReady = widget.phoneNumber.trim().isNotEmpty;
        final bool showRetrySend =
            !_controller.hasCodeBeenSent && !_controller.isSendingCode;

        return AuthBackground(
          titlePrefix: 'Verify',
          titleHighlight: 'OTP Code',
          description:
              'Enter the 6-digit code sent to your mobile number. The app will autofill it when your device supports it.',
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'We sent a verification code to $maskedPhone.',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.82),
                  fontSize: 14.5,
                  height: 1.45,
                ),
              ),
              if (_controller.statusMessage != null) ...[
                const SizedBox(height: 14),
                _StatusCard(message: _controller.statusMessage!),
              ],
              if (_controller.errorMessage != null) ...[
                const SizedBox(height: 12),
                _ErrorCard(message: _controller.errorMessage!),
              ],
              const SizedBox(height: 20),
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () {
                  _controller.clearError();
                  _otpFocusNode.requestFocus();
                },
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      height: 64,
                      child: TextField(
                        controller: _otpController,
                        focusNode: _otpFocusNode,
                        autofocus: false,
                        keyboardType: TextInputType.number,
                        textInputAction: TextInputAction.done,
                        autofillHints: const [AutofillHints.oneTimeCode],
                        style: const TextStyle(
                          color: Colors.transparent,
                          fontSize: 1,
                        ),
                        cursorColor: Colors.transparent,
                        showCursor: false,
                        enableSuggestions: false,
                        autocorrect: false,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(
                            OtpVerificationController.otpLength,
                          ),
                        ],
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          counterText: '',
                          contentPadding: EdgeInsets.zero,
                        ),
                        onTap: _controller.clearError,
                        onChanged: (value) {
                          unawaited(_controller.updateOtpCode(value));
                        },
                        onSubmitted: (_) {
                          unawaited(_controller.verifyCode());
                        },
                      ),
                    ),
                    IgnorePointer(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: List<Widget>.generate(
                          OtpVerificationController.otpLength,
                          (index) => _OtpDigitBox(
                            value: index < _controller.otpCode.length
                                ? _controller.otpCode[index]
                                : '',
                            isFilled: index < _controller.otpCode.length,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  TextButton(
                    onPressed: _controller.canResend && sessionReady
                        ? () {
                            _otpFocusNode.requestFocus();
                            unawaited(_controller.sendCode(isResend: true));
                          }
                        : null,
                    child: Text(
                      _controller.canResend
                          ? 'Resend OTP'
                          : 'Resend in 00:${_controller.secondsUntilResend.toString().padLeft(2, '0')}',
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text(
                      'Change number',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              AuthSubmitButton(
                label: _controller.isSendingCode
                    ? 'Sending code...'
                    : showRetrySend
                    ? 'Retry sending code'
                    : _controller.isVerifyingCode
                    ? 'Verifying...'
                    : 'Verify and Continue',
                isLoading:
                    _controller.isSendingCode || _controller.isVerifyingCode,
                onPressed: !sessionReady
                    ? null
                    : showRetrySend
                    ? () => unawaited(_controller.sendCode())
                    : _controller.canVerify
                    ? () => unawaited(_controller.verifyCode())
                    : null,
              ),
              const SizedBox(height: 12),
              Text(
                'Automatic verification works on supported Android devices, and iOS can suggest the SMS code above the keyboard.',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.78),
                  fontSize: 12.5,
                  height: 1.45,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _OtpDigitBox extends StatelessWidget {
  final String value;
  final bool isFilled;

  const _OtpDigitBox({required this.value, required this.isFilled});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 46,
      height: 56,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: isFilled ? 0.18 : 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isFilled ? Colors.white : Colors.white.withValues(alpha: 0.24),
          width: isFilled ? 1.6 : 1,
        ),
      ),
      child: Text(
        value,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 22,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _StatusCard extends StatelessWidget {
  final String message;

  const _StatusCard({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.16)),
      ),
      child: Row(
        children: [
          const Icon(Icons.sms_rounded, color: Colors.white),
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
