import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:aplikasi/services/api_config.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FeedbackPage extends StatefulWidget {
  const FeedbackPage({super.key});

  @override
  State<FeedbackPage> createState() => _FeedbackPageState();
}

class _FeedbackPageState extends State<FeedbackPage> {
  final Color primaryColor = const Color(0xFFA79277);
  final TextEditingController feedbackController = TextEditingController();

  int rating = 0;
  // Di dalam _FeedbackPageState:
  void _submitFeedback() async {
    if (rating == 0 || feedbackController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Mohon beri rating dan ulasan")),
      );
      return;
    }

    // AMBIL ID DARI STORAGE, JANGAN DI-HARDCODE 8
    final prefs = await SharedPreferences.getInstance();
    final int? currentUserId = prefs.getInt('user_id');

    if (currentUserId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Sesi berakhir, silakan login kembali")),
      );
      return;
    }

    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/api/feedback/submit'),
        headers: ApiConfig.headers,
        body: jsonEncode({
          "user_id": currentUserId,
          "message": feedbackController.text,
          "rating": rating,
        }),
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Terima kasih atas feedback Anda ❤️")),
        );
        Future.delayed(const Duration(milliseconds: 600), () {
          Navigator.pop(context);
        });
      } else {
        throw Exception("Gagal mengirim feedback");
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Terjadi kesalahan: $e")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,

      appBar: AppBar(
        title: const Text(
          "Feedback Pengguna",
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black,
      ),

      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// ================= HEADER =================
            const SizedBox(height: 16),
            const Text(
              "Bagaimana pengalamanmu menggunakan aplikasi ini?",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),

            const SizedBox(height: 16),

            /// ================= RATING =================
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (index) {
                return IconButton(
                  onPressed: () {
                    setState(() {
                      rating = index + 1;
                    });
                  },
                  icon: Icon(
                    Icons.star,
                    size: 36,
                    color: index < rating ? Colors.amber : Colors.grey.shade300,
                  ),
                );
              }),
            ),

            const SizedBox(height: 8),

            Center(
              child: Text(
                rating == 0 ? "Beri rating" : "$rating dari 5",
                style: TextStyle(color: Colors.grey.shade600),
              ),
            ),

            const SizedBox(height: 24),

            /// ================= INPUT FEEDBACK =================
            TextField(
              controller: feedbackController,
              maxLines: 5,
              decoration: InputDecoration(
                hintText: "Tulis ulasan atau saran kamu di sini...",
                filled: true,
                fillColor: Colors.grey.shade100,
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: primaryColor),
                ),
              ),
            ),

            const SizedBox(height: 32),

            /// ================= BUTTON =================
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _submitFeedback,
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: const Text(
                  "Kirim Feedback",
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
    );
  }
}
