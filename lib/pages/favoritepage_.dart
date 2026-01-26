// import 'dart:convert';
// import 'package:flutter/material.dart';
// import 'package:http/http.dart' as http;
// import 'package:shared_preferences/shared_preferences.dart';
// import 'package:url_launcher/url_launcher.dart';

// class FavoritePage extends StatefulWidget {
//   const FavoritePage({super.key});

//   @override
//   State<FavoritePage> createState() => _FavoritePageState();
// }

// class _FavoritePageState extends State<FavoritePage>
//     with SingleTickerProviderStateMixin {
//   late TabController _tabController;
//   final Color primaryColor = const Color(0xFFA79277);

//   List<dynamic> _wishlistItems = [];
//   bool _isLoading = true;

//   // ⚠️ GANTI IP LAPTOP KAMU DI SINI
//   final String _baseUrl = "http://172.20.240.164:5000/swipeer_api";

//   @override
//   void initState() {
//     super.initState();
//     _tabController = TabController(length: 2, vsync: this);
//     _fetchWishlist(); // Ambil data saat halaman dibuka
//   }

//   Future<void> _fetchWishlist() async {
//     try {
//       final prefs = await SharedPreferences.getInstance();
//       final userId = prefs.getInt('user_id') ?? 1;

//       // Panggil API get_favorites
//       final url = Uri.parse(
//         "$_baseUrl/api/wardrobe_action.php?action=get_favorites&user_id=$userId",
//       );
//       final response = await http.get(url);
//       final data = jsonDecode(response.body);

//       if (data['status'] == true) {
//         setState(() {
//           _wishlistItems = data['data'];
//           _isLoading = false;
//         });
//       } else {
//         setState(() => _isLoading = false);
//       }
//     } catch (e) {
//       print("Error wishlist: $e");
//       setState(() => _isLoading = false);
//     }
//   }

//   Future<void> _launchUrl(String urlString) async {
//     if (urlString.isEmpty) return;
//     if (!await launchUrl(
//       Uri.parse(urlString),
//       mode: LaunchMode.externalApplication,
//     )) {
//       print("Gagal buka link");
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Colors.white,
//       appBar: AppBar(
//         title: const Text(
//           'Favorit',
//           style: TextStyle(fontWeight: FontWeight.w600),
//         ),
//         centerTitle: true,
//         backgroundColor: Colors.white,
//         elevation: 0,
//         foregroundColor: Colors.black,
//         bottom: TabBar(
//           controller: _tabController,
//           indicatorColor: primaryColor,
//           labelColor: primaryColor,
//           unselectedLabelColor: Colors.grey,
//           tabs: const [
//             Tab(text: 'Wishlist (Online)'),
//             Tab(text: 'My Outfit (Lemari)'), // Placeholder
//           ],
//         ),
//       ),
//       body: TabBarView(
//         controller: _tabController,
//         children: [
//           _buildWishlistGrid(), // Tampilkan data asli di tab pertama
//           const Center(child: Text("Fitur Lemari segera hadir!")),
//         ],
//       ),
//     );
//   }

//   Widget _buildWishlistGrid() {
//     if (_isLoading) return const Center(child: CircularProgressIndicator());
//     if (_wishlistItems.isEmpty)
//       return const Center(
//         child: Text(
//           'Belum ada item favorit',
//           style: TextStyle(color: Colors.grey),
//         ),
//       );

//     return GridView.builder(
//       padding: const EdgeInsets.all(16),
//       itemCount: _wishlistItems.length,
//       gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
//         crossAxisCount: 2,
//         mainAxisSpacing: 16,
//         crossAxisSpacing: 16,
//         childAspectRatio: 0.7,
//       ),
//       itemBuilder: (context, index) {
//         final item = _wishlistItems[index];
//         return Container(
//           decoration: BoxDecoration(
//             color: Colors.white,
//             borderRadius: BorderRadius.circular(10),
//             border: Border.all(color: Colors.grey.shade200),
//             boxShadow: [
//               BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 5),
//             ],
//           ),
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               Expanded(
//                 child: ClipRRect(
//                   borderRadius: const BorderRadius.vertical(
//                     top: Radius.circular(10),
//                   ),
//                   child: Image.network(
//                     item['image_url'],
//                     width: double.infinity,
//                     fit: BoxFit.cover,
//                     errorBuilder: (c, e, s) => const Icon(Icons.broken_image),
//                   ),
//                 ),
//               ),
//               Padding(
//                 padding: const EdgeInsets.all(10),
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     Text(
//                       item['item_name'],
//                       maxLines: 1,
//                       overflow: TextOverflow.ellipsis,
//                       style: const TextStyle(
//                         fontWeight: FontWeight.w600,
//                         fontSize: 13,
//                       ),
//                     ),
//                     const SizedBox(height: 4),
//                     Text(
//                       "Rp ${item['price']}",
//                       style: TextStyle(
//                         fontSize: 12,
//                         color: primaryColor,
//                         fontWeight: FontWeight.bold,
//                       ),
//                     ),
//                     const SizedBox(height: 8),
//                     SizedBox(
//                       width: double.infinity,
//                       height: 30,
//                       child: ElevatedButton(
//                         style: ElevatedButton.styleFrom(
//                           backgroundColor: primaryColor,
//                         ),
//                         onPressed: () => _launchUrl(item['link'] ?? ''),
//                         child: const Text(
//                           "Beli Lagi",
//                           style: TextStyle(fontSize: 11, color: Colors.white),
//                         ),
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//             ],
//           ),
//         );
//       },
//     );
//   }
// }
