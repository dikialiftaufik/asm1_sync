# SYNC — Secure Your Neural Cognition

<div align="center">
  <img src="assets/images/logo_no-bg.png" alt="SYNC Logo" width="120" />
  
  <h3>Jurnal Pribadi Terenkripsi dengan Autentikasi Biometrik</h3>
  
  <p>
    <img src="https://img.shields.io/badge/Flutter-3.x-02569B?style=flat-square&logo=flutter" />
    <img src="https://img.shields.io/badge/Dart-3.x-0175C2?style=flat-square&logo=dart" />
    <img src="https://img.shields.io/badge/Enkripsi-AES--256-green?style=flat-square&logo=letsencrypt" />
    <img src="https://img.shields.io/badge/Autentikasi-Biometrik-blue?style=flat-square&logo=authelia" />
    <img src="https://img.shields.io/badge/Platform-Android%20%7C%20iOS-lightgrey?style=flat-square" />
  </p>
</div>

---

## 📖 Deskripsi

**SYNC** adalah aplikasi jurnal digital yang dirancang dengan filosofi **"security-first"** — setiap keputusan desain dan arsitektur diambil dengan mempertimbangkan privasi dan keamanan data pengguna di atas segalanya.

SYNC adalah alat manajemen pengetahuan pribadi (Personal Knowledge Management / PKM) dan observasi psikologis. Setiap catatan yang Anda buat dienkripsi menggunakan standar kriptografi militer (AES-256-CBC) dan dilindungi oleh otentikasi biometrik perangkat Anda — menjadikan data Anda benar-benar hanya milik Anda.

> _"SYNC bukan sekadar catatan. Ini adalah brankas pikiran Anda."_

---

## 🛡️ Filosofi Keamanan SYNC

SYNC dibangun di atas tiga pilar keamanan utama:

### 1. 🔐 Zero-Knowledge Architecture

Data Anda **tidak pernah meninggalkan perangkat**. Tidak ada server, tidak ada cloud sync, tidak ada akun yang perlu dibuat. Setiap catatan disimpan sebagai file terenkripsi (`.sync`) di penyimpanan privat internal perangkat yang hanya bisa diakses oleh aplikasi SYNC sendiri.

### 2. 🧠 In-Memory Decryption

Dekripsi terjadi **hanya di RAM (memori aktif)**, bukan di disk. Artinya:

- File `.sync` di disk selalu dalam bentuk ciphertext (teks acak terenkripsi)
- Plaintext (teks asli yang bisa dibaca) hanya ada saat widget aktif di layar
- Saat Anda menutup catatan, plaintext hilang dari memori secara otomatis

### 3. 👁️ Anti Shoulder Surfing

Fitur **Tap-to-Reveal** memastikan konten catatan selalu dalam keadaan **blur** saat layar dibuka. Hanya saat Anda menekan dan menahan layar, teks menjadi terbaca. Ini melindungi dari orang yang mengintip layar HP Anda di tempat umum.

**Layer keamanan tambahan:**

- `FLAG_SECURE`: Memblokir screenshot dan menyembunyikan preview di Recent Apps
- Auto-lock: Aplikasi terkunci otomatis setiap kali masuk ke background
- Biometrik wajib: Tidak ada PIN backup yang bisa di-brute force
- Kunci AES disimpan di Android Keystore / iOS Secure Enclave

---

## ✨ Fitur Utama

| Fitur                      | Deskripsi                                                        |
| -------------------------- | ---------------------------------------------------------------- |
| 🔐 **Biometric Lock**      | Sidik jari / Face ID wajib setiap membuka aplikasi               |
| 🔒 **AES-256 Encryption**  | Setiap catatan dienkripsi dengan kunci unik per-perangkat        |
| 👁️ **Tap-to-Reveal**       | Konten otomatis diburamkan, tampil hanya saat ditekan            |
| 📁 **Local-First Storage** | Data tersimpan sebagai file `.sync` di perangkat, tanpa database |
| 🚫 **Screenshot Blocker**  | `FLAG_SECURE` memblokir semua bentuk rekaman layar               |
| 🔄 **Auto-Lock**           | Kunci otomatis saat aplikasi masuk background                    |
| ✏️ **Swipe to Delete**     | Hapus catatan dengan swipe + konfirmasi                          |
| 🌙 **Minimalist UI**       | Desain bersih "preppy/soft" dengan tipografi DM Sans             |

---

## 🛠️ Teknologi yang Digunakan

```yaml
dependencies:
  local_auth: ^2.3.0 # Autentikasi biometrik (sidik jari / Face ID)
  encrypt: ^5.0.3 # Enkripsi AES-256-CBC
  path_provider: ^2.1.5 # Akses direktori penyimpanan perangkat
  flutter_windowmanager: ^0.2.0 # FLAG_SECURE (blokir screenshot)
  flutter_secure_storage: ^9.2.4 # Simpan kunci AES di Keystore/Keychain
  intl: ^0.20.2 # Format tanggal Bahasa Indonesia
```

---

## 📁 Struktur Proyek

```
lib/
├── main.dart                  # Entry point aplikasi
│
├── models/
│   └── note_model.dart        # Model data catatan
│
├── services/
│   ├── crypto_service.dart    # Enkripsi & dekripsi AES-256
│   ├── storage_service.dart   # Baca/tulis file terenkripsi
│   └── biometric_service.dart # Autentikasi biometrik
│
├── screens/
│   ├── splash_screen.dart     # Layar pembuka (animasi logo)
│   ├── lock_screen.dart       # Layar biometrik
│   ├── home_screen.dart       # Daftar catatan
│   ├── editor_screen.dart     # Membuat/mengedit catatan
│   └── reader_screen.dart     # Membaca catatan (dengan blur)
│
└── theme/
    └── app_theme.dart         # Design system (warna, font, komponen)

assets/
├── images/
│   └── logo.png               # Logo SYNC
└── fonts/
    ├── DMSans-Regular.ttf
    ├── DMSans-Medium.ttf
    ├── DMSans-Bold.ttf
    └── DMSans-Italic.ttf
```

---

## 🚀 Cara Instalasi & Setup

### Prasyarat

- Flutter SDK `>=3.x`
- Android Studio / VS Code dengan Flutter extension
- Perangkat Android (API 23+) atau iOS (12.0+) dengan biometrik terdaftar

### Langkah-langkah

**1. Clone repositori**

```bash
git clone https://github.com/username/sync.git
cd sync
```

**2. Install dependensi**

```bash
flutter pub get
```

**3. Download font DM Sans**

Download [DM Sans dari Google Fonts](https://fonts.google.com/specimen/DM+Sans) lalu tempatkan file `.ttf` di:

```
assets/fonts/DMSans-Regular.ttf
assets/fonts/DMSans-Medium.ttf
assets/fonts/DMSans-Bold.ttf
assets/fonts/DMSans-Italic.ttf
```

**4. Konfigurasi Android (Sudah diatur, verifikasi saja)**

File `android/app/src/main/AndroidManifest.xml` harus memiliki:

```xml
<uses-permission android:name="android.permission.USE_BIOMETRIC" />
<uses-permission android:name="android.permission.USE_FINGERPRINT" />
```

**5. Konfigurasi iOS (Jika target iOS)**

Tambahkan ke `ios/Runner/Info.plist`:

```xml
<key>NSFaceIDUsageDescription</key>
<string>SYNC memerlukan Face ID untuk melindungi jurnal pribadi Anda</string>
```

**6. Jalankan aplikasi**

```bash
flutter run
```

---

## 📱 Alur Penggunaan (User Flow)

```
Buka Aplikasi
     │
     ▼
[Splash Screen]  ──── 2.5 detik ────▶  [Lock Screen]
                                              │
                              ┌───────────────┴──────────────────┐
                              │ Biometrik Berhasil               │ Biometrik Gagal
                              ▼                                  ▼
                        [Home Screen]                    Tampilkan error + Coba Lagi
                              │
              ┌───────────────┴────────────────────────┐
              │ Tap catatan                            │ Tap "Catatan Baru"
              ▼                                        ▼
        [Reader Screen]                         [Editor Screen]
        (Konten blur,                           (Tulis judul & isi)
         tahan untuk reveal)                          │
                                                [Simpan] → Enkripsi → File .sync
```

---

## 🔐 Detail Teknis Keamanan

### Algoritma Enkripsi

- **Algoritma**: AES (Advanced Encryption Standard)
- **Ukuran Kunci**: 256-bit (level enkripsi yang digunakan militer)
- **Mode Operasi**: CBC (Cipher Block Chaining)
- **Padding**: PKCS7

### Penyimpanan Kunci

Kunci enkripsi AES **tidak disimpan dalam kode sumber** (tidak di-hardcode). Kunci dibuat secara acak pada instalasi pertama dan disimpan menggunakan:

- **Android**: EncryptedSharedPreferences (diback oleh Android Keystore System)
- **iOS**: Keychain Services (Apple Secure Enclave)

### Format File

File catatan disimpan dengan ekstensi `.sync` di direktori dokumen privat aplikasi. Isi file adalah Base64-encoded ciphertext dari teks asli yang terformat:

```
Plaintext (sebelum enkripsi):
  TITLE:Judul Catatan
  CREATED:2024-04-02T10:00:00.000
  UPDATED:2024-04-02T10:00:00.000
  CONTENT:
  Isi catatan di sini...

File .sync (Base64 ciphertext):
  U2FsdGVkX1+rJ2x... (teks acak tidak terbaca)
```

---

## 📄 Lisensi

Proyek ini dibuat sebagai tugas akademik untuk mata kuliah **Pemrograman Perangkat Bergerak Lanjut** di **Telkom University**.

---

## 👨‍💻 Developer

| Info            | Detail                                |
| --------------- | ------------------------------------- |
| **Nama**        | Diki Alif Taufik                      |
| **NIM**         | 607012400005                          |
| **Mata Kuliah** | Pemrograman Perangkat Bergerak Lanjut |
| **Institusi**   | Telkom University                     |
| **Tahun**       | 2026                                  |

---

<div align="center">
  <p><i>SYNC — Your data stays with you. Always.</i></p>
</div>
