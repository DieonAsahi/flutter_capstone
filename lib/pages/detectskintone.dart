import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:typed_data';
import 'package:camera/camera.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image/image.dart' as img;
import 'package:aplikasi/services/api_config.dart';

class SkinDetectPage extends StatefulWidget {
  const SkinDetectPage({super.key});

  @override
  State<SkinDetectPage> createState() => _SkinDetectPageState();
}

class _SkinDetectPageState extends State<SkinDetectPage> {
  CameraController? _controller;
  List<CameraDescription> _cameras = [];

  CameraDescription? _frontCamera;
  CameraDescription? _backCamera;
  CameraDescription? _activeCamera;

  bool _cameraReady = false;
  Uint8List? _capturedBytes;

  bool showResult = false;
  bool showCorrection = false;
  bool validated = false;
  bool get isCaptured => _capturedBytes != null;

  String? aiResult;
  String? selectedSkin;
  String? correctedResult;

  final Color primaryColor = const Color(0xFFA79277);

  final List<String> skinList = [
    "Putih",
    "Kuning Langsat",
    "Sawo Matang",
    "Gelap",
  ];

  // ================= UTILITY: CROP & ANALISIS CAHAYA =================

  // Fungsi Hitung Kecerahan (0 - 255)
  double calculateBrightness(img.Image image) {
    int totalBrightness = 0;
    int pixelCount = image.width * image.height;

    for (int y = 0; y < image.height; y++) {
      for (int x = 0; x < image.width; x++) {
        final pixel = image.getPixel(x, y);
        final r = pixel.r;
        final g = pixel.g;
        final b = pixel.b;
        totalBrightness += ((0.299 * r) + (0.587 * g) + (0.114 * b)).toInt();
      }
    }
    return totalBrightness / pixelCount;
  }

  Uint8List cropToCircle(Uint8List bytes) {
    final image = img.decodeImage(bytes)!;

    final width = image.width;
    final height = image.height;

    // POSISI HARUS SAMA DENGAN FaceOverlayPainter
    final centerX = width ~/ 2;
    final centerY = (height / 2.3).round();
    final radius = (width * 0.32).round();

    final left = centerX - radius;
    final top = centerY - radius;
    final size = radius * 2;

    // Pastikan crop area tidak keluar batas
    final safeLeft = left < 0 ? 0 : left;
    final safeTop = top < 0 ? 0 : top;
    final safeWidth = (safeLeft + size > width) ? width - safeLeft : size;
    final safeHeight = (safeTop + size > height) ? height - safeTop : size;

    final cropped = img.copyCrop(
      image,
      x: safeLeft,
      y: safeTop,
      width: safeWidth,
      height: safeHeight,
    );

    return Uint8List.fromList(img.encodeJpg(cropped));
  }

  // ================= INIT CAMERA =================
  @override
  void initState() {
    super.initState();
    _initCamera();
  }

  Future<void> _initCamera() async {
    try {
      _cameras = await availableCameras();
      if (_cameras.isEmpty) return;

      for (var cam in _cameras) {
        if (cam.lensDirection == CameraLensDirection.front) {
          _frontCamera = cam;
        } else if (cam.lensDirection == CameraLensDirection.back) {
          _backCamera = cam;
        }
      }

      // default: kamera depan
      _activeCamera = _frontCamera ?? _backCamera ?? _cameras.first;
      await _startCamera(_activeCamera!);
    } catch (e) {
      debugPrint("Error Init Camera: $e");
    }
  }

  Future<void> _startCamera(CameraDescription camera) async {
    _cameraReady = false;
    await _controller?.dispose();

    _controller = CameraController(
      camera,
      ResolutionPreset.medium,
      enableAudio: false,
    );

    try {
      await _controller!.initialize();
      await _controller!.setFlashMode(FlashMode.off);

      if (!mounted) return;
      setState(() => _cameraReady = true);
    } catch (e) {
      debugPrint("Camera Start Error: $e");
    }
  }

  // ================= SWITCH CAMERA =================
  Future<void> switchCamera() async {
    if (_frontCamera == null || _backCamera == null) return;
    _activeCamera = _activeCamera == _frontCamera ? _backCamera : _frontCamera;
    await _startCamera(_activeCamera!);
  }

  // ================= CAPTURE & SCAN =================
  Future<void> pickAndScanImage() async {
    debugPrint("pickAndScanImage() START");
    if (!_cameraReady || _capturedBytes != null || _controller == null) return;

    try {
      // 1️⃣ Ambil foto
      final XFile file = await _controller!.takePicture();
      final rawBytes = await file.readAsBytes();

      // 2️⃣ Decode untuk Analisis Cahaya
      // Note: decodeImage might be slow for large images on main thread.
      // In production, consider using compute() / isolate.
      final originalImage = img.decodeImage(rawBytes);
      if (originalImage == null) return;

      // 3️⃣ Cek Kecerahan (Brightness Check - Client Side Pre-check)
      // Ini optional karena backend sudah cek, tapi bagus untuk UX instan
      double brightness = calculateBrightness(originalImage);
      if (brightness < 40) {
        _showWarning("Foto terlalu gelap. Cari cahaya yang lebih terang.");
        return;
      } else if (brightness > 220) {
        _showWarning("Foto terlalu terang. Hindari cahaya lampu langsung.");
        return;
      }

      // 4️⃣ Crop & Prepare
      final croppedBytes = cropToCircle(rawBytes);
      final base64Image = base64Encode(croppedBytes);

      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getInt('user_id');

      setState(() {
        _capturedBytes = croppedBytes;
        showResult = false;
        showCorrection = false;
        validated = false;
      });

      debugPrint("SENDING IMAGE TO API...");

      // 5️⃣ Kirim ke backend
      final response = await http.post(
        Uri.parse("${ApiConfig.baseUrl}/scan_face"),
        headers: ApiConfig.headers,
        body: jsonEncode({
          "user_id": userId,
          "image": "data:image/jpeg;base64,$base64Image",
        }),
      );

      // 6️⃣ Handle response
      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        // SUKSES
        if (data["status"] == "preview") {
          setState(() {
            aiResult = data["skin_tone"];
            showResult = true;
          });
        }
      } else {
        // ERROR DARI BACKEND (400 / 500)
        // Backend Python sudah kirim message spesifik ("Foto terlalu gelap", dsb)
        String errorMessage = data["message"] ?? "Terjadi kesalahan";

        _showWarning(errorMessage);

        // Reset agar user bisa foto ulang otomatis
        setState(() {
          _capturedBytes = null;
        });
      }
    } catch (e) {
      debugPrint("SCAN FAILED: $e");
      _showWarning("Gagal terhubung ke server.");
      setState(() => _capturedBytes = null);
    }
  }

  void _showWarning(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.warning_amber_rounded, color: Colors.white),
            const SizedBox(width: 10),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.redAccent,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  Future<void> saveResult() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getInt('user_id');

    final result = correctedResult ?? aiResult;
    if (result == null || userId == null) return;

    try {
      final response = await http.post(
        Uri.parse("${ApiConfig.baseUrl}/scan_face"),
        headers: ApiConfig.headers,
        body: jsonEncode({
          "user_id": userId,
          "confirm": true,
          "skin_tone": result,
        }),
      );

      if (response.statusCode == 200) {
        setState(() {
          validated = true;
          showCorrection = false;
        });
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Data berhasil disimpan! ✨")),
        );
      }
    } catch (e) {
      _showWarning("Gagal menyimpan data.");
    }
  }

  // ================= RESET =================
  void resetAll() async {
    if (_controller != null && _controller!.value.isInitialized) {
      await _controller!.setFlashMode(FlashMode.off);
    }

    setState(() {
      _capturedBytes = null;
      showResult = false;
      showCorrection = false;
      validated = false;
      aiResult = null;
      correctedResult = null;
      selectedSkin = null;
    });
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  // ================= UI =================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          "Tone Scan",
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Container(
                width: double.infinity,
                height: 490,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Stack(
                  children: [
                    if (_capturedBytes != null)
                      ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: Image.memory(_capturedBytes!, fit: BoxFit.cover),
                      )
                    else if (_cameraReady)
                      ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            CameraPreview(_controller!),
                            // OVERLAY BULAT
                            CustomPaint(painter: FaceOverlayPainter()),
                          ],
                        ),
                      ),

                    Positioned(
                      bottom: 16,
                      left: 16,
                      child: FloatingActionButton(
                        mini: true,
                        backgroundColor: Colors.black,
                        onPressed: isCaptured ? null : switchCamera,
                        child: const Icon(
                          Icons.cameraswitch,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: isCaptured
                      ? null
                      : () async {
                          await pickAndScanImage();
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text(
                    "Ambil Foto & Analisis",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.white),
                  ),
                ),
              ),

              // ================= HASIL =================
              if (showResult && aiResult != null) ...[
                const SizedBox(height: 24),

                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Hasil Prediksi AI",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Prediksi AI: $aiResult",
                            style: const TextStyle(fontSize: 20),
                          ),

                          if (correctedResult != null) ...[
                            const SizedBox(height: 8),
                            Text(
                              "Koreksi Anda: $correctedResult",
                              style: const TextStyle(
                                fontSize: 18,
                                color: Colors.green,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ],
                      ),

                      const SizedBox(height: 16),

                      if (!validated)
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton(
                                onPressed: saveResult,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: primaryColor,
                                ),
                                child: const Text("Sesuai"),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () {
                                  setState(() {
                                    showCorrection = true;
                                  });
                                },
                                child: const Text("Koreksi"),
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
              ],

              // ================= KOREKSI MANUAL =================
              if (showCorrection) ...[
                const SizedBox(height: 16),

                DropdownButtonFormField<String>(
                  value: selectedSkin,
                  decoration: _inputDecoration("Pilih Warna Kulit"),
                  items: skinList
                      .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                      .toList(),
                  onChanged: (val) {
                    setState(() {
                      selectedSkin = val;
                      correctedResult = val;
                    });
                  },
                ),
              ],

              // TOMBOL RESET
              if (_capturedBytes != null) ...[
                const SizedBox(height: 16),
                TextButton.icon(
                  onPressed: resetAll,
                  icon: const Icon(Icons.refresh, color: Colors.grey),
                  label: const Text(
                    "Foto Ulang",
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String label) => InputDecoration(
    labelText: label,
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
  );
}

// ================= OVERLAY =================
class FaceOverlayPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.black.withOpacity(0.6);
    final center = Offset(size.width / 2, size.height / 2.3);
    final radius = size.width * 0.32;

    final bg = Path()..addRect(Rect.fromLTWH(0, 0, size.width, size.height));
    final hole = Path()
      ..addOval(Rect.fromCircle(center: center, radius: radius));

    canvas.drawPath(Path.combine(PathOperation.difference, bg, hole), paint);
  }

  @override
  bool shouldRepaint(_) => false;
}
