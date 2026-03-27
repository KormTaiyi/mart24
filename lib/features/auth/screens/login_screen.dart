import 'package:flutter/material.dart';
import 'package:enefty_icons/enefty_icons.dart';
import 'package:mart24/core/network/api_exception.dart';
import 'package:mart24/core/routes/app_routes.dart';
import 'package:mart24/core/state/session_manager.dart';
import 'package:mart24/core/storage/app_storage.dart';
import 'package:mart24/features/auth/models/auth_switch_result.dart';
import 'package:mart24/features/auth/screens/register_screen.dart';
import 'package:mart24/features/auth/services/api/auth_api_service.dart';
import 'package:mart24/features/auth/services/auth_service.dart';
import 'package:mart24/features/auth/services/social_auth_service.dart';
import 'package:mart24/features/auth/widgets/auth_background.dart';
import 'package:mart24/features/auth/widgets/auth_social_buttons.dart';
import 'package:mart24/features/auth/widgets/auth_submit_button.dart';
import 'package:mart24/features/auth/widgets/auth_text_field.dart';
import 'package:mart24/features/auth/widgets/auth_toggle.dart';

class LoginScreen extends StatefulWidget {
  final bool returnResultOnSuccess;
  final bool useSwitchResultForToggle;

  const LoginScreen({
    super.key,
    this.returnResultOnSuccess = false,
    this.useSwitchResultForToggle = false,
  });

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  static const String _rememberMeEnabledKey = 'auth.rememberMe.enabled.v1';
  static const String _rememberedIdentifierKey =
      'auth.rememberMe.identifier.v1';
  static const Duration _snackDedupWindow = Duration(seconds: 2);
  final AuthApiService _authApiService = AuthApiService();
  bool _rememberMe = false;
  bool _isSubmitting = false;
  bool _isSocialLoading = false;
  String? _lastSnackMessage;
  DateTime? _lastSnackAt;
  final TextEditingController _identifierController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _restoreRememberedIdentifier();
  }

  @override
  void dispose() {
    _identifierController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _restoreRememberedIdentifier() async {
    final bool rememberMeEnabled =
        await AppStorage.getBool(_rememberMeEnabledKey) ?? false;
    final String rememberedIdentifier =
        (await AppStorage.getString(_rememberedIdentifierKey) ?? '').trim();

    if (!mounted) {
      return;
    }

    setState(() {
      _rememberMe = rememberMeEnabled;
      if (rememberMeEnabled && rememberedIdentifier.isNotEmpty) {
        _identifierController.text = rememberedIdentifier;
      }
    });
  }

  Future<void> _persistRememberMe({
    required String identifier,
    required bool rememberMe,
  }) async {
    if (rememberMe) {
      await AppStorage.setBool(_rememberMeEnabledKey, true);
      await AppStorage.setString(_rememberedIdentifierKey, identifier.trim());
      return;
    }

    await AppStorage.setBool(_rememberMeEnabledKey, false);
    await AppStorage.remove(_rememberedIdentifierKey);
  }

  Future<void> _submit() async {
    if (_isSubmitting || _isSocialLoading) {
      return;
    }

    final AuthValidationResult validation = AuthService.validateLoginInput(
      identifier: _identifierController.text,
      password: _passwordController.text,
    );

    if (!validation.isValid) {
      FocusScope.of(context).unfocus();
      await Future<void>.delayed(const Duration(milliseconds: 120));
      if (!mounted) {
        return;
      }

      _showSnack(validation.message ?? 'Invalid input');
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final tokens = await _authApiService.login(
        identifier: validation.normalizedIdentifier,
        password: _passwordController.text.trim(),
      );
      if (!tokens.hasAccessToken) {
        _showSnack('Login failed. Missing access token in API response.');
        return;
      }

      await _persistRememberMe(
        identifier: validation.normalizedIdentifier,
        rememberMe: _rememberMe,
      );
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
      _showSnack('Unable to login right now. Please try again.');
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
    _showSnack('Phone OTP login is currently unavailable. Use email login.');
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

        final tokens = await _authApiService.googleLoginClient(
          idToken: idToken,
          accessToken: result.accessToken,
        );
        if (!tokens.hasAccessToken) {
          _showSnack('Google login response does not include an access token.');
          return;
        }

        await _persistRememberMe(
          identifier: result.identifier ?? '',
          rememberMe: _rememberMe,
        );
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
        'Social sign-in is ready on client. Connect it to your backend auth endpoint to complete login.',
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
      titlePrefix: 'Login for',
      titleHighlight: 'Mart 24',
      description:
          'Create a new account to receive exclusive offers and shop products at Mart 24',
      isFormScrollable: false,
      child: Column(
        children: [
          AuthToggle(
            selectedTab: AuthTab.login,
            onLoginTap: () {},
            onRegisterTap: () {
              if (widget.useSwitchResultForToggle) {
                Navigator.of(context).pop(AuthSwitchResult.toRegister);
                return;
              }

              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (_) => RegisterScreen(
                    returnResultOnSuccess: widget.returnResultOnSuccess,
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 10),
          AuthTextField(
            hintText: "Email",
            icon: EneftyIcons.sms_outline,
            keyboardType: TextInputType.emailAddress,
            controller: _identifierController,
          ),
          const SizedBox(height: 14),
          AuthTextField(
            hintText: "Password",
            icon: EneftyIcons.lock_outline,
            isPassword: true,
            controller: _passwordController,
          ),
          Row(
            children: [
              Transform.scale(
                scale: 0.95,
                child: Checkbox(
                  value: _rememberMe,
                  onChanged: (value) async {
                    final bool nextValue = value ?? false;
                    setState(() {
                      _rememberMe = nextValue;
                    });
                    if (!nextValue) {
                      await _persistRememberMe(
                        identifier: '',
                        rememberMe: false,
                      );
                    }
                  },
                  activeColor: Colors.white,
                  checkColor: const Color(0xFF1F5B74),
                  side: const BorderSide(color: Colors.white, width: 1.6),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              const Expanded(
                child: Text(
                  'Remember Me',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              InkWell(
                borderRadius: BorderRadius.circular(8),
                onTap: () {
                  Navigator.pushNamed(context, AppRoutes.forgotPassword);
                },
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                  child: Text(
                    'Forgot Password?',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
          AuthSubmitButton(
            label: _isSubmitting ? 'Logging in...' : 'Login',
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
            isLoading: _isSubmitting || _isSocialLoading,
          ),
        ],
      ),
    );
  }
}
