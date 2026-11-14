/// Format angka dan tanggal untuk UI kasir.
/// Ditulis manual agar tidak bergantung pada data locale intl.
library;

String formatRupiah(num value) {
  final rounded = value.round();
  final negative = rounded < 0;
  final digits = rounded.abs().toString();
  final buffer = StringBuffer();
  for (var i = 0; i < digits.length; i++) {
    final remaining = digits.length - i;
    buffer.write(digits[i]);
    if (remaining > 1 && remaining % 3 == 1) {
      buffer.write('.');
    }
  }
  return '${negative ? '-' : ''}Rp$buffer';
}

String _two(int n) => n.toString().padLeft(2, '0');

const List<String> _shortMonths = [
  'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
  'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des',
];

/// Contoh hasil: 14 Nov 2026, 09.30
String formatDateTime(DateTime dt) {
  return '${dt.day} ${_shortMonths[dt.month - 1]} ${dt.year}, '
      '${_two(dt.hour)}.${_two(dt.minute)}';
}

/// Contoh hasil: 14 Nov 2026
String formatDate(DateTime dt) {
  return '${dt.day} ${_shortMonths[dt.month - 1]} ${dt.year}';
}

/// Contoh hasil: 09.30
String formatTime(DateTime dt) {
  return '${_two(dt.hour)}.${_two(dt.minute)}';
}
