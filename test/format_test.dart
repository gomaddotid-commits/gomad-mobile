import 'package:flutter_test/flutter_test.dart';
import 'package:gomad_mobile/src/format.dart';

void main() {
  test('format rupiah memakai pemisah ribuan tanpa desimal', () {
    expect(asMoney('160545.00'), 'Rp 160.545');
    expect(asMoney('1000000.00'), 'Rp 1.000.000');
    expect(asMoney('0.00'), 'Rp 0');
    expect(asMoney(null), '-');
  });

  test('nilai dinamis dari API dikonversi dengan aman', () {
    expect(asInt(12), 12);
    expect(asInt('12'), 12);
    expect(asInt(12.0), 12);
    expect(asInt(null), isNull);
    expect(asInt('bukan angka'), isNull);
    expect(asStrings(['A1', 'A2']), ['A1', 'A2']);
    expect(asStrings(null), isEmpty);
  });

  test('jam dan tanggal diformat sesuai kontrak', () {
    expect(asClock('07:30:00'), '07:30');
    expect(asClock(null), '-');
    expect(asDate(DateTime(2026, 3, 7)), '2026-03-07');
  });
}
