import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:async';
import 'package:aplikasi/services/api_config.dart';

class AddClothPage extends StatefulWidget {
  const AddClothPage({super.key});

  @override
  State<AddClothPage> createState() => _AddClothPageState();
}

class _AddClothPageState extends State<AddClothPage> {
  bool showResult = false;
  bool showCorrection = false;

  final Color primaryColor = const Color(0xFFA79277);

  CameraController? _cameraController;
  XFile? _capturedImage;

  // --- VARIABEL AI ---
  String? aiStyle;
  String? aiCategory;
  String? aiFitting;
  String? aiColor;
  String? userGender;

  // --- VARIABEL MANUAL ---
  String? manualStyle;
  String? manualCategory;
  String? manualFitting;
  String? manualColor;

  bool isCameraReady = false;
  bool hasTakenPhoto = false;

  bool _isLoading = false;
  String _loadingText = "Memulai analisis...";
  Timer? _loadingTimer;

  final List<String> _loadingMessages = [
    "🔍 Memindai tekstur kain...",
    "🎨 Sedang mengecek palet warna...",
    "📐 Mengukur potongan (fitting)...",
    "🤖 AI sedang berpikir keras...",
    "✨ Sedikit lagi, merapikan data...",
  ];

  // --- LOGIKA LIST FITTING ---
  final List<String> fittingPriaBaju = ["Fit", "Loose"];
  final List<String> fittingPriaCelana = ["Fit", "Loose"];

  final List<String> fittingWanitaBaju = [
    "Fitted",
    "Flare",
    "Loose",
    "Shoulder",
  ];
  final List<String> fittingWanitaCelana = [
    "Fitted",
    "Flare",
    "Straight",
    "Wide",
  ];
  final List<String> fittingWanitaRok = ["Flare", "Mermaid", "Straight"];

  String normalizeGender(String? gender) {
    if (gender == null) return "";
    if (gender == "male") return "pria";
    if (gender == "female") return "wanita";
    return gender;
  }

  String normalizeColor(String color) {
    return color
        .trim()
        .toLowerCase()
        .split(' ')
        .map((word) {
          return word.isNotEmpty
              ? word[0].toUpperCase() + word.substring(1)
              : "";
        })
        .join(' ');
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    _loadingTimer?.cancel();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _initBackCamera();
    _loadGender();
  }

  final Map<String, List<String>> categoryByGender = {
    "male": ["jacket", "outer", "pants", "shirt", "suit", "tshirt"],
    "female": [
      "jacket",
      "blazer",
      "blouse",
      "dress",
      "outer",
      "pants",
      "shirt",
      "skirt",
      "tshirt",
    ],
  };

  final Map<String, String> categoryLabelMap = {
    "tshirt": "Baju",
    "shirt": "Kemeja",
    "pants": "Celana",
    "suit": "Jas",
    "skirt": "Rok",
    "outer": "Outer",
    "jacket": "Jaket",
    "blazer": "Blazer",
    "dress": "Dress",
    "blouse": "Blus",
  };

  final Map<String, Map<String, List<String>>> validRules = {
    'pria': {
      'formal': ['suit', 'shirt', 'pants', 'tshirt'],
      'casual': ['outer', 'pants', 'shirt', 'tshirt'],
      'sport': ['jacket', 'pants', 'tshirt'],
    },
    'wanita': {
      'formal': [
        'blazer',
        'blouse',
        'dress',
        'pants',
        'shirt',
        'skirt',
        'tshirt',
        'outer',
      ],
      'casual': [
        'blouse',
        'outer',
        'pants',
        'shirt',
        'skirt',
        'tshirt',
        'blazer',
      ],
      'sport': ['jacket', 'pants', 'tshirt', 'skirt'],
    },
  };

  List<String> _getFilteredCategories() {
    if (userGender == null) return [];
    String genderKey = normalizeGender(userGender);
    if (manualStyle != null) {
      String styleKey = manualStyle!.toLowerCase();
      return validRules[genderKey]?[styleKey] ?? [];
    }
    return categoryByGender[userGender!] ?? [];
  }

  void _startLoadingAnimation() {
    int index = 0;
    _loadingTimer = Timer.periodic(const Duration(seconds: 2), (timer) {
      setState(() {
        _loadingText = _loadingMessages[index % _loadingMessages.length];
        index++;
      });
    });
  }

  String displayCategory(String? value) {
    if (value == null) return "-";
    return categoryLabelMap[value.toLowerCase()] ?? value;
  }

  List<String> _getFittingOptions() {
    if (manualCategory == null || userGender == null) return [];
    String cat = manualCategory!.toLowerCase();
    String gender = normalizeGender(userGender);

    if (gender == 'pria') {
      if (['pants'].contains(cat)) return fittingPriaCelana;
      return fittingPriaBaju;
    } else {
      if (['pants'].contains(cat)) return fittingWanitaCelana;
      if (['skirt'].contains(cat)) return fittingWanitaRok;
      return fittingWanitaBaju;
    }
  }

  Future<int?> _getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt("user_id");
  }

  Future<String?> _getGender() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString("gender");
  }

  Future<void> _loadGender() async {
    final gender = await _getGender();
    setState(() {
      userGender = gender;
    });
  }

  Future<void> _initBackCamera() async {
    try {
      final cameras = await availableCameras();
      final backCamera = cameras.firstWhere(
        (cam) => cam.lensDirection == CameraLensDirection.back,
      );

      _cameraController = CameraController(
        backCamera,
        ResolutionPreset.medium,
        enableAudio: false,
      );
      await _cameraController!.initialize();
      await _cameraController!.setFlashMode(FlashMode.off);
      setState(() => isCameraReady = true);
    } catch (e) {
      debugPrint("Camera init error: $e");
    }
  }

  Future<void> _resetAndRetakePhoto() async {
    setState(() {
      hasTakenPhoto = false;
      showResult = false;
      showCorrection = false;
      _capturedImage = null;

      aiStyle = null;
      aiCategory = null;
      aiFitting = null;
      aiColor = null;
      manualStyle = null;
      manualCategory = null;
      manualFitting = null;
      manualColor = null;
    });
    if (_cameraController != null) await _cameraController!.dispose();
    _initBackCamera();
  }

  Future<void> _takePhotoAndAnalyze() async {
    if (userGender == null || userGender!.isEmpty) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: Colors.redAccent,
          title: const Text(
            "Data Tidak Lengkap",
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          content: const Text(
            "Ups! Harap lengkapi data Gender di Halaman Profil dulu ya agar AI bisa bekerja maksimal 😉",
            style: TextStyle(color: Colors.white),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text("OK", style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      );
      return;
    }

    if (!isCameraReady || _cameraController == null) return;

    setState(() {
      _isLoading = true;
      _loadingText = "Mengambil gambar...";
    });

    try {
      final XFile rawImage = await _cameraController!.takePicture();
      _capturedImage = rawImage;
      _startLoadingAnimation();

      final bytes = await File(_capturedImage!.path).readAsBytes();
      final base64Image = base64Encode(bytes);
      final userId = await _getUserId();
      final gender = await _getGender();

      final response = await http
          .post(
            Uri.parse("${ApiConfig.baseUrl}/api/wardrobe/item"),
            headers: ApiConfig.headers,
            body: jsonEncode({
              "action": "predict",
              "user_id": userId,
              "gender": gender,
              "image_data": "data:image/jpeg;base64,$base64Image",
            }),
          )
          .timeout(const Duration(seconds: 15));

      _loadingTimer?.cancel();

      if (response.statusCode != 200) {
        String errorMessage = "Terjadi kesalahan server";
        try {
          final errorData = jsonDecode(response.body);
          errorMessage = errorData['error'] ?? response.body;
        } catch (_) {
          errorMessage = response.body;
        }
        throw errorMessage;
      }

      final data = jsonDecode(response.body);

      setState(() {
        aiStyle = data["prediction"]["style"];
        aiCategory = data["prediction"]["category"];
        aiFitting = data["prediction"]["fitting"];
        aiColor = data["prediction"]["color"];

        showResult = true;
        showCorrection = false;
        hasTakenPhoto = true;
        _isLoading = false;
      });
    } catch (e) {
      _loadingTimer?.cancel();
      setState(() => _isLoading = false);

      String cleanError = e.toString().replaceAll("Exception: ", "");

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(cleanError),
          backgroundColor: Colors.redAccent,
          duration: const Duration(seconds: 4),
          action: SnackBarAction(
            label: "OK",
            textColor: Colors.white,
            onPressed: () {},
          ),
        ),
      );
    }
  }

  Future<void> _confirmSave() async {
    final bytes = await File(_capturedImage!.path).readAsBytes();
    final base64Image = base64Encode(bytes);
    final userId = await _getUserId();
    final gender = normalizeGender(await _getGender());

    final response = await http.post(
      Uri.parse("${ApiConfig.baseUrl}/api/wardrobe/item"),
      headers: ApiConfig.headers,
      body: jsonEncode({
        "action": "save",
        "user_id": userId,
        "gender": gender,
        "style": aiStyle,
        "category": aiCategory,
        "fitting": aiFitting,
        "color": aiColor,
        "image_data": "data:image/jpeg;base64,$base64Image",
      }),
    );
    if (response.statusCode != 200) {
      throw Exception("Gagal simpan: ${response.body}");
    }
  }

  Future<void> _saveCorrection() async {
    if (manualStyle == null ||
        manualCategory == null ||
        manualFitting == null ||
        manualColor == null ||
        manualColor!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Lengkapi semua data koreksi")),
      );
      return;
    }

    final bytes = await File(_capturedImage!.path).readAsBytes();
    final base64Image = base64Encode(bytes);
    final userId = await _getUserId();
    final gender = normalizeGender(await _getGender());

    final response = await http.post(
      Uri.parse("${ApiConfig.baseUrl}/api/wardrobe/item"),
      headers: ApiConfig.headers,
      body: jsonEncode({
        "action": "save",
        "user_id": userId,
        "gender": gender,
        "style": manualStyle!.toLowerCase(),
        "category": manualCategory!,
        "fitting": manualFitting!,
        "color": normalizeColor(manualColor!),
        "image_data": "data:image/jpeg;base64,$base64Image",
      }),
    );

    if (response.statusCode != 200) {
      throw Exception("Gagal simpan koreksi: ${response.body}");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          "Foto Pakaian",
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
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: _capturedImage != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: Image.file(
                          File(_capturedImage!.path),
                          fit: BoxFit.cover,
                        ),
                      )
                    : isCameraReady && _cameraController != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: CameraPreview(_cameraController!),
                      )
                    : const Center(
                        child: Text(
                          "Memuat Kamera...",
                          style: TextStyle(color: Colors.grey),
                        ),
                      ),
              ),
              const SizedBox(height: 24),
              _isLoading
                  ? Column(
                      children: [
                        const CircularProgressIndicator(
                          color: Color(0xFFA79277),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          _loadingText,
                          style: TextStyle(
                            color: Colors.grey.shade700,
                            fontWeight: FontWeight.w500,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    )
                  : SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryColor,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        onPressed: (hasTakenPhoto || _isLoading)
                            ? null
                            : _takePhotoAndAnalyze,
                        child: const Text(
                          "Ambil Foto & Analisis",
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 18,
                          ),
                        ),
                      ),
                    ),
              const SizedBox(height: 30),
              if (showResult) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      const Text("Prediksi AI", style: TextStyle(fontSize: 14)),
                      const SizedBox(height: 8),
                      Text(
                        "${aiStyle ?? ""} ${aiFitting ?? ""} ${displayCategory(aiCategory)} ${aiColor ?? ""}",
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  "Apakah hasil ini sudah sesuai?",
                  style: TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: primaryColor,
                          side: BorderSide(color: primaryColor),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        onPressed: () async {
                          try {
                            await _confirmSave();
                            if (!mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text("Data berhasil disimpan"),
                                backgroundColor: Colors.green,
                              ),
                            );
                            Navigator.pop(context, true);
                          } catch (e) {
                            if (!mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text("Gagal: $e"),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        },
                        child: const Text(
                          "Sesuai",
                          style: TextStyle(fontSize: 16),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryColor,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        onPressed: () {
                          setState(() {
                            // Validasi data AI sebelum masuk ke dropdown manual
                            String? rawStyle = aiStyle?.trim().toLowerCase();
                            String? rawCat = aiCategory?.trim().toLowerCase();
                            String? rawFit = aiFitting?.trim();

                            final validStyles = ["casual", "formal", "sport"];
                            manualStyle = validStyles.contains(rawStyle)
                                ? rawStyle
                                : null;

                            List<String> currentValidCats =
                                _getFilteredCategories();
                            manualCategory = currentValidCats.contains(rawCat)
                                ? rawCat
                                : null;

                            manualFitting = null;
                            if (manualCategory != null) {
                              List<String> fitOptions = _getFittingOptions();
                              if (fitOptions.contains(rawFit)) {
                                manualFitting = rawFit;
                              }
                            }

                            manualColor = aiColor;
                            showCorrection = true;
                          });
                        },
                        child: const Text(
                          "Koreksi",
                          style: TextStyle(color: Colors.white, fontSize: 16),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
              if (showCorrection) ...[
                const SizedBox(height: 30),
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    "Koreksi Manual",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  decoration: _inputDecoration("Style"),
                  value: manualStyle,
                  hint: const Text("Pilih Style"),
                  items: const [
                    DropdownMenuItem(value: "casual", child: Text("Casual")),
                    DropdownMenuItem(value: "formal", child: Text("Formal")),
                    DropdownMenuItem(value: "sport", child: Text("Sport")),
                  ],
                  onChanged: (v) {
                    setState(() {
                      manualStyle = v;
                      manualCategory = null;
                      manualFitting = null;
                    });
                  },
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  decoration: _inputDecoration("Kategori"),
                  value: _getFilteredCategories().contains(manualCategory)
                      ? manualCategory
                      : null,
                  hint: const Text("Pilih Kategori"),
                  items: _getFilteredCategories()
                      .map(
                        (value) => DropdownMenuItem(
                          value: value,
                          child: Text(categoryLabelMap[value] ?? value),
                        ),
                      )
                      .toList(),
                  onChanged: (v) {
                    setState(() {
                      manualCategory = v;
                      manualFitting = null;
                    });
                  },
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  decoration: _inputDecoration("Fitting / Potongan"),
                  value: _getFittingOptions().contains(manualFitting)
                      ? manualFitting
                      : null,
                  hint: const Text("Pilih Potongan"),
                  items: _getFittingOptions()
                      .map((f) => DropdownMenuItem(value: f, child: Text(f)))
                      .toList(),
                  onChanged: (v) => setState(() => manualFitting = v),
                ),
                const SizedBox(height: 12),
                TextField(
                  decoration: _inputDecoration("Warna"),
                  controller: TextEditingController(text: manualColor),
                  onChanged: (v) => manualColor = v,
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    onPressed: () async {
                      try {
                        await _saveCorrection();
                        if (!mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text("Perubahan disimpan"),
                            backgroundColor: Colors.green,
                          ),
                        );
                        Navigator.pop(context, true);
                      } catch (e) {
                        if (!mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text("Gagal: $e"),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    },
                    child: const Text(
                      "Simpan Perubahan",
                      style: TextStyle(color: Colors.white, fontSize: 18),
                    ),
                  ),
                ),
              ],
              if (hasTakenPhoto) ...[
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: primaryColor),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    onPressed: _resetAndRetakePhoto,
                    child: Text(
                      "Foto Ulang",
                      style: TextStyle(
                        color: primaryColor,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      filled: true,
      fillColor: Colors.white,
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: Colors.grey.shade500, width: 1.5),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: primaryColor, width: 1.5),
      ),
    );
  }
}