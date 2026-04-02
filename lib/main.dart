// 🚀 ENTRY POINT: main.dart
// Ini adalah titik masuk (entry point) aplikasi SYNC.
// File ini sengaja dibuat SESIMPEL mungkin — hanya inisialisasi dan routing awal.
// Semua logika bisnis diletakkan di service, screen, dan model yang terpisah.
//
// Prinsip: "main.dart tidak boleh tau tentang enkripsi, biometrik, atau UI detail."

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'screens/splash_screen.dart';
import 'theme/app_theme.dart';

/// Fungsi utama Flutter — dipanggil pertama kali saat aplikasi dijalankan.
void main() async {
  // ✅ Wajib dipanggil sebelum melakukan operasi asinkron di main()
  // Ini memastikan Flutter engine sudah siap sebelum kita panggil method platform
  WidgetsFlutterBinding.ensureInitialized();

  // Inisialisasi data locale Bahasa Indonesia untuk library intl
  // Diperlukan agar DateFormat('EEEE', 'id_ID') bisa menghasilkan nama hari dalam Bahasa Indonesia
  await initializeDateFormatting('id_ID', null);

  // Kunci orientasi layar ke portrait saja
  // Mengapa? Desain SYNC dioptimalkan untuk portrait, landscape akan merusak layout
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Kustomisasi tampilan system overlay (status bar, navigation bar)
  // Membuat tampilan "immersive" yang menyatu dengan desain aplikasi
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent, // Status bar transparan
      statusBarIconBrightness: Brightness.dark, // Ikon gelap (untuk background putih)
      systemNavigationBarColor: Colors.white, // Navigation bar putih
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );

  runApp(const SyncApp());
}

/// Widget root aplikasi SYNC.
/// 
/// Menggunakan StatelessWidget karena tidak ada state global di root.
/// Semua state dikelola di masing-masing Screen secara lokal (sesuai prinsip
/// state management sederhana yang diminta — tanpa Riverpod/Bloc/GetX).
class SyncApp extends StatelessWidget {
  const SyncApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      // Nama aplikasi (digunakan di task manager OS)
      title: 'SYNC — Secure Your Neural Cognition',

      // Sembunyikan banner "DEBUG" di pojok kanan atas saat development
      // Agar screenshot demonstrasi terlihat lebih bersih dan profesional
      debugShowCheckedModeBanner: false,

      // Gunakan tema yang sudah kita definisikan di AppTheme
      // Semua komponen Material (Button, TextField, AppBar) akan ikuti tema ini
      theme: AppTheme.lightTheme,

      // Layar pertama yang ditampilkan: SplashScreen
      // SplashScreen → LockScreen → HomeScreen (flow utama aplikasi)
      home: const SplashScreen(),
    );
  }
}
