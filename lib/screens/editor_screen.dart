// ✏️ LAYAR: EditorScreen
// Layar untuk membuat catatan baru atau mengedit catatan yang sudah ada.
//
// Fitur keamanan:
// - FLAG_SECURE aktif (tidak bisa di-screenshot)
// - Auto-save jika pengguna meninggalkan layar tanpa menyimpan (opsional)
// - Enkripsi terjadi SAAT tombol Simpan ditekan, bukan real-time
//   (real-time encryption akan membebani CPU dan menghabiskan baterai)

import 'package:flutter/material.dart';
import 'package:flutter_windowmanager/flutter_windowmanager.dart';
import '../models/note_model.dart';
import '../services/storage_service.dart';
import '../theme/app_theme.dart';

class EditorScreen extends StatefulWidget {
  /// Jika [existingNote] tidak null, mode EDIT. Jika null, mode BUAT BARU.
  final NoteModel? existingNote;

  const EditorScreen({super.key, this.existingNote});

  @override
  State<EditorScreen> createState() => _EditorScreenState();
}

class _EditorScreenState extends State<EditorScreen> {
  // Controller untuk mengontrol dan membaca nilai input field
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _contentController = TextEditingController();

  // Focus node untuk berpindah focus antar field
  final FocusNode _contentFocusNode = FocusNode();

  // State saat sedang menyimpan (mencegah double-tap tombol simpan)
  bool _isSaving = false;
  // Apakah ada perubahan yang belum disimpan
  bool _hasChanges = false;

  bool get _isEditMode => widget.existingNote != null;

  @override
  void initState() {
    super.initState();
    _enableSecureMode();

    // Jika mode edit, isi field dengan data catatan yang ada
    if (_isEditMode) {
      _titleController.text = widget.existingNote!.title;
      _contentController.text = widget.existingNote!.content;
    }

    // Pantau perubahan teks untuk mendeteksi "ada perubahan belum disimpan"
    _titleController.addListener(_onTextChanged);
    _contentController.addListener(_onTextChanged);
  }

  Future<void> _enableSecureMode() async {
    try {
      await FlutterWindowManager.addFlags(FlutterWindowManager.FLAG_SECURE);
    } catch (e) {
      debugPrint('EditorScreen: FLAG_SECURE tidak bisa diaktifkan: $e');
    }
  }

  void _onTextChanged() {
    if (!_hasChanges) {
      setState(() => _hasChanges = true);
    }
  }

  /// Menyimpan catatan: enkripsi lalu tulis ke file.
  /// 
  /// Proses lengkap:
  /// 1. Validasi input (judul tidak boleh kosong)
  /// 2. Panggil StorageService.saveNote() atau updateNote()
  /// 3. StorageService akan memanggil CryptoService.encrypt() secara internal
  /// 4. Data terenkripsi ditulis ke file .sync
  /// 5. Kembali ke Home dengan signal "ada catatan baru" (return true)
  Future<void> _saveNote() async {
    // Hapus spasi di awal/akhir
    final title = _titleController.text.trim();
    final content = _contentController.text.trim();

    // Validasi: judul wajib diisi
    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Judul catatan tidak boleh kosong'),
          backgroundColor: AppColors.danger,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      if (_isEditMode) {
        // Mode edit: perbarui catatan yang sudah ada
        await StorageService.updateNote(
          existingNote: widget.existingNote!,
          newTitle: title,
          newContent: content,
        );
      } else {
        // Mode baru: buat catatan baru
        await StorageService.saveNote(title: title, content: content);
      }

      if (mounted) {
        // Tampilkan notifikasi berhasil
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.lock, color: Colors.white, size: 16),
                const SizedBox(width: 8),
                Text(_isEditMode ? 'Catatan diperbarui & dienkripsi' : 'Catatan disimpan & dienkripsi'),
              ],
            ),
            backgroundColor: AppColors.accent,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            duration: const Duration(seconds: 2),
          ),
        );

        // Kembalikan `true` ke HomeScreen agar daftar catatan di-refresh
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      setState(() => _isSaving = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal menyimpan: ${e.toString()}'),
            backgroundColor: AppColors.danger,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  /// Menangani tombol kembali saat ada perubahan belum disimpan.
  Future<bool> _onWillPop() async {
    if (!_hasChanges) return true;

    // Tampilkan dialog konfirmasi "batalkan perubahan?"
    final shouldLeave = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        backgroundColor: AppColors.background,
        title: Text('Tinggalkan tanpa menyimpan?', style: AppTextStyles.title),
        content: Text(
          'Perubahan yang belum disimpan akan hilang.',
          style: AppTextStyles.body.copyWith(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Tetap di Sini'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.danger),
            child: const Text('Tinggalkan'),
          ),
        ],
      ),
    );

    return shouldLeave ?? false;
  }

  @override
  void dispose() {
    // Selalu dispose controller dan focus node untuk mencegah memory leak
    _titleController.dispose();
    _contentController.dispose();
    _contentFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      // PopScope menggantikan WillPopScope yang sudah deprecated di Flutter 3.12+
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final shouldPop = await _onWillPop();
        if (shouldPop && mounted) Navigator.of(context).pop();
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.background,
          elevation: 0,
          leading: IconButton(
            onPressed: () async {
              final shouldPop = await _onWillPop();
              if (shouldPop && mounted) Navigator.of(context).pop();
            },
            icon: const Icon(Icons.arrow_back_rounded),
          ),
          title: Text(
            _isEditMode ? 'Edit Catatan' : 'Catatan Baru',
            style: AppTextStyles.title,
          ),
          actions: [
            // Tombol Simpan di AppBar
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: _isSaving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.accent,
                      ),
                    )
                  : TextButton.icon(
                      onPressed: _saveNote,
                      icon: const Icon(Icons.lock_outline_rounded, size: 16),
                      label: const Text('Enkripsi & Simpan'),
                    ),
            ),
          ],
        ),
        body: Column(
          children: [
            // Divider tipis di bawah AppBar
            Container(height: 1, color: AppColors.border),

            // Indikator status enkripsi
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
              color: AppColors.accentLight,
              child: Row(
                children: [
                  const Icon(Icons.shield_outlined, size: 14, color: AppColors.accent),
                  const SizedBox(width: 8),
                  Text(
                    'Catatan akan dienkripsi AES-256 sebelum disimpan',
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.accent,
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),

            // Form input
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Field judul — tanpa border, tampak seperti heading
                    TextField(
                      controller: _titleController,
                      style: AppTextStyles.headline.copyWith(fontSize: 22),
                      decoration: const InputDecoration(
                        hintText: 'Judul catatan...',
                        hintStyle: TextStyle(
                          color: AppColors.border,
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          fontFamily: 'DMSans',
                        ),
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        filled: false,
                        contentPadding: EdgeInsets.zero,
                      ),
                      textCapitalization: TextCapitalization.sentences,
                      maxLines: 2,
                      minLines: 1,
                      textInputAction: TextInputAction.next,
                      onSubmitted: (_) {
                        // Pindah ke field konten saat tekan "next" di keyboard
                        FocusScope.of(context).requestFocus(_contentFocusNode);
                      },
                    ),

                    const SizedBox(height: 4),
                    Container(height: 1, color: AppColors.border),
                    const SizedBox(height: 16),

                    // Field konten
                    TextField(
                      controller: _contentController,
                      focusNode: _contentFocusNode,
                      style: AppTextStyles.body.copyWith(height: 1.8),
                      decoration: const InputDecoration(
                        hintText: 'Tulis observasi, pemikiran, atau pengetahuanmu di sini...',
                        hintStyle: TextStyle(
                          color: AppColors.border,
                          fontSize: 15,
                          fontFamily: 'DMSans',
                          height: 1.8,
                        ),
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        filled: false,
                        contentPadding: EdgeInsets.zero,
                      ),
                      textCapitalization: TextCapitalization.sentences,
                      maxLines: null, // Tidak ada batas baris
                      minLines: 15,
                      keyboardType: TextInputType.multiline,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
