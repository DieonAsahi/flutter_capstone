import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:aplikasi/pages/profilepage.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    // Mock data user login
    SharedPreferences.setMockInitialValues({
      'user_id': 1,
      'name': 'Araa',
      'username': 'araa_dev',
      'gender': 'female',
      'bio': 'Flutter Enthusiast',
      'photo_url': '',
    });
  });

  Widget createTestWidget() {
    return const MaterialApp(
      home: ProfilePage(),
    );
  }

  testWidgets('Halaman Profil tampil dengan benar', (tester) async {
    await tester.pumpWidget(createTestWidget());
    await tester.pumpAndSettle();

    // AppBar username
    expect(find.text('@araa_dev'), findsOneWidget);

    // Nama user
    expect(find.text('Araa'), findsOneWidget);

    // Bio tampil
    expect(find.text('Flutter Enthusiast'), findsOneWidget);

    // Icon person (karena photo null)
    expect(find.byIcon(Icons.person), findsOneWidget);
  });

  testWidgets('TabBar Profil tampil lengkap', (tester) async {
    await tester.pumpWidget(createTestWidget());
    await tester.pumpAndSettle();

    expect(find.text('Postingan'), findsOneWidget);
    expect(find.text('My Oufit'), findsOneWidget);
    expect(find.text('Wishlist'), findsOneWidget);
  });

  testWidgets('Berpindah tab ke My Outfit berhasil', (tester) async {
    await tester.pumpWidget(createTestWidget());
    await tester.pumpAndSettle();

    await tester.tap(find.text('My Oufit'));
    await tester.pumpAndSettle();

    expect(find.text('My Oufit'), findsOneWidget);
  });

  testWidgets('Berpindah tab ke Wishlist berhasil', (tester) async {
    await tester.pumpWidget(createTestWidget());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Wishlist'));
    await tester.pumpAndSettle();

    expect(find.text('Wishlist'), findsOneWidget);
  });

  testWidgets('Tombol pengaturan tampil di AppBar', (tester) async {
    await tester.pumpWidget(createTestWidget());
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.settings_outlined), findsOneWidget);
  });
}
