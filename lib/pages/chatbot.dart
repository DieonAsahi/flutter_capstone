import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:aplikasi/services/api_config.dart';

class ChatbotPage extends StatefulWidget {
  const ChatbotPage({super.key});

  @override
  State<ChatbotPage> createState() => _ChatbotPageState();
}

class _ChatbotPageState extends State<ChatbotPage> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  final Color primaryColor = const Color(0xFFA79277);
  bool _isLoading = false;

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

    setState(() {
      messages.add({"text": text, "isUser": true});
      _isLoading = true;
    });

    _controller.clear();
    _scrollToBottom();

    try {
      final response = await http
          .post(
            Uri.parse("${ApiConfig.baseUrl}/get_response"),
            headers: ApiConfig.headers,
            body: jsonEncode({'message': text}),
          )
          .timeout(const Duration(seconds: 20));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        String botReply = data['response'];
        String motion = data['motion'] ?? "Idle";

        setState(() {
          messages.add({"text": botReply, "isUser": false, "motion": motion});
        });
      } else {
        _showErrorReply("Server Error: ${response.statusCode}");
      }
    } catch (e) {
      _showErrorReply(
        "Server sedang maintenance. Coba lagi nanti ya 😊",
      );
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

      /// ✅ UI AppBar jadi putih seperti contoh
      appBar: AppBar(
        title: const Text(
          'StyloBot',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.black),
        foregroundColor: Colors.black,
      ),

      body: Column(
        children: [
          /// ================= CHAT LIST =================
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

          /// ✅ Loading kecil (tetap ada tapi lebih soft)
          if (_isLoading)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: SizedBox(
                height: 3,
                child: LinearProgressIndicator(
                  color: primaryColor,
                  backgroundColor: Colors.grey.shade200,
                ),
              ),
            ),

          /// ================= INPUT =================
          _buildInputArea(),
        ],
      ),
    );
  }

  /// ================= CHAT BUBBLE (SIMPLE) =================
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

  /// ================= INPUT AREA (SIMPLE LIKE CONTOH) =================
  Widget _buildInputArea() {
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 6,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _controller,
                decoration: InputDecoration(
                  hintText: 'Tanya soal outfit kamu...',
                  hintStyle: const TextStyle(color: Colors.grey, fontSize: 15),
                  filled: true,
                  fillColor: Colors.grey[100],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                ),
                onSubmitted: (_) => _sendMessage(),
              ),
            ),
            const SizedBox(width: 8),

            /// ✅ tombol send icon seperti contoh
            IconButton(
              onPressed: _sendMessage,
              icon: Icon(Icons.send, color: primaryColor),
            ),
          ],
        ),
      ),
    );
  }
}
