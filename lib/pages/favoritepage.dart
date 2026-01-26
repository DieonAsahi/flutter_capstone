// import 'package:flutter/material.dart';
// import 'package:http/http.dart' as http;
// import 'dart:convert';
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

//   // --- KONFIGURASI URL (GUNAKAN FLASK UNTUK SEMUA) ---
//   // Pastikan IP dan Port :5000 benar
//   final String baseUrl = "http://172.20.240.164:5000";

//   // State untuk My Outfit
//   List<dynamic> myOutfitItems = [];
//   bool isLoadingMyOutfit = true;
//   int? _selectedOutfitIndex;
//   bool _isSharing = false;

//   // State untuk Wishlist
//   List<dynamic> wishlistItems = [];
//   bool isLoadingWishlist = true;

//   @override
//   void initState() {
//     super.initState();
//     _tabController = TabController(length: 2, vsync: this);
//     _fetchMyOutfits();
//     _fetchWishlist();
//   }

//   // --- FUNGSI FETCH MY OUTFIT (PYTHON) ---
//   Future<void> _fetchMyOutfits() async {
//     if (myOutfitItems.isEmpty) {
//       setState(() => isLoadingMyOutfit = true);
//     }

//     try {
//       final prefs = await SharedPreferences.getInstance();
//       final userId = prefs.getInt('user_id');
//       if (userId == null) {
//         if (mounted) setState(() => isLoadingMyOutfit = false);
//         return;
//       }

//       final response = await http.get(
//         Uri.parse("$baseUrl/api/my-outfits/$userId"),
//       );
//       if (response.statusCode == 200) {
//         final data = jsonDecode(response.body);
//         if (data['success']) {
//           if (mounted) {
//             setState(() {
//               myOutfitItems = data['outfits'];
//               isLoadingMyOutfit = false;
//             });
//           }
//         }
//       } else {
//         if (mounted) setState(() => isLoadingMyOutfit = false);
//       }
//     } catch (e) {
//       debugPrint("Error Fetch My Outfit: $e");
//       if (mounted) {
//         setState(() => isLoadingMyOutfit = false);
//       }
//     }
//   }

//   // --- FUNGSI FETCH WISHLIST (SEKARANG VIA FLASK) ---
//   Future<void> _fetchWishlist() async {
//     if (wishlistItems.isEmpty) {
//       setState(() => isLoadingWishlist = true);
//     }

//     try {
//       final prefs = await SharedPreferences.getInstance();
//       final userId = prefs.getInt('user_id') ?? 1;

//       // PERBAIKAN: Gunakan baseUrl Flask & Endpoint yang benar
//       final url = Uri.parse(
//         "$baseUrl/api/wardrobe_action?action=get_favorites&user_id=$userId",
//       );

//       final response = await http.get(url);

//       if (response.statusCode == 200) {
//         final data = jsonDecode(response.body);
//         if (data['status'] == true) {
//           if (mounted) {
//             setState(() {
//               wishlistItems = data['data']; // Ambil data dari key 'data'
//               isLoadingWishlist = false;
//             });
//           }
//         } else {
//           if (mounted) setState(() => isLoadingWishlist = false);
//         }
//       } else {
//         debugPrint("Server Error: ${response.statusCode}");
//         if (mounted) setState(() => isLoadingWishlist = false);
//       }
//     } catch (e) {
//       debugPrint("Error wishlist: $e");
//       if (mounted) setState(() => isLoadingWishlist = false);
//     }
//   }

//   // --- FUNGSI BUKA LINK ---
//   Future<void> _launchUrl(String? urlString) async {
//     if (urlString == null || urlString.isEmpty) return;
//     try {
//       if (!await launchUrl(
//         Uri.parse(urlString),
//         mode: LaunchMode.externalApplication,
//       )) {
//         debugPrint("Gagal buka link");
//       }
//     } catch (e) {
//       debugPrint("Error launch url: $e");
//     }
//   }

//   // --- FUNGSI SHARE ---
//   void _showShareBottomSheet(Map<String, dynamic> outfit) {
//     TextEditingController captionController = TextEditingController();

//     showModalBottomSheet(
//       context: context,
//       isScrollControlled: true,
//       shape: const RoundedRectangleBorder(
//         borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
//       ),
//       builder: (context) => Padding(
//         padding: EdgeInsets.only(
//           bottom: MediaQuery.of(context).viewInsets.bottom,
//           left: 20,
//           right: 20,
//           top: 20,
//         ),
//         child: Column(
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             const Text(
//               "Share Outfit ke Jelajah",
//               style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
//             ),
//             const SizedBox(height: 15),
//             ClipRRect(
//               borderRadius: BorderRadius.circular(12),
//               child: Image.network(
//                 "$baseUrl/${outfit['result_image_url']}",
//                 height: 200,
//                 fit: BoxFit.cover,
//                 errorBuilder: (context, error, stackTrace) =>
//                     const Icon(Icons.broken_image, size: 50),
//               ),
//             ),
//             const SizedBox(height: 15),
//             TextField(
//               controller: captionController,
//               decoration: const InputDecoration(
//                 hintText: "Masukkan caption...",
//                 border: OutlineInputBorder(),
//               ),
//               maxLines: 3,
//             ),
//             const SizedBox(height: 15),
//             SizedBox(
//               width: double.infinity,
//               height: 50,
//               child: ElevatedButton(
//                 style: ElevatedButton.styleFrom(backgroundColor: primaryColor),
//                 onPressed: () {
//                   Navigator.pop(context);
//                   _submitShare(
//                     outfit['result_image_url'],
//                     captionController.text,
//                   );
//                 },
//                 child: const Text(
//                   "Share Sekarang",
//                   style: TextStyle(color: Colors.white),
//                 ),
//               ),
//             ),
//             const SizedBox(height: 20),
//           ],
//         ),
//       ),
//     );
//   }

//   Future<void> _submitShare(String imageUrl, String caption) async {
//     setState(() => _isSharing = true);
//     try {
//       final prefs = await SharedPreferences.getInstance();
//       final userId = prefs.getInt('user_id');

//       final response = await http.post(
//         Uri.parse("$baseUrl/api/share"),
//         headers: {"Content-Type": "application/json"},
//         body: jsonEncode({
//           "user_id": userId,
//           "image_url": imageUrl,
//           "caption": caption,
//         }),
//       );

//       if (response.statusCode == 200) {
//         if (mounted) {
//           ScaffoldMessenger.of(context).showSnackBar(
//             const SnackBar(content: Text("Berhasil dibagikan ke Jelajah!")),
//           );
//           setState(() {
//             _selectedOutfitIndex = null;
//           });
//         }
//       }
//     } catch (e) {
//       debugPrint("Gagal share: $e");
//     } finally {
//       if (mounted) setState(() => _isSharing = false);
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
//           indicatorWeight: 3,
//           tabs: const [
//             Tab(text: 'My Outfit'),
//             Tab(text: 'Wishlist'),
//           ],
//         ),
//       ),
//       body: Stack(
//         children: [
//           TabBarView(
//             controller: _tabController,
//             children: [_buildMyOutfitGrid(), _buildWishlistGrid()],
//           ),

//           // Button Share (Hanya muncul di Tab 0)
//           if (_selectedOutfitIndex != null && _tabController.index == 0)
//             Positioned(
//               bottom: 30,
//               right: 20,
//               child: FloatingActionButton.extended(
//                 onPressed: () =>
//                     _showShareBottomSheet(myOutfitItems[_selectedOutfitIndex!]),
//                 backgroundColor: primaryColor,
//                 icon: const Icon(Icons.share, color: Colors.white),
//                 label: const Text(
//                   "Share Outfit",
//                   style: TextStyle(color: Colors.white),
//                 ),
//               ),
//             ),

//           if (_isSharing) const Center(child: CircularProgressIndicator()),
//         ],
//       ),
//     );
//   }

//   // --- BUILDER UNTUK MY OUTFIT ---
//   Widget _buildMyOutfitGrid() {
//     if (isLoadingMyOutfit && myOutfitItems.isEmpty) {
//       return const Center(child: CircularProgressIndicator());
//     }

//     return RefreshIndicator(
//       color: primaryColor,
//       onRefresh: _fetchMyOutfits,
//       child: myOutfitItems.isEmpty
//           ? LayoutBuilder(
//               builder: (context, constraints) => SingleChildScrollView(
//                 physics: const AlwaysScrollableScrollPhysics(),
//                 child: SizedBox(
//                   height: constraints.maxHeight,
//                   child: const Center(
//                     child: Text("Belum ada outfit tersimpan"),
//                   ),
//                 ),
//               ),
//             )
//           : GridView.builder(
//               padding: const EdgeInsets.all(16),
//               physics: const AlwaysScrollableScrollPhysics(),
//               itemCount: myOutfitItems.length,
//               gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
//                 crossAxisCount: 2,
//                 mainAxisSpacing: 16,
//                 crossAxisSpacing: 16,
//                 childAspectRatio: 0.7,
//               ),
//               itemBuilder: (context, index) {
//                 final item = myOutfitItems[index];
//                 bool isSelected = _selectedOutfitIndex == index;

//                 return GestureDetector(
//                   onLongPress: () {
//                     setState(() => _selectedOutfitIndex = index);
//                   },
//                   onTap: () {
//                     setState(
//                       () => _selectedOutfitIndex = (isSelected) ? null : index,
//                     );
//                   },
//                   child: Container(
//                     decoration: BoxDecoration(
//                       color: Colors.white,
//                       borderRadius: BorderRadius.circular(12),
//                       border: Border.all(
//                         color: isSelected ? primaryColor : Colors.transparent,
//                         width: 3,
//                       ),
//                       boxShadow: [
//                         BoxShadow(
//                           color: Colors.black.withOpacity(0.05),
//                           blurRadius: 5,
//                           offset: const Offset(0, 2),
//                         ),
//                       ],
//                     ),
//                     child: Column(
//                       crossAxisAlignment: CrossAxisAlignment.start,
//                       children: [
//                         Expanded(
//                           child: ClipRRect(
//                             borderRadius: const BorderRadius.vertical(
//                               top: Radius.circular(12),
//                             ),
//                             child: Image.network(
//                               "$baseUrl/${item['result_image_url']}",
//                               width: double.infinity,
//                               fit: BoxFit.cover,
//                               errorBuilder: (context, error, stackTrace) =>
//                                   const Center(child: Icon(Icons.broken_image)),
//                             ),
//                           ),
//                         ),
//                         Padding(
//                           padding: const EdgeInsets.all(10),
//                           child: Column(
//                             crossAxisAlignment: CrossAxisAlignment.start,
//                             children: [
//                               Text(
//                                 item['outfit_name'] ?? 'Outfit',
//                                 style: const TextStyle(
//                                   fontWeight: FontWeight.bold,
//                                 ),
//                                 maxLines: 1,
//                               ),
//                               const Text(
//                                 "Custom AI",
//                                 style: TextStyle(
//                                   fontSize: 11,
//                                   color: Colors.grey,
//                                 ),
//                               ),
//                             ],
//                           ),
//                         ),
//                       ],
//                     ),
//                   ),
//                 );
//               },
//             ),
//     );
//   }

//   // --- BUILDER UNTUK WISHLIST (FIXED) ---
//   Widget _buildWishlistGrid() {
//     if (isLoadingWishlist && wishlistItems.isEmpty) {
//       return const Center(child: CircularProgressIndicator());
//     }

//     return RefreshIndicator(
//       color: primaryColor,
//       onRefresh: _fetchWishlist,
//       child: wishlistItems.isEmpty
//           ? LayoutBuilder(
//               builder: (context, constraints) => SingleChildScrollView(
//                 physics: const AlwaysScrollableScrollPhysics(),
//                 child: SizedBox(
//                   height: constraints.maxHeight,
//                   child: const Center(
//                     child: Text(
//                       'Belum ada item favorit',
//                       style: TextStyle(color: Colors.grey),
//                     ),
//                   ),
//                 ),
//               ),
//             )
//           : GridView.builder(
//               padding: const EdgeInsets.all(16),
//               physics: const AlwaysScrollableScrollPhysics(),
//               itemCount: wishlistItems.length,
//               gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
//                 crossAxisCount: 2,
//                 mainAxisSpacing: 16,
//                 crossAxisSpacing: 16,
//                 childAspectRatio: 0.7,
//               ),
//               itemBuilder: (context, index) {
//                 final item = wishlistItems[index];

//                 // PERBAIKAN LOGIKA GAMBAR
//                 // Cek apakah URL online (http) atau lokal (static/...)
//                 String imageUrl = item['image_url'] ?? '';
//                 if (imageUrl.isNotEmpty && !imageUrl.startsWith('http')) {
//                   imageUrl = "$baseUrl/$imageUrl";
//                 }

//                 return Container(
//                   decoration: BoxDecoration(
//                     color: Colors.white,
//                     borderRadius: BorderRadius.circular(10),
//                     border: Border.all(color: Colors.grey.shade200),
//                     boxShadow: [
//                       BoxShadow(
//                         color: Colors.grey.withOpacity(0.1),
//                         blurRadius: 5,
//                       ),
//                     ],
//                   ),
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       Expanded(
//                         child: ClipRRect(
//                           borderRadius: const BorderRadius.vertical(
//                             top: Radius.circular(10),
//                           ),
//                           child: Image.network(
//                             imageUrl,
//                             width: double.infinity,
//                             fit: BoxFit.cover,
//                             errorBuilder: (c, e, s) =>
//                                 const Icon(Icons.broken_image),
//                           ),
//                         ),
//                       ),
//                       Padding(
//                         padding: const EdgeInsets.all(10),
//                         child: Column(
//                           crossAxisAlignment: CrossAxisAlignment.start,
//                           children: [
//                             Text(
//                               item['item_name'] ?? 'Item',
//                               maxLines: 1,
//                               overflow: TextOverflow.ellipsis,
//                               style: const TextStyle(
//                                 fontWeight: FontWeight.w600,
//                                 fontSize: 13,
//                               ),
//                             ),
//                             const SizedBox(height: 4),
//                             Text(
//                               "Rp ${item['price']}",
//                               style: TextStyle(
//                                 fontSize: 12,
//                                 color: primaryColor,
//                                 fontWeight: FontWeight.bold,
//                               ),
//                             ),
//                             const SizedBox(height: 8),
//                             SizedBox(
//                               width: double.infinity,
//                               height: 30,
//                               child: ElevatedButton(
//                                 style: ElevatedButton.styleFrom(
//                                   backgroundColor: primaryColor,
//                                 ),
//                                 onPressed: () => _launchUrl(item['link'] ?? ''),
//                                 child: const Text(
//                                   "Beli Lagi",
//                                   style: TextStyle(
//                                     fontSize: 11,
//                                     color: Colors.white,
//                                   ),
//                                 ),
//                               ),
//                             ),
//                           ],
//                         ),
//                       ),
//                     ],
//                   ),
//                 );
//               },
//             ),
//     );
//   }
// }