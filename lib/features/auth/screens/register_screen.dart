import 'package:enefty_icons/enefty_icons.dart';
import 'package:flutter/material.dart';
import 'package:mart24/core/network/api_exception.dart';
import 'package:mart24/core/routes/app_routes.dart';
import 'package:mart24/core/state/session_manager.dart';
import 'package:mart24/features/auth/models/auth_switch_result.dart';
import 'package:mart24/features/auth/screens/login_screen.dart';
import 'package:mart24/features/auth/services/api/auth_api_service.dart';
import 'package:mart24/features/auth/services/auth_service.dart';
import 'package:mart24/features/auth/services/social_auth_service.dart';
import 'package:mart24/features/auth/widgets/auth_background.dart';
import 'package:mart24/features/auth/widgets/auth_social_buttons.dart';
import 'package:mart24/features/auth/widgets/auth_submit_button.dart';
import 'package:mart24/features/auth/widgets/auth_text_field.dart';
import 'package:mart24/features/auth/widgets/auth_toggle.dart';

class RegisterScreen extends StatefulWidget {
  final bool returnResultOnSuccess;
  final bool useSwitchResultForToggle;

  const RegisterScreen({
    super.key,
    this.returnResultOnSuccess = false,
    this.useSwitchResultForToggle = false,
  });

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  static const Duration _snackDedupWindow = Duration(seconds: 2);

  final AuthApiService _authApiService = AuthApiService();
  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isSubmitting = false;
  bool _isSocialLoading = false;
  String? _lastSnackMessage;
  DateTime? _lastSnackAt;

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_isSubmitting || _isSocialLoading) {
      return;
    }

    final AuthValidationResult validation =
        AuthService.validateRegistrationInput(
          fullName: _fullNameController.text,
          email: _emailController.text,
          password: _passwordController.text,
        );

    if (!validation.isValid) {
      FocusScope.of(context).unfocus();
      await Future<void>.delayed(const Duration(milliseconds: 120));
      if (!mounted) {
        return;
      }

      _showSnack(validation.message ?? 'Invalid registration input');
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final tokens = await _authApiService.registerClient(
        fullName: _fullNameController.text.trim(),
        email: validation.normalizedIdentifier,
        password: _passwordController.text.trim(),
      );

      if (!tokens.hasAccessToken) {
        _showSnack(
          'Registration failed. Missing access token in API response.',
        );
        return;
      }

      SessionManager.login(identifier: validation.normalizedIdentifier);

      if (!mounted) {
        return;
      }

      if (widget.returnResultOnSuccess) {
        Navigator.of(context).pop(true);
        return;
      }

      Navigator.pushNamedAndRemoveUntil(
        context,
        AppRoutes.home,
        (route) => false,
      );
    } on ApiException catch (error) {
      _showSnack(error.message);
    } catch (_) {
      _showSnack('Unable to register right now. Please try again.');
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  Future<void> _handleGoogleSignIn() async {
    await _handleSocialSignIn(
      SocialAuthService.signInWithGoogle,
      useBackendForGoogle: true,
    );
  }

  Future<void> _handleAppleSignIn() async {
    await _handleSocialSignIn(SocialAuthService.signInWithApple);
  }

  void _handlePhoneSignIn() {
    _showSnack(
      'Phone OTP registration is currently unavailable. Use email registration.',
    );
  }

  Future<void> _handleSocialSignIn(
    Future<SocialAuthResult> Function() signInAction, {
    bool useBackendForGoogle = false,
  }) async {
    if (_isSubmitting || _isSocialLoading) {
      return;
    }

    setState(() {
      _isSocialLoading = true;
    });

    try {
      final SocialAuthResult result = await signInAction();
      if (useBackendForGoogle) {
        final String? idToken = result.idToken?.trim();
        if (idToken == null || idToken.isEmpty) {
          _showSnack('Google sign-in did not return an ID token.');
          return;
        }

        final tokens = await _authApiService.googleRegisterClient(
          idToken: idToken,
          accessToken: result.accessToken,
        );
        if (!tokens.hasAccessToken) {
          _showSnack(
            'Google register response does not include an access token.',
          );
          return;
        }

        SessionManager.login(identifier: result.identifier);

        if (!mounted) {
          return;
        }

        if (widget.returnResultOnSuccess) {
          Navigator.of(context).pop(true);
          return;
        }

        Navigator.pushNamedAndRemoveUntil(
          context,
          AppRoutes.home,
          (route) => false,
        );
        return;
      }

      _showSnack(
        'Social sign-in is ready on client. Connect it to your backend auth endpoint to complete registration.',
      );
    } on ApiException catch (error) {
      _showSnack(error.message);
    } on SocialAuthException catch (error) {
      _showSnack(error.message);
    } catch (_) {
      _showSnack('Authentication failed. Please try again.');
    } finally {
      if (mounted) {
        setState(() {
          _isSocialLoading = false;
        });
      }
    }
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
    return AuthBackground(
      titlePrefix: 'Register for',
      titleHighlight: 'Mart 24',
      description:
          'Create a new account to receive exclusive offers and shop products at Mart 24',
      isFormScrollable: false,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AuthToggle(
            selectedTab: AuthTab.register,
            onLoginTap: () {
              if (widget.useSwitchResultForToggle) {
                Navigator.of(context).pop(AuthSwitchResult.toLogin);
                return;
              }

              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (_) => LoginScreen(
                    returnResultOnSuccess: widget.returnResultOnSuccess,
                  ),
                ),
              );
            },
            onRegisterTap: _submit,
          ),
          const SizedBox(height: 10),
          AuthTextField(
            hintText: 'Full Name',
            icon: EneftyIcons.profile_circle_outline,
            controller: _fullNameController,
          ),
          const SizedBox(height: 10),
          AuthTextField(
            hintText: 'Email',
            icon: EneftyIcons.sms_outline,
            keyboardType: TextInputType.emailAddress,
            controller: _emailController,
          ),
          const SizedBox(height: 10),
          AuthTextField(
            hintText: 'Password',
            icon: EneftyIcons.lock_outline,
            isPassword: true,
            controller: _passwordController,
          ),
          const SizedBox(height: 10),
          AuthSubmitButton(
            label: _isSubmitting ? 'Registering...' : 'Register',
            onPressed: () {
              if (_isSubmitting || _isSocialLoading) {
                return;
              }
              _submit();
            },
          ),
          const SizedBox(height: 10),
          AuthSocialButtons(
            onAppleTap: _handleAppleSignIn,
            onGoogleTap: _handleGoogleSignIn,
            onPhoneTap: _handlePhoneSignIn,
            showTerms: true,
            isLoading: _isSocialLoading || _isSubmitting,
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
