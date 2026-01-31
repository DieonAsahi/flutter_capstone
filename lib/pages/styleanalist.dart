import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:aplikasi/services/api_config.dart';
import 'package:url_launcher/url_launcher.dart'; // Pastikan sudah ditambah di pubspec.yaml

class StylePage extends StatefulWidget {
  const StylePage({super.key});
  @override
  State<StylePage> createState() => _StylePageState();
}

class _StylePageState extends State<StylePage> {
  CameraController? _cameraController;
  List<CameraDescription>? _cameras;

  int _selectedCameraIndex = 0;
  bool isCameraInitialized = false;
  bool isResult = false;
  bool isLoading = false;
  bool isMaoReady = false;
  File? _capturedImage;
  String analysisText = "";
  String currentMotion = "Idle";

  final Color primaryColor = const Color(0xFFA79277);
  final FlutterTts _tts = FlutterTts();
  InAppWebViewController? _webController;

  @override
  void initState() {
    super.initState();
    availableCameras().then((cameras) {
      _cameras = cameras;
      if (_cameras != null && _cameras!.isNotEmpty) {
        _initCamera(_selectedCameraIndex);
      }
    });
    _setupTTS();
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    _tts.stop();
    super.dispose();
  }

  void _setupTTS() async {
    await _tts.setLanguage("id-ID");
    await _tts.setPitch(1.0);
    await _tts.setSpeechRate(0.5);
  }

  Future<void> _initCamera(int index) async {
    if (_cameraController != null) {
      await _cameraController!.dispose();
    }
    setState(() => isCameraInitialized = false);
    try {
      if (_cameras != null && _cameras!.isNotEmpty) {
        _cameraController = CameraController(
          _cameras![index],
          ResolutionPreset.high,
          enableAudio: false,
        );
        await _cameraController!.initialize();
        try {
          await _cameraController!.setFlashMode(FlashMode.off);
        } catch (e) {
          debugPrint("Flash tidak tersedia: $e");
        }
        if (mounted) {
          setState(() {
            _selectedCameraIndex = index;
            isCameraInitialized = true;
          });
        }
      }
    } catch (e) {
      debugPrint("Kamera Error: $e");
    }
  }

  void _onSwitchCamera() {
    if (_cameras == null || _cameras!.length < 2) return;
    int newIndex = (_selectedCameraIndex == 0) ? 1 : 0;
    _initCamera(newIndex);
  }

  Future<void> _captureAndAnalyze() async {
    if (_cameraController == null || !_cameraController!.value.isInitialized)
      return;
    setState(() {
      isLoading = true;
      isResult = false;
      isMaoReady = false;
    });
    try {
      final photo = await _cameraController!.takePicture();
      final imageFile = File(photo.path);
      String base64Image = base64Encode(await imageFile.readAsBytes());

      final response = await http
          .post(
            Uri.parse("${ApiConfig.baseUrl}/analyze_image"),
            headers: ApiConfig.headers,
            body: jsonEncode({"image": base64Image}),
          )
          .timeout(const Duration(seconds: 30));

      if (!mounted) return;
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _capturedImage = imageFile;
          analysisText = data['full_text'] ?? "";
          currentMotion = data['motion'] ?? "Idle";
          isResult = true;
          isLoading = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => isLoading = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Gagal: $e")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(isResult ? "Saran Fashion Mao" : "Scan Pakaian"),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        leading: isResult
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () {
                  _tts.stop();
                  setState(() {
                    isResult = false;
                    isLoading = false;
                    _initCamera(_selectedCameraIndex);
                  });
                },
              )
            : null,
      ),
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: isResult ? _buildResult() : _buildCameraPreview(),
          ),
          if (isLoading)
            Container(
              color: Colors.white,
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(color: primaryColor),
                    const SizedBox(height: 20),
                    Text(
                      "Mao sedang berpikir...",
                      style: TextStyle(
                        color: primaryColor,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCameraPreview() {
    return Column(
      children: [
        Expanded(
          child: Stack(
            children: [
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: isCameraInitialized
                      ? CameraPreview(_cameraController!)
                      : const Center(child: CircularProgressIndicator()),
                ),
              ),
              Positioned(
                top: 15,
                right: 15,
                child: FloatingActionButton.small(
                  backgroundColor: Colors.white.withOpacity(0.5),
                  onPressed: _onSwitchCamera,
                  child: const Icon(Icons.flip_camera_ios, color: Colors.black),
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
            onPressed: _captureAndAnalyze,
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: const Text(
              "Ambil Foto & Analisis",
              style: TextStyle(fontSize: 18, color: Colors.white),
            ),
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildResult() {
    return SingleChildScrollView(
      child: Column(
        children: [
          Container(
            width: double.infinity,
            height: 350,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: _capturedImage != null
                  ? Image.file(_capturedImage!, fit: BoxFit.cover)
                  : const Icon(Icons.image, size: 50),
            ),
          ),
          Stack(
            alignment: Alignment.center,
            clipBehavior: Clip.none,
            children: [
              Container(
                height: 400,
                width: double.infinity,
                margin: const EdgeInsets.only(top: 40),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.withOpacity(0.2)),
                ),
                child: // Di dalam widget _buildResult()
                InAppWebView(
                  initialUrlRequest: URLRequest(
                    url: WebUri("${ApiConfig.baseUrl}/view"),
                    // TAMBAHKAN HEADERS DI SINI
                    headers: {'ngrok-skip-browser-warning': 'true'},
                  ),
                  initialSettings: InAppWebViewSettings(
                    javaScriptEnabled: true,
                    transparentBackground: true,
                    // Tambahkan pengaturan ini agar aset Live2D bisa dimuat
                    allowFileAccessFromFileURLs: true,
                    allowUniversalAccessFromFileURLs: true,
                    mixedContentMode:
                        MixedContentMode.MIXED_CONTENT_ALWAYS_ALLOW,
                  ),
                  onWebViewCreated: (c) => _webController = c,
                  onLoadStop: (c, u) async {
                    final cookieManager = CookieManager.instance();
                    await cookieManager.setCookie(
                      url: WebUri(ApiConfig.baseUrl),
                      name: "ngrok-skip-browser-warning",
                      value: "true",
                      domain:
                          "https://hireable-unelegant-linwood.ngrok-free.dev", // Sesuaikan dengan domain ngrok Anda
                      isSecure: true,
                    );
                    if (mounted) {
                      setState(() => isMaoReady = true);
                      // Tunggu PIXI selesai render
                      await Future.delayed(const Duration(milliseconds: 2000));
                      _webController?.evaluateJavascript(
                        source: "changeMotion('$currentMotion')",
                      );
                      _tts.speak(analysisText);
                    }
                  },
                ),
              ),
              if (isMaoReady)
                Positioned(
                  top: -20,
                  child: Column(
                    children: [
                      Container(
                        constraints: BoxConstraints(
                          maxWidth: MediaQuery.of(context).size.width * 0.9,
                        ),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black12,
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                          border: Border.all(
                            color: primaryColor.withOpacity(0.2),
                          ),
                        ),
                        child: Text(
                          analysisText,
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 14, height: 1.4),
                        ),
                      ),
                      CustomPaint(
                        size: const Size(20, 12),
                        painter: TrianglePainter(),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: () async {
              final url = Uri.parse("${ApiConfig.baseUrl}/view");
              if (await canLaunchUrl(url)) {
                await launchUrl(url, mode: LaunchMode.externalApplication);
              }
            },
            icon: const Icon(Icons.open_in_browser),
            label: const Text("Buka di Chrome & Izinkan Ngrok"),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              minimumSize: const Size(double.infinity, 48),
            ),
          ),
          const SizedBox(height: 10),
          OutlinedButton(
            onPressed: () => _webController?.reload(),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(double.infinity, 48),
            ),
            child: const Text("Sudah Izinkan? Klik Refresh"),
          ),
          const SizedBox(height: 20),
          OutlinedButton(
            onPressed: () {
              _tts.stop();
              setState(() {
                isResult = false;
                isLoading = false;
                _initCamera(_selectedCameraIndex);
              });
            },
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: primaryColor),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              minimumSize: const Size(double.infinity, 48),
            ),
            child: Text(
              "Cek Pakaian Lain",
              style: TextStyle(color: primaryColor),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}

class TrianglePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    var paint = Paint()..color = Colors.white;
    var path = Path();
    path.moveTo(0, 0);
    path.lineTo(size.width / 2, size.height);
    path.lineTo(size.width, 0);
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
