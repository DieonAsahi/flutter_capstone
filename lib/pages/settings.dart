import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:url_launcher/url_launcher.dart';
import 'package:aplikasi/services/api_config.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  // --- LOGOUT ---
  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          "Konfirmasi",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: const Text("Apakah kamu yakin ingin keluar?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Batal", style: TextStyle(color: Colors.black)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              // shape: RoundedRectangleBorder(
              //   borderRadius: BorderRadius.circular(12),
              // ),
            ),
            onPressed: () async {
              final prefs = await SharedPreferences.getInstance();
              await prefs.clear();
              await _googleSignIn.signOut();

              if (mounted) {
                Navigator.pushNamedAndRemoveUntil(
                  context,
                  '/login',
                  (route) => false,
                );
              }
            },
            child: const Text("Logout", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // --- GANTI PASSWORD ---
  // void _showChangePasswordDialog(BuildContext context) {
  //   final TextEditingController passController = TextEditingController();

  //   showDialog(
  //     context: context,
  //     builder: (context) => AlertDialog(
  //       title: const Text("Ganti Password"),
  //       content: Column(
  //         mainAxisSize: MainAxisSize.min,
  //         children: [
  //           const Text(
  //             "Catatan: Minimal 8 karakter, maksimal 12 karakter.",
  //             style: TextStyle(fontSize: 12, color: Colors.grey),
  //           ),
  //           const SizedBox(height: 10),
  //           TextField(
  //             controller: passController,
  //             obscureText: true,
  //             decoration: const InputDecoration(
  //               labelText: "Password Baru",
  //               border: OutlineInputBorder(),
  //             ),
  //           ),
  //         ],
  //       ),
  //       actions: [
  //         TextButton(
  //           onPressed: () => Navigator.pop(context),
  //           child: const Text("Batal"),
  //         ),
  //         ElevatedButton(
  //           onPressed: () async {
  //             String newPass = passController.text.trim();

  //             // Tambahkan Validasi di sini
  //             if (newPass.length < 8 || newPass.length > 12) {
  //               ScaffoldMessenger.of(context).showSnackBar(
  //                 const SnackBar(
  //                   content: Text("Password harus 8-12 karakter!"),
  //                   backgroundColor: Colors.orange,
  //                 ),
  //               );
  //               return;
  //             }

  //             Navigator.pop(context);
  //             await _changePasswordApi(newPass);
  //           },
  //           child: const Text("Simpan"),
  //         ),
  //       ],
  //     ),
  //   );
  // }

  void _showChangePasswordDialog(BuildContext context) {
    final TextEditingController passController = TextEditingController();
    // Tambahkan controller untuk konfirmasi password
    final TextEditingController confirmPassController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Ganti Password"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Catatan: Minimal 8 karakter, maksimal 12 karakter.",
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 15),

            // Input Password Baru
            TextField(
              controller: passController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: "Password Baru",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(10)),
                  borderSide: BorderSide(color: Color(0xFFA79277))
                ),
                isDense: true,
              ),
            ),
            const SizedBox(height: 15),

            // Input Konfirmasi Password
            TextField(
              controller: confirmPassController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: "Konfirmasi Password Baru",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(10)),
                  borderSide: BorderSide(color: Color(0xFFA79277))
                ),
                isDense: true,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Batal", style: TextStyle(color: Colors.black)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFFA79277),
              // shape: RoundedRectangleBorder(
              //   borderRadius: BorderRadius.circular(12),
              // ),
            ),
            onPressed: () async {
              String newPass = passController.text.trim();
              String confirmPass = confirmPassController.text.trim();

              // 1. Validasi Panjang Karakter
              if (newPass.length < 8 || newPass.length > 12) {
                _showErrorSnackBar(context, "Password harus 8-12 karakter!");
                return;
              }

              // 2. Validasi Kecocokan (Client-side validation)
              if (newPass != confirmPass) {
                _showErrorSnackBar(context, "Konfirmasi password tidak cocok!");
                return;
              }

              // Jika valid, tutup dialog dan panggil API
              Navigator.pop(context);
              await _changePasswordApi(newPass);
            },
            child: const Text("Simpan", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // Helper agar kode lebih bersih
  void _showErrorSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  Future<void> _changePasswordApi(String newPassword) async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getInt('user_id');

    try {
      final response = await http.post(
        Uri.parse("${ApiConfig.baseUrl}/api/change_password"),
        headers: ApiConfig.headers,
        body: jsonEncode({"user_id": userId, "new_password": newPassword}),
      );

      final data = jsonDecode(response.body);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(data['message']),
            backgroundColor: data['success'] ? Colors.green : Colors.red,
          ),
        );
      }
    } catch (e) {
      debugPrint("Error ganti password: $e");
    }
  }

  // --- TAUTKAN GOOGLE ---
  Future<void> _linkGoogleAccount() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return;

      final String email = googleUser.email;
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getInt('user_id');

      final response = await http.post(
        Uri.parse("${ApiConfig.baseUrl}/api/link_google"),
        headers: ApiConfig.headers,
        body: jsonEncode({"user_id": userId, "google_email": email}),
      );

      final data = jsonDecode(response.body);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(data['message']),
            backgroundColor: data['success'] ? Colors.green : Colors.red,
          ),
        );
      }
      await _googleSignIn.signOut();
    } catch (e) {
      debugPrint("Error link google: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Gagal menautkan akun Google")),
        );
      }
    }
  }

  // // --- ATUR GENDER (HANYA 1X) ---
  // void _showGenderDialog(BuildContext context) async {
  //   final prefs = await SharedPreferences.getInstance();
  //   String? currentGender = prefs.getString('gender');

  //   // Perbaikan: Cek berbagai kemungkinan nilai kosong dari DB/SharedPreferences
  //   bool isNotSet =
  //       (currentGender == null ||
  //       currentGender.isEmpty ||
  //       currentGender.toLowerCase() == "null" ||
  //       currentGender == "-" ||
  //       currentGender.toLowerCase() == "belum diatur");

  //   if (!isNotSet) {
  //     if (!mounted) return;
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       const SnackBar(content: Text("Gender hanya bisa diatur satu kali.")),
  //     );
  //     return;
  //   }
  //   showDialog(
  //     context: context,
  //     builder: (ctx) => AlertDialog(
  //       title: const Text("Pilih Gender"),
  //       content: Column(
  //         mainAxisSize: MainAxisSize.min,
  //         children: [
  //           const Text("Hati-hati, gender tidak bisa diubah setelah disimpan."),
  //           const SizedBox(height: 20),
  //           Row(
  //             mainAxisAlignment: MainAxisAlignment.spaceEvenly,
  //             children: [
  //               // Bungkus tombol pertama dengan Expanded
  //               Expanded(child: _genderBtn(ctx, "Laki-laki")),
  //               const SizedBox(width: 10), // Beri sedikit jarak antar tombol
  //               // Bungkus tombol kedua dengan Expanded
  //               Expanded(child: _genderBtn(ctx, "Perempuan")),
  //             ],
  //           ),
  //         ],
  //       ),
  //     ),
  //   );
  // }

  void _showGenderDialog(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    String? currentGender = prefs.getString('gender');

    bool isNotSet =
        (currentGender == null ||
        currentGender.isEmpty ||
        currentGender.toLowerCase() == "null" ||
        currentGender == "-" ||
        currentGender.toLowerCase() == "belum diatur");

    if (!isNotSet) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Gender hanya bisa diatur satu kali.")),
      );
      return;
    }

    String? selectedGender; // Variabel penampung pilihan

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        // Agar dropdown bisa berubah saat dipilih
        builder: (context, setState) => AlertDialog(
          title: const Text("Pilih Gender"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Hati-hati, gender tidak bisa diubah setelah disimpan.",
                style: TextStyle(fontSize: 13, color: Colors.grey),
              ),
              const SizedBox(height: 20),
              DropdownButtonFormField<String>(
                value: selectedGender,
                decoration: const InputDecoration(
                  labelText: "Pilih Jenis Kelamin",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(10)),
                  ),
                ),
                items: ["Laki-laki", "Perempuan"]
                    .map(
                      (label) =>
                          DropdownMenuItem(value: label, child: Text(label)),
                    )
                    .toList(),
                onChanged: (value) {
                  setState(() {
                    selectedGender = value;
                  });
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text("Batal", style: TextStyle(color: Colors.black)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFFA79277),
                // shape: RoundedRectangleBorder(
                //   borderRadius: BorderRadius.circular(12),
                // ),
              ),
              onPressed: () {
                if (selectedGender != null) {
                  // Panggil fungsi save yang sudah Anda buat
                  _saveGender(selectedGender!, ctx);
                } else {
                  ScaffoldMessenger.of(ctx).showSnackBar(
                    const SnackBar(content: Text("Pilih gender dulu!")),
                  );
                }
              },
              child: const Text("Atur", style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  // Widget _genderBtn(BuildContext ctx, String label) {
  //   return ElevatedButton(
  //     style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFA79277)),
  //     onPressed: () => _saveGender(label, ctx),
  //     child: Text(label, style: const TextStyle(color: Colors.white)),
  //   );
  // }

  // Future<void> _saveGender(String gender, BuildContext ctx) async {
  //   Navigator.pop(ctx);
  //   final prefs = await SharedPreferences.getInstance();
  //   final userId = prefs.getInt('user_id');

  //   try {
  //     final response = await http.post(
  //       Uri.parse("${ApiConfig.baseUrl}/api/user/update_gender"),
  //       headers: ApiConfig.headers,
  //       body: jsonEncode({"user_id": userId, "gender": gender}),
  //     );

  //     final data = jsonDecode(response.body);

  //     if (response.statusCode == 200 && data['success'] == true) {
  //       String savedGender = (gender == "Laki-laki") ? "male" : "female";
  //       await prefs.setString('gender', savedGender);

  //       if (mounted) {
  //         ScaffoldMessenger.of(context).showSnackBar(
  //           const SnackBar(content: Text("Gender berhasil disimpan!")),
  //         );
  //       }
  //     } else {
  //       if (mounted) {
  //         ScaffoldMessenger.of(context).showSnackBar(
  //           SnackBar(content: Text(data['message'] ?? "Gagal update gender")),
  //         );
  //       }
  //     }
  //   } catch (e) {
  //     if (mounted) {
  //       ScaffoldMessenger.of(
  //         context,
  //       ).showSnackBar(SnackBar(content: Text("Gagal: $e")));
  //     }
  //   }
  // }

  Future<void> _saveGender(String gender, BuildContext ctx) async {
    // 1. Tutup dialog segera setelah tombol ditekan
    Navigator.pop(ctx);

    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getInt('user_id');

    try {
      final response = await http.post(
        Uri.parse("${ApiConfig.baseUrl}/api/user/update_gender"),
        headers: ApiConfig.headers,
        body: jsonEncode({"user_id": userId, "gender": gender}),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        // Sesuai logika Anda: Laki-laki -> male, Perempuan -> female
        String savedGender = (gender == "Laki-laki") ? "male" : "female";
        await prefs.setString('gender', savedGender);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Gender berhasil disimpan!")),
          );
          // Opsional: Refresh UI halaman profil jika perlu
          setState(() {});
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(data['message'] ?? "Gagal update gender")),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Gagal: $e")));
      }
    }
  }

  // --- BANTUAN ---
  void _showHelpDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Bantuan"),
        content: const Text(
          "Jika Anda mengalami kendala, silakan hubungi tim support kami atau cek FAQ.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Tutup"),
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
          'Pengaturan',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            _settingItem(
              icon: Icons.edit,
              title: 'Edit Profil',
              onTap: () => Navigator.pushNamed(context, '/editprofile'),
            ),

            _settingItem(
              icon: Icons.lock_outline,
              title: 'Ganti Password',
              onTap: () => _showChangePasswordDialog(context),
            ),

            _settingItem(
              icon: Icons.link,
              title: 'Tautkan Akun Google',
              onTap: _linkGoogleAccount,
            ),

            // --- MENU ATUR GENDER ---
            _settingItem(
              icon: Icons.wc,
              title: 'Atur Gender',
              onTap: () => _showGenderDialog(context),
            ),

            _settingItem(
              icon: Icons.feedback_outlined,
              title: 'Feedback Pengguna',
              onTap: () => Navigator.pushNamed(context, '/feedback'),
            ),

            _settingItem(
              icon: Icons.help_outline,
              title: 'Bantuan',
              onTap: () => _showHelpDialog(context),
            ),

            const Divider(),

            _settingItem(
              icon: Icons.logout,
              title: 'Logout',
              isLogout: true,
              onTap: () => _showLogoutDialog(context),
            ),
          ],
        ),
      ),
    );
  }

  Widget _settingItem({
    required IconData icon,
    required String title,
    bool isLogout = false,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: isLogout ? Colors.red : Colors.black),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.w500,
          color: isLogout ? Colors.red : Colors.black,
        ),
      ),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }
}
