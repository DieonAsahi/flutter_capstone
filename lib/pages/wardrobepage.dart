import 'package:aplikasi/pages/addclothes.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:aplikasi/services/api_config.dart';

class WardrobePage extends StatefulWidget {
  const WardrobePage({super.key});

  @override
  State<WardrobePage> createState() => _WardrobePageState();
}

class _WardrobePageState extends State<WardrobePage> {
  final Color primaryColor = const Color(0xFFA79277);
  // IP ADDRESS (Sesuaikan dengan laptop)

  // ================== MAPPING HELPERS ==================
  String mapCategory(String dbCategory) {
    switch (dbCategory.toLowerCase()) {
      case 'shirt':
        return 'Kemeja';
      case 'tshirt':
        return 'Kaos';
      case 'jacket':
        return 'Jaket';
      case 'pants':
        return 'Celana';
      case 'dress':
        return 'Dress';
      default:
        return dbCategory;
    }
  }

  String mapStyle(String dbStyle) {
    switch (dbStyle.toLowerCase()) {
      case 'casual':
        return 'Casual';
      case 'formal':
        return 'Formal';
      case 'sport':
        return 'Sport';
      default:
        return dbStyle;
    }
  }

  String selectedStyle = 'Casual';
  String selectedCategory = 'Semua';

  final List<String> styles = ['Formal', 'Casual', 'Sport'];
  List<String> categories = ['Semua'];
  List<Map<String, dynamic>> clothes = [];
  bool isLoading = true;

  // --- FETCH DATA ---
  Future<void> fetchWardrobe() async {
    setState(() => isLoading = true);
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getInt('user_id');

    final response = await http.get(
      Uri.parse(
        '${ApiConfig.baseUrl}/api/wardrobe/$userId?style=${selectedStyle.toLowerCase()}',
      ),
    );

    final data = jsonDecode(response.body);

    if (data['success']) {
      setState(() {
        clothes = (data['items'] as List).map((item) {
          return {
            'id': item['item_id'], // PENTING: Simpan ID untuk hapus
            'name': item['item_name'],
            'style': mapStyle(item['style']),
            'category': mapCategory(item['category_name'] ?? ''),
            'image': '${ApiConfig.baseUrl}/${item['image_url']}',
          };
        }).toList();

        categories = [
          'Semua',
          ...((data['categories'] ?? []) as List).map((c) => mapCategory(c)),
        ];
        isLoading = false;
      });
    } else {
      setState(() => isLoading = false);
    }
  }

  // --- HAPUS BAJU ---
  Future<void> _deleteItem(int id) async {
    // Konfirmasi Dialog
    bool confirm =
        await showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text("Hapus Baju?"),
            content: const Text("Baju ini akan dihapus permanen dari lemari."),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text("Batal", style: TextStyle(color: Colors.black)),
              ),
              TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text("Hapus", style: TextStyle(color: Colors.red)),
              ),
            ],
          ),
        ) ??
        false;

    if (!confirm) return;

    try {
      // Di dalam fungsi _deleteItem
      final response = await http.post(
        Uri.parse("${ApiConfig.baseUrl}/api/delete/wardrobe"),
        // TAMBAHKAN LINE INI
        headers: ApiConfig.headers
          ..addAll({"Content-Type": "application/json"}),
        body: jsonEncode({"id": id}),
      );

      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data['success'] == true) {
        Navigator.pop(context); // Tutup dialog detail gambar
        fetchWardrobe(); // Refresh list
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("Baju berhasil dihapus")));
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Gagal: ${data['message']}")));
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error: $e")));
    }
  }

  // --- CARD ITEM ---
  Widget _buildClothesCard(BuildContext context, Map<String, dynamic> item) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () {
                // --- DIALOG FULL SCREEN + HAPUS ---
                showDialog(
                  context: context,
                  builder: (ctx) => Dialog(
                    backgroundColor: Colors.transparent,
                    insetPadding: const EdgeInsets.all(10),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // Gambar
                        InteractiveViewer(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.network(
                              item['image'],
                              fit: BoxFit.contain,
                            ),
                          ),
                        ),

                        // Tombol Tutup (Kanan Atas)
                        Positioned(
                          top: 10,
                          right: 10,
                          child: CircleAvatar(
                            backgroundColor: Colors.black54,
                            child: IconButton(
                              icon: const Icon(
                                Icons.close,
                                color: Colors.white,
                              ),
                              onPressed: () => Navigator.pop(ctx),
                            ),
                          ),
                        ),

                        // Tombol Hapus (Kanan Bawah)
                        Positioned(
                          bottom: 20,
                          right: 20,
                          child: FloatingActionButton(
                            backgroundColor: Colors.red,
                            mini: true,
                            onPressed: () => _deleteItem(item['id']),
                            child: const Icon(
                              Icons.delete,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(10),
                ),
                child: Image.network(
                  item['image'],
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (c, e, s) => const Icon(Icons.broken_image),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(10),
            child: Text(
              item['name'] ?? 'Tanpa Nama',
              style: const TextStyle(fontWeight: FontWeight.w600),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    fetchWardrobe();
  }

  @override
  Widget build(BuildContext context) {
    final filteredClothes = clothes.where((item) {
      final matchStyle = item['style'] == selectedStyle;
      final matchCategory = selectedCategory == 'Semua'
          ? true
          : item['category'] == selectedCategory;
      return matchStyle && matchCategory;
    }).toList();

    return DefaultTabController(
      length: styles.length,
      initialIndex: 1, // Default ke Casual
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          title: const Text(
            'Lemari',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          backgroundColor: Colors.white,
          elevation: 0,
          centerTitle: true,
          foregroundColor: Colors.black,
        ),
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // TAB STYLE
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TabBar(
                labelColor: primaryColor,
                unselectedLabelColor: Colors.grey,
                indicatorColor: primaryColor,
                indicatorWeight: 3,
                onTap: (index) {
                  setState(() {
                    selectedStyle = styles[index];
                    selectedCategory = 'Semua';
                  });
                  fetchWardrobe();
                },
                tabs: styles.map((style) => Tab(text: style)).toList(),
              ),
            ),
            const SizedBox(height: 16),

            // KATEGORI FILTER
            SizedBox(
              height: 40,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: categories.length,
                itemBuilder: (context, index) {
                  final category = categories[index];
                  final isSelected = selectedCategory == category;
                  return GestureDetector(
                    onTap: () => setState(() => selectedCategory = category),
                    child: Container(
                      margin: const EdgeInsets.only(right: 10),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? primaryColor.withOpacity(0.2)
                            : Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isSelected
                              ? primaryColor
                              : Colors.grey.shade300,
                        ),
                      ),
                      child: Text(
                        category,
                        style: TextStyle(
                          color: isSelected ? primaryColor : Colors.black,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 20),

            // GRID LEMARI
            Expanded(
              child: isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : filteredClothes.isEmpty
                  ? const Center(child: Text("Belum ada baju di kategori ini"))
                  : GridView.builder(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            mainAxisSpacing: 16,
                            crossAxisSpacing: 16,
                            childAspectRatio: 0.7,
                          ),
                      itemCount: filteredClothes.length,
                      itemBuilder: (context, index) =>
                          _buildClothesCard(context, filteredClothes[index]),
                    ),
            ),
          ],
        ),

        // FAB ADD CLOTHES
        floatingActionButton: FloatingActionButton(
          backgroundColor: primaryColor,
          onPressed: () async {
            final result = await Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const AddClothPage()),
            );
            if (result == true) fetchWardrobe();
          },
          child: const Icon(Icons.camera_alt, color: Colors.white),
        ),
      ),
    );
  }
}
