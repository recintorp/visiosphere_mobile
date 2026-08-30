class Validators {
  /// Empty, whitespace-only, or one of the placeholder words the UI prints in
  /// place of a missing value. Saving any of these is what produced the blank
  /// and "None" rows QA reported, so none of them count as a real answer.
  static bool isBlank(String? value) {
    final v = (value ?? '').trim().toLowerCase();
    return v.isEmpty || v == 'none' || v == 'n/a' || v == 'null';
  }

  /// Deliberately permissive: it rejects the shapes that cannot be an address
  /// at all, and leaves the rest to the server, which is the only thing that
  /// can actually know whether an address exists.
  static bool isValidEmail(String value) =>
      RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(value.trim());

  static String? validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Email is required';
    }
    final emailRegex = RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
    if (!emailRegex.hasMatch(value)) {
      return 'Please enter a valid email';
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

  static String? validateUsername(String? value) {
    if (value == null || value.isEmpty) {
      return 'Username is required';
    }
    if (value.length < 3) {
      return 'Username must be at least 3 characters';
    }
    return null;
  }

  static String? validatePhoneNumber(String? value) {
    if (value == null || value.isEmpty) {
      return 'Phone number is required';
    }
    final phoneRegex = RegExp(r'^\+?1?\d{9,15}$');
    if (!phoneRegex.hasMatch(value.replaceAll(RegExp(r'\D'), ''))) {
      return 'Please enter a valid phone number';
    }
    return null;
  }
}