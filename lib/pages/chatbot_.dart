import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_markdown/flutter_markdown.dart'; // Pastikan sudah add di pubspec.yaml

class ChatbotPage extends StatefulWidget {
  const ChatbotPage({super.key});

  @override
  State<ChatbotPage> createState() => _ChatbotPageState();
}

class _ChatbotPageState extends State<ChatbotPage> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  // ✅ IP ADDRESS DIKEMBALIKAN SESUAI PERMINTAAN (10.xxxx)
  final String _baseUrl = "http://172.20.240.164:5000/get_response";

  final Color primaryColor = const Color(0xFFA79277);
  bool _isLoading = false;

  // List pesan menampung text, isUser, dan motion
  List<Map<String, dynamic>> messages = [
    {
      "text": "Hai 👋 Aku Mao!\nAku bisa bantu rekomendasi outfit kamu ✨",
      "isUser": false,
      "motion": "Idle",
    },
  ];

  Future<void> _sendMessage() async {
    String text = _controller.text.trim();
    if (text.isEmpty) return;

    // 1. Tampilkan pesan user
    setState(() {
      messages.add({"text": text, "isUser": true});
      _isLoading = true;
    });

    _controller.clear();
    _scrollToBottom();

    try {
      // 2. Kirim ke Server Flask
      final response = await http
          .post(
            Uri.parse(_baseUrl),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'message': text}),
          )
          .timeout(
            const Duration(seconds: 20),
          ); // Timeout diperpanjang sedikit jaga-jaga lambat

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        // 3. Ambil data response & motion dari JSON Python
        String botReply = data['response'];
        String motion = data['motion'] ?? "Idle"; // Default ke Idle jika null

        // Debug: Cek di console terminal
        print("Bot Reply: $botReply");
        print("Motion: $motion");

        setState(() {
          messages.add({
            "text": botReply,
            "isUser": false,
            "motion": motion, // Simpan motion ini
          });
        });
      } else {
        _showErrorReply("Server Error: ${response.statusCode}");
      }
    } catch (e) {
      _showErrorReply(
        "Gagal terhubung ke $_baseUrl\nPastikan Laptop & HP di Wi-Fi yang sama.",
      );
      print("Error Connection: $e");
    } finally {
      setState(() => _isLoading = false);
      _scrollToBottom();
    }
  }

  void _showErrorReply(String msg) {
    setState(() {
      messages.add({"text": msg, "isUser": false});
    });
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'StyloBot',
          style: TextStyle(fontWeight: FontWeight.w600, color: Colors.white),
        ),
        backgroundColor: primaryColor,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Column(
        children: [
          // ================= CHAT LIST =================
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: messages.length,
              itemBuilder: (context, index) {
                final msg = messages[index];
                return _buildChatBubble(
                  text: msg['text'],
                  isUser: msg['isUser'],
                );
              },
            ),
          ),

          // Loading bar saat menunggu jawaban
          if (_isLoading)
            LinearProgressIndicator(
              color: primaryColor,
              backgroundColor: Colors.white,
            ),

          // ================= INPUT AREA =================
          _buildInputArea(),
        ],
      ),
    );
  }

  // ================= CHAT BUBBLE (DENGAN MARKDOWN) =================
  Widget _buildChatBubble({required String text, required bool isUser}) {
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        decoration: BoxDecoration(
          color: isUser ? primaryColor : Colors.grey[200],
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isUser ? 16 : 0),
            bottomRight: Radius.circular(isUser ? 0 : 16),
          ),
        ),
        // Logic: Jika User pakai Text biasa, Jika Bot pakai Markdown agar rapi
        child: isUser
            ? Text(
                text,
                style: const TextStyle(color: Colors.white, fontSize: 14),
              )
            : MarkdownBody(
                data: text,
                styleSheet: MarkdownStyleSheet(
                  p: const TextStyle(color: Colors.black87, fontSize: 14),
                  strong: TextStyle(
                    color: primaryColor,
                    fontWeight: FontWeight.bold,
                  ),
                  listBullet: const TextStyle(color: Colors.black87),
                ),
              ),
      ),
    );
  }

  // ================= INPUT AREA =================
  Widget _buildInputArea() {
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 5,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _controller,
                style: const TextStyle(fontSize: 14),
                decoration: InputDecoration(
                  hintText: 'Tanya outfit...',
                  hintStyle: TextStyle(color: Colors.grey[400]),
                  filled: true,
                  fillColor: Colors.grey[100],
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 10,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30),
                    borderSide: BorderSide.none,
                  ),
                ),
                onSubmitted: (_) => _sendMessage(),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              decoration: BoxDecoration(
                color: primaryColor,
                shape: BoxShape.circle,
              ),
              child: IconButton(
                onPressed: _sendMessage,
                icon: const Icon(
                  Icons.send_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
