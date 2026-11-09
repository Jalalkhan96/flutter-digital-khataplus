// Small display helpers shared by every screen. Plain Dart only.

/// Formats an amount the way a shopkeeper writes it:
/// `1250` -> "Rs 1,250", `1250.5` -> "Rs 1,250.50", `-400` -> "-Rs 400".
String rupees(num value) {
  final sign = value < 0 ? '-' : '';
  final abs = value.abs();
  final whole = abs.truncate();
  final fraction = abs - whole;

  final digits = whole.toString();
  final grouped = StringBuffer();
  for (var i = 0; i < digits.length; i++) {
    grouped.write(digits[i]);
    final remaining = digits.length - i - 1;
    if (remaining > 0 && remaining % 3 == 0) grouped.write(',');
  }

  if (fraction == 0) return '${sign}Rs $grouped';
  final paisa = (fraction * 100).round().toString().padLeft(2, '0');
  return '${sign}Rs $grouped.$paisa';
}

/// "9 Nov 2026"-style short date.
String shortDate(DateTime date) {
  const months = <String>[
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  return '${date.day} ${months[date.month - 1]} ${date.year}';
}

/// Parses what the shopkeeper typed into an amount field.
///
/// Accepts "1250", "1,250" and "1250.50". Returns null for empty,
/// non-numeric or non-positive input so forms can show one clean error.
double? parseAmount(String raw) {
  final cleaned = raw.replaceAll(',', '').trim();
  if (cleaned.isEmpty) return null;
  final value = double.tryParse(cleaned);
  if (value == null || value <= 0) return null;
  return value;
}
