import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_sign_in/google_sign_in.dart';
// Ganti path ini sesuai lokasi file SearchPage kamu
import 'package:aplikasi/pages/searchpage.dart'; 

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  static const Color primaryColor = Color(0xFFA79277);

  @override
  void initState() {
    super.initState();
    fetchUsername();
    fetchBodyShape();
  }

  String? username;
  String? bodyShape;
  String? bodyShapeDesc;

  final Map<String, String> bodyShapeDescriptions = {
    "Hourglass": "Bahu dan pinggul seimbang dengan pinggang ramping.",
    "Pear": "Pinggul lebih besar dari bahu. Cocok fokus ke atasan.",
    "Inverted Triangle": "Bahu lebih lebar dari pinggul.",
    "Rectangle": "Bahu, pinggang, dan pinggul hampir sejajar.",
    "Apple": "Bagian tengah tubuh lebih dominan.",
  };

  Future<void> fetchUsername() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      username = prefs.getString('username');
    });
  }

  Future<void> fetchBodyShape() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getInt('user_id');

    // Pastikan user_id ada sebelum request
    if (userId == null) return;

    try {
      final response = await http.get(
        // GANTI IP INI SESUAI LAPTOP
        Uri.parse('http://172.20.240.164:5000/api/bodyshape/$userId'),
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

  // --- LOGIKA LOGOUT ---
  Future<void> _handleLogout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear(); // Hapus data sesi lokal
    await GoogleSignIn().signOut(); // Logout dari Google

    if (mounted) {
      // Pindah ke halaman Login dan hapus semua history halaman
      Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
    }
  }

  // --- POP-UP KONFIRMASI KELUAR ---
  Future<bool> _showExitDialog() async {
    return await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text("Konfirmasi"),
            content: const Text("Apakah Anda yakin ingin Logout dan keluar?"),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false), // Batal
                child: const Text("Batal"),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                onPressed: () => Navigator.of(context).pop(true), // Ya, Logout
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
    // 1. BUNGKUS DENGAN POPSCOPE
    return PopScope(
      canPop: false, // Mencegah aplikasi langsung tertutup
      onPopInvoked: (didPop) async {
        if (didPop) return;

        // 2. TAMPILKAN DIALOG SAAT BACK DITEKAN
        final bool shouldLogout = await _showExitDialog();

        if (shouldLogout) {
          _handleLogout();
        }
      },
      child: Scaffold(
        backgroundColor: Colors.white,

        // ================= BODY =================
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ================= TOP HEADER =================
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Hello,',
                          style: TextStyle(color: Colors.black54, fontSize: 14),
                        ),
                        Text(
                          '${username ?? "User"} 👋',
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

                    // Ikon Chatbot & Profil
                    Row(
                      children: [
                        IconButton(
                          onPressed: () {
                            Navigator.pushNamed(context, '/chatbot');
                          },
                          icon: const Icon(Icons.chat, color: primaryColor),
                        ),
                        IconButton(
                          onPressed: () {
                            Navigator.pushNamed(context, '/profile');
                          },
                          icon: const Icon(Icons.person, color: primaryColor),
                        ),
                      ],
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // ================= SEARCH (NAVIGASI) =================
                // Menggunakan GestureDetector agar bisa diklik pindah halaman
                GestureDetector(
                  onTap: () {
                    // Pastikan SearchPage sudah diimport
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const SearchPage()),
                    );
                  },
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                          color: Colors.grey.shade300, width: 1.5),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.search, color: Colors.grey),
                        const SizedBox(width: 12),
                        Text(
                          'Cari pakaian...',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 15,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // ================= INFO BENTUK TUBUH =================
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
                      const SizedBox(width: 15),
                      SizedBox(
                        height: 90,
                        width: 70,
                        child: Image.asset('assets/images/getstarted.png'),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // ================= SERING DIGUNAKAN =================
                const Text(
                  "Sering kamu gunakan",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildChip("Oversized T-Shirt"),
                      _buildChip("High Waist Jeans"),
                      _buildChip("Blazer"),
                      _buildChip("Cardigan"),
                    ],
                  ),
                ),

                const SizedBox(height: 32),

                // ================= FITUR UTAMA =================
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
                      onTap: () {
                        Navigator.pushNamed(context, '/bodyshape');
                      },
                    ),
                    FeatureCard(
                      icon: Icons.auto_awesome,
                      title: 'Analisis Pakaian',
                      onTap: () {
                        Navigator.pushNamed(context, '/analysis');
                      },
                    ),
                    FeatureCard(
                      icon: Icons.edit,
                      title: 'Custom Outfit',
                      onTap: () {
                        Navigator.pushNamed(context, '/custom');
                      },
                    ),
                    FeatureCard(
                      icon: Icons.recommend_outlined,
                      title: 'Rekomendasi',
                      onTap: () {
                        Navigator.pushNamed(context, '/recommendation');
                      },
                    ),
                    FeatureCard(
                      icon: Icons.color_lens,
                      title: 'Warna Kulit',
                      onTap: () {
                        Navigator.pushNamed(context, '/skintone');
                      },
                    ),
                  ],
                ),

                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ================= CHIP =================
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

// ================= FEATURE CARD =================
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