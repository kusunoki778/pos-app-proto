import 'package:flutter_test/flutter_test.dart';

import 'package:realtime_communication/core/formatters.dart';

void main() {
  group('formatRupiah', () {
    test('nol', () {
      expect(formatRupiah(0), 'Rp0');
    });

    test('angka kecil tanpa pemisah', () {
      expect(formatRupiah(950), 'Rp950');
    });

    test('ribuan', () {
      expect(formatRupiah(1500), 'Rp1.500');
    });

    test('jutaan', () {
      expect(formatRupiah(1234567), 'Rp1.234.567');
    });

    test('desimal dibulatkan', () {
      expect(formatRupiah(250.4), 'Rp250');
      expect(formatRupiah(250.6), 'Rp251');
    });

    test('negatif', () {
      expect(formatRupiah(-2000), '-Rp2.000');
    });
  });

  group('formatDateTime', () {
    test('format Indonesia', () {
      final dt = DateTime(2026, 11, 14, 9, 5);
      expect(formatDateTime(dt), '14 Nov 2026, 09.05');
    });
  });

  group('formatDate', () {
    test('tanpa jam', () {
      final dt = DateTime(2026, 1, 3);
      expect(formatDate(dt), '3 Jan 2026');
    });
  });
}
