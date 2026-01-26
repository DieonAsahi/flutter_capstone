import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:aplikasi/services/api_config.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  static const Color primaryColor = Color(0xFFA79277);

  String? name;
  String? bodyShape;
  String? bodyShapeDesc;

  // Variabel untuk data dinamis "Sering Digunakan"
  List<String> frequentItems = ["Loading..."];

  final Map<String, String> bodyShapeDescriptions = {
    "Hourglass": "Bahu dan pinggul seimbang dengan pinggang ramping.",
    "Pear": "Pinggul lebih besar dari bahu. Cocok fokus ke atasan.",
    "Inverted Triangle": "Bahu lebih lebar dari pinggul.",
    "Rectangle": "Bahu, pinggang, dan pinggul hampir sejajar.",
    "Apple": "Bagian tengah tubuh lebih dominan.",
  };

  @override
  void initState() {
    super.initState();
    _loadAllData();
  }

  // --- LOGIKA REFRESH ---
  // Fungsi ini dipicu saat user menarik layar ke bawah
  Future<void> _handleRefresh() async {
    await _loadAllData();
  }

  // --- LOGIKA SYNC DATA ---
  Future<void> _loadAllData() async {
    await fetchUsernameLocal(); // 1. Ambil dari lokal dulu (biar cepat)
    await fetchUserProfileServer(); // 2. Ambil dari DB (biar sinkron)
    await fetchBodyShape(); // 3. Ambil data bentuk tubuh
    await _fetchFrequentItems(); // 4. Ambil item sering digunakan
  }

  // Fungsi 1: Ambil Nama dari SharedPreferences (Lokal)
  Future<void> fetchUsernameLocal() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      name = prefs.getString('name');
    });
  }

  // Fungsi 2: Sinkronisasi Nama dari API (Database)
  Future<void> fetchUserProfileServer() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getInt('user_id');
    if (userId == null) return;

    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/api/user/$userId/profile'),
        headers: ApiConfig.headers,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          setState(() {
            name = data['name'] ?? data['username'];
          });
          await prefs.setString('name', name!);
        }
      }
    } catch (e) {
      debugPrint("Gagal sinkronisasi nama dari database: $e");
    }
  }

  Future<void> fetchBodyShape() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getInt('user_id');
    if (userId == null) return;

    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/api/bodyshape/$userId'),
        headers: ApiConfig.headers,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          setState(() {
            bodyShape = data['body_shape'];
            bodyShapeDesc = bodyShapeDescriptions[bodyShape];
          });
        }
      }
    } catch (e) {
      debugPrint("Gagal ambil body shape: $e");
    }
  }

  Future<void> _fetchFrequentItems() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getInt('user_id');
    if (userId == null) return;

    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/api/user/$userId/frequent'),
        headers: ApiConfig.headers,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          setState(() {
            frequentItems = List<String>.from(data['items']);
          });
        }
      }
    } catch (e) {
      debugPrint("Gagal ambil frequent items: $e");
      setState(() {
        frequentItems = ["Casual", "Basic"];
      });
    }
  }

  Future<void> _handleLogout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    await GoogleSignIn().signOut();

    if (mounted) {
      Navigator.pushNamedAndRemoveUntil(context, '/login', (_) => false);
    }
  }

  Future<bool> _showExitDialog() async {
    return await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text(
              "Konfirmasi",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            content: const Text("Apakah Anda yakin ingin Logout dan keluar?"),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text(
                  "Batal",
                  style: TextStyle(color: Colors.black),
                ),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                onPressed: () => Navigator.pop(context, true),
                child: const Text(
                  "Ya, Keluar",
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
        ) ??
        false;
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) async {
        if (didPop) return;
        final shouldLogout = await _showExitDialog();
        if (shouldLogout) _handleLogout();
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          // --- PENAMBAHAN REFRESH INDICATOR ---
          child: RefreshIndicator(
            color: primaryColor,
            onRefresh: _handleRefresh,
            child: SingleChildScrollView(
              // Menambahkan physics agar bisa ditarik meski konten sedikit
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  /// ================= HEADER =================
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Hello,',
                            style: TextStyle(
                              color: Colors.black54,
                              fontSize: 14,
                            ),
                          ),
                          Text(
                            '${name ?? "User"} 👋',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              fontFamilyFallback: [
                                'Segoe UI Emoji',
                                'Noto Color Emoji',
                              ],
                            ),
                          ),
                        ],
                      ),
                      IconButton(
                        onPressed: () {
                          Navigator.pushNamed(context, '/chatbot');
                        },
                        icon: const Icon(Icons.chat, color: primaryColor),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  /// ================= INFO BENTUK TUBUH =================
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF2E1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                "Bentuk Tubuh Kamu:",
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                bodyShape ?? "-",
                                style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: primaryColor,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                bodyShapeDesc ?? "Belum diisi",
                                style: const TextStyle(fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        SizedBox(
                          height: 90,
                          width: 70,
                          child: Image.asset('assets/images/getstarted.png'),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  /// ================= SERING DIGUNAKAN =================
                  const Text(
                    "Sering kamu gunakan",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: frequentItems.map((item) {
                        return _buildChip(item);
                      }).toList(),
                    ),
                  ),

                  const SizedBox(height: 32),

                  /// ================= FITUR =================
                  const Text(
                    "MyStyle",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    mainAxisSpacing: 16,
                    crossAxisSpacing: 16,
                    childAspectRatio: 1.1,
                    children: [
                      FeatureCard(
                        icon: Icons.accessibility_new,
                        title: 'Bentuk Tubuh',
                        onTap: () => Navigator.pushNamed(context, '/bodyshape'),
                      ),
                      FeatureCard(
                        icon: Icons.auto_awesome,
                        title: 'Analisis Pakaian',
                        onTap: () => Navigator.pushNamed(context, '/analysis'),
                      ),
                      FeatureCard(
                        icon: Icons.edit,
                        title: 'Custom Outfit',
                        onTap: () => Navigator.pushNamed(context, '/custom'),
                      ),
                      FeatureCard(
                        icon: Icons.recommend_outlined,
                        title: 'Rekomendasi',
                        onTap: () =>
                            Navigator.pushNamed(context, '/recommendation'),
                      ),
                      FeatureCard(
                        icon: Icons.color_lens,
                        title: 'Warna Kulit',
                        onTap: () => Navigator.pushNamed(context, '/skintone'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildChip(String label) {
    return Container(
      margin: const EdgeInsets.only(right: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Text(label, style: const TextStyle(fontSize: 13)),
    );
  }
}

class FeatureCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;

  const FeatureCard({
    super.key,
    required this.icon,
    required this.title,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    const Color primaryColor = Color(0xFFA79277);

    return Container(
      decoration: BoxDecoration(
        color: primaryColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(24),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 35, color: primaryColor),
            const SizedBox(height: 12),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}