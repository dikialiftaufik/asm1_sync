// 📖 LAYAR: ReaderScreen
// Layar untuk membaca catatan yang sudah tersimpan.
//
// Fitur Utama - "Tap-to-Reveal" (Anti Shoulder Surfing):
// Seluruh konten catatan ditampilkan dalam keadaan BLUR secara default.
// Pengguna harus menekan dan MENAHAN layar (long press) untuk membaca teks.
// Saat jari diangkat, teks kembali diburamkan.
//
// Menagpa tap-to-reveal?
// Melindungi dari "shoulder surfing" — kondisi ketika seseorang mengintip
// layar HP di tempat umum (angkutan umum, kafe, dll).
//
// Proses In-Memory Decryption:
// 1. Baca ciphertext dari file .sync
// 2. Dekripsi di RAM → _note (variabel di State)
// 3. Tampilkan ke layar (dengan efek blur sebagai default)
// 4. Dispose widget → variabel hilang dari RAM, file tetap terenkripsi

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_windowmanager/flutter_windowmanager.dart';
import 'package:intl/intl.dart';
import '../models/note_model.dart';
import '../services/storage_service.dart';
import '../theme/app_theme.dart';
import 'editor_screen.dart';

class ReaderScreen extends StatefulWidget {
  /// ID catatan yang akan dibuka (nama file tanpa ekstensi)
  final String noteId;

  const ReaderScreen({super.key, required this.noteId});

  @override
  State<ReaderScreen> createState() => _ReaderScreenState();
}

class _ReaderScreenState extends State<ReaderScreen>
    with SingleTickerProviderStateMixin {
  // Data catatan yang sudah didekripsi (hanya ada di RAM, tidak ditulis ke disk)
  NoteModel? _note;

  // State loading saat sedang mendekripsi
  bool _isLoading = true;

  // Pesan error jika dekripsi gagal
  String? _errorMessage;

  // Apakah teks sedang "terungkap" (blur dimatikan)
  bool _isRevealed = false;

  // Animasi untuk transisi blur ↔ clear
  late AnimationController _revealController;
  late Animation<double> _blurAnimation;

  @override
  void initState() {
    super.initState();
    _enableSecureMode();

    // Animasi blur: dari 14.0 (sangat buram) ke 0.0 (jelas)
    _revealController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _blurAnimation = Tween<double>(begin: 14.0, end: 0.0).animate(
      CurvedAnimation(parent: _revealController, curve: Curves.easeOut),
    );

    // Muat dan dekripsi catatan saat layar dibuka
    _loadAndDecryptNote();
  }

  Future<void> _enableSecureMode() async {
    try {
      await FlutterWindowManager.addFlags(FlutterWindowManager.FLAG_SECURE);
    } catch (e) {
      debugPrint('ReaderScreen: FLAG_SECURE tidak bisa diaktifkan: $e');
    }
  }

  /// Membaca file .sync dari storage dan mendekripsinya di memori.
  ///
  /// "In-Memory Decryption": file dibaca dari disk → dekripsi di RAM →
  /// hasil disimpan di variabel Dart → saat widget dispose, variabel hilang otomatis.
  Future<void> _loadAndDecryptNote() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final note = await StorageService.getNoteById(widget.noteId);

      if (mounted) {
        setState(() {
          _note = note;
          _isLoading = false;
          if (note == null) {
            _errorMessage = 'Catatan tidak ditemukan atau rusak';
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Gagal mendekripsi catatan: ${e.toString()}';
        });
      }
    }
  }

  /// Tampilkan konten saat jari ditekan lama.
  void _revealContent() {
    setState(() => _isRevealed = true);
    _revealController.forward();
  }

  /// Sembunyikan konten kembali saat jari diangkat.
  void _hideContent() {
    setState(() => _isRevealed = false);
    _revealController.reverse();
  }

  String _formatDate(DateTime date) {
    return DateFormat('EEEE, dd MMMM yyyy — HH:mm', 'id_ID').format(date);
  }

  @override
  void dispose() {
    _revealController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        actions: [
          // Tombol edit — hanya tampil jika catatan berhasil dimuat
          if (_note != null)
            IconButton(
              onPressed: () async {
                // Pastikan _note tidak null sebelum dikirim ke EditorScreen
                final currentNote = _note!;
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => EditorScreen(existingNote: currentNote),
                  ),
                );
                if (result == true && mounted) {
                  // Kembali ke HomeScreen dengan sinyal refresh
                  Navigator.of(context).pop(true);
                }
              },
              icon: const Icon(Icons.edit_outlined, size: 20),
              tooltip: 'Edit Catatan',
            ),
          const SizedBox(width: 8),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    // State 1: Loading
    if (_isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(
              color: AppColors.accent,
              strokeWidth: 2,
            ),
            const SizedBox(height: 16),
            Text(
              'Mendekripsi catatan...',
              style: AppTextStyles.caption,
            ),
          ],
        ),
      );
    }

    // State 2: Error
    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, color: AppColors.danger, size: 48),
              const SizedBox(height: 16),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: AppTextStyles.body,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _loadAndDecryptNote,
                child: const Text('Coba Lagi'),
              ),
            ],
          ),
        ),
      );
    }

    // State 3: Sukses — tampilkan catatan
    // Gunakan _note! dengan aman karena di sini _note pasti tidak null
    // (error sudah ditangani di state 2 di atas)
    final note = _note!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ─── HEADER: Judul dan metadata ──────────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(note.title, style: AppTextStyles.headline),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(
                    Icons.access_time_rounded,
                    size: 12,
                    color: AppColors.textSecondary,
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      _formatDate(note.updatedAt),
                      style: AppTextStyles.caption.copyWith(fontSize: 11),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(
                    Icons.lock,
                    size: 12,
                    color: AppColors.accent.withOpacity(0.8),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Didekripsi AES-256 di memori saja',
                    style: AppTextStyles.caption.copyWith(
                      fontSize: 11,
                      color: AppColors.accent.withOpacity(0.8),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        Container(height: 1, color: AppColors.border),

        // ─── INSTRUKSI TAP-TO-REVEAL ──────────────────────────────────
        AnimatedOpacity(
          opacity: _isRevealed ? 0.0 : 1.0,
          duration: const Duration(milliseconds: 200),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
            color: AppColors.accentLight,
            child: Row(
              children: [
                const Icon(
                  Icons.touch_app_outlined,
                  size: 14,
                  color: AppColors.accent,
                ),
                const SizedBox(width: 8),
                Text(
                  'Tekan dan tahan untuk membaca konten',
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.accent,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),

        // ─── AREA KONTEN DENGAN TAP-TO-REVEAL ───────────────────────
        Expanded(
          child: GestureDetector(
            onLongPressStart: (_) => _revealContent(),
            onLongPressEnd: (_) => _hideContent(),
            behavior: HitTestBehavior.opaque,
            child: AnimatedBuilder(
              animation: _blurAnimation,
              builder: (context, child) {
                return Stack(
                  fit: StackFit.expand,
                  children: [
                    // Konten teks asli (di bawah blur)
                    SingleChildScrollView(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SelectableText(
                            note.content.isEmpty
                                ? '(Catatan ini tidak memiliki konten)'
                                : note.content,
                            style: AppTextStyles.body.copyWith(
                              height: 1.8,
                              color: note.content.isEmpty
                                  ? AppColors.textSecondary
                                  : AppColors.textPrimary,
                              fontStyle: note.content.isEmpty
                                  ? FontStyle.italic
                                  : FontStyle.normal,
                            ),
                          ),
                          const SizedBox(height: 80),
                        ],
                      ),
                    ),

                    // Overlay blur — aktif ketika belum di-reveal
                    if (_blurAnimation.value > 0.1)
                      Positioned.fill(
                        child: ClipRect(
                          child: BackdropFilter(
                            // BackdropFilter mengaburkan semua widget di belakangnya
                            filter: ImageFilter.blur(
                              sigmaX: _blurAnimation.value,
                              sigmaY: _blurAnimation.value,
                            ),
                            child: Container(
                              color: AppColors.background.withOpacity(0.05),
                            ),
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
          ),
        ),

        // ─── FOOTER: Status visibility ────────────────────────────────
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: AppColors.surface,
            border: Border(top: BorderSide(color: AppColors.border)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                _isRevealed
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined,
                size: 14,
                color: AppColors.textSecondary,
              ),
              const SizedBox(width: 6),
              Text(
                _isRevealed
                    ? 'Konten terlihat — lepaskan untuk menyembunyikan'
                    : 'Konten tersembunyi (anti shoulder surfing)',
                style: AppTextStyles.caption.copyWith(fontSize: 11),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
