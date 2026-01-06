class Validators {
  // 🔐 Email validation
  static String? email(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Email is required';
    }

    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');

    if (!emailRegex.hasMatch(value.trim())) {
      return 'Enter a valid email address';
    }

    return null;
  }

  // 🔐 Password validation
  static String? password(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }

    if (value.length < 6) {
      return 'Password must be at least 6 characters';
    }

    return null;
  }

  // 👤 Name validation
  static String? name(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'This field is required';
    }

    if (value.trim().length < 3) {
      return 'Must be at least 3 characters';
    }

    return null;
  }

  // 📘 Course title validation
  static String? courseTitle(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Course title is required';
    }
    return null;
  }

  // 💰 Price validation
  static String? price(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Price is required';
    }

    final price = double.tryParse(value);
    if (price == null || price < 0) {
      return 'Enter a valid price';
    }

    return null;
  }
}
