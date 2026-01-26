import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:aplikasi/services/api_config.dart';
class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  // 1. Mengganti Email Controller menjadi Username Controller
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  final GoogleSignIn _googleSignIn = GoogleSignIn();

  bool isLoading = false;

  // --- 1. TAMBAHKAN FUNGSI INI JUGA DI SINI ---
  void showTopSnackBar(
    BuildContext context,
    String message, {
    bool isError = false,
  }) {
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isError ? Icons.error_outline : Icons.check_circle_outline,
              color: Colors.white,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
        backgroundColor: isError ? Colors.red.shade400 : Colors.green.shade400,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        // Logic posisi di ATAS
        margin: EdgeInsets.only(
          bottom: MediaQuery.of(context).size.height - 130,
          left: 16,
          right: 16,
        ),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  // ... (import tetap sama)

  Future<void> login() async {
    if (usernameController.text.isEmpty) {
      showTopSnackBar(context, 'Isi username anda', isError: true);
      return;
    }
    if (passwordController.text.isEmpty) {
      showTopSnackBar(context, 'Isi password anda', isError: true);
      return;
    }

    if (!mounted) return;
    setState(() => isLoading = true);

    try {
      // 1. GANTI URL DENGAN ALAMAT NGROK KAMU
      final response = await http
          .post(
            Uri.parse('${ApiConfig.baseUrl}/api/login'),
            headers: ApiConfig.headers,
            body: jsonEncode({
              'username': usernameController.text,
              'password': passwordController.text,
            }),
          )
          .timeout(
            const Duration(seconds: 10),
          ); // Tambah durasi karena ngrok butuh waktu lebih lama

      if (!mounted) return;
      setState(() => isLoading = false);

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.clear();
        await prefs.setInt("user_id", data["user_id"]);
        await prefs.setString("username", data["username"]);
        await prefs.setString("name", data["name"] ?? "");
        await prefs.setString("email", data["email"] ?? "");
        await prefs.setString("gender", data["gender"] ?? "Belum diatur");
        await prefs.setString("photo_url", data["photo_url"] ?? "");
        await prefs.setBool('is_logged_in', true);

        showTopSnackBar(context, "Login Berhasil!");
        Navigator.of(context).pushReplacementNamed('/home');
      } else {
        showTopSnackBar(
          context,
          data['message'] ?? 'Login gagal',
          isError: true,
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => isLoading = false);

      String errorMessage = "Terjadi kesalahan: $e";
      if (e.toString().contains("SocketException")) {
        errorMessage = "Pastikan ngrok sudah aktif di laptop";
      }
      showTopSnackBar(context, errorMessage, isError: true);
    }
  }

  // --- LOGIKA LOGIN GOOGLE (SESUAIKAN JUGA) ---
  Future<void> _handleGoogleSignIn() async {
    setState(() => isLoading = true);
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        setState(() => isLoading = false);
        return;
      }

      // SESUAIKAN URL NGROK DI SINI JUGA
      final response = await http.post(
        Uri.parse("${ApiConfig.baseUrl}/google_login"),
        headers: ApiConfig.headers,
        body: jsonEncode({
          "email": googleUser.email,
          "username": googleUser.displayName ?? "User",
          "photo_url": googleUser.photoUrl ?? "",
        }),
      );

      // ... (sisanya sama dengan kode awal kamu)
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        final prefs = await SharedPreferences.getInstance();
        await prefs.setInt('user_id', data['user_id']);
        await prefs.setString('username', data['username']);
        await prefs.setString('email', data['email']);
        await prefs.setString("gender", data["gender"] ?? "");
        await prefs.setString("photo_url", data["photo_url"] ?? "");
        await prefs.setBool('is_logged_in', true);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Berhasil Masuk dengan Google!")),
          );
          Navigator.of(context).pushReplacementNamed('/home');
        }
      } else {
        throw Exception("Gagal koneksi server");
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Gagal Login Google: $error"),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 48),
              const SizedBox(height: 32),

              // Judul
              const Text(
                'Welcome Back!',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),

              const SizedBox(height: 8),

              // Subtitle
              Text(
                'Masuk untuk mendapatkan rekomendasi\ngaya pakaian terbaikmu',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: Colors.grey[700]),
              ),

              const SizedBox(height: 32),

              // Input USERNAME (Sebelumnya Email)
              TextField(
                controller: usernameController,
                decoration: InputDecoration(
                  labelText: 'Username', // Label Username
                  hintText: 'yourusername', // Hint Username
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(
                      color: Color(0xFFA79277),
                      width: 1.5,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Input PASSWORD
              TextField(
                controller: passwordController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: 'Password',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(
                      color: Color(0xFFA79277),
                      width: 1.5,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Tombol LOGIN
              SizedBox(
                height: 52,
                child: ElevatedButton(
                  onPressed: isLoading ? null : () => login(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFA79277),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          'Login',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),

              const SizedBox(height: 24),

              // Divider
              Row(
                children: [
                  Expanded(child: Divider(color: Colors.grey[300])),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: Text(
                      "Atau masuk dengan",
                      style: TextStyle(color: Colors.grey[600], fontSize: 12),
                    ),
                  ),
                  Expanded(child: Divider(color: Colors.grey[300])),
                ],
              ),

              const SizedBox(height: 20),

              // Tombol GOOGLE (Tetap Ada)
              SizedBox(
                height: 52,
                child: OutlinedButton.icon(
                  onPressed: isLoading ? null : _handleGoogleSignIn,
                  icon: Image.asset(
                    'assets/images/google_logo.png',
                    height: 24,
                    errorBuilder: (ctx, err, stack) => const Icon(
                      Icons.g_mobiledata,
                      size: 30,
                      color: Colors.blue,
                    ),
                  ),
                  label: const Text(
                    'Google',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.black87,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: Colors.grey.shade300),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Link ke Register
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'Belum punya akun? ',
                    style: TextStyle(color: Colors.grey),
                  ),
                  GestureDetector(
                    onTap: () {
                      Navigator.pushNamed(context, '/register');
                    },
                    child: const Text(
                      'Daftar',
                      style: TextStyle(
                        color: Color(0xFFA79277),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}
