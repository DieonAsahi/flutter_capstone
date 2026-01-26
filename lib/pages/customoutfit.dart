import 'dart:convert';
import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path_provider/path_provider.dart';
import 'package:aplikasi/services/api_config.dart';

enum CustomStep { select, analyze, result }

class CustomOutfitPage extends StatefulWidget {
  const CustomOutfitPage({super.key});

  @override
  State<CustomOutfitPage> createState() => _CustomOutfitPageState();
}

class _CustomOutfitPageState extends State<CustomOutfitPage> {
  final Color primaryColor = const Color(0xFFA79277);

  final ImagePicker _picker = ImagePicker();

  int? _selectedTopId;
  int? _selectedBottomId;
  CustomStep step = CustomStep.select;
  File? _personImage;

  // Variabel Gambar Pakaian (untuk preview di kotak)
  File? _topImage;
  File? _bottomImage;

  String? _resultImageUrl;
  bool _isLoading = false;

  // Variabel Loading Animasi
  String _loadingText = "Menyiapkan AI...";
  Timer? _loadingTimer;
  final List<String> _loadingMessages = [
    "🚀 Menghubungkan ke IDM-VTON...",
    "📐 Mengukur proporsi tubuh...",
    "👕 Mencoba atasan...",
    "👖 Menyesuaikan bawahan...",
    "✨ Finishing touch (HD)...",
  ];

  List<dynamic> _wardrobeItems = [];

  @override
  void initState() {
    super.initState();
    _fetchWardrobe();
  }

  @override
  void dispose() {
    _loadingTimer?.cancel();
    super.dispose();
  }

  // --- LOGIKA LOADING ---
  void _startLoadingAnimation() {
    int index = 0;
    _loadingTimer = Timer.periodic(const Duration(seconds: 4), (timer) {
      if (mounted) {
        setState(() {
          _loadingText = _loadingMessages[index % _loadingMessages.length];
          index++;
        });
      }
    });
  }

  Future<void> _fetchWardrobe() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getInt('user_id');
      if (userId == null) return;

      final response = await http.get(
        Uri.parse("${ApiConfig.baseUrl}/api/wardrobe/simple/$userId"),
        headers: ApiConfig.headers,
      );
      if (response.statusCode == 200) {
        setState(() {
          _wardrobeItems = jsonDecode(response.body)['items'];
        });
      }
    } catch (e) {
      debugPrint("Error lemari: $e");
    }
  }

  Future<File?> _downloadWardrobeImage(String imageUrl) async {
    try {
      final response = await http.get(
        Uri.parse("${ApiConfig.baseUrl}/$imageUrl"),
        headers: ApiConfig.headers,
      );
      final documentDirectory = await getTemporaryDirectory();
      final file = File(
        '${documentDirectory.path}/wardrobe_${DateTime.now().millisecondsSinceEpoch}.jpg',
      );
      file.writeAsBytesSync(response.bodyBytes);
      return file;
    } catch (e) {
      return null;
    }
  }

  Future<void> _pickPersonImage() async {
    final XFile? pickedFile = await _picker.pickImage(
      source: ImageSource.gallery,
    );
    if (pickedFile != null)
      setState(() => _personImage = File(pickedFile.path));
  }

  void _showWardrobePicker(String type) {
    String selectedStyle = "";
    String selectedCategory = "Semua";

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            List<dynamic> itemsByStyle = _wardrobeItems.where((item) {
              bool matchType = false;
              String cat = item['category_name'].toString().toLowerCase();
              if (type == 'top') {
                matchType = [
                  'shirt',
                  'tshirt',
                  'jacket',
                  'suit',
                  'blouse',
                ].contains(cat);
              } else {
                matchType = ['pants', 'skirt'].contains(cat);
              }
              if (selectedStyle.isEmpty) return matchType;
              return matchType &&
                  item['style'].toString().toLowerCase() ==
                      selectedStyle.toLowerCase();
            }).toList();

            List<dynamic> finalFiltered = itemsByStyle.where((item) {
              if (selectedCategory == "Semua") return true;
              return item['category_name'].toString().toLowerCase() ==
                  selectedCategory.toLowerCase();
            }).toList();

            return Container(
              height: MediaQuery.of(context).size.height * 0.85,
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Text(
                    "Pilih ${type == 'top' ? 'Baju' : 'Celana'}",
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 15),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: ['Formal', 'Casual', 'Sport'].map((style) {
                      return ChoiceChip(
                        label: Text(style),
                        selected: selectedStyle == style,
                        onSelected: (val) => setModalState(() {
                          selectedStyle = val ? style : "";
                          selectedCategory = "Semua";
                        }),
                      );
                    }).toList(),
                  ),
                  const Divider(),
                  Expanded(
                    child: finalFiltered.isEmpty
                        ? const Center(
                            child: Text("Tidak ada pakaian ditemukan"),
                          )
                        : GridView.builder(
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 3,
                                  crossAxisSpacing: 10,
                                  mainAxisSpacing: 10,
                                ),
                            itemCount: finalFiltered.length,
                            itemBuilder: (context, index) {
                              return GestureDetector(
                                onTap: () async {
                                  Navigator.pop(context);
                                  setState(() => _isLoading = true);
                                  File? file = await _downloadWardrobeImage(
                                    finalFiltered[index]['image_url'],
                                  );
                                  setState(() {
                                    if (type == 'top') {
                                      _topImage = file;
                                      _selectedTopId =
                                          finalFiltered[index]['item_id'];
                                    } else {
                                      _bottomImage = file;
                                      _selectedBottomId =
                                          finalFiltered[index]['item_id'];
                                    }
                                    _isLoading = false;
                                  });
                                },
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: Image.network(
                                    "${ApiConfig.baseUrl}/${finalFiltered[index]['image_url']}",
                                    headers: ApiConfig.headers,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // --- LOGIKA UTAMA PROSES OUTFIT ---
  Future<void> _processOutfit() async {
    if (_personImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Pilih foto Anda terlebih dahulu")),
      );
      return;
    }

    if (_selectedTopId == null && _selectedBottomId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Pilih minimal satu pakaian (Baju atau Celana)"),
        ),
      );
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getInt('user_id');
    if (userId == null) return;

    setState(() {
      step = CustomStep.analyze;
      _isLoading = true;
      _loadingText = "Memulai AI...";
    });

    _startLoadingAnimation();

    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse("${ApiConfig.baseUrl}/api/process-outfit"),
      );

      // Tambahkan header ngrok manual ke request multipart
      request.headers.addAll(ApiConfig.headers);

      request.fields['user_id'] = userId.toString();

      if (_selectedTopId != null)
        request.fields['top_item_id'] = _selectedTopId.toString();

      if (_selectedBottomId != null)
        request.fields['bottom_item_id'] = _selectedBottomId.toString();

      request.files.add(
        await http.MultipartFile.fromPath('person_image', _personImage!.path),
      );

      var streamedResponse = await request.send().timeout(
        const Duration(minutes: 3),
      );
      var response = await http.Response.fromStream(streamedResponse);

      _loadingTimer?.cancel();

      if (response.statusCode == 200) {
        var data = jsonDecode(response.body);
        setState(() {
          String rawUrl = data['result_url'];
          _resultImageUrl = rawUrl.startsWith('http')
              ? rawUrl
              : "${ApiConfig.baseUrl}/$rawUrl";
          step = CustomStep.result;
        });
      } else {
        throw Exception("Gagal: ${response.body}");
      }
    } catch (e) {
      _loadingTimer?.cancel();
      setState(() => step = CustomStep.select);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error: $e")));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showSaveDialog() {
    TextEditingController nameController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Simpan ke My Outfit"),
        content: TextField(
          controller: nameController,
          decoration: const InputDecoration(
            hintText: "Nama Outfit (Misal: Gaya Santai)",
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Batal"),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _saveOutfitToDb(nameController.text);
            },
            child: const Text("Simpan"),
          ),
        ],
      ),
    );
  }

  Future<void> _saveOutfitToDb(String name) async {
    setState(() => _isLoading = true);
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getInt('user_id');

    try {
      final response = await http.post(
        Uri.parse("${ApiConfig.baseUrl}/api/save-outfit"),
        headers: ApiConfig.headers,
        body: jsonEncode({
          "user_id": userId,
          "outfit_name": name,
          "result_url": _resultImageUrl,
          "item_ids": [_selectedTopId, _selectedBottomId],
        }),
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("✨ Tersimpan di My Outfit!")),
        );
        setState(() {
          step = CustomStep.select;
          _resultImageUrl = null;
          _topImage = null;
          _bottomImage = null;
          _selectedTopId = null;
          _selectedBottomId = null;
        });
      }
    } catch (e) {
      debugPrint("Gagal simpan: $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("AI Custom Outfit"),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),
      body: Stack(
        children: [
          Center(
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              child: _buildMainContent(),
            ),
          ),

          if (step != CustomStep.analyze)
            Positioned(
              left: 20,
              right: 20,
              bottom: 24,
              child: _buildActionButton(),
            ),
        ],
      ),
    );
  }

  Widget _buildMainContent() {
    if (step == CustomStep.result && _resultImageUrl != null) {
      return Column(
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.network(
                _resultImageUrl!,
                headers: ApiConfig.headers,
                fit: BoxFit.contain,
              ),
            ),
          ),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: _showSaveDialog,
            icon: const Icon(Icons.save, size: 20),
            label: const Text("Simpan Outfit"),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
              minimumSize: const Size(double.infinity, 45),
            ),
          ),
          const SizedBox(height: 60),
        ],
      );
    }

    if (step == CustomStep.analyze) {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(color: Color(0xFFA79277)),
          const SizedBox(height: 20),
          Text(
            _loadingText,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 10),
          const Text(
            "Mungkin butuh waktu 30-60 detik...",
            style: TextStyle(color: Colors.grey),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "1. Foto Kamu (Dari HP)",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Expanded(
          flex: 5,
          child: GestureDetector(
            onTap: _pickPersonImage,
            child: _buildImageBox(
              _personImage,
              "Upload Foto Body",
              isPerson: true,
            ),
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          "2. Pilih dari Lemari",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Expanded(
          flex: 3,
          child: Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => _showWardrobePicker('top'),
                  child: _buildImageBox(_topImage, "Baju"),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: GestureDetector(
                  onTap: () => _showWardrobePicker('bottom'),
                  child: _buildImageBox(_bottomImage, "Celana"),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 80),
      ],
    );
  }

  Widget _buildImageBox(File? image, String label, {bool isPerson = false}) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: image != null ? primaryColor : Colors.grey.shade300,
          width: 2,
        ),
      ),
      child: image != null
          ? ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.file(
                image,
                fit: isPerson ? BoxFit.contain : BoxFit.cover,
              ),
            )
          : Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.add_a_photo_outlined),
                  const SizedBox(height: 4),
                  Text(label, style: const TextStyle(fontSize: 12)),
                ],
              ),
            ),
    );
  }

  Widget _buildActionButton() {
    if (step == CustomStep.result) {
      return SizedBox(
        height: 52,
        width: double.infinity,
        child: OutlinedButton(
          onPressed: () => setState(() => step = CustomStep.select),
          style: OutlinedButton.styleFrom(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          child: const Text("Coba Lagi"),
        ),
      );
    }
    return SizedBox(
      height: 52,
      width: double.infinity,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        onPressed: _isLoading ? null : _processOutfit,
        child: _isLoading
            ? const CircularProgressIndicator(color: Colors.white)
            : const Text(
                "Mulai Try-On ✨",
                style: TextStyle(color: Colors.white),
              ),
      ),
    );
  }
}