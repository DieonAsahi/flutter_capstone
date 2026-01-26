import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Import untuk FilteringTextInputFormatter
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:aplikasi/services/api_config.dart';

class BodyShapePage extends StatefulWidget {
  const BodyShapePage({super.key});

  @override
  State<BodyShapePage> createState() => _BodyShapePageState();
}

const Map<String, String> bodyShapeDescriptions = {
  "Hourglass": "Bahu dan pinggul seimbang dengan pinggang ramping.",
  "Pear": "Pinggul lebih besar dari bahu. Cocok fokus ke atasan.",
  "Inverted Triangle": "Bahu lebih lebar dari pinggul.",
  "Rectangle": "Bahu, pinggang, dan pinggul hampir sejajar.",
  "Apple": "Bagian tengah tubuh lebih dominan.",
};

class _BodyShapePageState extends State<BodyShapePage> {
  final TextEditingController bustController = TextEditingController();
  final TextEditingController waistController = TextEditingController();
  final TextEditingController hipsController = TextEditingController();

  final Color primaryColor = const Color(0xFFA79277);

  String? bodyShapeResult;
  String? bodyShapeDesc;
  bool showConfirm = false;
  bool isSaved = false;

  // --- FUNGSI VALIDASI & HITUNG ---
  Future<void> _calculateBodyShape() async {
    // 1. Cek Input Kosong
    if (bustController.text.isEmpty ||
        waistController.text.isEmpty ||
        hipsController.text.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Mohon isi semua data")));
      return;
    }

    // 2. Parsing ke Double (Cegah FormatException)
    double? bust = double.tryParse(bustController.text.replaceAll(',', '.'));
    double? waist = double.tryParse(waistController.text.replaceAll(',', '.'));
    double? hip = double.tryParse(hipsController.text.replaceAll(',', '.'));

    // 3. Validasi Angka & Logika (Cegah 0, Negatif, atau Angka Raksasa)
    if (bust == null || waist == null || hip == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Harap masukan data yang benar (hanya angka)"),
        ),
      );
      return;
    }

    if (bust <= 0 || waist <= 0 || hip <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Ukuran tidak boleh 0 atau negatif")),
      );
      return;
    }

    if (bust > 300 || waist > 300 || hip > 300) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Ukuran tidak logis (Maksimal 300 cm)")),
      );
      return;
    }

    // --- JIKA LOLOS VALIDASI, BARU KIRIM KE API ---
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getInt('user_id');

    if (userId == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("User belum login")));
      return;
    }

    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/api/bodyshape/calculate'),
        headers: ApiConfig.headers,
        body: jsonEncode({
          'user_id': userId,
          'bust': bust,
          'waist': waist,
          'hip': hip,
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        setState(() {
          bodyShapeResult = data['body_shape'];
          bodyShapeDesc = data['description'];
          showConfirm = true;
          isSaved = false;
        });
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(data['message'] ?? "Gagal memproses data")),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error: $e")));
    }
  }

  // ... (Kode build UI tetap sama, HANYA ubah input formatter di TextField)

  // ================= INPUT FIELD (UPDATE) =================
  Widget _buildInputField(String label, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: TextField(
        controller: controller,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        // Tambahkan ini agar user HANYA bisa ketik angka & titik/koma
        inputFormatters: [
          FilteringTextInputFormatter.allow(RegExp(r'^\d+[\.,]?\d*')),
        ],
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(fontSize: 16, color: Colors.grey),
          suffixText: 'cm',
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
        ),
      ),
    );
  }

  // ... (Sisa kode UI build, save function, guide section sama persis dengan yang lama)
  // Tidak perlu saya tulis ulang semua karena hanya bagian Validasi & InputField yang berubah.
  // Silakan salin fungsi _calculateBodyShape dan _buildInputField di atas.

  @override
  Widget build(BuildContext context) {
    // Paste kode build() lama Anda di sini, tidak ada perubahan struktur UI.
    // Pastikan memanggil _buildInputField yang baru.
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          'Bentuk Tubuh',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // ================= IMAGE =================
              Image.asset(
                'assets/images/bodytypes.jpg',
                height: 500,
                fit: BoxFit.contain,
              ),

              const SizedBox(height: 20),

              // ================= DESC =================
              Text(
                'Cari tahu bentuk tubuhmu dan jadilah lebih percaya diri!',
                style: TextStyle(fontSize: 16, color: Colors.grey[700]),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 30),

              // ================= INPUT =================
              _buildInputField('Bust (Lingkar Dada)', bustController),
              _buildInputField('Waist (Lingkar Pinggang)', waistController),
              _buildInputField('Hips (Lingkar Pinggul)', hipsController),

              const SizedBox(height: 30),

              // ================= BUTTON =================
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _calculateBodyShape,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: const Text(
                    'Lihat Hasil',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),

              // ================= RESULT (DI BAWAH BUTTON) =================
              if (bodyShapeResult != null) ...[
                const SizedBox(height: 24),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF2E1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Bentuk Tubuhmu Adalah',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 12),

                      Text(
                        bodyShapeResult ?? "Tidak Diketahui",
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: primaryColor,
                        ),
                      ),
                      const SizedBox(height: 8),

                      Text(
                        bodyShapeDesc ?? "Deskripsi tidak tersedia.",
                        style: const TextStyle(fontSize: 14),
                      ),
                    ],
                  ),
                ),

                // ================= KONFIRMASI =================
                if (showConfirm && !isSaved) ...[
                  const SizedBox(height: 20),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.green),
                    ),
                    child: const Text(
                      "Apakah hasil ini sudah sesuai?",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.green,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),

                  const SizedBox(height: 20),

                  Row(
                    children: [
                      // ===== SESUAI =====
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
                            final prefs = await SharedPreferences.getInstance();
                            final userId = prefs.getInt('user_id');

                            if (userId == null) return;

                            try {
                              final response = await http.post(
                                Uri.parse(
                                  '${ApiConfig.baseUrl}/api/bodyshape/save',
                                ),
                                headers: ApiConfig.headers,
                                body: jsonEncode({
                                  'user_id': userId,
                                  'body_shape': bodyShapeResult ?? "Unknown",
                                }),
                              );

                              final data = jsonDecode(response.body);

                              if (data['success'] == true) {
                                setState(() {
                                  isSaved = true;
                                  showConfirm = false;
                                });
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text("Berhasil disimpan!"),
                                  ),
                                );
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text("Gagal: ${data['message']}"),
                                  ),
                                );
                              }
                            } catch (e) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text("Error koneksi: $e")),
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

                      // ===== KOREKSI =====
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
                              bodyShapeResult = null;
                              bodyShapeDesc = null;
                              showConfirm = false;
                            });
                          },
                          child: const Text(
                            "Ulangi",
                            style: TextStyle(color: Colors.white, fontSize: 16),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],

                if (isSaved) ...[
                  const SizedBox(height: 20),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.green),
                    ),
                    child: const Text(
                      "Bentuk tubuh anda sudah disimpan",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.green,
                      ),
                    ),
                  ),
                ],
              ],
              const SizedBox(height: 40),

              // ================= GUIDE =================
              _buildGuideSection(),

              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGuideSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: const [
        Text(
          "📏 Panduan Pengukuran Bentuk Tubuh",
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 12),
        Text(
          "Gunakan pita pengukur (meteran kain), berdiri tegak, dan kenakan pakaian yang pas.\n",
        ),
        Text(
          "1. Bust (Lingkar Dada)",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        Text(
          "Ukur bagian terlebar dari dada, pastikan meteran sejajar lantai.\n",
        ),
        Text(
          "2. Waist (Lingkar Pinggang)",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        Text(
          "Ukur bagian terkecil dari pinggang alami, jangan menahan napas.\n",
        ),
        Text(
          "3. Hips (Lingkar Pinggul)",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        Text("Ukur bagian terlebar dari pinggul dan bokong."),
      ],
    );
  }
}
