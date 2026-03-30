class AuthValidationResult {
  final bool isValid;
  final String? message;
  final String normalizedIdentifier;

  const AuthValidationResult({
    required this.isValid,
    this.message,
    this.normalizedIdentifier = '',
  });
}

class AuthService {
  AuthService._();

  static AuthValidationResult validateLoginInput({
    required String identifier,
    required String password,
  }) {
    final String normalizedIdentifier = identifier.trim().toLowerCase();
    final String normalizedPassword = password.trim();

    if (normalizedIdentifier.isEmpty || normalizedPassword.isEmpty) {
      return const AuthValidationResult(
        isValid: false,
        message: 'Please enter email and password',
      );
    }

    if (!_isValidEmail(normalizedIdentifier)) {
      return const AuthValidationResult(
        isValid: false,
        message: 'Please enter a valid email address',
      );
    }

    return AuthValidationResult(
      isValid: true,
      normalizedIdentifier: normalizedIdentifier,
    );
  }

  static AuthValidationResult validateRegistrationInput({
    required String email,
    required String password,
  }) {
    final String normalizedEmail = email.trim().toLowerCase();
    final String normalizedPassword = password.trim();

    if (normalizedEmail.isEmpty && normalizedPassword.isEmpty) {
      return const AuthValidationResult(
        isValid: false,
        message: 'Email and password are required',
      );
    }

    if (normalizedEmail.isEmpty) {
      return const AuthValidationResult(
        isValid: false,
        message: 'Email is required',
      );
    }

    if (normalizedPassword.isEmpty) {
      return const AuthValidationResult(
        isValid: false,
        message: 'Password is required',
      );
    }

    if (!_isValidEmail(normalizedEmail)) {
      return const AuthValidationResult(
        isValid: false,
        message: 'Please enter a valid email address',
      );
    }

    if (normalizedPassword.length < 6) {
      return const AuthValidationResult(
        isValid: false,
        message: 'Password must be at least 6 characters',
      );
    }

    return AuthValidationResult(
      isValid: true,
      normalizedIdentifier: normalizedEmail,
    );
  }

  static AuthValidationResult validateRegistrationPhone(String value) {
    final String normalizedPhone = normalizePhoneDigits(value);
    if (normalizedPhone.length < 8 || normalizedPhone.length > 15) {
      return const AuthValidationResult(
        isValid: false,
        message: 'Please enter a valid phone number',
      );
    }

    return AuthValidationResult(
      isValid: true,
      normalizedIdentifier: normalizedPhone,
    );
  }

  static String normalizePhoneDigits(String rawPhone) {
    final StringBuffer buffer = StringBuffer();
    for (final int codeUnit in rawPhone.trim().codeUnits) {
      if (codeUnit >= 48 && codeUnit <= 57) {
        buffer.writeCharCode(codeUnit);
      }
    }
    return buffer.toString();
  }

  static bool _isValidEmail(String value) {
    final String email = value.trim();
    if (email.isEmpty || email.contains(' ')) {
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

    final int dotIndex = domainPart.indexOf('.');
    if (dotIndex <= 0 || dotIndex >= domainPart.length - 1) {
      return false;
    }

    return true;
  }
}
