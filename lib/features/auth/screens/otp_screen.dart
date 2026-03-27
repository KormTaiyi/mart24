import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:enefty_icons/enefty_icons.dart';
import 'package:mart24/core/routes/app_routes.dart';
import 'package:mart24/core/state/session_manager.dart';
import 'package:mart24/core/theme/app_color.dart';
import 'package:mart24/features/auth/services/phone_auth_service.dart';
import 'package:mart24/features/auth/widgets/otp_box.dart';
import 'package:mart24/features/auth/widgets/otp_keypad_button.dart';

class OtpScreen extends StatefulWidget {
  final String phoneNumber;
  final String e164PhoneNumber;
  final String verificationId;
  final int? resendToken;
  final bool returnResultOnSuccess;

  const OtpScreen({
    super.key,
    this.phoneNumber = '',
    this.e164PhoneNumber = '',
    this.verificationId = '',
    this.resendToken,
    this.returnResultOnSuccess = false,
  });

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  static const int _otpLength = 6;
  static const Duration _snackDedupWindow = Duration(seconds: 2);
  final List<String> _otpDigits = List<String>.filled(_otpLength, '');
  final TextEditingController _otpController = TextEditingController();
  final FocusNode _otpFocusNode = FocusNode();
  bool _isVerifying = false;
  late String _verificationId;
  String? _lastSnackMessage;
  DateTime? _lastSnackAt;

  @override
  void initState() {
    super.initState();
    _verificationId = widget.verificationId;
    _otpController.addListener(_handleOtpChanged);
  }

  @override
  void dispose() {
    _otpController.removeListener(_handleOtpChanged);
    _otpController.dispose();
    _otpFocusNode.dispose();
    super.dispose();
  }

  void _onNumberTap(String value) {
    if (_otpController.text.length >= _otpDigits.length) {
      return;
    }

    _otpController.text = '${_otpController.text}$value';
    _otpController.selection = TextSelection.collapsed(
      offset: _otpController.text.length,
    );
  }

  void _onBackspace() {
    if (_otpController.text.isEmpty) {
      return;
    }

    _otpController.text = _otpController.text.substring(
      0,
      _otpController.text.length - 1,
    );
    _otpController.selection = TextSelection.collapsed(
      offset: _otpController.text.length,
    );
  }

  String get otpCode => _otpDigits.join();

  void _handleOtpChanged() {
    final sanitized = _digitsOnly(_otpController.text);
    final normalized = sanitized.length > _otpDigits.length
        ? sanitized.substring(0, _otpDigits.length)
        : sanitized;

    if (_otpController.text != normalized) {
      _otpController.value = TextEditingValue(
        text: normalized,
        selection: TextSelection.collapsed(offset: normalized.length),
      );
      return;
    }

    var changed = false;
    for (int i = 0; i < _otpDigits.length; i++) {
      final nextValue = i < normalized.length ? normalized[i] : '';
      if (_otpDigits[i] != nextValue) {
        _otpDigits[i] = nextValue;
        changed = true;
      }
    }

    if (changed && mounted) {
      setState(() {});
    }

    if (normalized.length == _otpDigits.length) {
      _verifyOtp();
    }
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

  Future<void> _verifyOtp() async {
    if (!mounted || _isVerifying || otpCode.length != _otpDigits.length) {
      return;
    }

    setState(() {
      _isVerifying = true;
    });

    final result = await PhoneAuthService.verifyOtp(
      verificationId: _verificationId,
      smsCode: otpCode,
    );
    if (!mounted) {
      return;
    }

    if (!result.isSuccess) {
      setState(() {
        _isVerifying = false;
      });

      _showSnack(result.message ?? 'Invalid OTP code.');
      return;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }

      SessionManager.login(identifier: widget.phoneNumber);

      if (widget.returnResultOnSuccess) {
        final NavigatorState navigator = Navigator.of(context);
        navigator.pop(true);
        if (navigator.canPop()) {
          navigator.pop(true);
        }
        return;
      }

      Navigator.pushNamedAndRemoveUntil(
        context,
        AppRoutes.home,
        (route) => false,
      );
    });
  }

  void _showSnack(String message) {
    if (!mounted) {
      return;
    }

    final DateTime now = DateTime.now();
    final bool isDuplicate =
        _lastSnackMessage == message &&
        _lastSnackAt != null &&
        now.difference(_lastSnackAt!) <= _snackDedupWindow;
    if (isDuplicate) {
      return;
    }

    _lastSnackMessage = message;
    _lastSnackAt = now;

    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        content: Text(message),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary,
      body: SafeArea(
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          child: Stack(
            children: [
              Positioned(
                left: -1000,
                top: 0,
                width: 1,
                height: 1,
                child: TextField(
                  controller: _otpController,
                  focusNode: _otpFocusNode,
                  readOnly: true,
                  showCursor: false,
                  enableInteractiveSelection: false,
                  keyboardType: TextInputType.none,
                  autofillHints: const [AutofillHints.oneTimeCode],
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(_otpDigits.length),
                  ],
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    counterText: '',
                    isCollapsed: true,
                  ),
                ),
              ),
              LayoutBuilder(
                builder: (context, constraints) {
                  return SingleChildScrollView(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: constraints.maxHeight,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          IconButton(
                            onPressed: () => Navigator.pop(context),
                            icon: const Icon(
                              EneftyIcons.arrow_left_2_outline,
                              color: Colors.white,
                            ),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                          Column(
                            children: [
                              Center(
                                child: Image.asset(
                                  "assets/images/e-mart_v2.png",
                                  width: 120,
                                  fit: BoxFit.cover,
                                ),
                              ),
                              const SizedBox(height: 10),
                              const Text(
                                "Enter the verification code we've sent\nto your mobile phone number",
                                textAlign: TextAlign.left,
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 16,
                                  height: 1.5,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: List.generate(
                              _otpLength,
                              (index) => OtpBox(value: _otpDigits[index]),
                            ),
                          ),
                          const SizedBox(height: 10),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.12),
                            ),
                            child: Column(
                              children: [
                                const Text(
                                  'From Messages',
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 12,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  _isVerifying
                                      ? 'Verifying...'
                                      : 'Code sent to ${widget.e164PhoneNumber}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),
                          _buildNumberRow(['1', '2', '3']),
                          const SizedBox(height: 10),
                          _buildNumberRow(['4', '5', '6']),
                          const SizedBox(height: 10),
                          _buildNumberRow(['7', '8', '9']),
                          const SizedBox(height: 10),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              const SizedBox(width: 76, height: 76),
                              KeypadButton(
                                label: '0',
                                onTap: () => _onNumberTap('0'),
                              ),
                              KeypadButton(
                                icon: EneftyIcons.eraser_outline,
                                onTap: _onBackspace,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNumberRow(List<String> numbers) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: numbers
          .map(
            (number) =>
                KeypadButton(label: number, onTap: () => _onNumberTap(number)),
          )
          .toList(),
    );
  }
}
