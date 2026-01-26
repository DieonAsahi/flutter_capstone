import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:aplikasi/pages/homepage.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    // Mock SharedPreferences agar tidak error saat initState memanggil data lokal
    SharedPreferences.setMockInitialValues({'name': 'Araa', 'user_id': 1});
  });

  Widget createTestWidget() {
    return MaterialApp(
      home: const HomePage(),
      routes: {
        '/bodyshape': (_) => const Scaffold(body: Text('BodyShape Page')),
        '/analysis': (_) => const Scaffold(body: Text('Analysis Page')),
        '/custom': (_) => const Scaffold(body: Text('Custom Page')),
        '/recommendation': (_) =>
            const Scaffold(body: Text('Recommendation Page')),
        '/skintone': (_) => const Scaffold(body: Text('Skintone Page')),
        '/chatbot': (_) => const Scaffold(body: Text('Chatbot Page')),
      },
    );
  }

  testWidgets('HomePage tampil dengan komponen utama', (
    WidgetTester tester,
  ) async {
    // ATUR RESOLUSI LAYAR (Tinggi dibuat 1600 agar semua konten terlihat)
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1.0;

    await tester.pumpWidget(createTestWidget());
    await tester
        .pumpAndSettle(); // Tunggu sinkronisasi SharedPreferences & Animation

    // Header
    expect(find.text('Hello,'), findsOneWidget);
    expect(find.textContaining('Araa'), findsOneWidget);

    // Section Bentuk Tubuh
    expect(find.text('Bentuk Tubuh Kamu:'), findsOneWidget);

    // Section MyStyle
    expect(find.text('MyStyle'), findsOneWidget);

    addTearDown(tester.view.resetPhysicalSize);
  });

  testWidgets('FeatureCard Bentuk Tubuh dapat ditekan', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(800, 1600);
    await tester.pumpWidget(createTestWidget());
    await tester.pumpAndSettle();

    final cardFinder = find.text('Bentuk Tubuh');

    // Pastikan widget terlihat di dalam scroll view sebelum ditekan
    await tester.ensureVisible(cardFinder);
    await tester.tap(cardFinder);
    await tester.pumpAndSettle();

    expect(find.text('BodyShape Page'), findsOneWidget);

    addTearDown(tester.view.resetPhysicalSize);
  });

  testWidgets('FeatureCard Warna Kulit dapat ditekan', (
    WidgetTester tester,
  ) async {
    // --- FIX: Ukuran layar diperbesar agar 'Warna Kulit' masuk area hit-test ---
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1.0;

    await tester.pumpWidget(createTestWidget());
    await tester.pumpAndSettle();

    final cardFinder = find.text('Warna Kulit');

    // Scroll otomatis ke posisi widget
    await tester.ensureVisible(cardFinder);
    await tester.tap(cardFinder);
    await tester.pumpAndSettle();

    expect(find.text('Skintone Page'), findsOneWidget);

    addTearDown(tester.view.resetPhysicalSize);
  });

  testWidgets('Icon chatbot dapat ditekan', (WidgetTester tester) async {
    await tester.pumpWidget(createTestWidget());
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.chat));
    await tester.pumpAndSettle();

    expect(find.text('Chatbot Page'), findsOneWidget);
  });
}