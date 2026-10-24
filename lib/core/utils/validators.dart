class Validators {
  Validators._();

  static String? validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Email address is required';
    }
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9.!#$%&’*+/=?^_`{|}~-]+@[a-zA-Z0-9-]+(?:\.[a-zA-Z0-9-]+)+$',
    );
    if (!emailRegex.hasMatch(value.trim())) {
      return 'Please enter a valid email address';
    }
    return null;
  }

  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }
    if (value.length < 6) {
      return 'Password must be at least 6 characters';
    }
    return null;
  }

  static String? validateName(String? value, {String fieldName = 'Name'}) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName is required';
    }
    if (value.trim().length < 2) {
      return '$fieldName must be at least 2 characters';
    }
    return null;
  }

  static String? validatePhone(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Phone number is required';
    }
    final phoneRegex = RegExp(r'^[6-9]\d{9}$');
    final cleaned = value.replaceAll(RegExp(r'\s+|-'), '');
    if (!phoneRegex.hasMatch(cleaned)) {
      return 'Enter a valid 10-digit Indian mobile number';
    }
    return null;
  }

  static String? validatePinCode(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'PIN code is required';
    }
    final pinRegex = RegExp(r'^\d{6}$');
    if (!pinRegex.hasMatch(value.trim())) {
      return 'Enter a valid 6-digit postal PIN code';
    }
    return null;
  }

  static String? validateUtrNumber(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'UPI Reference / UTR Number is required';
    }
    final cleaned = value.trim();
    // Indian banking UTR is typically 12 digits or alphanumeric 10-18 chars
    final utrRegex = RegExp(r'^[a-zA-Z0-9]{10,22}$');
    if (!utrRegex.hasMatch(cleaned)) {
      return 'Enter a valid 12-digit or 10-22 character UTR / Ref number';
    }
    return null;
  }

  static String? validatePrice(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Price is required';
    }
    final parsed = double.tryParse(value.trim());
    if (parsed == null || parsed <= 0) {
      return 'Enter a valid positive price';
    }
    return null;
  }

  static String? validateStock(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Stock quantity is required';
    }
    final parsed = int.tryParse(value.trim());
    if (parsed == null || parsed < 0) {
      return 'Enter a non-negative integer for stock';
    }
    return null;
  }

  static String? validateRequired(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName is required';
    }
    return null;
  }
}
