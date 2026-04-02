// 🖥️ LAYAR: SplashScreen
// Layar pembuka yang ditampilkan saat aplikasi pertama kali dibuka.
//
// Fungsi splash screen dalam SYNC:
// 1. Menampilkan identitas brand (logo)
// 2. Memberikan waktu untuk inisialisasi service (crypto, storage)
// 3. Transisi mulus menuju Lock Screen
//
// Desain: Putih bersih dengan logo di tengah dan animasi fade-in yang halus.

import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'lock_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  // AnimationController: mengontrol durasi dan alur animasi
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();

    // Inisialisasi controller animasi dengan durasi 1.2 detik
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    // Fade animation: logo muncul dari transparan menjadi solid
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
      ),
    );

    // Scale animation: logo "tumbuh" dari kecil ke ukuran normal
    _scaleAnimation = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOutCubic),
      ),
    );

    // Mulai animasi segera setelah widget dibangun
    _animationController.forward();

    // Navigasi ke Lock Screen setelah 2.5 detik
    _navigateToLockScreen();
  }

  /// Menunggu lalu berpindah ke Lock Screen.
  Future<void> _navigateToLockScreen() async {
    await Future.delayed(const Duration(milliseconds: 2500));

    // Cek apakah widget masih ada di tree sebelum navigate
    if (mounted) {
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) =>
              const LockScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
          transitionDuration: const Duration(milliseconds: 600),
        ),
      );
    }
  }

  @override
  void dispose() {
    // Selalu dispose AnimationController untuk mencegah memory leak!
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: AnimatedBuilder(
          animation: _animationController,
          builder: (context, child) {
            return Opacity(
              opacity: _fadeAnimation.value,
              child: Transform.scale(
                scale: _scaleAnimation.value,
                child: child,
              ),
            );
          },
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logo aplikasi
              Image.asset(
                'assets/images/logo.png',
                width: 120,
                height: 120,
              ),
              const SizedBox(height: 24),
              // Nama aplikasi
              Text(
                'SYNC',
                style: AppTextStyles.displayLarge.copyWith(
                  letterSpacing: 8,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Secure Your Neural Cognition',
                style: AppTextStyles.caption.copyWith(
                  letterSpacing: 2,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 60),
              // Indikator loading minimal
              SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 1.5,
                  color: AppColors.textSecondary.withOpacity(0.4),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
