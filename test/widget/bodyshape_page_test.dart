import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:aplikasi/pages/bodyshape.dart';

void main() {
  // Pastikan binding terinisialisasi
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    // Mock data user login agar tidak error saat SharedPreferences dipanggil
    SharedPreferences.setMockInitialValues({'user_id': 1});
  });

  Widget createTestWidget() {
    return const MaterialApp(home: BodyShapePage());
  }

  testWidgets('Halaman BodyShape tampil dengan benar', (tester) async {
    await tester.pumpWidget(createTestWidget());

    // Memastikan judul dan elemen dasar muncul
    expect(find.text('Bentuk Tubuh'), findsOneWidget);
    expect(find.byType(TextField), findsNWidgets(3));
  });

  testWidgets('Klik tanpa input menampilkan snackbar error', (tester) async {
    // --- PERBAIKAN 1: Atur Ukuran Layar ---
    // Kita buat layar lebih tinggi (1200) agar tombol 'Lihat Hasil' tidak terpotong
    tester.view.physicalSize = const Size(800, 1200);
    tester.view.devicePixelRatio = 1.0;

    await tester.pumpWidget(createTestWidget());

    final buttonFinder = find.text('Lihat Hasil');

    // --- PERBAIKAN 2: Scroll ke tombol ---
    // ensureVisible akan mensimulasikan scroll sampai widget terlihat
    await tester.ensureVisible(buttonFinder);
    await tester.pumpAndSettle(); // Tunggu animasi scroll selesai

    await tester.tap(buttonFinder);
    await tester.pump(); // Trigger frame untuk snackbar

    expect(find.text('Mohon isi semua data'), findsOneWidget);

    // Reset ukuran layar setelah test selesai agar tidak mengganggu test lain
    addTearDown(tester.view.resetPhysicalSize);
  });

  testWidgets('Input non-angka ditolak formatter', (tester) async {
    await tester.pumpWidget(createTestWidget());

    final bustField = find.byType(TextField).at(0);

    // Simulasi user mengetik huruf
    await tester.enterText(bustField, 'abc');
    await tester.pump();

    // Karena kita pakai FilteringTextInputFormatter, teks seharusnya tetap kosong
    final textField = tester.widget<TextField>(bustField);
    expect(textField.controller!.text.isEmpty, true);
  });

  testWidgets('Input valid dapat diproses', (tester) async {
    // Atur layar agar tombol bisa di-klik
    tester.view.physicalSize = const Size(800, 1200);
    tester.view.devicePixelRatio = 1.0;

    await tester.pumpWidget(createTestWidget());

    // Isi semua field
    await tester.enterText(find.byType(TextField).at(0), '90');
    await tester.enterText(find.byType(TextField).at(1), '70');
    await tester.enterText(find.byType(TextField).at(2), '95');

    final buttonFinder = find.text('Lihat Hasil');
    await tester.ensureVisible(buttonFinder);
    await tester.tap(buttonFinder);
    await tester.pump();

    // Pastikan snackbar "Mohon isi semua data" TIDAK muncul
    expect(find.text('Mohon isi semua data'), findsNothing);

    addTearDown(tester.view.resetPhysicalSize);
  });
}