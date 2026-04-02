// Test file untuk SYNC App.
// Test dasar ini memverifikasi bahwa SyncApp bisa dirender tanpa crash.
// Catatan: Biometrik dan enkripsi tidak bisa diuji di unit test biasa
// karena memerlukan hardware (sensor sidik jari) dan platform channel.

import 'package:flutter_test/flutter_test.dart';
import 'package:asm1_sync/main.dart';

void main() {
  testWidgets('SYNC App smoke test — SyncApp dapat dirender', (WidgetTester tester) async {
    // Build widget root aplikasi SYNC
    await tester.pumpWidget(const SyncApp());

    // Verifikasi bahwa widget berhasil dirender (tidak throw exception)
    // SplashScreen akan ditampilkan pertama kali
    expect(find.byType(SyncApp), findsOneWidget);
  });
}
