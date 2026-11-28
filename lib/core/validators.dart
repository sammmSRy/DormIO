/// Data validation used by BOTH the UI forms and the repositories.
/// Every method returns `null` when valid, or an error message when invalid,
/// so it can be plugged straight into a TextFormField:
///   TextFormField(validator: Validators.email)
class Validators {
  static String? requiredField(String? v, {String field = 'This field'}) =>
      (v == null || v.trim().isEmpty) ? '$field is required' : null;

  static String? fullName(String? v) {
    final s = v?.trim() ?? '';
    if (s.isEmpty) return 'Full name is required';
    if (s.length < 2) return 'Name is too short';
    if (s.length > 60) return 'Name must be 60 characters or fewer';
    return null;
  }

  static final _emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

  static String? email(String? v) {
    final s = v?.trim() ?? '';
    if (s.isEmpty) return 'Email is required';
    if (!_emailRegex.hasMatch(s)) return 'Enter a valid email address';
    return null;
  }

  /// Accepts "+639171234567", "0917 123 4567", "80-1234-5678", etc.
  static String? phone(String? v) {
    final s = normalizePhone(v ?? '');
    if (s.isEmpty) return 'Phone number is required';
    if (!RegExp(r'^\+?[0-9]{7,15}$').hasMatch(s)) {
      return 'Enter a valid phone number';
    }
    return null;
  }

  /// Removes spaces, dashes and brackets.
  static String normalizePhone(String raw) =>
      raw.replaceAll(RegExp(r'[\s\-()]'), '');

  /// Builds a stored phone number from the country dropdown + local number.
  /// toE164('+81', '080-1234-5678') -> '+818012345678'
  static String toE164(String countryCode, String local) {
    var digits = normalizePhone(local);
    if (digits.startsWith('+')) return digits;
    if (digits.startsWith('0')) digits = digits.substring(1);
    return '$countryCode$digits';
  }

  /// "At least 8 characters with numbers & symbols" (Create Account screen).
  static String? password(String? v) {
    final s = v ?? '';
    if (s.length < 8) return 'Use at least 8 characters';
    if (!RegExp(r'[0-9]').hasMatch(s)) return 'Add at least one number';
    if (!RegExp(r'[^A-Za-z0-9]').hasMatch(s)) return 'Add at least one symbol';
    return null;
  }

  /// 0..4 -> drives the 4-segment strength bar on the Create Account screen.
  static int passwordStrength(String s) {
    var score = 0;
    if (s.length >= 8) score++;
    if (RegExp(r'[0-9]').hasMatch(s)) score++;
    if (RegExp(r'[^A-Za-z0-9]').hasMatch(s)) score++;
    if (RegExp(r'[A-Z]').hasMatch(s) && RegExp(r'[a-z]').hasMatch(s)) score++;
    return score;
  }

  static String? price(String? v) {
    final n = double.tryParse((v ?? '').replaceAll(',', '').trim());
    if (n == null) return 'Enter a valid price';
    if (n <= 0) return 'Price must be greater than 0';
    if (n > 1000000) return 'Price is too high';
    return null;
  }

  static String? positiveInt(String? v, {int max = 100, String field = 'Value'}) {
    final n = int.tryParse((v ?? '').trim());
    if (n == null) return '$field must be a whole number';
    if (n < 1) return '$field must be at least 1';
    if (n > max) return '$field must be $max or fewer';
    return null;
  }

  static String? amount(double? v) {
    if (v == null || v <= 0) return 'Amount must be greater than 0';
    if (v > 1000000) return 'Amount is too high';
    return null;
  }

  static String? moveInDate(DateTime? d) {
    if (d == null) return 'Choose a move-in date';
    final today = DateTime.now();
    final startOfToday = DateTime(today.year, today.month, today.day);
    if (d.isBefore(startOfToday)) return 'Move-in date cannot be in the past';
    return null;
  }

  static String? durationMonths(int? m) {
    if (m == null || m < 1) return 'Stay must be at least 1 month';
    if (m > 24) return 'Stay cannot be longer than 24 months';
    return null;
  }
}
