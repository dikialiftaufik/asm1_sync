// 📦 MODEL: NoteModel
// File ini mendefinisikan struktur data untuk satu catatan (note) di aplikasi SYNC.
// Menggunakan pola sederhana (pure Dart class) agar mudah dipahami tanpa library tambahan.

/// Representasi satu catatan dalam aplikasi SYNC.
/// 
/// Catatan disimpan sebagai file .txt terenkripsi di penyimpanan lokal.
/// Model ini digunakan untuk MEMBUNGKUS data saat dibaca/ditampilkan di UI,
/// bukan untuk menyimpannya — penyimpanan ditangani oleh [StorageService].
class NoteModel {
  /// ID unik catatan, sekaligus nama file tanpa ekstensi.
  /// Format: timestamp Unix saat catatan dibuat (contoh: "1712040000000")
  /// Menggunakan timestamp agar selalu unik tanpa perlu database.
  final String id;

  /// Judul catatan dalam bentuk plaintext (TIDAK dienkripsi secara terpisah).
  /// Judul disimpan dalam satu file bersama isi catatan, dienkripsi bersamaan.
  final String title;

  /// Isi/konten catatan dalam bentuk plaintext.
  /// Di dalam file, konten ini sudah dalam bentuk ciphertext (terenkripsi).
  final String content;

  /// Waktu pembuatan catatan.
  /// Disimpan sebagai bagian dari file terenkripsi agar tidak bisa dipalsukan.
  final DateTime createdAt;

  /// Waktu terakhir catatan diperbarui.
  final DateTime updatedAt;

  // Constructor: Membuat instance NoteModel baru
  const NoteModel({
    required this.id,
    required this.title,
    required this.content,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Factory constructor untuk membuat NoteModel dari String terformat.
  /// 
  /// Format file yang diekspektasi (setelah didekripsi):
  /// ```
  /// TITLE:Judul Catatan
  /// CREATED:2024-04-02T10:00:00.000
  /// UPDATED:2024-04-02T10:00:00.000
  /// CONTENT:
  /// Isi catatan bisa multi-baris...
  /// ```
  /// 
  /// Mengapa format ini? Karena menggunakan key-value sederhana yang 
  /// mudah di-parse tanpa perlu library JSON atau serialization kompleks.
  factory NoteModel.fromEncryptedString(String id, String decryptedText) {
    try {
      final lines = decryptedText.split('\n');
      String title = '';
      DateTime? createdAt;
      DateTime? updatedAt;
      final contentLines = <String>[];
      bool isReadingContent = false;

      for (final line in lines) {
        if (isReadingContent) {
          // Setelah marker "CONTENT:", semua baris berikutnya adalah isi catatan
          contentLines.add(line);
        } else if (line.startsWith('TITLE:')) {
          title = line.substring(6); // Ambil teks setelah "TITLE:"
        } else if (line.startsWith('CREATED:')) {
          createdAt = DateTime.tryParse(line.substring(8));
        } else if (line.startsWith('UPDATED:')) {
          updatedAt = DateTime.tryParse(line.substring(8));
        } else if (line == 'CONTENT:') {
          isReadingContent = true; // Mulai membaca konten dari baris selanjutnya
        }
      }

      return NoteModel(
        id: id,
        title: title.isNotEmpty ? title : 'Catatan Tanpa Judul',
        content: contentLines.join('\n'),
        createdAt: createdAt ?? DateTime.now(),
        updatedAt: updatedAt ?? DateTime.now(),
      );
    } catch (e) {
      // Jika parsing gagal, kembalikan model kosong daripada crash
      return NoteModel(
        id: id,
        title: 'Error: Gagal Membaca',
        content: '',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
    }
  }

  /// Mengubah NoteModel menjadi String terformat untuk dienkripsi dan disimpan.
  /// Kebalikan dari [fromEncryptedString].
  String toEncryptedString() {
    return '''TITLE:$title
CREATED:${createdAt.toIso8601String()}
UPDATED:${updatedAt.toIso8601String()}
CONTENT:
$content''';
  }

  /// Membuat salinan NoteModel dengan perubahan tertentu.
  /// Berguna saat mengedit catatan (judul/konten berubah, ID & createdAt tetap).
  NoteModel copyWith({
    String? title,
    String? content,
    DateTime? updatedAt,
  }) {
    return NoteModel(
      id: id,
      title: title ?? this.title,
      content: content ?? this.content,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
