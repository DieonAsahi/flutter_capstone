import 'dart:typed_data';
import 'package:image/image.dart' as img;

class DetectSkinTone {
  /// Hitung kecerahan citra (0–255)
  static double calculateBrightness(img.Image image) {
    int totalBrightness = 0;
    int pixelCount = image.width * image.height;

    for (int y = 0; y < image.height; y++) {
      for (int x = 0; x < image.width; x++) {
        final pixel = image.getPixel(x, y);
        totalBrightness +=
            ((0.299 * pixel.r) +
                    (0.587 * pixel.g) +
                    (0.114 * pixel.b))
                .toInt();
      }
    }
    return totalBrightness / pixelCount;
  }

  /// Crop wajah berbentuk lingkaran (berdasarkan overlay)
  static Uint8List cropToCircle(Uint8List bytes) {
    final image = img.decodeImage(bytes)!;

    final width = image.width;
    final height = image.height;

    final centerX = width ~/ 2;
    final centerY = (height / 2.3).round();
    final radius = (width * 0.32).round();

    final left = centerX - radius;
    final top = centerY - radius;
    final size = radius * 2;

    final safeLeft = left < 0 ? 0 : left;
    final safeTop = top < 0 ? 0 : top;
    final safeWidth =
        (safeLeft + size > width) ? width - safeLeft : size;
    final safeHeight =
        (safeTop + size > height) ? height - safeTop : size;

    final cropped = img.copyCrop(
      image,
      x: safeLeft,
      y: safeTop,
      width: safeWidth,
      height: safeHeight,
    );

    return Uint8List.fromList(img.encodeJpg(cropped));
  }

  /// Validasi brightness (UX + backend safety)
  static bool isBrightnessValid(double brightness) {
    return brightness >= 40 && brightness <= 220;
  }
}
