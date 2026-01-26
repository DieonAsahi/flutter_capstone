import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:aplikasi/pages/registerpage.dart'; // Pastikan path file register kamu benar

void main() {
  testWidgets('RegisterPage UI and Validation Test', (WidgetTester tester) async {
    // 1. Atur resolusi layar agar tidak ada elemen yang off-screen
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1.0;

    // 2. Render halaman Register
    await tester.pumpWidget(const MaterialApp(home: RegisterPage()));

    // 3. Pastikan elemen utama muncul
    expect(find.text('Create Account'), findsOneWidget);
    
    final registerButtonFinder = find.widgetWithText(ElevatedButton, 'Register');
    expect(registerButtonFinder, findsOneWidget);

    // 4. Simulasi Input: Isi Nama dan Username agar validasi tidak berhenti di awal
    await tester.enterText(find.byType(TextField).at(0), 'Akmal Kurniawan');
    await tester.enterText(find.byType(TextField).at(1), 'akmal_k');
    
    // 5. Simulasi Error: Isi password tapi konfirmasi dikosongkan
    await tester.enterText(find.byType(TextField).at(2), 'password123'); // Password
    await tester.enterText(find.byType(TextField).at(3), ''); // Confirm Password kosong
    
    // 6. Scroll ke tombol jika diperlukan dan Tekan Register
    await tester.ensureVisible(registerButtonFinder);
    await tester.tap(registerButtonFinder);

    // 7. PENTING: Tunggu animasi SnackBar muncul sepenuhnya
    // pumpAndSettle akan menunggu semua animasi (termasuk floating snackbar) selesai
    await tester.pumpAndSettle();

    // 8. Cek apakah pesan error muncul
    expect(find.text('Konfirmasi password tidak sama'), findsOneWidget);

    // Reset ukuran layar
    addTearDown(tester.view.resetPhysicalSize);
  });
}