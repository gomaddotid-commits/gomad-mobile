import 'theme/gomad_theme.dart';

/// Ruang kerja yang dikenal aplikasi native.
///
/// Satu akun = satu fungsi (aturan yang sama dengan web). Peta dari
/// `account_type` ke ruang kerja ada di sini dan **hanya** di sini, supaya
/// menambah peran baru cukup satu baris.
///
/// Kenapa tidak semua peran? Tiga peran di bawah ini yang benar-benar butuh
/// dibawa di ponsel: penumpang memesan di jalan, supir mengabsen penumpang di
/// terminal, penjaga warung mencatat jualan sambil berdiri. Peran lain tetap
/// memakai web karena pekerjaannya di meja (layar besar, banyak tabel).
enum Workspace {
  passenger('Penumpang', 'Cari jadwal, pesan tiket, dan pantau perjalanan.'),
  driver('Supir', 'Lihat tugas, naikkan penumpang, dan tutup perjalanan.'),
  warungGuard('Penjaga warung', 'Catat penjualan harian di kasir warung.'),
  warungOwner('Pemilik warung', 'Pantau penjualan kasir warung.'),
  webOnly('Belum ada di aplikasi', 'Peran ini masih dikerjakan di web.');

  const Workspace(this.label, this.description);

  final String label;
  final String description;

  /// `account_type` dari kontrak API → ruang kerja native.
  static Workspace fromAccountType(String? accountType) {
    return switch (accountType) {
      'customer' => Workspace.passenger,
      'driver' => Workspace.driver,
      'warung_guard' => Workspace.warungGuard,
      'warung_owner' => Workspace.warungOwner,
      _ => Workspace.webOnly,
    };
  }

  DesignLanguage get language => this == Workspace.passenger
      ? DesignLanguage.consumer
      : DesignLanguage.operational;
}
