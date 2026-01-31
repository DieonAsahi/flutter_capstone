import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:aplikasi/services/api_config.dart';

class RecommendationPage extends StatefulWidget {
  const RecommendationPage({super.key});

  @override
  State<RecommendationPage> createState() => _RecommendationPageState();
}

class _RecommendationPageState extends State<RecommendationPage> {
  final Color primaryColor = const Color(0xFFA79277);

  int? userId;
  List<dynamic> wardrobeItems = [];
  bool isLoadingWardrobe = false;
  bool isTryOnLoading = false;

  int totalMatchScore = 0;
  String recommendationSummary = "";

  String selectedSource = 'lemari';
  String selectedWardrobeStyle = "formal";
  String? gender;

  File? _bodyImage;
  String? _tryOnResultUrl;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    loadUser();
  }

  Future<void> loadUser() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      userId = prefs.getInt("user_id");
      String? rawGender = prefs.getString("gender")?.toLowerCase();
      if (rawGender != null &&
          (rawGender.contains('male') ||
              rawGender.contains('laki') ||
              rawGender.contains('pria'))) {
        gender = 'pria';
      } else {
        gender = 'wanita';
      }
    });
    if (userId != null) fetchRecommendation();
  }

  Future<void> fetchRecommendation() async {
    if (userId == null || gender == null) return;
    setState(() {
      isLoadingWardrobe = true;
      _tryOnResultUrl = null;
      wardrobeItems = [];
    });

    try {
      final res = await http.post(
        Uri.parse("${ApiConfig.baseUrl}/api/recommendation/final"),
        headers: ApiConfig.headers,
        body: jsonEncode({
          "user_id": userId,
          "style": selectedWardrobeStyle,
          "gender": gender,
          "source": selectedSource,
        }),
      );

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        setState(() {
          wardrobeItems = data["recommendations"];
          totalMatchScore = data["total_match_score"] ?? 0;
          recommendationSummary = data["summary"] ?? "";
        });
      } else if (res.statusCode == 400) {
        final data = jsonDecode(res.body);
        _showMissingDataDialog(data['message'] ?? "Lengkapi data profil.");
      }
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Gagal terhubung ke server")),
        );
    } finally {
      if (mounted) setState(() => isLoadingWardrobe = false);
    }
  }

  // --- UI & ACTION HELPERS ---

  Future<void> _launchUrl(String? urlString) async {
    if (urlString == null || urlString.isEmpty) return;
    final Uri url = Uri.parse(urlString);
    await launchUrl(url, mode: LaunchMode.externalApplication);
  }

  Future<void> _pickImage(ImageSource source) async {
    final XFile? photo = await _picker.pickImage(source: source);
    if (photo != null) {
      setState(() {
        _bodyImage = File(photo.path);
        _tryOnResultUrl = null;
      });
    }
  }

  void _showImageSourceOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        height: 180,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildSourceOption(
              icon: Icons.camera_alt,
              label: "Kamera",
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.camera);
              },
            ),
            _buildSourceOption(
              icon: Icons.photo_library,
              label: "Galeri",
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> startTryOn() async {
    if (_bodyImage == null || wardrobeItems.isEmpty) return;
    setState(() => isTryOnLoading = true);
    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse("${ApiConfig.baseUrl}/api/recommendation/visualize"),
      );
      request.headers.addAll(ApiConfig.headers);
      request.fields['user_id'] = userId.toString();
      if (selectedSource == 'online') {
        request.fields['top_image_url'] = wardrobeItems[0]['image_url'];
        if (wardrobeItems.length > 1)
          request.fields['bottom_image_url'] = wardrobeItems[1]['image_url'];
      } else {
        for (var item in wardrobeItems) {
          String cat = (item['fitting_name'] ?? "").toString().toLowerCase();
          if (cat.contains('pants') ||
              cat.contains('celana') ||
              cat.contains('skirt')) {
            request.fields['bottom_id'] = item['item_id'].toString();
          } else {
            request.fields['top_id'] = item['item_id'].toString();
          }
        }
      }
      request.files.add(
        await http.MultipartFile.fromPath('person_image', _bodyImage!.path),
      );
      var response = await http.Response.fromStream(await request.send());
      if (response.statusCode == 200) {
        setState(
          () => _tryOnResultUrl = jsonDecode(response.body)['result_url'],
        );
      }
    } catch (e) {
      debugPrint(e.toString());
    } finally {
      setState(() => isTryOnLoading = false);
    }
  }

  Future<void> saveOutfit(String name) async {
    if (selectedSource == 'online') return;
    final res = await http.post(
      Uri.parse("${ApiConfig.baseUrl}/api/save-outfit"),
      headers: ApiConfig.headers,
      body: jsonEncode({
        "user_id": userId,
        "outfit_name": name,
        "result_url": _tryOnResultUrl,
        "item_ids": wardrobeItems
            .map((item) => item['item_id'] as int)
            .toList(),
      }),
    );
    if (res.statusCode == 200)
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Outfit disimpan!")));
  }

  void showSaveDialog() {
    TextEditingController nameController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Namakan Outfit"),
        content: TextField(controller: nameController),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Batal"),
          ),
          ElevatedButton(
            onPressed: () {
              saveOutfit(nameController.text);
              Navigator.pop(context);
            },
            child: const Text("Simpan"),
          ),
        ],
      ),
    );
  }

  void _showMissingDataDialog(String message) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Info"),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'Rekomendasi Pakaian',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Pilih Sumber Rekomendasi',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _sourceCard(
                    title: 'Lemari',
                    icon: Icons.checkroom,
                    isActive: selectedSource == 'lemari',
                    onTap: () {
                      setState(() {
                        selectedSource = 'lemari';
                        fetchRecommendation();
                      });
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _sourceCard(
                    title: 'Online',
                    icon: Icons.shopping_bag,
                    isActive: selectedSource == 'online',
                    onTap: () {
                      setState(() {
                        selectedSource = 'online';
                        fetchRecommendation();
                      });
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 28),
            Center(
              child: GestureDetector(
                onTap: _showImageSourceOptions,
                child: Container(
                  width: 220,
                  height: 350,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: primaryColor.withOpacity(0.5)),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: _buildMainImageContent(),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 28),

            // === PENAMBAHAN SKOR & KOMENTAR (Hanya di mode Lemari) ===
            if (selectedSource == 'lemari' && wardrobeItems.isNotEmpty) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: totalMatchScore >= 80
                      ? Colors.green.withOpacity(0.05)
                      : Colors.orange.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: totalMatchScore >= 80
                        ? Colors.green.withOpacity(0.2)
                        : Colors.orange.withOpacity(0.2),
                  ),
                ),
                child: Row(
                  children: [
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        SizedBox(
                          width: 50,
                          height: 50,
                          child: CircularProgressIndicator(
                            value: totalMatchScore / 100,
                            strokeWidth: 5,
                            backgroundColor: Colors.grey.shade200,
                            color: totalMatchScore >= 80
                                ? Colors.green
                                : Colors.orange,
                          ),
                        ),
                        Text(
                          "$totalMatchScore%",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                            color: totalMatchScore >= 80
                                ? Colors.green
                                : Colors.orange,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "ANALISIS STYLO",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 11,
                              letterSpacing: 1.1,
                              color: Colors.grey,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            recommendationSummary,
                            style: const TextStyle(
                              fontSize: 12,
                              height: 1.4,
                              color: Colors.black87,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],

            // TOMBOL AKSI
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: fetchRecommendation,
                    icon: const Icon(Icons.refresh),
                    label: const Text("Ganti"),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.grey,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: (_bodyImage == null || isTryOnLoading)
                        ? null
                        : startTryOn,
                    icon: isTryOnLoading
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.camera_alt_outlined),
                    label: Text(isTryOnLoading ? "Proses..." : "Coba"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blueAccent,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                if (selectedSource == 'lemari') ...[
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: wardrobeItems.isEmpty ? null : showSaveDialog,
                      icon: const Icon(Icons.bookmark_border),
                      label: const Text("Simpan"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 28),

            Text(
              selectedSource == 'lemari'
                  ? 'Rekomendasi dari Lemari'
                  : 'Katalog Produk Online',
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _styleButton("Formal"),
                _styleButton("Casual"),
                _styleButton("Sport"),
              ],
            ),
            const SizedBox(height: 16),

            _buildRecommendationContent(),
          ],
        ),
      ),
    );
  }

  Widget _buildRecommendationContent() {
    if (isLoadingWardrobe)
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: CircularProgressIndicator(),
        ),
      );
    if (wardrobeItems.isEmpty)
      return const Center(child: Text("Data tidak ditemukan."));
    if (selectedSource == 'lemari') {
      return SizedBox(
        height: 180,
        child: ListView(
          scrollDirection: Axis.horizontal,
          children: wardrobeItems
              .map(
                (item) => _wardrobeCard(
                  _translateCategory(
                    item["fitting_name"] ?? item["category_name"] ?? "Pakaian",
                  ),
                  imageUrl: "${ApiConfig.baseUrl}/${item["image_url"]}",
                  itemScore: item["match_score"], // Skor per item
                ),
              )
              .toList(),
        ),
      );
    } else {
      return GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: wardrobeItems.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.75,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
        ),
        itemBuilder: (ctx, index) => _onlineProductCard(wardrobeItems[index]),
      );
    }
  }

  Widget _onlineProductCard(dynamic item) {
    // 1. Ambil raw URL dari database
    String rawUrl = item['image_url'] ?? '';

    // 2. Logika Penentuan URL Gambar:
    // Jika rawUrl diawali 'http', berarti itu link internet langsung (misal: Shopee).
    // Jika tidak, berarti itu path relatif dari hasil upload Admin (misal: static/uploads/xxx.jpg),
    // maka kita harus menggabungkannya dengan baseUrl dari ApiConfig.
    String img = rawUrl.startsWith('http')
        ? rawUrl
        : "${ApiConfig.baseUrl}/$rawUrl";

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Bagian Gambar Produk
          Expanded(
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(16),
              ),
              child: Image.network(
                img,
                fit: BoxFit.cover,
                width: double.infinity,
                // Headers penting agar gambar bisa tembus jika kamu pakai Ngrok
                headers: const {"ngrok-skip-browser-warning": "true"},
                // Penanganan jika gambar gagal dimuat
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: Colors.grey.shade100,
                    child: const Center(
                      child: Icon(
                        Icons.broken_image_outlined,
                        color: Colors.grey,
                        size: 30,
                      ),
                    ),
                  );
                },
                // Loading indicator saat gambar sedang didownload
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Center(
                    child: CircularProgressIndicator(
                      value: loadingProgress.expectedTotalBytes != null
                          ? loadingProgress.cumulativeBytesLoaded /
                                loadingProgress.expectedTotalBytes!
                          : null,
                      strokeWidth: 2,
                    ),
                  );
                },
              ),
            ),
          ),
          // Bagian Informasi Produk (Nama & Tombol Beli)
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item['item_name'] ?? 'Produk Tanpa Nama',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 6),
                SizedBox(
                  width: double.infinity,
                  height: 30,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: EdgeInsets.zero,
                    ),
                    onPressed: () => _launchUrl(item['purchase_link']),
                    child: const Text(
                      "Beli",
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _wardrobeCard(String title, {String? imageUrl, int? itemScore}) {
    return Container(
      width: 140,
      margin: const EdgeInsets.only(right: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          Expanded(
            child: Stack(
              children: [
                imageUrl != null
                    ? ClipRRect(
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(15),
                        ),
                        child: Image.network(
                          imageUrl,
                          fit: BoxFit.cover,
                          width: double.infinity,
                        ),
                      )
                    : const Center(child: Icon(Icons.checkroom)),
                if (itemScore != null)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: primaryColor,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        "$itemScore%",
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(10),
            child: Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  // --- REUSABLE COMPONENTS ---
  Widget _buildSourceOption({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: primaryColor),
          ),
          const SizedBox(height: 8),
          Text(label),
        ],
      ),
    );
  }

  Widget _buildMainImageContent() {
    if (isTryOnLoading)
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text(
            "Fitting baju...",
            style: TextStyle(color: Colors.grey, fontSize: 12),
          ),
        ],
      );
    if (_tryOnResultUrl != null)
      return Image.network(_tryOnResultUrl!, fit: BoxFit.contain);
    if (_bodyImage != null) return Image.file(_bodyImage!, fit: BoxFit.cover);
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.add_a_photo_outlined,
          size: 50,
          color: primaryColor.withOpacity(0.5),
        ),
        const SizedBox(height: 8),
        Text(
          'Foto Badan',
          style: TextStyle(fontWeight: FontWeight.w600, color: primaryColor),
        ),
      ],
    );
  }

  Widget _styleButton(String styleName) {
    final isActive = selectedWardrobeStyle == styleName.toLowerCase();
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: () {
          setState(() => selectedWardrobeStyle = styleName.toLowerCase());
          fetchRecommendation();
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: isActive
                ? primaryColor.withOpacity(0.2)
                : Colors.grey.shade100,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isActive ? primaryColor : Colors.grey.shade300,
            ),
          ),
          child: Text(
            styleName,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: isActive ? primaryColor : Colors.black,
            ),
          ),
        ),
      ),
    );
  }

  Widget _sourceCard({
    required String title,
    required IconData icon,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 100,
        decoration: BoxDecoration(
          color: isActive
              ? primaryColor.withOpacity(0.1)
              : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isActive ? primaryColor : Colors.grey.shade300,
            width: isActive ? 2 : 1,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: primaryColor),
            const SizedBox(height: 4),
            Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: isActive ? primaryColor : Colors.black,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _translateCategory(String originalName) {
    if (originalName.isEmpty) return "Pakaian";
    String lower = originalName.toLowerCase();
    if (lower.contains('t-shirt') || lower.contains('kaos')) return 'Kaos';
    if (lower.contains('shirt') || lower.contains('kemeja')) return 'Kemeja';
    if (lower.contains('pants') || lower.contains('celana')) return 'Celana';
    if (lower.contains('jacket') || lower.contains('jaket')) return 'Jaket';
    if (lower.contains('outer')) return 'Outer';
    if (lower.contains('skirt') || lower.contains('rok')) return 'Rok';
    if (lower.contains('dress')) return 'Gaun';
    return originalName;
  }
}
