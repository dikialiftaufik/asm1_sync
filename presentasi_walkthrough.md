# Naskah Presentasi & Walkthrough Tutorial: Membangun SYNC dari Nol

Dokumen ini adalah rekam jejak sistematis tahap-demi-tahap (tutorial) cara membangun aplikasi **SYNC (Secure Your Neural Cognition)** dari nol absolut beserta naskah presentasi (yang diucapkan) untuk kegiatan demonstrasi *live coding* atau presentasi di depan kelas.

---

## Slide 1: Latar Belakang & Solusi

**Visual di layar (Poin-poin):**
- **Masalah:** Catatan di perangkat bergerak rentan diintip (Shoulder Surfing), perangkat dipinjam, atau dicuri secara fisik.
- **Solusi (SYNC):** Aplikasi jurnal berkonsep "Brankas Digital" yang menawarkan rekayasa kriptografi level militer (AES-256), *Biometric Gate*, *Tap-to-Reveal*, dan *Anti-Screenshot*.

💬 **Naskah Presentasi:**
> "Selamat pagi/siang. Pada kesempatan kali ini saya akan mendemonstrasikan secara *step-by-step* proses rekayasa awal aplikasi SYNC – Secure Your Neural Cognition. 
> SYNC lahir dari sebuah isu sederhana: kerentanan catatan pribadi. Mulai dari yang sepele seperti diintip orang dari belakang *(shoulder surfing)* hingga ancaman terbesar perangkat jatuh ke tangan yang salah. Solusi yang SYNC tawarkan adalah memadukan enkripsi *military-grade* AES-256, lapisan biometrik perangkat keras, penolakan akses rekaman layar, hingga UX pembacaan aman *Tap-to-Reveal*."

---

## Slide 2: Persiapan Awal & Injeksi Dependensi (Package)

**Visual di layar:**
- Command line instruksi pembuatan flutter.
- Daftar *package* (dependensi) di file `pubspec.yaml` beserta alasannya.

**Langkah Pembuatan:**
1. Eksekusi perintah di terminal: `flutter create asm1_sync`
2. Buka file `pubspec.yaml` dan tambahkan paket keamanan krusial. 

**Kode yang Dimasukkan (`pubspec.yaml` Baris 14-36):**
```yaml
dependencies:
  flutter:
    sdk: flutter
  cupertino_icons: ^1.0.8
  local_auth: ^2.3.0 # Membuka API Sensor sidik jari/FaceID
  encrypt: ^5.0.3 # Framework Kriptografi AES-256
  path_provider: ^2.1.5 # Mengakses laci sandbox memori internal
  flutter_secure_storage: ^9.2.4 # Menyimpan Kunci Enkripsi ke Keystore/Keychain
  intl: ^0.20.2 # Format pelokalan bahasa Indonesia
  google_fonts: ^6.2.1 # Tipografi
  screen_protector: ^1.5.1 # Pemblokir Screenshot
```

💬 **Naskah Presentasi:**
> "Untuk membuatnya dari nol, pertama kita eksekusi `flutter create asm1_sync`. Setelah rangka aplikasi terbuat, langkah awal yang paling krusial adalah mempersenjatai `pubspec.yaml`.
> Kita definisikan dependensinya. Kita inject paket `encrypt` dan `flutter_secure_storage` untuk enkripsi, `local_auth` untuk *fingerprint*, `path_provider` untuk direktori terisolasi, dan `screen_protector` sebagai pamungkas pencegah tangkapan layar OS. Kenapa *secure storage* wajib? Karena menaruh *password* secara tulisan mentah (*hardcode*) di pemrograman aplikasi itu adalah sebuah kelalaian fatal."

---

## Slide 3: Konfigurasi Kerangka Titik Masuk (Entry Point)

**Visual di layar:**
- Kode `lib/main.dart` (Bagian konfigurasi OS & orientasi).

**Langkah Pembuatan:**
1. Hapus isi bawaan `main.dart`, buat dari awal untuk inisialiasi status bar, orientasi, dan *routing*.

**Kode yang Dimasukkan (`lib/main.dart` Baris 14-43):**
```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('id_ID', null);

  // Kunci orientasi ke Portrait saja
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Modifikasi tampilan bar notifikasi & gestur OS
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: Colors.white,
    ),
  );
  runApp(const SyncApp()); // Arahkan ke SplashScreen
}
```

💬 **Naskah Presentasi:**
> "Kita mulai pembangunannya dari titik masuk paling bawah yaitu `main.dart`. Mulai dari baris 14, kode `main()` bukan sekadar menjalankan aplikasi. Di sini kita menonaktifkan paksa orientasi lanskap (*portraitUp*) dan mematikan bentrokan pewarnaan UI *System Navigation bar* agar membaur tembus pandang secara estetik. Aplikasi ini kita arahkan murni lurus menyasar rutinitas awalan `SplashScreen()`, jadi tidak akan pernah memuat isi buku catatan sebelum perintah divalidasi keamanannya."

---

## Slide 4: Pembuatan Model Data Terdistilasi (Parsing & Struktur)

**Visual di layar:**
- Kode struktur model data di `lib/models/note_model.dart`.
- Menyoroti fungsi konverter `.fromEncryptedString()`

**Langkah Pembuatan:**
Membuat file struktur cetakan data (blueprint) memori/catatan agar mudah diolah di memori berjalan, sekaligus bisa dikonversi (*parsing*) dari hasil bongkaran algoritma dekripsi sandi ke teks biasa.

**Kode yang Dimasukkan (`lib/models/note_model.dart` Baris 53-83):**
```dart
  factory NoteModel.fromEncryptedString(String id, String decryptedText) {
    try {
      final lines = decryptedText.split('\n');
      String title = '';
      DateTime? createdAt; DateTime? updatedAt;
      final contentLines = <String>[];
      bool isReadingContent = false;

      for (final line in lines) {
        if (isReadingContent) { contentLines.add(line); } 
        else if (line.startsWith('TITLE:')) { title = line.substring(6); } 
        else if (line == 'CONTENT:') { isReadingContent = true; }
      }
//...
```

💬 **Naskah Presentasi:**
> "Sebelum membahas enkripsinya, mari kita rancang dulu fondasi propertinya melalui blok kode di file `lib/models/note_model.dart`.
> Kita membuat pola `NoteModel`. Perhatikan logika algoritma *factory fromEncryptedString* mulai baris 53. Fungsi ini krusial sebagai jembatan. Model ini memandu cara aplikasi merespons bilamana data teks sandi berhasil ditelanjangi (*decrypted*). Model akan membelah variabel melalui deteksi prefiks buatan sendiri seperti `TITLE:` dan `CONTENT:` kemudian menerjemahkannya ke dalam baris memori yang siap dibaca RAM pengguna."

---

## Slide 5: Lapisan Keamanan Kriptografi (CryptoService)

**Visual di layar:**
- Kode `lib/services/crypto_service.dart`.
- Fokus di letak metode `encrypt()` dengan injeksi `Encrypter`.

**Langkah Pembuatan:**
Membangun file layanan (*service*) yang murni mengatur enkripsi AES-256 tipe CBC. Kunci akan dibuat abstrak (*lazy generation*) dan dirahasiakan ke sistem OS iOS/Android itu sendiri, bukan ke kode aplikasi.

**Kode yang Dimasukkan (`lib/services/crypto_service.dart` Baris 83-95):**
```dart
  static Future<String> encrypt(String plaintext) async {
    try {
      final key = await _getOrCreateKey(); // Ambil kunci rahasia dari Keystore
      final iv = await _getOrCreateIV();

      // Buat encrypter dengan sandi AES tipe CBC
      final encrypter = enc.Encrypter(enc.AES(key, mode: enc.AESMode.cbc));
      final encrypted = encrypter.encrypt(plaintext, iv: iv);

      // Ubah dari bytes acak menjadi serangkaian String terformat aman: Base64
      return encrypted.base64;
    } catch (e) { throw Exception('Enkripsi gagal: $e'); }
  }
```

💬 **Naskah Presentasi:**
> "Bagian inti dari arsitektur pertahanan ini digarap di `lib/services/crypto_service.dart`. 
> Perhatikan pada tata baris penulisan fungsi `encrypt()`. Prosesnya berjalan tiga lapis. Pertama ambil kunci atau bangkitkan kunci rahasia berkekuatan padat 256-bit dan tanamkan ke luar jangkauan pembacaan aplikasi yakni *Keystore*. Lalu panggil modul AES mode gembok silang berkelanjutan (CBC). Dan ketika `encrypter.encrypt()` mengubah data pengguna menjadi ampas *bytes* digital tak terbaca, kita modifikasi lagi agar *outputnya* menjadi String mulus format representasi ASCII: yakni format Base64 yang siap kita benamkan ke dalam memori perangkat selamanya."

---

## Slide 6: Lapisan Keamanan I/O (StorageService)

**Visual di layar:**
- Kode `lib/services/storage_service.dart`.
- Menyorot fungsi private `_writeNoteToFile()`.

**Langkah Pembuatan:**
Membuat penyimpanan dengan cara mengubah model ke representasi teks, men-trigger enkripsi, lalu menanam fail-nya dengan nama rahasia berekstensi buatan sendiri, `.sync`.

**Kode yang Dimasukkan (`lib/services/storage_service.dart` Baris 142-152):**
```dart
  static Future<void> _writeNoteToFile(NoteModel note) async {
    final dir = await _getNotesDirectory(); // panggil App Sandbox Directory
    final file = File('${dir.path}/${note.id}.sync');

    // 1. Ubah model text, 2. Panggil CryptoService untuk mengubahnya ke Base64 (Ciperteks)
    final plaintext = note.toEncryptedString();
    final ciphertext = await CryptoService.encrypt(plaintext);

    // Tulis ciphertext murni (yg sudah terenkripsi) ke file fisik disk!
    await file.writeAsString(ciphertext);
  }
```

💬 **Naskah Presentasi:**
> "Kemana ampas teks dari kriptografi file tadi harusnya dibuang dan disimpan? Proses itu dikontrol pada `storage_service.dart` baris 142.
> Kita tak butuh kerumitan *SQLite Database*. Kita atur `_writeNoteToFile()` agar menulis ciperteks yang kita konversi lewat pemanggilan langsung fungsi Crypto tadi secara harafiah ke sebuah file teks langsung di direktori *Sandbox* OS. Dan yang terpenting disoroti: filenya dilabeli murni dengan nama ID berwaktu unik (*timestamp* Unix) dan ekstensi modifikasi *proprietary* buatan aplikasi ini sendiri yang kami rahasia beri nama berekstensi `.sync`. Bahkan bila direktori root dibobol, seluruh datanya cuma bertajuk ekstensi tak dikenal berisi teks Base64 acak."

---

## Slide 7: Deteksi Jati Diri & Biometrik Penjaga

**Visual di layar:**
- Kode `lib/screens/lock_screen.dart` terintegrasi dengan `biometric_service.dart`.
- Demonstrasi interaksi sistem mendeteksi jari atau wajah di baris pengondisian boolean `isAuthenticating`.

**Langkah Pembuatan:**
Membuat UI dan Logika `lock_screen.dart` merespon fungsi `authenticate()` dari layer `biometric_service`.

**Kode yang Dimasukkan (`lib/screens/lock_screen.dart` Baris 72-114):**
```dart
  Future<void> _authenticate() async {
    if (_isAuthenticating) return;
    setState(() { _isAuthenticating = true; });

    try {
      final isAvailable = await BiometricService.isAvailable();
      if (!isAvailable) { return; } // Gagal hardware

      // Panggil gerbang OS
      final success = await BiometricService.authenticate();

      if (success) {
        // Tembus? Navigasi terobos ke Home Screen
        Navigator.of(context).pushReplacement(
          PageRouteBuilder(pageBuilder: (_, __, ___) => const HomeScreen())
        );
      } else {
        // Gagal sensor jari? paksa tampil animasi goyang
        _shakeController.forward(from: 0);
      }
    }
  }
```

💬 **Naskah Presentasi:**
> "Kini jembatannya sudah kuat, kita butuh gembok luarnya. Kita satukan modul `biometric_service.dart` ke perlakuan `lock_screen.dart` layar depan.
> Di kode `_authenticate()` pada baris 72, layar memanipulasi *State* menjadi status loading dan seketika menembakkan pemicu interupsi aplikasi untuk membangunkan fungsi sensor wajah atau jempol OS melalui `BiometricService.authenticate()`. Kalau nilai *boolean*nya menembus menjadi `true`, silakan rute ke `HomeScreen` dibongkar. Kalau nilainya `false` karena palsu atau tertolak oleh OS, kita tolak dengan pemicu `shakeController` agar antarmuka menggeser secara *horizontal tween* untuk sensasi visual penolakan estetik goyang kepada penusupnya."

---

## Slide 8: Penyelesaian Inti Layar Penampil Utama (Tap-to-Reveal Reader)

**Visual di layar:**
- Implementasi blur (*anti-shoulder surfing*) di `lib/screens/reader_screen.dart`.
- Pemicu (*Trigger*) In-Memory Decryption & Layar Penahan (ScreenProtector).

**Langkah Pembuatan:**
Mendesain `reader_screen.dart` dengan membungkus teks menggunakan widget `BackdropFilter` dan deteksi penahanan tangan `GestureDetector`.

**Kode yang Dimasukkan (`lib/screens/reader_screen.dart` Baris 308-360):**
```dart
// MENCEGAH SCREENSHOT 
await ScreenProtector.preventScreenshotOn();

// ...
// LOGIKA PEMBURAMAN LAYAR (TAP-TO-REVEAL)
GestureDetector(
  onLongPressStart: (_) => _revealContent(),
  onLongPressEnd: (_) => _hideContent(),
  child: Stack(
    children: [
       SelectableText(note.content), // Teks Asli yg terbaca
       // LAYER BLUR PEMBUNGKUS
       if (_blurAnimation.value > 0.1)
          Positioned.fill(
             child: ClipRect(
                child: BackdropFilter(
                  filter: ImageFilter.blur(
                    sigmaX: _blurAnimation.value, sigmaY: _blurAnimation.value,
                  ),
                  child: Container(color: AppColors.background.withOpacity(0.05)),
                ),
             ),
          ),
    ],
  ),
),
```

💬 **Naskah Presentasi:**
> "Sebagai langkah klimaks koding fungsional, mari kita lihat anatomi pertahanan final kami di `reader_screen.dart`.
> File ini bertugas mengekstrak catatan dari kegelapan (sistem yang kami sebut *In-Memory Decryption*), hanya sementara di RAM semata. Mengingat isinya krusial bila direkam matanya oleh tetangga kursi sebelah si pengguna, perhatikan cara kodingannya melindungi hal ini.
> Kami menghimpun baris awal agar memanggil pustaka *ScreenProtector* level C-Language *(preventScreenshotOn)* untuk memutus memori dari tangkapan dan API rekam gambar layar bawaan Handphone sistem serentak. 
> Serta tak lupa, baris 308 menindih Widget Stack teks tersebut di atas pendaran Filter buram (Blur) `BackdropFilter`. Kami menggunakan pendeteksi kontrol interaksi `GestureDetector` *onLongPressStart* untuk menjatuhkan rasio kalkulasi intensitas angka kaburnya ketika pengguna dengan sadar menekan panel interaksi layar berlama-lama (Tap-to-reveal), bila jari diangkat sejenak merespon insting (*onLongPressEnd*), ketajaman buram instan seketika mengempaskan pandangan matanya."

---

## Slide 9: Demonstrasi Workflow Eksekusi Otomatis Logika (Penutup)

**Visual di layar:**
- Skema/Bagan diagram relasi pemrosesan lengkap layar demi layar atau video siklus nyata pemutaran *live*.

💬 **Naskah Presentasi:**
> "Kesimpulannya, kalau seluruh arsitektur tulisan kode teknis kita hubungkan di kompilasi rilis, ini adalah demonstrasi akhir *workflow* yang akan secara konsisten dilalui:
> 1. Aplikasi masuk lewat Main App, disesap orientasinya menjadi paten, dideteksi splash transisinya.
> 2. Pintu Biometrik otomatis menggigit alur memori depan dan mem- *bypass* gerbang jika valid. 
> 3. Tampil ke layar beranda *Home*, memanggil semua *file proprietary .sync* dan mendekripsinya sebentar hanya sekadar menangkap daftar tajuk (judu).
> 4. Ketik memori yang ingin dicatat menyentuh editor pensil. File kemudian dipotong dan dienkripsi paksa bersama CBC menjadi file mematikan nir-sentuh teks di internal. 
> 5. Dibaca kembali (*Reader* Screen). OS level sistem dikunci dari pendeteksi screenshot perekaman internal dan hanya terburam rapat membekukan isi kalau tak ditahan (*Tap and hold*). Otomatis hancur bilamana tombol rilis diangkat dari genggaman jarinya.
> 
> Demikian pembedahan demonstrasi struktur rancang bangun sistem tertutup dari rekayasa SYNC, terimakasih."
