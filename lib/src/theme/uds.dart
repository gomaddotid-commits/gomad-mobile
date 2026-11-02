import 'package:flutter/material.dart';

/// Token visual UDS v1.0.
///
/// Angka di berkas ini **disalin langsung** dari `docs/blueprint/15-design-system.md`
/// dan `resources/css/app.css` — bukan dikarang di sini. Kalau token web berubah,
/// ubah di dua tempat sekaligus; jangan membuat nilai baru yang hanya ada di
/// aplikasi.
///
/// Satu penyimpangan sengaja diikuti dari web: `gray500` memakai `#6b776c`
/// (kontras 4.69:1), bukan `#7d887d` dari dokumen (3.69:1 — gagal §12.1).
abstract final class Uds {
  // ---- Merek (docs §4.2) ----
  static const lime = Color(0xFFA8E62E);
  static const limeFresh = Color(0xFFDFFF52);
  static const green = Color(0xFF258447);
  static const greenDeep = Color(0xFF174D38);
  static const yellow = Color(0xFFF6D83D);

  // ---- Netral ----
  static const gray50 = Color(0xFFF7FAF2);
  static const gray100 = Color(0xFFF1F3EF);
  static const gray200 = Color(0xFFE4E8E1);
  static const gray300 = Color(0xFFD3D9CF);
  static const gray400 = Color(0xFFA7B0A6);
  static const gray500 = Color(0xFF6B776C);
  static const gray600 = Color(0xFF5E6A5F);
  static const black900 = Color(0xFF263B2B);

  // ---- Semantik ----
  static const success = Color(0xFF258447);
  static const warning = Color(0xFFD99A18);
  static const error = Color(0xFFD64545);
  static const info = Color(0xFF3278B7);

  static const white = Colors.white;

  // ---- Bentuk ----
  static const radiusSm = 8.0;
  static const radiusMd = 12.0;
  static const radiusLg = 16.0;
  static const radiusXl = 24.0;

  // ---- Jarak (skala 4) ----
  static const space1 = 4.0;
  static const space2 = 8.0;
  static const space3 = 12.0;
  static const space4 = 16.0;
  static const space5 = 24.0;
  static const space6 = 32.0;

  /// Padding halaman. Web memakai 16 → 24 → 32 → 40 mengikuti lebar layar;
  /// di ponsel 16 adalah nilai yang berlaku, tablet naik ke 24.
  static double gutter(BuildContext context) =>
      MediaQuery.sizeOf(context).width >= 700 ? space5 : space4;

  /// Target sentuh minimum. UDS §12.2 meminta 44 logical pixel, Material 48 —
  /// ambil yang lebih ketat.
  static const minTapTarget = 48.0;

  /// Line-height teks isi yang dipakai seluruh aplikasi.
  static const bodyHeight = 1.55;
}
