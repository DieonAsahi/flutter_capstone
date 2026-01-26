import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:aplikasi/services/api_config.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final TextEditingController _searchController = TextEditingController();
  List<dynamic> _onlineResults = [];
  bool _isLoading = false;
  bool _hasText = false;

  @override
  void initState() {
    super.initState();

    _searchController.addListener(() {
      setState(() {
        _hasText = _searchController.text.isNotEmpty;
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  final Set<String> _likedItems = {};

  // --- FUNGSI CARI ---
  Future<void> _doSearch(String keyword) async {
    if (keyword.isEmpty) return;
    setState(() => _isLoading = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getInt('user_id') ?? 1;

      // PERBAIKAN: Hapus .php dari URL
      final url = Uri.parse(
        "${ApiConfig.baseUrl}/api/wardrobe_action?action=search&keyword=$keyword&user_id=$userId",
      );

      final response = await http.get(url, headers: ApiConfig.headers);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data['status'] == true) {
          setState(() {
            _onlineResults = data['online']; // Ambil hasil online dari JSON

            // Cek status like
            _likedItems.clear();
            for (var item in _onlineResults) {
              if (item['is_liked'] == true || item['is_liked'] == 1) {
                _likedItems.add(item['item_name']);
              }
            }
          });
        }
      } else {
        print("Error Server: ${response.statusCode}");
      }
    } catch (e) {
      print("Error Search: $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // --- FUNGSI LIKE / FAVORIT ---
  Future<void> _toggleFavorite(dynamic item) async {
    String itemName = item['item_name'];

    setState(() {
      if (_likedItems.contains(itemName)) {
        _likedItems.remove(itemName);
      } else {
        _likedItems.add(itemName);
      }
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getInt('user_id') ?? 1;

      // PERBAIKAN: Hapus .php dari URL
      final url = Uri.parse(
        "${ApiConfig.baseUrl}/api/wardrobe_action?action=toggle_wishlist",
      );

      final response = await http.post(
        url,
        headers: ApiConfig.headers,
        body: jsonEncode({
          'user_id': userId,
          'item_name': itemName,
          'image_url': item['image_url'],
          'price': item['price'],
          'link': item['purchase_link'] ?? '',
        }),
      );

      final data = jsonDecode(response.body);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(data['message']),
            duration: const Duration(milliseconds: 600),
            backgroundColor: _likedItems.contains(itemName)
                ? Colors.green
                : Colors.red,
          ),
        );
      }
    } catch (e) {
      print("Gagal like: $e");
      setState(() {
        if (_likedItems.contains(itemName))
          _likedItems.remove(itemName);
        else
          _likedItems.add(itemName);
      });
    }
  }

  Future<void> _launchUrl(String urlString) async {
    if (urlString.isEmpty) return;
    final Uri url = Uri.parse(urlString);
    try {
      if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
        print('Gagal buka link');
      }
    } catch (e) {
      print('Error launch url: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            _buildSearchHeader(),
            Expanded(child: _buildBody()),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Container(
        height: 50,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade300, width: 1.5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _searchController,
                autofocus: false,
                decoration: InputDecoration(
                  hintText: "Misal: kemeja, celana...",
                  hintStyle: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 15,
                  ),
                  border: InputBorder.none,
                  isDense: true,
                ),
                onSubmitted: (val) => _doSearch(val),
              ),
            ),

            /// ✅ ICON TOGGLE (SEARCH ↔ SILANG)
            GestureDetector(
              onTap: () {
                if (_hasText) {
                  // Kalau ada teks -> jadi silang -> clear
                  setState(() {
                    _searchController.clear();
                    _onlineResults.clear(); // balik ke tampilan awal
                  });
                } else {
                  // Kalau kosong -> tombol search
                  _doSearch(_searchController.text);
                }
              },
              child: Icon(
                _hasText ? Icons.close : Icons.search,
                color: Colors.grey.shade600,
                size: 22,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // appBar: AppBar(
  //   backgroundColor: Colors.white,
  //   elevation: 0,
  //   iconTheme: const IconThemeData(color: Colors.black),
  //   title: TextField(
  //     controller: _searchController,
  //     autofocus: false, // Ubah false biar keyboard gak langsung muncul
  //     decoration: const InputDecoration(
  //       hintText: "Cari baju (misal: kemeja)...",
  //       border: InputBorder.none,
  //     ),
  //     onSubmitted: (val) => _doSearch(val),
  //   ),
  //   actions: [
  //     IconButton(
  //       icon: const Icon(Icons.search, color: Colors.grey),
  //       onPressed: () => _doSearch(_searchController.text),
  //     ),
  //   ],
  // ),
  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_onlineResults.isEmpty) {
      return const Center(
        child: Text(
          "Ketik nama pakaian untuk mencari...",
          style: TextStyle(color: Colors.grey, fontSize: 15),
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _onlineResults.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.65,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemBuilder: (ctx, i) => _searchCard(_onlineResults[i]),
    );
  }

  //     body: _isLoading
  //         ? const Center(child: CircularProgressIndicator())
  //         : _onlineResults.isEmpty
  //         ? const Center(child: Text("Ketik nama baju untuk mencari..."))
  //         : GridView.builder(
  //             padding: const EdgeInsets.all(16),
  //             itemCount: _onlineResults.length,
  //             gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
  //               crossAxisCount: 2,
  //               childAspectRatio: 0.65,
  //               crossAxisSpacing: 12,
  //               mainAxisSpacing: 12,
  //             ),
  //             itemBuilder: (ctx, i) => _searchCard(_onlineResults[i]),
  //           ),
  //   );
  // }

  Widget _searchCard(dynamic item) {
    bool isLiked = _likedItems.contains(item['item_name']);
    String imageUrl = item['image_url'];

    // Cek jika gambar lokal (bukan http), tambahkan base url
    if (!imageUrl.startsWith('http')) {
      imageUrl = "${ApiConfig.baseUrl}/$imageUrl";
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 4,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Stack(
              children: [
                Positioned.fill(
                  child: ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(12),
                    ),
                    child: Image.network(
                      imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (c, e, s) => const Center(
                        child: Icon(Icons.broken_image, color: Colors.grey),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: 5,
                  right: 5,
                  child: GestureDetector(
                    onTap: () => _toggleFavorite(item),
                    child: CircleAvatar(
                      backgroundColor: Colors.white,
                      radius: 16,
                      child: Icon(
                        isLiked ? Icons.favorite : Icons.favorite_border,
                        color: isLiked ? Colors.red : Colors.grey,
                        size: 20,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item['item_name'],
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
                Text(
                  "Rp ${item['price']}",
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFFA79277),
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  height: 32,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFA79277),
                    ),
                    onPressed: () {
                      _launchUrl(item['purchase_link'] ?? '');
                    },
                    child: const Text(
                      "Lihat",
                      style: TextStyle(color: Colors.white, fontSize: 12),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
