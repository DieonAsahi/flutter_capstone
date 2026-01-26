import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:aplikasi/services/api_config.dart';

class ExplorePage extends StatefulWidget {
  const ExplorePage({super.key});

  @override
  State<ExplorePage> createState() => _ExplorePageState();
}

class _ExplorePageState extends State<ExplorePage> {
  final Color primaryColor = const Color(0xFFA79277);
  List<dynamic> posts = [];
  bool isLoading = true;
  int? currentUserId;

  @override
  void initState() {
    super.initState();
    _loadUserAndFetchPosts();
  }

  // Ambil ID User dari SharedPreferences lalu ambil post
  Future<void> _loadUserAndFetchPosts() async {
    final prefs = await SharedPreferences.getInstance();
    currentUserId = prefs.getInt('user_id');
    if (currentUserId != null) {
      _fetchPosts();
    } else {
      // Jika user id null, stop loading
      setState(() => isLoading = false);
    }
  }

  // Mengambil semua postingan dari API /api/explore
  Future<void> _fetchPosts() async {
    // MODIFIKASI: Hanya tampilkan loading penuh jika list masih kosong
    if (posts.isEmpty) {
      setState(() => isLoading = true);
    }

    try {
      final response = await http.get(
        Uri.parse("${ApiConfig.baseUrl}/api/explore/$currentUserId"),

        headers: ApiConfig.headers,
      );
      if (response.statusCode == 200) {
        if (mounted) {
          setState(() {
            posts = jsonDecode(response.body);
            isLoading = false;
          });
        }
      } else {
        if (mounted) setState(() => isLoading = false);
      }
    } catch (e) {
      debugPrint("Error Fetching Explore: $e");
      if (mounted) setState(() => isLoading = false);
    }
  }

  // Fitur Like/Unlike
  Future<void> _toggleLike(int shareId, int index) async {
    try {
      final response = await http.post(
        Uri.parse("${ApiConfig.baseUrl}/api/share/like"),
        headers: ApiConfig.headers,
        body: jsonEncode({"user_id": currentUserId, "share_id": shareId}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (mounted) {
          setState(() {
            posts[index]['liked'] = data['liked'];
            // Update jumlah likes secara lokal agar responsif
            if (data['liked']) {
              posts[index]['total_likes']++;
            } else {
              posts[index]['total_likes']--;
            }
          });
        }
      }
    } catch (e) {
      debugPrint("Error Liking: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    // 1. Jika sedang loading awal & data kosong, tampilkan Spinner
    if (isLoading && posts.isEmpty) {
      return Scaffold(
        backgroundColor: Colors.white,
        appBar: _buildAppBar(),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    // 2. Tampilkan Halaman Utama dengan RefreshIndicator
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: _buildAppBar(),
      body: RefreshIndicator(
        onRefresh: _fetchPosts,
        color: primaryColor,
        child: posts.isEmpty
            // Jika data kosong (tapi sudah selesai loading), pakai LayoutBuilder + ScrollView
            // agar tetap bisa ditarik ke bawah untuk refresh
            ? LayoutBuilder(
                builder: (context, constraints) => SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: SizedBox(
                    height: constraints.maxHeight,
                    child: const Center(
                      child: Text("Belum ada outfit yang dibagikan"),
                    ),
                  ),
                ),
              )
            // Jika ada data, tampilkan ListView
            : ListView.builder(
                physics: const AlwaysScrollableScrollPhysics(),
                itemCount: posts.length,
                itemBuilder: (context, index) {
                  return _buildPost(index);
                },
              ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: const Text(
        'Jelajah',
        style: TextStyle(fontWeight: FontWeight.w600),
      ),
      backgroundColor: Colors.white,
      elevation: 0,
      centerTitle: true,
      foregroundColor: Colors.black,
    );
  }

  Widget _buildPost(int index) {
    final post = posts[index];
    final String imageUrl = "${ApiConfig.baseUrl}/${post['image_url']}";
    final String? userPhoto = post['profile_photo_url'];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ================= HEADER USER =================
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: primaryColor.withOpacity(0.2),
                backgroundImage: (userPhoto != null && userPhoto.isNotEmpty)
                    ? NetworkImage(
                        userPhoto.startsWith('http')
                            ? userPhoto
                            : "${ApiConfig.baseUrl}/$userPhoto",
                      )
                    : null,
                child: (userPhoto == null || userPhoto.isEmpty)
                    ? Text(
                        post['username'][0].toUpperCase(),
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      )
                    : null,
              ),
              const SizedBox(width: 10),
              Text(
                post['username'],
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),

        // ================= IMAGE OUTFIT =================
        GestureDetector(
          onDoubleTap: () =>
              _toggleLike(post['share_id'], index), // Double tap untuk like
          child: Image.network(
            imageUrl,
            width: double.infinity,
            height: 500, // Tinggi disesuaikan agar tidak terlalu memanjang
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) =>
                const Center(child: Icon(Icons.broken_image, size: 50)),
          ),
        ),

        // ================= INTERACTION BAR =================
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
          child: Row(
            children: [
              IconButton(
                icon: Icon(
                  post['liked'] == 1 || post['liked'] == true
                      ? Icons.favorite
                      : Icons.favorite_border,
                  color: post['liked'] == 1 || post['liked'] == true
                      ? Colors.red
                      : Colors.black,
                ),
                onPressed: () => _toggleLike(post['share_id'], index),
              ),
              Text(
                "${post['total_likes'] ?? 0} Suka",
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),

        // ================= CAPTION =================
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: RichText(
            text: TextSpan(
              style: const TextStyle(color: Colors.black, fontSize: 14),
              children: [
                TextSpan(
                  text: '${post['username']} ',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                TextSpan(text: post['caption'] ?? ''),
              ],
            ),
          ),
        ),

        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            "Dibagikan pada ${post['created_at'].toString().split(' ')[0]}",
            style: const TextStyle(color: Colors.grey, fontSize: 11),
          ),
        ),

        const SizedBox(height: 20),
        Divider(color: Colors.grey.shade300, thickness: 1),
      ],
    );
  }
}
