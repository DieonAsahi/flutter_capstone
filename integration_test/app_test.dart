import 'package:aplikasi/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Flow Utama: Landing -> Login -> Home -> Rekomendasi', (tester) async {
    // 1. Mulai Aplikasi
    await tester.pumpWidget(MyApp());
    await tester.pumpAndSettle();

    // 2. Tekan Tombol di Landing Page
    // Mencari tombol yang mengandung teks 'Get Started'
    final btnGetStarted = find.text('Get Started');
    expect(btnGetStarted, findsOneWidget);
    await tester.tap(btnGetStarted);
    
    // Tunggu transisi navigasi selesai sepenuhnya
    // Kita beri waktu 3 detik untuk animasi pindah halaman
    await tester.pumpAndSettle(const Duration(seconds: 3));

    // 3. Verifikasi & Isi Login Page
    // Jika mencari Key gagal, kita cari berdasarkan label teks 'Username'
    final usernameField = find.byType(TextField).at(0);
    final passwordField = find.byType(TextField).at(1);
    
    // Pastikan field ditemukan
    expect(usernameField, findsOneWidget, reason: "TextField Username tidak ditemukan di layar.");

    await tester.enterText(usernameField, '_can');
    await tester.pump();
    await tester.enterText(passwordField, '12345678');
    await tester.pump();
    
    // Tekan tombol Login
    final loginButton = find.widgetWithText(ElevatedButton, 'Login');
    await tester.tap(loginButton);

    // 4. Menunggu Respon Server (Ngrok/Flask)
    // Beri waktu 10 detik karena proses login melibatkan database asli
    await tester.pumpAndSettle(const Duration(seconds: 10));

    // 5. Verifikasi Masuk Home
    // Cari teks 'Hello,' yang ada di HomePage kamu
    expect(find.textContaining('Hello,'), findsOneWidget, reason: "Gagal masuk ke HomePage.");

    // 6. Navigasi ke Rekomendasi
    final menuRekomendasi = find.text('Rekomendasi');
    await tester.ensureVisible(menuRekomendasi);
    await tester.tap(menuRekomendasi);
    await tester.pumpAndSettle(const Duration(seconds: 2));

    // 7. Cek Halaman Rekomendasi
    expect(find.text('Pilih Sumber Rekomendasi'), findsOneWidget);
    
    print("-----------------------------------------");
    print("TEST INTEGRASI BERHASIL PASSED! ✨");
    print("-----------------------------------------");
  });
}