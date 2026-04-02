// 🔑 SERVICE: BiometricService
// File ini menangani autentikasi biometrik menggunakan local_auth.
// Biometrik menjadi "kunci pintu" aplikasi SYNC — tanpanya, tidak ada
// yang bisa masuk ke catatan meskipun data terenkripsi di tangan mereka.

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';

/// Service yang menyediakan fungsi autentikasi biometrik.
/// 
/// Mendukung: Fingerprint (sidik jari), Face ID, dan fallback ke PIN perangkat.
class BiometricService {
  // Instance LocalAuthentication bersifat singleton cukup satu dari sini
  static final LocalAuthentication _auth = LocalAuthentication();

  /// Memeriksa apakah perangkat mendukung autentikasi biometrik.
  /// 
  /// Mengapa perlu dicek terlebih dahulu?
  /// Tidak semua perangkat punya sensor biometrik. Jika dipaksa tanpa pengecekan,
  /// aplikasi akan crash. Pengecekan ini memungkinkan kita menampilkan pesan
  /// yang tepat kepada pengguna.
  static Future<bool> isAvailable() async {
    try {
      // canCheckBiometrics: apakah hardware biometrik tersedia?
      final canCheck = await _auth.canCheckBiometrics;
      // isDeviceSupported: apakah perangkat mendukung autentikasi sama sekali?
      final isSupported = await _auth.isDeviceSupported();
      return canCheck || isSupported;
    } on PlatformException catch (e) {
      debugPrint('BiometricService: Gagal mengecek ketersediaan biometrik: $e');
      return false;
    }
  }

  /// Mendapatkan daftar jenis biometrik yang tersedia di perangkat.
  /// 
  /// Digunakan untuk menampilkan ikon yang tepat (sidik jari vs wajah)
  /// pada layar Lock Screen.
  static Future<List<BiometricType>> getAvailableBiometrics() async {
    try {
      return await _auth.getAvailableBiometrics();
    } on PlatformException {
      return [];
    }
  }

  /// Meminta pengguna untuk melakukan autentikasi biometrik.
  /// 
  /// Parameter penting:
  /// - [localizedReason]: Pesan yang ditampilkan di dialog sistem (harus jelas!)
  /// - [useErrorDialogs]: Tampilkan dialog error otomatis jika gagal
  /// - [stickyAuth]: Jika true, dialog tetap ada meski app di-background
  ///   (berguna saat pengguna beralih app lalu kembali)
  /// 
  /// Mengembalikan [true] jika autentikasi berhasil, [false] jika gagal atau dibatalkan.
  static Future<bool> authenticate() async {
    try {
      final result = await _auth.authenticate(
        localizedReason: 'Verifikasi identitas Anda untuk membuka SYNC',
        options: const AuthenticationOptions(
          useErrorDialogs: true,
          stickyAuth: true,
          // biometricOnly: false berarti juga mengizinkan fallback ke PIN/pola
          // Ini penting agar pengguna dengan masalah sensor bisa tetap masuk
          biometricOnly: false,
        ),
      );
      return result;
    } on PlatformException catch (e) {
      debugPrint('BiometricService: Autentikasi gagal: ${e.code} - ${e.message}');
      // Jika error CODE adalah "NotAvailable" atau "NotEnrolled", beri tahu user
      return false;
    }
  }
}
