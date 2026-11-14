import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Palet "hangat seperti toko".
/// Dipilih dari arah desain yang disetujui pemilik: krem seperti kertas kas,
/// hijau tua sebagai warna utama, kuning kunyit sebagai satu-satunya aksen.
class AppColors {
  const AppColors._();

  static const cream = Color(0xFFFAF6EE); // latar terang, mengurangi silau
  static const surface = Color(0xFFFFFDF7); // kartu di atas krem
  static const green = Color(0xFF1F4D3A); // primer, kontras aman di atas krem
  static const greenSoft = Color(0xFFE4EDE5); // latar chip ikon
  static const amber = Color(0xFFE0A526); // aksen: total, tombol bayar
  static const ink = Color(0xFF1C1B18); // teks utama
  static const inkMuted = Color(0xFF5C564A); // teks sekunder
  static const outline = Color(0xFFDCD3C2); // garis batas kartu
  static const error = Color(0xFFB3261E);

  // Versi gelap: permukaan hangat, bukan hitam murni.
  static const darkBg = Color(0xFF17150F);
  static const darkSurface = Color(0xFF211E17);
  static const darkGreen = Color(0xFF8CC7A6); // primer tetap terbaca di gelap
  static const darkOnGreen = Color(0xFF12241C);
  static const darkInk = Color(0xFFEFEAE0);
  static const darkInkMuted = Color(0xFFA89F8F);
  static const darkOutline = Color(0xFF3B372C);
}

/// Alasan tipografi: Plus Jakarta Sans, rupa huruf dari Indonesia,
/// dengan angka tabular supaya kolom harga rapi saat dipindai kasir.
TextTheme _textTheme(Brightness brightness) {
  final base = GoogleFonts.plusJakartaSansTextTheme(
    ThemeData(brightness: brightness).textTheme,
  );
  TextStyle tabular(TextStyle style) => style.copyWith(
        fontFeatures: const [FontFeature.tabularFigures()],
      );
  return base.copyWith(
    titleLarge: tabular(base.titleLarge!),
    titleMedium: tabular(base.titleMedium!),
    bodyMedium: tabular(base.bodyMedium!),
    labelLarge: tabular(base.labelLarge!),
  );
}

ThemeData buildLightTheme() {
  final scheme = ColorScheme.light(
    primary: AppColors.green,
    onPrimary: const Color(0xFFF7F3E8),
    secondary: AppColors.amber,
    onSecondary: AppColors.ink,
    surface: AppColors.surface,
    onSurface: AppColors.ink,
    error: AppColors.error,
    onError: Colors.white,
    outline: AppColors.outline,
  );

  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: AppColors.cream,
    textTheme: _textTheme(Brightness.light),
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.cream,
      foregroundColor: AppColors.ink,
      elevation: 0,
      centerTitle: false,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.surface,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppColors.outline),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppColors.outline),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppColors.green, width: 1.6),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.green,
        foregroundColor: const Color(0xFFF7F3E8),
        minimumSize: const Size.fromHeight(48),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        textStyle: const TextStyle(fontWeight: FontWeight.w600),
      ),
    ),
    cardTheme: CardThemeData(
      color: AppColors.surface,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: AppColors.outline),
      ),
      margin: EdgeInsets.zero,
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: AppColors.surface,
      indicatorColor: AppColors.greenSoft,
      iconTheme: WidgetStateProperty.resolveWith(
        (states) => IconThemeData(
          color: states.contains(WidgetState.selected)
              ? AppColors.green
              : AppColors.inkMuted,
        ),
      ),
      labelTextStyle: WidgetStateProperty.resolveWith(
        (states) => TextStyle(
          fontSize: 12,
          fontWeight: states.contains(WidgetState.selected)
              ? FontWeight.w700
              : FontWeight.w500,
          color: states.contains(WidgetState.selected)
              ? AppColors.green
              : AppColors.inkMuted,
        ),
      ),
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: AppColors.green,
      contentTextStyle: const TextStyle(color: Color(0xFFF7F3E8)),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ),
    dividerTheme: const DividerThemeData(color: AppColors.outline),
  );
}

ThemeData buildDarkTheme() {
  final scheme = ColorScheme.dark(
    primary: AppColors.darkGreen,
    onPrimary: AppColors.darkOnGreen,
    secondary: AppColors.amber,
    onSecondary: AppColors.darkBg,
    surface: AppColors.darkSurface,
    onSurface: AppColors.darkInk,
    error: const Color(0xFFF2B8B5),
    onError: const Color(0xFF601410),
    outline: AppColors.darkOutline,
  );

  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: AppColors.darkBg,
    textTheme: _textTheme(Brightness.dark),
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.darkBg,
      foregroundColor: AppColors.darkInk,
      elevation: 0,
      centerTitle: false,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.darkSurface,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppColors.darkOutline),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppColors.darkOutline),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppColors.darkGreen, width: 1.6),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.darkGreen,
        foregroundColor: AppColors.darkOnGreen,
        minimumSize: const Size.fromHeight(48),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        textStyle: const TextStyle(fontWeight: FontWeight.w600),
      ),
    ),
    cardTheme: CardThemeData(
      color: AppColors.darkSurface,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: AppColors.darkOutline),
      ),
      margin: EdgeInsets.zero,
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: AppColors.darkSurface,
      indicatorColor: const Color(0xFF2A3B31),
      iconTheme: WidgetStateProperty.resolveWith(
        (states) => IconThemeData(
          color: states.contains(WidgetState.selected)
              ? AppColors.darkGreen
              : AppColors.darkInkMuted,
        ),
      ),
      labelTextStyle: WidgetStateProperty.resolveWith(
        (states) => TextStyle(
          fontSize: 12,
          fontWeight: states.contains(WidgetState.selected)
              ? FontWeight.w700
              : FontWeight.w500,
          color: states.contains(WidgetState.selected)
              ? AppColors.darkGreen
              : AppColors.darkInkMuted,
        ),
      ),
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: AppColors.darkSurface,
      contentTextStyle: const TextStyle(color: AppColors.darkInk),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ),
    dividerTheme: const DividerThemeData(color: AppColors.darkOutline),
  );
}
