import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:aplikasi/utils/detectskintone_logic.dart';

void main() {
  group('Unit Test - Skin Tone Detection', () {
    test('Brightness gambar gelap bernilai rendah', () {
      final image = _createSolidImage(10, 10, 10, 10, 10);

      final brightness =
          DetectSkinTone.calculateBrightness(image);

      expect(brightness < 40, true);
    });

    test('Brightness gambar terang bernilai tinggi', () {
      final image = _createSolidImage(10, 10, 240, 240, 240);

      final brightness =
          DetectSkinTone.calculateBrightness(image);

      expect(brightness > 220, true);
    });

    test('Brightness valid berada dalam rentang aman', () {
      final image = _createSolidImage(10, 10, 120, 100, 90);

      final brightness =
          DetectSkinTone.calculateBrightness(image);

      expect(
          DetectSkinTone.isBrightnessValid(brightness), true);
    });

    test('Crop wajah menghasilkan byte image tidak kosong', () {
      final image = _createSolidImage(300, 400, 150, 130, 110);

      final bytes = Uint8List.fromList(img.encodeJpg(image));
      final cropped =
          DetectSkinTone.cropToCircle(bytes);

      expect(cropped.isNotEmpty, true);
    });

    test('Crop wajah menghasilkan ukuran lebih kecil', () {
      final image = _createSolidImage(300, 400, 150, 150, 150);

      final originalBytes =
          Uint8List.fromList(img.encodeJpg(image));
      final cropped =
          DetectSkinTone.cropToCircle(originalBytes);

      expect(cropped.length < originalBytes.length, true);
    });
  });
}

/// ================= HELPER =================
/// Membuat image dengan warna solid TANPA fill()
img.Image _createSolidImage(
    int width, int height, int r, int g, int b) {
  final image = img.Image(width: width, height: height);

  for (int y = 0; y < height; y++) {
    for (int x = 0; x < width; x++) {
      image.setPixelRgb(x, y, r, g, b);
    }
  }
  return image;
}
