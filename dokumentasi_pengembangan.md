# Dokumentasi Riwayat Pengembangan SYNC (Secure Your Neural Cognition)

Dokumen ini adalah rekam jejak sistematis tahap-demi-tahap (walkthrough) cara pembuatan aplikasi **SYNC** dari nol, merangkum modifikasi spesifik pada file, rentang baris kode, beserta fungsionalitas teknisnya.

---

## 1. Pendahuluan
### Latar Belakang
Catatan digital di perangkat seluler rentan terhadap pengintaian fisik secara langsung (*shoulder surfing*) maupun peretasan data saat perangkat dipinjamkan, hilang, atau dicuri.

### Solusi
Aplikasi jurnal dengan arsitektur "Brankas Pribadi" (SYNC) yang memadukan keamanan level mesin:
- Enkripsi Data AES-256 (Tersimpan sebagai Ciphertext)
- Penjaga Gerbang Biometrik (Mencegah peretasan fisik)
- Anti-Screenshot (Pemblokiran rekaman level Sistem Operasi)
- Antarmuka Pembacaan *Tap-to-Reveal*

---

## 2. Fitur Utama Aplikasi
1. **In-Memory Decryption**: Data hanya didekripsi sesaat di RAM HP saat ingin dibaca, file mentahnya di *storage* tetap berupa sandi buram.
2. **Kunci Sandi Tak Tersentuh**: *Passcode* enkripsi dibenamkan di dalam Android Keystore/iOS Keychain menggunakan metode *Secure Storage*, bukan *hardcode* teks di dalam program.
3. **Pengelolaan File '.sync'**: Tidak memakai database standar; melainkan menata file binar yang dilabeli dengan format tertutup khusus buatan sendiri (`.sync`) di *sandbox* folder dalam perangkat.
4. **Anti-Leak Interface**: Mekanisme kabur (*blur*) yang akan luruh hanya ketika pengguna menahan jari (menekan layar) di catatan dan memblokir upaya *screen-recorder* aplikasi manapun.

---

## 3. Persiapan & Instalasi *Package*

### Tahap 1: Inisiasi Proyek
Semuanya dimulai dari terminal:
```bash
flutter create asm1_sync
cd asm1_sync
```

### Tahap 2: Registrasi *Packages* (`pubspec.yaml`)
Di awal pengerjaan, fondasi *tools* keamanan diregistrasikan di file **`pubspec.yaml`** (Baris 14-21):
```yaml
dependencies:
  flutter:
    sdk: flutter
  cupertino_icons: ^1.0.8
  local_auth: ^2.3.0 # Mengakses sensor pemindai sidik jari/Face ID hardware
  encrypt: ^5.0.3 # Library untuk melakukan Cryptographic AES-256 
  path_provider: ^2.1.5 # Mandapatkan lokasi folder 'Sandbox' privat OS
  flutter_secure_storage: ^9.2.4 # Komunikasi API ke Keystore untuk menyembunyikan Password 
  intl: ^0.20.2 # Format waktu kalender
  google_fonts: ^6.2.1 # Pengunduh otomatis tipograf
  screen_protector: ^1.5.1 # FLAG_SECURE (proteksi larangan tangkapan/rekam layar OS)
```

---

## 4. Riwayat *Coding* & Arsitektur secara Sistematis

Berikut adalah riwayat eksekusi penulisan *source code* secara logis dan berurutan dari hulu (setup/servis) ke hilir (tampilan/UI).

### Tahap 3: Konstruksi Titik Masuk (Entry Point)
**File:** `lib/main.dart`
**Fungsi Utama:** Melakukan rutinitas inisialisasi awal UI dan memblokir layar menjadi rotasi Potret paksa secara hierarki OS.
- **Baris 14-43 `main()`**: Menyiapkan Engine Flutter (`ensureInitialized`), mematikan orientasi putar-layar menggunakan `SystemChrome.setPreferredOrientations`, dan mematikan bayangan warna pada status baterai bar ponsel (`setSystemUIOverlayStyle`). 
- **Baris 67-69 `SyncApp`**: Merutekan layar default tidak ke dasbor (*Home*), melainkan ditembak lurus wajib melewati `SplashScreen` lalu `LockScreen`.

### Tahap 4: Pembentukan Blueprint Data (Data Model)
**File:** `lib/models/note_model.dart`
**Fungsi Utama:** Mengajari Flutter cara merekatkan/memotong data tulisan catatan sebelum masuk dan keluar dari proses enkripsi kode biner.
- **Baris 53-94 `fromEncryptedString()`**: Karena kita *TIDAK* pakai SQL/Database, kita membuat struktur manual. Blok algoritma ini akan memecah file teks sandi (*ciperteks*) menggunakan indikator string buatan seperti `TITLE:` dan `CONTENT:` lalu menyusunnya menjadi variabel memori kelas RAM biasa `(NoteModel)`.
- **Baris 98-104 `toEncryptedString()`**: Mengetik ulang variabel dalam memori menjadi sepotong kalimat besar panjang berformat sebelum siap dilempar ke pelumat enkripsi *CryptoService*.

### Tahap 5: Lapisan Keamanan Inti (Kriptografi AES-256)
**File:** `lib/services/crypto_service.dart`
**Fungsi Utama:** Muka belakang mesin modifikasi enkripsi CBC.
- **Baris 39-52 `_getOrCreateKey()`**: Kode rahasia *(kunci sandi AES 32-byte)* tidak pernah terlihat secara fisik di dalam *source code*. Pada fungsi ini program disuruh mencari kuncinya diam-diam dari sistem *Android Keystore API*, jika perangkat belum memilikinya, ia disuruh meracik kunci keamanan baru dan menanamnya kembali secara tersembunyi.
- **Baris 83-100 `encrypt(String plaintext)`**: Data dikunyah! `encrypter.encrypt` akan mengubah teks pengguna dengan mode persilangan `AESMode.cbc`. Setelah hancur menjadi *bytes*, kita mengubahnya di baris 95 ke wajah ASCII yang nyaman disimpan sebagai `encrypted.base64`.
- **Baris 112-127 `decrypt(String ciphertext)`**: Kode membongkar string *Base64* dan menyusun ulang urutan *bytes* menjadikannya teks orisinil kembali (HANYA sewaktu hendak ditatap matanya secara langsung melalui halaman UI nanti).

### Tahap 6: Lapisan Arus Berkas Privat (Storage I/O Service)
**File:** `lib/services/storage_service.dart`
**Fungsi Utama:** Memalsukan dan menciptakan fisik fail direktori agar menjadi wujud berkas khusus yang terisolir (`.sync`).
- **Baris 34-42 `_getNotesDirectory()`:** Mencari *folder sandbox* absolut milik sistem yang di luar jangkauan pencari riwayat memori pihak ketiga.
- **Baris 142-152 `_writeNoteToFile(NoteModel note)`:** Blok yang memfinalisasikan wujud file. Baris `147-148` meneriaki fungsi `CryptoService.encrypt` secara berantai sebelum memutakhirkan penulisan akhir menggunakan perintah `file.writeAsString(ciphertext)` yang menghasilkan file berekstensi rahasia bernama `<id_unik_berdasarkan_waktu>.sync`. 

### Tahap 7: Lapisan Penjaga Gerbang Pengenal Identitas Biometrik
**File:** `lib/services/biometric_service.dart` & `lib/screens/lock_screen.dart`
**Fungsi Utama:** Layar perbatasan *login* aplikasi untuk merespons perangkat keras sidik jari/pemindai muka.
- **`biometric_service.dart` (Baris 57-75)**: Menulis perantara asinkron yang melontarkan validasi OS `_auth.authenticate()` ke hadapan muka pengguna agar menaruh jarinya pada area sensor ponsel.
- **`lock_screen.dart` (Baris 72-131)**: Kalau parameter sidik jari menjawab `true` pada baris `103`, rute halaman tembus perizinan membimbing *routing* menuju `HomeScreen`. Jika `false`, menendang balik masuk *state* ditolak disertai panggilan trigger modul animasi bergoyang (`_shakeController.forward()` di baris `116`).

### Tahap 8: Perancangan Layar Anti-Pengintaian 
**File:** `lib/screens/reader_screen.dart`
**Fungsi Utama:** Metode *Tap-to-Reveal* dan *OS Screen Blocking* (Mencegah diitip secara visibilitas manusia dari belakang & di *record* mesin).
- **Baris 75-81 `_enableSecureMode()`**: Kode pemicu modul package `ScreenProtector.preventScreenshotOn()`. Murni memblokir OS UI Level merespons segala hal seputar tangkapan gambar sistem layar; diubah menjadi piksel gelap seketika.
- **Baris 308 `GestureDetector()`**: Membuat area baca sensitif pijakan jari berjenis `onLongPressStart` dan `onLongPressEnd` (Fungsi interaksi *tahan-lama-untuk-menyimak*).
- **Baris 345-359 `BackdropFilter(ImageFilter.blur)`**: Ketika jari pengguna tidak sedang menekan teks catatan berdekripsi dalam RAM yang ditampilkannya, logika *Filter* menaruh penindih grafis blur berkekuatan sebaran sigma tinggi (baris 351). Menjanjikan tulisan itu utuh tapi rusak tak bisa dibaca bilamana tanpa disengaja layarnya disinggung atau dilihat sekejap.

### Tahap Tambahan: Editor, Splash & Beranda
- **`editor_screen.dart`**: Wadah tempat kodingan menerima pengetikan *input multi-line*. Punya mekanisme proteksi baris `79-145` `_saveNote()` yang berantai mengirim objek teks hasil ketikan menyambung permohonan ke lapisan kriptografi dan input output `.sync` tadi ketika diklik simpan.
- **`home_screen.dart`**: Layar muka utama dengan *observer* (baris 27-38). Di dalamnya terdapat algoritma di baris `101-119` `didChangeAppLifecycleState` yang secara instingtif memaksa melabuhkan UI ditendang kembali ke `LockScreen` apabila OS mendeteksi aplikasi memasukin status `AppLifecycleState.paused` (aplikasi ditinggalkan menuju *Recents Apps / Background*).

---

## 5. Demonstrasi Kesatuan *Workflow* Operasional (Selesai)

Apabila rangkaian riwayat teknis lapisan-lapisah kode di atas disatukan menjadi bundel biner/APK tunggal (*Build Release*), urutan berfungsinya skenario (*workflow*) hasil pembuatan aplikasi ini adalah:

1. **Inisiasi Kunci:** *Splash Screen* muncul; `CryptoService` membangun sandi perawan ke bagian saku Keystore Android/iOS pada latar belakang sistem.
2. **Validasi:** `LockScreen` meminta jari untuk perizinan; `BiometricService` membaca jawaban OS; berhasil.
3. **Konstruksi UI:** `HomeScreen` secara *in-memory* membacakan nama judul berkas `.sync` dari piringan memori kotak pasir `StorageService` saja.
4. **Aliran Memori Penginputan Didekripsi:** Menekan simbol '+' di mana OS dilingkupi tameng `screen_protector`. Pengguna mengetik kalimat -> Tekan Simpan -> teks dialihkan ke `CryptoService.encrypt()` -> wujud *bytes string Base64* dibalut ke rute file rahasia baru via `StorageService.saveNote()`.
5. **Mekanisme Ekstraksi Interaktif:** Pengguna menekan sebuah catatan -> *Reader Screen* mengeksekusi `getNoteById(id.sync)` untuk diterjemahkan oleh pembongkaran kripotgrafi memori RAM `decrypt()` -> Ditampilkannya ditindih oleh tameng grafik blur (BackdropFilter) -> Ditekan kuat, kaburnya luluh -> Tangan diangkat, kembali blur aman. 
6. **Mekanisme Relock:** Pengguna keluar melalui tombol navigasi layar HP -> `didChangeAppLifecycleState` memantau dan langsung berstatus terhenti permanen. Memaksa sensor jari dibuthkan jika dibuka kembali via logo navigasi Recent Apps.

*— Dokumentasi Selesai*
