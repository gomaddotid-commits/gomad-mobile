/// Pembantu konversi nilai JSON.
///
/// Sebagian field kontrak masih bertipe longgar (`Object?`) karena Scramble tidak
/// dapat menyimpulkan tipe dari nilai dinamis di controller. Konversi dilakukan
/// di satu tempat agar UI tidak penuh `as` yang rapuh.
int? asInt(Object? value) {
  if (value == null) {
    return null;
  }
  if (value is int) {
    return value;
  }
  if (value is num) {
    return value.toInt();
  }

  return int.tryParse('$value');
}

List<String> asStrings(Object? value) {
  if (value is List) {
    return value.map((item) => '$item').toList(growable: false);
  }

  return const <String>[];
}

/// Rp 160.545 — pemisah ribuan titik, tanpa desimal (Rupiah tanpa sen).
String asMoney(String? value) {
  final amount = double.tryParse(value ?? '');
  if (amount == null) {
    return '-';
  }

  final digits = amount.round().toString();
  final buffer = StringBuffer();

  for (var index = 0; index < digits.length; index++) {
    if (index > 0 && (digits.length - index) % 3 == 0) {
      buffer.write('.');
    }
    buffer.write(digits[index]);
  }

  return 'Rp $buffer';
}

/// `07:30:00` menjadi `07:30`.
String asClock(String? value) {
  if (value == null || value.isEmpty) {
    return '-';
  }

  return value.length >= 5 ? value.substring(0, 5) : value;
}

/// `yyyy-MM-dd` — bentuk tanggal yang diminta API.
String asDate(DateTime date) {
  final month = date.month.toString().padLeft(2, '0');
  final day = date.day.toString().padLeft(2, '0');

  return '${date.year}-$month-$day';
}
