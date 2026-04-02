// 📁 SERVICE: StorageService
// File ini bertanggung jawab atas SEMUA operasi Input/Output (baca/tulis) file
// ke penyimpanan lokal perangkat.
//
// Filosofi Arsitektur:
// Kita menggunakan file .txt (bukan SQLite/database) agar:
// 1. Arsitektur lebih mudah dipahami (satu catatan = satu file)
// 2. Data lebih mudah di-backup secara manual jika diperlukan
// 3. Tidak ada ketergantungan pada database engine yang kompleks
//
// Direktori penyimpanan: getApplicationDocumentsDirectory()
// Ini adalah folder privat yang hanya bisa diakses oleh aplikasi SYNC,
// tidak terlihat oleh File Manager biasa tanpa root access.

import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import '../models/note_model.dart';
import '../services/crypto_service.dart';

/// Service yang mengelola penyimpanan dan pembacaan file catatan.
/// 
/// Konvensi penamaan file: `{id}.sync`
/// Contoh: `1712040000000.sync`
/// Ekstensi `.sync` menandakan file milik aplikasi SYNC dan berisi data terenkripsi.
class StorageService {
  /// Mendapatkan referensi ke direktori dokumen aplikasi.
  /// 
  /// Mengapa menggunakan [getApplicationDocumentsDirectory]?
  /// - Android: /data/data/{package_name}/app_flutter/ (folder privat)
  /// - iOS: NSDocumentDirectory (disertakan dalam iCloud backup jika dikonfigurasi)
  /// Folder ini terisolasi dari aplikasi lain (sandbox) dan lebih aman
  /// dibanding Downloads atau External Storage yang bisa diakses semua app.
  static Future<Directory> _getNotesDirectory() async {
    final appDir = await getApplicationDocumentsDirectory();
    // Buat subdirektori 'notes' agar lebih terorganisir
    final notesDir = Directory('${appDir.path}/notes');
    if (!await notesDir.exists()) {
      await notesDir.create(recursive: true);
    }
    return notesDir;
  }

  /// Mendapatkan daftar semua catatan (hanya judul dan metadata, tanpa dekripsi isi).
  /// 
  /// Mengapa hanya metadata? Karena dekripsi butuh waktu dan resource CPU.
  /// Kita hanya dekripsi konten saat pengguna benar-benar membuka catatan tersebut.
  /// Ini adalah optimasi performa sekaligus prinsip "minimal exposure" —
  /// data sensitif hanya didekripsi saat benar-benar dibutuhkan.
  static Future<List<NoteModel>> getAllNotes() async {
    try {
      final dir = await _getNotesDirectory();
      final files = dir.listSync()
          .whereType<File>()
          .where((f) => f.path.endsWith('.sync'))
          .toList();

      final List<NoteModel> notes = [];

      for (final file in files) {
        try {
          // Baca ciphertext dari file
          final ciphertext = await file.readAsString();
          // Dekripsi untuk mendapatkan plaintext (termasuk judul)
          final plaintext = await CryptoService.decrypt(ciphertext);
          // Ambil ID dari nama file (tanpa ekstensi)
          final id = file.path.split(Platform.pathSeparator).last.replaceAll('.sync', '');
          // Parse plaintext menjadi NoteModel
          final note = NoteModel.fromEncryptedString(id, plaintext);
          notes.add(note);
        } catch (e) {
          // Jika satu file gagal dibaca, skip dan lanjutkan yang lain
          // daripada membuat seluruh list gagal dimuat
          debugPrint('StorageService: Gagal membaca file ${file.path}: $e');
        }
      }

      // Urutkan berdasarkan waktu update terbaru (yang terbaru muncul pertama)
      notes.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
      return notes;
    } catch (e) {
      debugPrint('StorageService: Gagal memuat daftar catatan: $e');
      return [];
    }
  }

  /// Menyimpan catatan baru ke file terenkripsi.
  /// 
  /// Proses:
  /// 1. Konversi NoteModel → plaintext terformat
  /// 2. Enkripsi plaintext → ciphertext (AES-256)
  /// 3. Tulis ciphertext ke file .sync
  /// 
  /// ID catatan menggunakan timestamp Unix dalam milidetik sebagai nama file
  /// agar selalu unik tanpa perlu counter atau UUID library.
  static Future<NoteModel> saveNote({
    required String title,
    required String content,
  }) async {
    // Buat ID baru dari timestamp saat ini
    final id = DateTime.now().millisecondsSinceEpoch.toString();
    final now = DateTime.now();

    // Buat model catatan baru
    final note = NoteModel(
      id: id,
      title: title,
      content: content,
      createdAt: now,
      updatedAt: now,
    );

    // Enkripsi dan simpan ke file
    await _writeNoteToFile(note);
    return note;
  }

  /// Memperbarui catatan yang sudah ada.
  /// 
  /// Menggunakan ID yang sama (nama file sama), sehingga file lama
  /// akan ditimpa dengan konten baru yang sudah dienkripsi ulang.
  static Future<NoteModel> updateNote({
    required NoteModel existingNote,
    required String newTitle,
    required String newContent,
  }) async {
    final updatedNote = existingNote.copyWith(
      title: newTitle,
      content: newContent,
      updatedAt: DateTime.now(),
    );

    // Tulis ulang file yang sama
    await _writeNoteToFile(updatedNote);
    return updatedNote;
  }

  /// Helper private: Proses enkripsi + penulisan file.
  /// 
  /// Dipisah menjadi fungsi tersendiri (private) karena digunakan oleh
  /// [saveNote] dan [updateNote] — menghindari duplikasi kode (DRY principle).
  static Future<void> _writeNoteToFile(NoteModel note) async {
    final dir = await _getNotesDirectory();
    final file = File('${dir.path}/${note.id}.sync');

    // Ubah model menjadi string terformat, lalu enkripsi
    final plaintext = note.toEncryptedString();
    final ciphertext = await CryptoService.encrypt(plaintext);

    // Tulis ciphertext ke file (bukan plaintext!)
    await file.writeAsString(ciphertext);
  }

  /// Membaca dan mendekripsi satu catatan berdasarkan ID-nya.
  /// 
  /// Ini adalah implementasi "In-Memory Decryption":
  /// - Ciphertext dibaca dari disk
  /// - Didekripsi menjadi plaintext di RAM
  /// - Dikembalikan ke UI untuk ditampilkan
  /// - Saat widget di-dispose, plaintext tidak ada lagi di mana pun
  static Future<NoteModel?> getNoteById(String id) async {
    try {
      final dir = await _getNotesDirectory();
      final file = File('${dir.path}/$id.sync');

      if (!await file.exists()) return null;

      final ciphertext = await file.readAsString();
      final plaintext = await CryptoService.decrypt(ciphertext);
      return NoteModel.fromEncryptedString(id, plaintext);
    } catch (e) {
      debugPrint('StorageService: Gagal membaca catatan $id: $e');
      return null;
    }
  }

  /// Menghapus file catatan berdasarkan ID.
  static Future<bool> deleteNote(String id) async {
    try {
      final dir = await _getNotesDirectory();
      final file = File('${dir.path}/$id.sync');
      if (await file.exists()) {
        await file.delete();
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('StorageService: Gagal menghapus catatan $id: $e');
      return false;
    }
  }
}
