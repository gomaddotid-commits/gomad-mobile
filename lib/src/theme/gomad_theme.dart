import 'package:flutter/material.dart';

import 'uds.dart';

/// Dua bahasa desain UDS v1.0 (web: `app/Core/Identity/Domain/DesignLanguage.php`).
///
/// - [consumer] — dipakai penumpang dan halaman publik: latar bergradasi,
///   permukaan kaca, navigasi bawah.
/// - [operational] — dipakai semua peran kerja (supir, penjaga warung, pemilik):
///   permukaan solid, kontras tinggi, satu aksi utama per layar.
enum DesignLanguage {
  consumer,
  operational;

  /// Akun pelanggan memakai bahasa konsumen; selain itu operasional.
  /// Nilai `account_type` berasal dari kontrak API (`customer`, `driver`, ...).
  static DesignLanguage fromAccountType(String? accountType) {
    return accountType == 'customer' ? DesignLanguage.consumer : DesignLanguage.operational;
  }

  bool get isConsumer => this == DesignLanguage.consumer;
}

/// Tema Material 3 yang diturunkan dari token [Uds].
///
/// Aplikasi ini tidak memakai `ColorScheme.fromSeed` dengan warna acak: seluruh
/// warna sudah ditentukan dokumen desain, jadi skema disusun eksplisit supaya
/// tidak ada nuansa hijau liar yang muncul dari algoritma Material.
abstract final class GomadTheme {
  static ThemeData of(DesignLanguage language) {
    const scheme = ColorScheme(
      brightness: Brightness.light,
      primary: Uds.greenDeep,
      onPrimary: Uds.white,
      primaryContainer: Uds.lime,
      onPrimaryContainer: Uds.black900,
      secondary: Uds.green,
      onSecondary: Uds.white,
      secondaryContainer: Uds.gray100,
      onSecondaryContainer: Uds.black900,
      tertiary: Uds.yellow,
      onTertiary: Uds.black900,
      error: Uds.error,
      onError: Uds.white,
      surface: Uds.white,
      onSurface: Uds.black900,
      surfaceContainerLowest: Uds.white,
      surfaceContainerLow: Uds.gray50,
      surfaceContainer: Uds.gray100,
      surfaceContainerHigh: Uds.gray200,
      surfaceContainerHighest: Uds.gray200,
      onSurfaceVariant: Uds.gray600,
      outline: Uds.gray300,
      outlineVariant: Uds.gray200,
      inverseSurface: Uds.black900,
      onInverseSurface: Uds.gray50,
      shadow: Uds.black900,
    );

    final base = ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: language.isConsumer ? Colors.transparent : Uds.gray50,
      splashFactory: InkSparkle.splashFactory,
      visualDensity: VisualDensity.standard,
    );

    return base.copyWith(
      textTheme: _textTheme(base.textTheme),
      appBarTheme: AppBarTheme(
        backgroundColor: language.isConsumer ? Colors.transparent : Uds.white,
        foregroundColor: Uds.black900,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0.5,
        centerTitle: false,
        titleTextStyle: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: Uds.black900,
          height: 1.3,
        ),
      ),
      cardTheme: CardThemeData(
        color: Uds.white,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Uds.radiusLg),
          side: const BorderSide(color: Uds.gray200),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(52),
          backgroundColor: Uds.greenDeep,
          foregroundColor: Uds.white,
          disabledBackgroundColor: Uds.gray200,
          disabledForegroundColor: Uds.gray500,
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Uds.radiusMd)),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size.fromHeight(Uds.minTapTarget),
          foregroundColor: Uds.greenDeep,
          side: const BorderSide(color: Uds.gray300),
          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Uds.radiusMd)),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: Uds.greenDeep,
          minimumSize: const Size(0, Uds.minTapTarget),
          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Uds.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        labelStyle: const TextStyle(color: Uds.gray600),
        hintStyle: const TextStyle(color: Uds.gray500),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(Uds.radiusMd),
          borderSide: const BorderSide(color: Uds.gray300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(Uds.radiusMd),
          borderSide: const BorderSide(color: Uds.gray300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(Uds.radiusMd),
          borderSide: const BorderSide(color: Uds.green, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(Uds.radiusMd),
          borderSide: const BorderSide(color: Uds.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(Uds.radiusMd),
          borderSide: const BorderSide(color: Uds.error, width: 2),
        ),
      ),
      chipTheme: base.chipTheme.copyWith(
        backgroundColor: Uds.gray100,
        selectedColor: Uds.lime,
        labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Uds.black900),
        side: const BorderSide(color: Uds.gray200),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Uds.radiusSm)),
      ),
      dividerTheme: const DividerThemeData(color: Uds.gray200, thickness: 1, space: 1),
      listTileTheme: const ListTileThemeData(
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        titleTextStyle: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Uds.black900),
        subtitleTextStyle: TextStyle(fontSize: 13, color: Uds.gray600),
        minVerticalPadding: 12,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: Uds.black900,
        contentTextStyle: const TextStyle(color: Uds.white, fontSize: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Uds.radiusMd)),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: Uds.white,
        indicatorColor: Uds.lime,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        height: 68,
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => TextStyle(
            fontSize: 12,
            fontWeight: states.contains(WidgetState.selected) ? FontWeight.w600 : FontWeight.w500,
            color: states.contains(WidgetState.selected) ? Uds.black900 : Uds.gray500,
          ),
        ),
        iconTheme: WidgetStateProperty.resolveWith(
          (states) => IconThemeData(
            size: 22,
            color: states.contains(WidgetState.selected) ? Uds.greenDeep : Uds.gray500,
          ),
        ),
      ),
      tabBarTheme: const TabBarThemeData(
        labelColor: Uds.greenDeep,
        unselectedLabelColor: Uds.gray500,
        indicatorColor: Uds.greenDeep,
        dividerColor: Uds.gray200,
        labelStyle: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        unselectedLabelStyle: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(color: Uds.green),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: Uds.white,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(Uds.radiusXl)),
        ),
      ),
    );
  }

  /// Skala tipografi UDS §5. Ukuran ponsel lebih kecil satu tingkat dari web
  /// karena jarak pandang lebih dekat; bobot dan tinggi baris tetap sama.
  static TextTheme _textTheme(TextTheme base) {
    return base
        .copyWith(
          displaySmall: const TextStyle(fontSize: 30, fontWeight: FontWeight.w700, height: 1.15, color: Uds.black900),
          headlineMedium: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700, height: 1.2, color: Uds.black900),
          headlineSmall: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600, height: 1.25, color: Uds.black900),
          titleLarge: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600, height: 1.3, color: Uds.black900),
          titleMedium: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, height: 1.35, color: Uds.black900),
          bodyLarge: const TextStyle(fontSize: 16, height: Uds.bodyHeight, color: Uds.black900),
          bodyMedium: const TextStyle(fontSize: 14, height: Uds.bodyHeight, color: Uds.black900),
          bodySmall: const TextStyle(fontSize: 13, height: Uds.bodyHeight, color: Uds.gray600),
          labelLarge: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Uds.black900),
          labelMedium: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 0.4, color: Uds.gray600),
        )
        .apply(fontFamilyFallback: const ['Inter']);
  }
}
