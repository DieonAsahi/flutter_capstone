import 'package:aplikasi/pages/loginpage.dart';
import 'package:flutter/material.dart';

class LandingPage extends StatelessWidget {
  const LandingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 40),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Gambar Ilustrasi
                Image.asset(
                  'assets/images/getstarted.png',
                  height: 250,
                  fit: BoxFit.contain,
                ),

                SizedBox(height: 32),

                // Judul Aplikasi
                Text(
                  'Stylo',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),

                SizedBox(height: 12),

                // Deskripsi Singkat
                Text(
                  'Dapatkan rekomendasi outfit yang sesuai dengan bentuk tubuhmu agar tampil lebih percaya diri setiap hari',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 15, color: Colors.grey[700]),
                ),

                SizedBox(height: 40),

                // Button Get Started
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: () {
                      // Navigator.pushReplacementNamed(context, '/login');
                      // Navigator.of(context).pushReplacement(
                      //   MaterialPageRoute(builder: (_) => LoginPage()),
                      // );
                      Navigator.of(
                        context,
                        rootNavigator: true,
                      ).pushReplacement(
                        MaterialPageRoute(builder: (_) => const LoginPage()),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFFA79277),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: Text(
                      'Get Started',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
