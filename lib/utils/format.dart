import 'package:intl/intl.dart';

/// Money, phone and date formatting shared by every screen.
///
/// Before this existed, `NumberFormat('#,##0', 'en_KE')` was declared in two
/// screens and the member sheet invented its own `toStringAsFixed(0)` format.
/// `en_KE` is not a locale bundled with intl 0.19.0, so the locale argument was
/// silently falling back to `en`. These helpers state the intent once.
class Format {
  const Format._();

  static final NumberFormat _whole = NumberFormat('#,##0');
  static final NumberFormat _withCents = NumberFormat('#,##0.00');
  static final DateFormat _dueDate = DateFormat('d MMM y');
  static final DateFormat _stamp = DateFormat('d MMM, h:mm a');

  /// `1500.5` reads as `1,501`; cents are only shown when they exist so the
  /// collected and outstanding totals on screen reconcile.
  static String kes(num? value) {
    if (value == null) return 'KES 0';
    final isWhole = value == value.roundToDouble();
    final text = isWhole ? _whole.format(value) : _withCents.format(value);
    return 'KES $text';
  }

  /// Bare grouped number, for places that render the KES label themselves.
  static String amount(num? value) =>
      value == null ? '0' : _whole.format(value);

  static String dueDate(DateTime date) => _dueDate.format(date);

  static String timestamp(DateTime date) => _stamp.format(date.toLocal());

  /// Best effort timestamp parse; the API sends ISO 8601 or null.
  static String timestampFrom(String? iso) {
    if (iso == null || iso.isEmpty) return '';
    final parsed = DateTime.tryParse(iso);
    return parsed == null ? '' : timestamp(parsed);
  }

  /// `0712 345 678` reads better than `+254712345678` on a small screen.
  static String phone(String raw) {
    final digits = raw.replaceAll(RegExp(r'\D'), '');
    final national = digits.startsWith('254') && digits.length == 12
        ? digits.substring(3)
        : digits.startsWith('0') && digits.length == 10
            ? digits.substring(1)
            : digits.length == 9
                ? digits
                : null;
    if (national == null || national.length != 9) return raw;
    return '0${national.substring(0, 3)} ${national.substring(3, 6)} '
        '${national.substring(6)}';
  }

  /// Normalises to the `+2547XXXXXXXX` form the API stores, or returns null.
  static String? normalizeKenyanPhone(String raw) {
    final digits = raw.replaceAll(RegExp(r'\D'), '');
    String? national;
    if (digits.startsWith('254') && digits.length == 12) {
      national = digits.substring(3);
    } else if (digits.startsWith('0') && digits.length == 10) {
      national = digits.substring(1);
    } else if (digits.length == 9) {
      national = digits;
    }
    if (national == null || national.length != 9) return null;
    if (!national.startsWith('7') && !national.startsWith('1')) return null;
    return '+254$national';
  }

  /// First letter of a display name, safe when the name is empty.
  static String initial(String displayName) =>
      displayName.trim().isEmpty ? '?' : displayName.trim()[0].toUpperCase();
}
