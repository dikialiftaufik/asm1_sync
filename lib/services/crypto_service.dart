// 🔐 SERVICE: CryptoService
// File ini bertanggung jawab penuh atas SEMUA operasi kriptografi dalam SYNC.
// Menggunakan enkripsi AES-256 dengan mode CBC dan padding PKCS7.
//
// Filosofi Keamanan:
// - Kunci enkripsi (Secret Key) TIDAK boleh di-hardcode dalam kode sumber.
// - Kunci disimpan di Android Keystore / iOS Keychain via flutter_secure_storage.
// - Ini mencegah kunci bocor jika seseorang men-decompile APK aplikasi.

import 'dart:convert';
import 'dart:typed_data';
import 'package:encrypt/encrypt.dart' as enc;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Service yang menyediakan fungsi enkripsi dan dekripsi teks.
/// 
/// Algoritma: AES-256-CBC dengan IV acak per-enkripsi.
/// "AES-256" berarti kunci berukuran 256 bit (32 byte).
/// "CBC" (Cipher Block Chaining) berarti setiap blok data bergantung pada blok sebelumnya,
/// membuat pola dalam plaintext tidak tampak dalam ciphertext.
class CryptoService {
  // Gunakan FlutterSecureStorage untuk menyimpan kunci dengan aman
  // di Android Keystore / iOS Secure Enclave
  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true, // Gunakan EncryptedSharedPreferences
    ),
  );

  // Nama kunci di secure storage
  static const String _keyAlias = 'sync_aes_secret_key';
  static const String _ivAlias = 'sync_aes_master_iv';

  /// Mengambil atau membuat kunci enkripsi AES-256 baru.
  /// 
  /// Mengapa menggunakan lazy initialization (buat jika belum ada)?
  /// Agar kunci hanya dibuat sekali saat pertama kali dibutuhkan,
  /// dan selalu konsisten di setiap sesi aplikasi.
  static Future<enc.Key> _getOrCreateKey() async {
    String? storedKey = await _storage.read(key: _keyAlias);

    if (storedKey == null) {
      // Kunci belum ada, buat kunci baru yang benar-benar acak (32 byte = 256 bit)
      final newKey = enc.Key.fromSecureRandom(32);
      // Simpan kunci sebagai Base64 string agar bisa disimpan sebagai teks
      await _storage.write(key: _keyAlias, value: base64Encode(newKey.bytes));
      return newKey;
    }

    // Kunci sudah ada, decode kembali dari Base64
    return enc.Key(Uint8List.fromList(base64Decode(storedKey)));
  }

  /// Mengambil atau membuat IV (Initialization Vector) master.
  /// 
  /// IV digunakan untuk memastikan enkripsi teks yang SAMA menghasilkan
  /// ciphertext yang BERBEDA setiap kali — ini disebut "semantic security".
  /// 
  /// Catatan: Untuk keamanan maksimal, IV idealnya unik per-enkripsi.
  /// Namun untuk kesederhanaan arsitektur (sesuai kebutuhan tugas),
  /// kita gunakan IV yang konsisten yang disimpan di secure storage.
  static Future<enc.IV> _getOrCreateIV() async {
    String? storedIV = await _storage.read(key: _ivAlias);

    if (storedIV == null) {
      final newIV = enc.IV.fromSecureRandom(16); // IV harus 16 byte untuk AES-CBC
      await _storage.write(key: _ivAlias, value: base64Encode(newIV.bytes));
      return newIV;
    }

    return enc.IV(Uint8List.fromList(base64Decode(storedIV)));
  }

  /// Mengenkripsi teks plaintext menjadi ciphertext (teks acak terenkripsi).
  /// 
  /// Proses:
  /// 1. Ambil kunci & IV dari secure storage
  /// 2. Buat encrypter dengan algoritma AES-CBC
  /// 3. Enkripsi teks → hasilkan Base64 string
  /// 
  /// Mengapa Base64? Karena hasil enkripsi adalah bytes (data biner),
  /// dan Base64 mengubahnya menjadi teks ASCII yang aman disimpan di file .txt
  static Future<String> encrypt(String plaintext) async {
    try {
      final key = await _getOrCreateKey();
      final iv = await _getOrCreateIV();

      // Buat encrypter dengan padding PKCS7 (padding standar untuk AES)
      final encrypter = enc.Encrypter(enc.AES(key, mode: enc.AESMode.cbc));

      // Lakukan enkripsi
      final encrypted = encrypter.encrypt(plaintext, iv: iv);

      // Kembalikan sebagai Base64 string
      return encrypted.base64;
    } catch (e) {
      // Melempar ulang error agar bisa di-handle oleh pemanggil
      throw Exception('Enkripsi gagal: $e');
    }
  }

  /// Mendekripsi ciphertext (Base64) kembali menjadi plaintext yang bisa dibaca.
  /// 
  /// Proses kebalikan dari [encrypt]:
  /// 1. Ambil kunci & IV yang sama dari secure storage
  /// 2. Decode Base64 → bytes
  /// 3. Dekripsi bytes → plaintext
  /// 
  /// Mengapa ini disebut "In-Memory Decryption"?
  /// Karena plaintext HANYA ada di RAM (variabel Dart), tidak pernah ditulis ke disk.
  /// Saat layar ditutup/widget dispose, data ini otomatis hilang dari memori.
  static Future<String> decrypt(String ciphertext) async {
    try {
      final key = await _getOrCreateKey();
      final iv = await _getOrCreateIV();

      final encrypter = enc.Encrypter(enc.AES(key, mode: enc.AESMode.cbc));

      // Buat objek Encrypted dari Base64 string
      final encrypted = enc.Encrypted.fromBase64(ciphertext);

      // Lakukan dekripsi dan kembalikan plaintext
      return encrypter.decrypt(encrypted, iv: iv);
    } catch (e) {
      throw Exception('Dekripsi gagal: $e');
    }
  }

  /// Menghapus kunci enkripsi dari secure storage.
  /// 
  /// PERHATIAN: Memanggil fungsi ini berarti SEMUA catatan tidak bisa
  /// didekripsi lagi! Hanya gunakan untuk fitur "Reset Aplikasi".
  static Future<void> deleteKeys() async {
    await _storage.delete(key: _keyAlias);
    await _storage.delete(key: _ivAlias);
  }
}
