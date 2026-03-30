import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mart24/core/theme/app_color.dart';

class AuthTextField extends StatefulWidget {
  final String hintText;
  final IconData icon;
  final bool isPassword;
  final TextInputType keyboardType;
  final TextEditingController? controller;

  const AuthTextField({
    super.key,
    required this.hintText,
    required this.icon,
    this.isPassword = false,
    this.keyboardType = TextInputType.text,
    this.controller,
  });

  @override
  State<AuthTextField> createState() => _AuthTextFieldState();
}

class _AuthTextFieldState extends State<AuthTextField> {
  bool _obscurePassword = true;

  @override
  Widget build(BuildContext context) {
    final bool isPhoneField = widget.keyboardType == TextInputType.phone;
    final bool obscureText = widget.isPassword && _obscurePassword;

    return TextField(
      controller: widget.controller,
      obscureText: obscureText,
      keyboardType: widget.keyboardType,
      enableSuggestions: !widget.isPassword,
      autocorrect: !widget.isPassword,
      inputFormatters: isPhoneField
          ? [
              TextInputFormatter.withFunction((oldValue, newValue) {
                final String text = newValue.text;
                final bool hasInvalidChar = text.codeUnits.any(
                  (codeUnit) =>
                      (codeUnit < 48 || codeUnit > 57) && codeUnit != 43,
                );
                if (hasInvalidChar) {
                  return oldValue;
                }
                final int plusCount = '+'.allMatches(text).length;
                final bool hasInvalidPlus =
                    plusCount > 1 ||
                    (text.contains('+') && !text.startsWith('+'));
                if (hasInvalidPlus) {
                  return oldValue;
                }
                return newValue;
              }),
              LengthLimitingTextInputFormatter(16),
            ]
          : null,
      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
      decoration: InputDecoration(
        prefixIcon: Icon(
          widget.icon,
          color: AppColors.circleBackground,
          size: 22,
        ),
        suffixIcon: widget.isPassword
            ? IconButton(
                onPressed: () {
                  setState(() {
                    _obscurePassword = !_obscurePassword;
                  });
                },
                icon: Icon(
                  _obscurePassword
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                  color: AppColors.circleBackground,
                  size: 22,
                ),
              )
            : null,
        hintText: widget.hintText,
        hintStyle: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w500,
        ),
        filled: true,
        fillColor: Colors.white12,
        // contentPadding: const EdgeInsets.symmetric(vertical: 20),
        // prefixIconConstraints: const BoxConstraints(minWidth: 2),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(22),
          borderSide: BorderSide.none,
        ),
        // enabledBorder: OutlineInputBorder(
        // borderRadius: BorderRadius.circular(22),
        // borderSide: BorderSide(color: Colors.white),
        // ),
        // focusedBorder: OutlineInputBorder(
        // borderRadius: BorderRadius.circular(22),
        // borderSide: const BorderSide(color: Colors.white),
        // ),
      ),
    );
  }
}
