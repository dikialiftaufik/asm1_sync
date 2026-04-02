// 🔐 LAYAR: LockScreen
// Layar autentikasi biometrik yang menjadi "penjaga gerbang" aplikasi SYNC.
// Ditampilkan setelah splash screen dan setiap kali app kembali dari background.
//
// Filosofi desain:
// - Minimalis: Hanya tampilkan apa yang diperlukan (satu tombol unlock)
// - Informatif: Beri tahu pengguna jika biometrik tidak tersedia
// - Failsafe: Jika biometrik gagal, tampilkan pesan yang membantu

import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';
import '../services/biometric_service.dart';
import '../theme/app_theme.dart';
import 'home_screen.dart';

class LockScreen extends StatefulWidget {
  const LockScreen({super.key});

  @override
  State<LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends State<LockScreen>
    with SingleTickerProviderStateMixin {
  // State untuk melacak apakah autentikasi sedang berlangsung
  bool _isAuthenticating = false;

  // Pesan error yang ditampilkan jika autentikasi gagal
  String? _errorMessage;

  // Tipe biometrik yang tersedia (untuk ikon yang tepat)
  List<BiometricType> _availableBiometrics = [];

  // Animasi "goyang" saat autentikasi gagal
  late AnimationController _shakeController;
  late Animation<double> _shakeAnimation;

  @override
  void initState() {
    super.initState();

    // Inisialisasi animasi goyang
    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    _shakeAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: -8.0), weight: 1),
      TweenSequenceItem(tween: Tween(begin: -8.0, end: 8.0), weight: 2),
      TweenSequenceItem(tween: Tween(begin: 8.0, end: -8.0), weight: 2),
      TweenSequenceItem(tween: Tween(begin: -8.0, end: 0.0), weight: 1),
    ]).animate(CurvedAnimation(
      parent: _shakeController,
      curve: Curves.easeInOut,
    ));

    // Muat info biometrik lalu langsung minta autentikasi
    _loadBiometricInfo();
  }

  /// Memuat informasi tentang biometrik yang tersedia di perangkat.
  Future<void> _loadBiometricInfo() async {
    final biometrics = await BiometricService.getAvailableBiometrics();
    if (mounted) {
      setState(() => _availableBiometrics = biometrics);
    }
    // Langsung minta autentikasi saat layar dibuka untuk UX yang mulus
    await _authenticate();
  }

  /// Memulai proses autentikasi biometrik.
  Future<void> _authenticate() async {
    if (_isAuthenticating) return; // Hindari double-tap

    setState(() {
      _isAuthenticating = true;
      _errorMessage = null;
    });

    try {
      // Cek dulu apakah biometrik tersedia
      final isAvailable = await BiometricService.isAvailable();

      if (!isAvailable) {
        if (mounted) {
          setState(() {
            _errorMessage =
                'Biometrik tidak tersedia di perangkat ini.\n'
                'Pastikan Anda sudah mendaftarkan sidik jari atau wajah\n'
                'di pengaturan perangkat.';
            _isAuthenticating = false;
          });
        }
        return;
      }

      // Minta autentikasi ke pengguna
      final success = await BiometricService.authenticate();

      if (!mounted) return;

      if (success) {
        // ✅ Berhasil: Navigasi ke Home Screen
        Navigator.of(context).pushReplacement(
          PageRouteBuilder(
            pageBuilder: (_, __, ___) => const HomeScreen(),
            transitionsBuilder: (_, animation, __, child) {
              return FadeTransition(opacity: animation, child: child);
            },
            transitionDuration: const Duration(milliseconds: 400),
          ),
        );
      } else {
        // ❌ Gagal: Tampilkan pesan dan animasi goyang
        _shakeController.forward(from: 0);
        setState(() {
          _errorMessage = 'Autentikasi gagal. Coba lagi.';
          _isAuthenticating = false;
        });
      }
    } catch (e) {
      if (mounted) {
        _shakeController.forward(from: 0);
        setState(() {
          _errorMessage = 'Terjadi kesalahan: ${e.toString()}';
          _isAuthenticating = false;
        });
      }
    }
  }

  /// Menentukan ikon yang tepat berdasarkan biometrik yang tersedia.
  IconData _getBiometricIcon() {
    if (_availableBiometrics.contains(BiometricType.face)) {
      return Icons.face_retouching_natural_outlined;
    }
    return Icons.fingerprint;
  }

  @override
  void dispose() {
    _shakeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            children: [
              const Spacer(flex: 3),

              // Logo & nama aplikasi
              Image.asset(
                'assets/images/logo.png',
                width: 64,
                height: 64,
              ),
              const SizedBox(height: 16),
              Text('SYNC', style: AppTextStyles.headline),
              const SizedBox(height: 8),
              Text(
                'Verifikasi identitas Anda untuk melanjutkan',
                textAlign: TextAlign.center,
                style: AppTextStyles.caption.copyWith(fontSize: 13),
              ),

              const Spacer(flex: 2),

              // Tombol kunci dengan animasi goyang saat gagal
              AnimatedBuilder(
                animation: _shakeAnimation,
                builder: (context, child) {
                  return Transform.translate(
                    offset: Offset(_shakeAnimation.value, 0),
                    child: child,
                  );
                },
                child: GestureDetector(
                  onTap: _isAuthenticating ? null : _authenticate,
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: _isAuthenticating
                          ? AppColors.accentLight
                          : AppColors.accent,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.accent.withOpacity(0.3),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: _isAuthenticating
                        ? const Center(
                            child: SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppColors.accent,
                              ),
                            ),
                          )
                        : Icon(
                            _getBiometricIcon(),
                            color: Colors.white,
                            size: 36,
                          ),
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Label status
              Text(
                _isAuthenticating ? 'Memverifikasi...' : 'Ketuk untuk membuka',
                style: AppTextStyles.caption.copyWith(fontSize: 13),
              ),

              const SizedBox(height: 32),

              // Pesan error (hanya tampil jika ada)
              if (_errorMessage != null) ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.dangerLight,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.danger.withOpacity(0.2),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.warning_amber_rounded,
                        color: AppColors.danger,
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.danger,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: _authenticate,
                  child: const Text('Coba Lagi'),
                ),
              ],

              const Spacer(flex: 2),

              // Footer
              Text(
                'SYNC v1.0.0 — Your data never leaves this device',
                textAlign: TextAlign.center,
                style: AppTextStyles.caption.copyWith(
                  fontSize: 11,
                  color: AppColors.textSecondary.withOpacity(0.5),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
