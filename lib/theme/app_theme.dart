// 🎨 DESIGN SYSTEM: AppTheme
// File ini mendefinisikan semua elemen visual SYNC di satu tempat terpusat.
//
// Mengapa sentralisasi tema?
// Jika warna atau font perlu diubah, cukup ubah di sini, semua layar ikut berubah.
// Ini adalah prinsip "Single Source of Truth" dalam desain UI.
//
// Estetika: Minimalis, bersih, "preppy/soft" dengan dominasi putih dan aksen indigo.

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Konstanta warna yang digunakan di seluruh aplikasi.
class AppColors {
  // Warna primer: Abu-abu gelap yang elegan (bukan hitam pekat)
  static const Color textPrimary = Color(0xFF1A1A2E);
  // Warna sekunder: Abu-abu medium untuk teks pendukung
  static const Color textSecondary = Color(0xFF6B7280);
  // Warna aksen: Biru keunguan yang lembut (indigo)
  static const Color accent = Color(0xFF6366F1);
  // Warna aksen muda untuk highlight dan latar belakang elemen aktif
  static const Color accentLight = Color(0xFFEEF2FF);
  // Warna latar belakang utama (putih bersih)
  static const Color background = Color(0xFFFFFFFF);
  // Warna latar belakang permukaan card
  static const Color surface = Color(0xFFF9FAFB);
  // Warna border yang sangat tipis dan subtle
  static const Color border = Color(0xFFE5E7EB);
  // Warna danger untuk tombol hapus
  static const Color danger = Color(0xFFEF4444);
  // Warna danger muda untuk latar konfirmasi hapus
  static const Color dangerLight = Color(0xFFFEF2F2);
}

/// Kelas pembangun tema MaterialApp.
class AppTheme {
  /// Menghasilkan ThemeData menggunakan Google Fonts DM Sans.
  ///
  /// Mengapa google_fonts dibanding font lokal?
  /// google_fonts mengunduh font secara otomatis dan men-cache-nya.
  /// Ini menghilangkan kebutuhan untuk menyimpan file .ttf di dalam proyek,
  /// sehingga ukuran APK lebih kecil dan setup lebih mudah.
  static ThemeData get lightTheme {
    // Ambil TextTheme dari Google Fonts DM Sans sebagai base
    final dmSansTextTheme = GoogleFonts.dmSansTextTheme();

    return ThemeData(
      useMaterial3: true,
      // Terapkan font DM Sans ke seluruh TextTheme
      textTheme: dmSansTextTheme,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.accent,
        brightness: Brightness.light,
        surface: AppColors.background,
      ),
      scaffoldBackgroundColor: AppColors.background,

      // AppBar: transparan tanpa shadow
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.background,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
        titleTextStyle: GoogleFonts.dmSans(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: AppColors.textPrimary,
          letterSpacing: -0.5,
        ),
      ),

      // Input field: border dengan radius minimalis
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.accent, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        hintStyle: GoogleFonts.dmSans(
          color: AppColors.textSecondary,
          fontSize: 15,
          fontWeight: FontWeight.w400,
        ),
      ),

      // ElevatedButton: solid dengan sudut membulat
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.accent,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: GoogleFonts.dmSans(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.2,
          ),
        ),
      ),

      // TextButton: tanpa background
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.accent,
          textStyle: GoogleFonts.dmSans(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      // Card: shadow sangat tipis
      cardTheme: CardThemeData(
        color: AppColors.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.border),
        ),
        clipBehavior: Clip.antiAlias,
      ),
    );
  }
}

/// Konstanta TextStyle yang sering digunakan di seluruh aplikasi.
/// Menggunakan GoogleFonts.dmSans() agar konsisten dengan tema.
class AppTextStyles {
  static TextStyle get displayLarge => GoogleFonts.dmSans(
    fontSize: 32,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
    letterSpacing: -1.0,
    height: 1.2,
  );

  static TextStyle get headline => GoogleFonts.dmSans(
    fontSize: 24,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
    letterSpacing: -0.5,
  );

  static TextStyle get title => GoogleFonts.dmSans(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
    letterSpacing: -0.2,
  );

  static TextStyle get body => GoogleFonts.dmSans(
    fontSize: 15,
    fontWeight: FontWeight.w400,
    color: AppColors.textPrimary,
    height: 1.6,
  );

  static TextStyle get caption => GoogleFonts.dmSans(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: AppColors.textSecondary,
    letterSpacing: 0.2,
  );

  static TextStyle get label => GoogleFonts.dmSans(
    fontSize: 13,
    fontWeight: FontWeight.w500,
    color: AppColors.textSecondary,
    letterSpacing: 0.5,
  );
}
