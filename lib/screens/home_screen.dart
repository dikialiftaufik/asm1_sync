// 🏠 LAYAR: HomeScreen
// Beranda aplikasi SYNC yang menampilkan daftar semua catatan.
// Ini adalah layar utama setelah pengguna berhasil terautentikasi.
//
// Fitur keamanan di layar ini:
// - Aplikasi dipantau untuk mendeteksi saat masuk ke background
// - Jika aplikasi kembali dari background, layar kunci ditampilkan ulang
// - Flutter WindowManager mencegah screenshot konten sensitif

import 'package:flutter/material.dart';
import 'package:screen_protector/screen_protector.dart';
import 'package:intl/intl.dart';
import '../models/note_model.dart';
import '../services/storage_service.dart';
import '../theme/app_theme.dart';
import 'editor_screen.dart';
import 'lock_screen.dart';
import 'reader_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  // Daftar catatan yang ditampilkan
  List<NoteModel> _notes = [];

  // State loading saat memuat catatan dari storage
  bool _isLoading = true;

  // Flag untuk mencegah auto-lock yang dipicu oleh dialog biometrik sistem
  // Ketika dialog biometrik muncul, app masuk ke state 'inactive', bukan 'paused'.
  // Namun setelah dialog ditutup, 'resumed' dipicu — kita TIDAK mau lock di sini.
  // Solusi: hanya lock jika SEBELUMNYA app benar-benar di-pause (masuk background).
  bool _wasInBackground = false;

  @override
  void initState() {
    super.initState();

    // Daftarkan observer untuk memantau lifecycle aplikasi
    // WidgetsBindingObserver memungkinkan kita bereaksi saat app masuk background
    WidgetsBinding.instance.addObserver(this);

    // Aktifkan FLAG_SECURE untuk memblokir screenshot
    _enableSecureMode();

    // Muat catatan dari storage
    _loadNotes();
  }

  /// Mengaktifkan mode aman yang memblokir screenshot dan preview di Recent Apps.
  ///
  /// Mengapa ini penting?
  /// Tanpa FLAG_SECURE, konten catatan bisa terekam di:
  /// 1. Screenshot manual oleh pengguna lain
  /// 2. Preview thumbnail di layar Recent Apps (bisa dilihat orang di sekitar)
  /// 3. Screen recording oleh aplikasi lain
  Future<void> _enableSecureMode() async {
    try {
      await ScreenProtector.preventScreenshotOn();
    } catch (e) {
      // Jika flutter_windowmanager tidak tersedia, lanjutkan tanpa crash
      debugPrint('HomeScreen: FLAG_SECURE tidak bisa diaktifkan: $e');
    }
  }

  /// Memuat semua catatan dari penyimpanan lokal secara asinkron.
  ///
  /// Mengapa menggunakan setState setelah future selesai?
  /// Karena operasi file membutuhkan waktu (I/O) dan kita tidak ingin
  /// membekukan UI selama proses berlangsung. setState memberitahu Flutter
  /// bahwa data sudah siap dan UI perlu diperbarui.
  Future<void> _loadNotes() async {
    setState(() => _isLoading = true);

    try {
      final notes = await StorageService.getAllNotes();
      if (mounted) {
        setState(() {
          _notes = notes;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        _showErrorSnackbar('Gagal memuat catatan: ${e.toString()}');
      }
    }
  }

  /// Dipanggil saat aplikasi berpindah status (foreground/background/inactive).
  ///
  /// WidgetsBindingObserver.didChangeAppLifecycleState adalah cara Flutter
  /// untuk memantau siklus hidup aplikasi tanpa Android-specific code.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    if (state == AppLifecycleState.paused) {
      // App benar-benar masuk ke background (layar Recent/home ditekan)
      _wasInBackground = true;
    }

    if (state == AppLifecycleState.resumed && _wasInBackground) {
      // App kembali ke foreground SETELAH benar-benar di-background
      // Kunci ulang untuk keamanan
      _wasInBackground = false;
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const LockScreen()),
        );
      }
    }
  }

  /// Menghapus catatan setelah konfirmasi dari pengguna.
  Future<void> _deleteNote(NoteModel note) async {
    // Tampilkan dialog konfirmasi sebelum menghapus
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        backgroundColor: AppColors.background,
        title: Text('Hapus Catatan?', style: AppTextStyles.title),
        content: Text(
          'Catatan "${note.title}" akan dihapus secara permanen dan tidak bisa dipulihkan.',
          style: AppTextStyles.body.copyWith(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.danger),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await StorageService.deleteNote(note.id);
      _loadNotes(); // Muat ulang daftar setelah menghapus
    }
  }

  void _showErrorSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.danger,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  void dispose() {
    // Hapus observer saat layar di-dispose untuk menghindari memory leak
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ─── HEADER ──────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _getGreeting(),
                          style: AppTextStyles.caption.copyWith(
                            letterSpacing: 1.5,
                            color: AppColors.accent,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text('Neural Log', style: AppTextStyles.headline),
                      ],
                    ),
                  ),
                  // Badge jumlah catatan
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.accentLight,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${_notes.length} entri',
                      style: AppTextStyles.label.copyWith(
                        color: AppColors.accent,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // ─── ISI UTAMA ────────────────────────────────────────────
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: AppColors.accent,
                        strokeWidth: 2,
                      ),
                    )
                  : _notes.isEmpty
                      ? _buildEmptyState()
                      : _buildNotesList(),
            ),
          ],
        ),
      ),

      // ─── FAB: Tombol Tambah Catatan ───────────────────────────────
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          // Navigasi ke editor, tunggu hasilnya
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const EditorScreen()),
          );
          // Jika editor mengembalikan true (catatan disimpan), muat ulang daftar
          if (result == true) _loadNotes();
        },
        backgroundColor: AppColors.accent,
        foregroundColor: Colors.white,
        elevation: 0,
        icon: const Icon(Icons.add_rounded, size: 20),
        label: Text(
          'Catatan Baru',
          style: AppTextStyles.label.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  /// Menampilkan daftar catatan menggunakan ListView.
  Widget _buildNotesList() {
    return RefreshIndicator(
      onRefresh: _loadNotes,
      color: AppColors.accent,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
        itemCount: _notes.length,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (context, index) {
          final note = _notes[index];
          return _buildNoteCard(note);
        },
      ),
    );
  }

  /// Membangun kartu individual untuk satu catatan.
  Widget _buildNoteCard(NoteModel note) {
    return Dismissible(
      // Swipe to delete dengan konfirmasi
      key: Key(note.id),
      direction: DismissDirection.endToStart,
      background: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: AppColors.dangerLight,
          borderRadius: BorderRadius.circular(16),
        ),
        alignment: Alignment.centerRight,
        child: const Icon(Icons.delete_outline, color: AppColors.danger),
      ),
      confirmDismiss: (_) async {
        await _deleteNote(note);
        return false; // Jangan auto-dismiss, biarkan _loadNotes yang handle
      },
      child: GestureDetector(
        onTap: () async {
          // Buka ReaderScreen, muat ulang setelah kembali
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ReaderScreen(noteId: note.id),
            ),
          );
          if (result == true) _loadNotes();
        },
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      note.title,
                      style: AppTextStyles.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 12,
                    color: AppColors.textSecondary,
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Preview isi: placeholder bar (melambangkan konten terenkripsi)
              Container(
                height: 12,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(height: 6),
              Container(
                height: 12,
                width: 140,
                decoration: BoxDecoration(
                  color: AppColors.border.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),

              const SizedBox(height: 12),

              // Metadata: tanggal update
              Row(
                children: [
                  Icon(
                    Icons.lock_outline_rounded,
                    size: 12,
                    color: AppColors.accent.withOpacity(0.7),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Terenkripsi · ${_formatDate(note.updatedAt)}',
                    style: AppTextStyles.caption.copyWith(fontSize: 11),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Tampilan kosong ketika belum ada catatan.
  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.accentLight,
                borderRadius: BorderRadius.circular(24),
              ),
              child: const Icon(
                Icons.book_outlined,
                size: 36,
                color: AppColors.accent,
              ),
            ),
            const SizedBox(height: 24),
            Text('Belum Ada Catatan', style: AppTextStyles.title),
            const SizedBox(height: 8),
            Text(
              'Mulai mencatat pemikiran, observasi,\ndan pengetahuan hari ini.',
              textAlign: TextAlign.center,
              style: AppTextStyles.body.copyWith(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Menghasilkan salam berdasarkan waktu hari ini.
  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'SELAMAT PAGI';
    if (hour < 17) return 'SELAMAT SIANG';
    if (hour < 20) return 'SELAMAT SORE';
    return 'SELAMAT MALAM';
  }

  /// Format tanggal yang ramah (misalnya: "2 Apr 2026")
  String _formatDate(DateTime date) {
    return DateFormat('d MMM yyyy', 'id_ID').format(date);
  }
}
