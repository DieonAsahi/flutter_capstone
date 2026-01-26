import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:aplikasi/services/api_config.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController =
      TextEditingController();

  bool isLoading = false;

  void showTopSnackBar(
    BuildContext context,
    String message, {
    bool isError = false,
  }) {
    ScaffoldMessenger.of(
      context,
    ).clearSnackBars(); // Hapus snackbar lama jika ada
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
        // Trik agar muncul di ATAS:
        // Margin bawah dibuat setinggi layar dikurangi offset (misal 130 pixel dari atas)
        margin: EdgeInsets.only(
          bottom: MediaQuery.of(context).size.height - 130,
          left: 16,
          right: 16,
        ),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> register() async {
    // --- GANTI VALIDASI LAMA DENGAN FUNGSI BARU ---

    if (nameController.text.isEmpty) {
      showTopSnackBar(context, 'Isi nama anda', isError: true);
      return;
    }
    if (usernameController.text.isEmpty) {
      showTopSnackBar(context, 'Isi username anda', isError: true);
      return;
    }
    if (passwordController.text.isEmpty) {
      showTopSnackBar(context, 'Isi password anda', isError: true);
      return;
    }
    if (passwordController.text.length < 8) {
      showTopSnackBar(context, 'Password minimal 8 karakter', isError: true);
      return;
    }
    if (passwordController.text != confirmPasswordController.text) {
      showTopSnackBar(context, 'Konfirmasi password tidak sama', isError: true);
      return;
    }

    setState(() => isLoading = true);

    try {
      final response = await http
          .post(
            Uri.parse('${ApiConfig.baseUrl}/api/register'),
            headers: ApiConfig.headers,
            body: json.encode({
              'name': nameController.text,
              'username': usernameController.text,
              'password': passwordController.text,
            }),
          )
          .timeout(const Duration(seconds: 10));

      final data = json.decode(response.body);

      setState(() => isLoading = false);

      if (data['success']) {
        // SUKSES
        showTopSnackBar(context, data['message']);
        Navigator.pushReplacementNamed(context, '/login');
      } else {
        // GAGAL DARI SERVER
        showTopSnackBar(context, data['message'], isError: true);
      }
    } catch (e) {
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Server sedang Maintenance')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(height: 48),

              // Ilustrasi (Tetap dikomentari sesuai kode asli)
              // Image.asset(
              //   'assets/images/register.png',
              //   height: 200,
              //   fit: BoxFit.contain,
              // ),
              SizedBox(height: 32),

              // Judul
              Text(
                'Create Account',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
              ),

              SizedBox(height: 8),

              // Subtitle
              Text(
                'Daftar untuk mendapatkan rekomendasi\n'
                'gaya pakaian terbaikmu',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: Colors.grey[700]),
              ),

              SizedBox(height: 32),

              // Nama
              TextField(
                controller: nameController,
                decoration: InputDecoration(
                  labelText: 'Nama',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(
                      color: Color(0xFFA79277),
                      width: 1.5,
                    ),
                  ),
                ),
              ),

              SizedBox(height: 16),

              // Username (Menggantikan Email, Desain Tetap)
              TextField(
                controller: usernameController,
                decoration: InputDecoration(
                  labelText: 'Username',
                  hintText: 'yourusername',
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

              // Password
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

              const SizedBox(height: 16),

              // Konfirmasi Password
              TextField(
                controller: confirmPasswordController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: 'Konfirmasi Password',
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

              const SizedBox(height: 28),

              // Button Register
              SizedBox(
                height: 52,
                child: ElevatedButton(
                  onPressed: isLoading ? null : () => register(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFFA79277),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          'Register',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),

              SizedBox(height: 24),

              // Login
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Sudah punya akun? ',
                    style: TextStyle(color: Colors.grey),
                  ),
                  GestureDetector(
                    onTap: () {
                      Navigator.pushReplacementNamed(context, '/login');
                    },
                    child: Text(
                      'Login',
                      style: TextStyle(
                        color: Color(0xFFA79277),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),

              SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}
