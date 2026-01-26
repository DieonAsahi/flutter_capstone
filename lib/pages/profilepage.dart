import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:url_launcher/url_launcher.dart';
import 'package:aplikasi/services/api_config.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage>
    with SingleTickerProviderStateMixin {
  final Color primaryColor = const Color(0xFFA79277);
  // GANTI IP INI SESUAI IP LAPTOP

  late TabController _tabController;

  // --- STATUS PROFIL ---
  String name = "Memuat...";
  String username = "@memuat";
  String gender = "Pengguna";
  String? photoUrl;
  String? bio;

  // Statistik
  String postsCount = "0";
  String outfitCount = "0";
  String favCount = "0";

  // --- DATA DAFTAR ---
  List<dynamic> postItems = [];
  List<dynamic> myOutfitItems = [];
  List<dynamic> wishlistItems = [];

  bool isLoadingPosts = true;
  bool isLoadingMyOutfit = true;
  bool isLoadingWishlist = true;

  // --- STATUS PILIHAN ---
  int? _selectedIndex;
  bool _isProcessing = false;

  // --- FUNGSI REFRESH OTOMATIS ---
  void _refreshAllData() {
    _fetchUserProfile();
    _fetchUserPosts();
    _fetchMyOutfits();
    _fetchWishlist();
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);

    // Pendengar: Reset pilihan saat tab berpindah
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) {
        setState(() {
          _selectedIndex = null;
        });
      }
    });

    _refreshAllData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // ==========================================
  // 1. AMBIL DATA
  // ==========================================
  Future<void> _fetchUserProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getInt('user_id');

    // Ambil data awal dari memori HP biar nggak kedip kosong
    setState(() {
      name = prefs.getString('name') ?? "Siapakah kamu ?";
      username = prefs.getString('username') ?? "username";
      bio = prefs.getString('bio') ?? ""; // Load bio dari lokal
      if (!username.startsWith('@')) username = "@$username";
      _processPhotoUrl(prefs.getString('photo_url'));
      _processGender(prefs.getString('gender'));
    });

    if (userId == null) return;

    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/api/user/$userId/profile'),
        headers: ApiConfig.headers,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && mounted) {
          setState(() {
            name = data['name'] ?? name;
            username = (data['username'] ?? username).startsWith('@')
                ? data['username']
                : "@${data['username']}";

            // AMBIL BIO DARI DB
            bio = data['bio'] ?? "";

            _processGender(data['gender']);
            _processPhotoUrl(data['photo_url']);

            // Simpan ke lokal biar pas buka app lagi langsung muncul
            prefs.setString('name', name);
            prefs.setString('photo_url', data['photo_url'] ?? "");
            prefs.setString('gender', data['gender'] ?? "");
            prefs.setString('bio', bio!);
          });
        }
      }
    } catch (e) {
      debugPrint("Gagal ambil profil: $e");
    }
  }

  void _processGender(String? rawGender) {
    if (rawGender == null) return;
    String g = rawGender.toLowerCase();
    if (g == 'male' || g == 'laki-laki')
      gender = "Laki-laki";
    else if (g == 'female' || g == 'perempuan')
      gender = "Perempuan";
    else
      gender = "-";
  }

  void _processPhotoUrl(String? url) {
    if (url != null && url.isNotEmpty) {
      photoUrl = url.startsWith('http')
          ? url
          : "${ApiConfig.baseUrl}/${url.startsWith('/') ? url.substring(1) : url}";
    } else {
      photoUrl = null;
    }
  }

  Future<void> _fetchUserPosts() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getInt('user_id');
      if (userId == null) return;
      final response = await http.get(
        Uri.parse("${ApiConfig.baseUrl}/api/user/$userId/posts"),
        headers: ApiConfig.headers,
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && mounted) {
          setState(() {
            postItems = data['posts'];
            postsCount = postItems.length.toString();
            isLoadingPosts = false;
          });
        }
      } else {
        if (mounted) setState(() => isLoadingPosts = false);
      }
    } catch (e) {
      if (mounted) setState(() => isLoadingPosts = false);
    }
  }

  Future<void> _fetchMyOutfits() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getInt('user_id');
      if (userId == null) {
        if (mounted) setState(() => isLoadingMyOutfit = false);
        return;
      }
      final response = await http.get(
        Uri.parse("${ApiConfig.baseUrl}/api/my-outfits/$userId"),
        headers: ApiConfig.headers,
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] && mounted) {
          setState(() {
            myOutfitItems = data['outfits'];
            outfitCount = myOutfitItems.length.toString();
            isLoadingMyOutfit = false;
          });
        }
      } else {
        if (mounted) setState(() => isLoadingMyOutfit = false);
      }
    } catch (e) {
      if (mounted) setState(() => isLoadingMyOutfit = false);
    }
  }

  Future<void> _fetchWishlist() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getInt('user_id') ?? 1;
      final response = await http.get(
        Uri.parse(
          "${ApiConfig.baseUrl}/api/wardrobe_action?action=get_favorites&user_id=$userId",
        ),
        headers: ApiConfig.headers,
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == true && mounted) {
          setState(() {
            wishlistItems = data['data'];
            favCount = wishlistItems.length.toString();
            isLoadingWishlist = false;
          });
        } else {
          if (mounted) setState(() => isLoadingWishlist = false);
        }
      } else {
        if (mounted) setState(() => isLoadingWishlist = false);
      }
    } catch (e) {
      if (mounted) setState(() => isLoadingWishlist = false);
    }
  }

  // ==========================================
  // 2. FUNGSI DETAIL
  // ==========================================

  void _triggerDetail() {
    if (_selectedIndex == null) return;
    int tab = _tabController.index;

    if (tab == 0)
      _viewDetail(postItems[_selectedIndex!], "Postingan");
    else if (tab == 1)
      _viewDetail(myOutfitItems[_selectedIndex!], "Outfit");
    else
      _viewDetail(wishlistItems[_selectedIndex!], "Favorit");
  }

  void _viewDetail(Map<String, dynamic> item, String type) {
    String rawUrl = "";
    if (type == "Postingan")
      rawUrl = item['image_url'];
    else if (type == "Outfit")
      rawUrl = item['result_image_url'];
    else
      rawUrl = item['image_url'];

    String imageUrl = rawUrl.startsWith('http')
        ? rawUrl
        : "${ApiConfig.baseUrl}/$rawUrl";

    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(16),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(16),
                    ),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        maxHeight: MediaQuery.of(context).size.height * 0.6,
                      ),
                      child: InteractiveViewer(
                        child: Image.network(imageUrl, fit: BoxFit.contain),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (type == "Postingan") ...[
                          Row(
                            children: [
                              const Icon(
                                Icons.favorite,
                                color: Colors.red,
                                size: 24,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                "${item['total_likes'] ?? 0} Suka",
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          RichText(
                            text: TextSpan(
                              style: const TextStyle(
                                color: Colors.black,
                                fontSize: 14,
                              ),
                              children: [
                                TextSpan(
                                  text: username.replaceAll("@", ""),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const TextSpan(text: "  "),
                                TextSpan(text: item['caption'] ?? ""),
                              ],
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            "Dibagikan dari Profil",
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 12,
                            ),
                          ),
                        ] else ...[
                          Text(
                            type == "Outfit"
                                ? (item['outfit_name'] ?? "Pakaian Saya")
                                : (item['item_name'] ?? "Barang Favorit"),
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                          if (type == "Favorit")
                            Text(
                              "Rp ${item['price']}",
                              style: TextStyle(
                                color: primaryColor,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Positioned(
              top: 0,
              right: 0,
              child: IconButton(
                icon: const Icon(Icons.cancel, color: Colors.white, size: 30),
                onPressed: () => Navigator.pop(ctx),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================
  // 3. FUNGSI HAPUS, UNDUH, BAGIKAN
  // ==========================================

  Future<void> _deleteSelectedItem() async {
    if (_selectedIndex == null) return;

    String apiUrl = "";
    int? idToDelete;
    String itemType = "";

    if (_tabController.index == 0) {
      apiUrl = "${ApiConfig.baseUrl}/api/delete/post";
      idToDelete = postItems[_selectedIndex!]['share_id'];
      itemType = "Postingan";
    } else if (_tabController.index == 1) {
      apiUrl = "${ApiConfig.baseUrl}/api/delete/outfit";
      idToDelete = myOutfitItems[_selectedIndex!]['outfit_id'];
      itemType = "Pakaian";
    } else {
      apiUrl = "${ApiConfig.baseUrl}/api/delete/wardrobe";
      idToDelete = wishlistItems[_selectedIndex!]['item_id'];
      itemType = "Favorit";
    }

    bool confirm =
        await showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: Text("Hapus $itemType?"),
            content: const Text("Item akan dihapus secara permanen."),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text("Batal"),
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

    setState(() => _isProcessing = true);

    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"id": idToDelete}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text("$itemType dihapus")));

          // --- REFRESH DATA SETELAH HAPUS ---
          _refreshAllData();

          setState(() {
            _selectedIndex = null;
          });
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Kesalahan: $e")));
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Future<void> _downloadImage(String imageUrl) async {
    if (await canLaunchUrl(Uri.parse(imageUrl))) {
      await launchUrl(
        Uri.parse(imageUrl),
        mode: LaunchMode.externalApplication,
      );
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Membuka gambar... Tekan tahan untuk menyimpan."),
        ),
      );
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Tautan error")));
    }
  }

  void _triggerShare() {
    if (_tabController.index == 1 && _selectedIndex != null) {
      _showShareBottomSheet(myOutfitItems[_selectedIndex!]);
    }
  }

  void _showShareBottomSheet(Map<String, dynamic> outfit) {
    TextEditingController captionController = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          left: 20,
          right: 20,
          top: 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              "Bagikan Pakaian",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            const SizedBox(height: 15),
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                "${ApiConfig.baseUrl}/${outfit['result_image_url']}",
                height: 200,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(height: 15),
            TextField(
              controller: captionController,
              decoration: const InputDecoration(
                hintText: "Keterangan...",
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 15),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: primaryColor),
                onPressed: () {
                  Navigator.pop(context);
                  _submitShare(
                    outfit['result_image_url'],
                    captionController.text,
                  );
                },
                child: const Text(
                  "Bagikan",
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Future<void> _submitShare(String imageUrl, String caption) async {
    setState(() => _isProcessing = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getInt('user_id');
      final response = await http.post(
        Uri.parse("${ApiConfig.baseUrl}/api/share"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "user_id": userId,
          "image_url": imageUrl,
          "caption": caption,
        }),
      );
      if (response.statusCode == 200 && mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("Berhasil dibagikan!")));

        // --- REFRESH DATA SETELAH SHARE ---
        _refreshAllData();

        setState(() => _selectedIndex = null);
      }
    } catch (e) {
      debugPrint("Err: $e");
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Future<void> _launchUrl(String? urlString) async {
    if (urlString != null && await canLaunchUrl(Uri.parse(urlString))) {
      await launchUrl(
        Uri.parse(urlString),
        mode: LaunchMode.externalApplication,
      );
    }
  }

  // ==========================================
  // UI BANGUN
  // ==========================================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        title: Text(
          username,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined, color: Colors.black),
            tooltip: "Pengaturan",
            onPressed: () {
              // --- .THEN() SUPAYA AUTO REFRESH PAS BALIK DARI SETTINGS ---
              Navigator.pushNamed(
                context,
                '/settings',
              ).then((_) => _refreshAllData());
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          NestedScrollView(
            headerSliverBuilder: (context, innerBoxIsScrolled) {
              return [
                // SliverToBoxAdapter(
                //   child: Padding(
                //     padding: const EdgeInsets.all(16.0),
                //     child: Column(
                //       crossAxisAlignment: CrossAxisAlignment.start,
                //       children: [
                //         Row(
                //           children: [
                //             Container(
                //               decoration: BoxDecoration(
                //                 shape: BoxShape.circle,
                //                 border: Border.all(color: Colors.grey.shade300),
                //               ),
                //               child: CircleAvatar(
                //                 radius: 40,
                //                 backgroundColor: Colors.grey.shade200,
                //                 backgroundImage: (photoUrl != null)
                //                     ? NetworkImage(photoUrl!)
                //                     : null,
                //                 child: (photoUrl == null)
                //                     ? Icon(
                //                         Icons.person,
                //                         size: 40,
                //                         color: Colors.grey.shade400,
                //                       )
                //                     : null,
                //               ),
                //             ),
                //             const SizedBox(width: 20),
                //             Expanded(
                //               child: Row(
                //                 mainAxisAlignment:
                //                     MainAxisAlignment.spaceAround,
                //                 children: [
                //                   _buildStatColumn("Post", postsCount),
                //                   _buildStatColumn("My Oufit", outfitCount),
                //                   _buildStatColumn("Wishlist", favCount),
                //                 ],
                //               ),
                //             ),
                //           ],
                //         ),
                //         const SizedBox(height: 12),
                //         // ... di dalam Column profil ...
                //         Text(
                //           name,
                //           style: const TextStyle(
                //             fontWeight: FontWeight.bold,
                //             fontSize: 16,
                //           ),
                //         ),
                //         // PINDAHKAN BIO KE SINI (DI LUAR IF GENDER)
                //         if (bio != null && bio!.isNotEmpty)
                //           Padding(
                //             padding: const EdgeInsets.only(top: 2),
                //             child: Text(
                //               bio!,
                //               style: TextStyle(color: Colors.grey.shade800),
                //             ),
                //           ),
                //         // GENDER TETAP MUNCUL JIKA ADA
                //         if (gender != "-")
                //           Padding(
                //             padding: const EdgeInsets.only(top: 2),
                //             child: Text(
                //               gender,
                //               style: TextStyle(
                //                 color: Colors.grey.shade600,
                //                 fontSize: 12,
                //               ),
                //             ),
                //           ),
                //         const SizedBox(height: 16),
                //       ],
                //     ),
                //   ),
                // ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: 24.0,
                      horizontal: 16.0,
                    ),
                    child: Column(
                      children: [
                        // 1. FOTO PROFIL
                        Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.grey.shade200,
                              width: 2,
                            ),
                          ),
                          child: CircleAvatar(
                            radius: 50,
                            backgroundColor: Colors.grey.shade100,
                            backgroundImage: (photoUrl != null)
                                ? NetworkImage(photoUrl!)
                                : null,
                            child: (photoUrl == null)
                                ? Icon(
                                    Icons.person,
                                    size: 50,
                                    color: Colors.grey.shade400,
                                  )
                                : null,
                          ),
                        ),
                        const SizedBox(height: 12),

                        // 2. NAMA LENGKAP
                        Text(
                          name,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 20,
                          ),
                        ),
                        // Username diletakkan kecil di bawah nama (opsional)
                        // Text(
                        //   username,
                        //   style: TextStyle(
                        //     color: Colors.grey.shade600,
                        //     fontSize: 13,
                        //   ),
                        // ),
                        const SizedBox(height: 5),

                        // 3. BADGE GENDER (DI BAWAH NAMA/USERNAME)
                        if (gender != "-")
                          Container(
                            margin: const EdgeInsets.only(
                              bottom: 12,
                            ), // Jarak ke Bio
                            child: OutlinedButton(
                              onPressed: null,
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 0,
                                ),
                                minimumSize: Size.zero,
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                side: BorderSide(
                                  color: gender == "Laki-laki"
                                      ? Colors.blue[300]!
                                      : Colors.pink[200]!,
                                  width: 1.0,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(15),
                                ),
                              ),
                              child: Text(
                                gender,
                                style: TextStyle(
                                  color: gender == "Laki-laki"
                                      ? Colors.blue[300]!
                                      : Colors.pink[200],
                                  fontWeight: FontWeight.w600,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ),

                        // 4. BIO (DI BAGIAN PALING BAWAH PROFIL)
                        if (bio != null && bio!.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 40),
                            child: Text(
                              bio!,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.grey.shade800,
                                fontSize: 14,
                                // fontStyle: FontStyle.italic,
                              ),
                            ),
                          ),
                        const SizedBox(height: 10),
                      ],
                    ),
                  ),
                ),
                SliverPersistentHeader(
                  delegate: _SliverAppBarDelegate(
                    TabBar(
                      controller: _tabController,
                      labelColor: Colors.black,
                      unselectedLabelColor: Colors.grey,
                      indicatorColor: primaryColor,
                      indicatorWeight: 2,
                      tabs: const [
                        Tab(icon: Icon(Icons.grid_on), text: "Postingan"),
                        Tab(icon: Icon(Icons.checkroom), text: "My Oufit"),
                        Tab(icon: Icon(Icons.favorite_border), text: "Wishlist"),
                      ],
                    ),
                  ),
                  pinned: true,
                ),
              ];
            },
            body: TabBarView(
              controller: _tabController,
              children: [
                _buildPostGrid(),
                _buildMyOutfitGrid(),
                _buildWishlistGrid(),
              ],
            ),
          ),

          if (_selectedIndex != null)
            Positioned(
              bottom: 20,
              left: 20,
              right: 20,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  vertical: 12,
                  horizontal: 16,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF2C2C2C),
                  borderRadius: BorderRadius.circular(50),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: _buildActionButtons(),
                ),
              ),
            ),

          if (_isProcessing) const Center(child: CircularProgressIndicator()),
        ],
      ),
    );
  }

  List<Widget> _buildActionButtons() {
    List<Widget> buttons = [];
    int tabIndex = _tabController.index;
    Map<String, dynamic> item;
    String imgUrl = "";

    try {
      if (tabIndex == 0) {
        item = postItems[_selectedIndex!];
        imgUrl = "${ApiConfig.baseUrl}/${item['image_url']}";
      } else if (tabIndex == 1) {
        item = myOutfitItems[_selectedIndex!];
        imgUrl = "${ApiConfig.baseUrl}/${item['result_image_url']}";
      } else {
        item = wishlistItems[_selectedIndex!];
        String url = item['image_url'] ?? '';
        imgUrl = url.startsWith('http') ? url : "${ApiConfig.baseUrl}/$url";
      }
    } catch (e) {
      return [
        IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => setState(() => _selectedIndex = null),
        ),
      ];
    }

    buttons.add(_actionBtn(Icons.visibility, "Detail", _triggerDetail));

    if (tabIndex == 1) {
      buttons.add(
        _actionBtn(Icons.download, "Unduh", () => _downloadImage(imgUrl)),
      );
      buttons.add(_actionBtn(Icons.share, "Bagikan", _triggerShare));
    }

    if (tabIndex == 2) {
      buttons.add(
        _actionBtn(Icons.shopping_cart, "Beli", () => _launchUrl(item['link'])),
      );
    }

    buttons.add(
      _actionBtn(
        Icons.delete_outline,
        "Hapus",
        _deleteSelectedItem,
        color: Colors.redAccent,
      ),
    );

    buttons.add(
      _actionBtn(
        Icons.close,
        "Tutup",
        () => setState(() => _selectedIndex = null),
      ),
    );

    return buttons;
  }

  Widget _actionBtn(
    IconData icon,
    String tooltip,
    VoidCallback onTap, {
    Color color = Colors.white,
  }) {
    return IconButton(
      icon: Icon(icon, color: color),
      tooltip: tooltip,
      onPressed: onTap,
    );
  }

  Widget _buildPostGrid() {
    if (isLoadingPosts && postItems.isEmpty)
      return const Center(child: CircularProgressIndicator());
    return RefreshIndicator(
      color: primaryColor,
      onRefresh: _fetchUserPosts,
      child: GridView.builder(
        padding: const EdgeInsets.only(bottom: 100),
        itemCount: postItems.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          mainAxisSpacing: 2,
          crossAxisSpacing: 2,
          childAspectRatio: 1,
        ),
        itemBuilder: (context, index) {
          final item = postItems[index];
          bool isSelected = _selectedIndex == index;
          return GestureDetector(
            onTap: () =>
                setState(() => _selectedIndex = isSelected ? null : index),
            child: Stack(
              children: [
                Positioned.fill(
                  child: Image.network(
                    "${ApiConfig.baseUrl}/${item['image_url']}",
                    fit: BoxFit.cover,
                    errorBuilder: (c, e, s) =>
                        Container(color: Colors.grey.shade200),
                  ),
                ),
                if (isSelected)
                  Container(
                    color: Colors.black54,
                    child: const Center(
                      child: Icon(
                        Icons.check_circle,
                        color: Colors.white,
                        size: 30,
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildMyOutfitGrid() {
    if (isLoadingMyOutfit && myOutfitItems.isEmpty)
      return const Center(child: CircularProgressIndicator());
    return RefreshIndicator(
      color: primaryColor,
      onRefresh: _fetchMyOutfits,
      child: GridView.builder(
        padding: const EdgeInsets.only(
          left: 16,
          right: 16,
          top: 16,
          bottom: 100,
        ),
        itemCount: myOutfitItems.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
          childAspectRatio: 0.7,
        ),
        itemBuilder: (context, index) {
          final item = myOutfitItems[index];
          bool isSelected = _selectedIndex == index;
          return GestureDetector(
            onTap: () =>
                setState(() => _selectedIndex = isSelected ? null : index),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected ? primaryColor : Colors.transparent,
                  width: 3,
                ),
                boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4)],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: ClipRRect(
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(12),
                      ),
                      child: Image.network(
                        "${ApiConfig.baseUrl}/${item['result_image_url']}",
                        width: double.infinity,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8),
                    child: Text(
                      item['outfit_name'] ?? 'Pakaian',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                      maxLines: 1,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildWishlistGrid() {
    if (isLoadingWishlist && wishlistItems.isEmpty)
      return const Center(child: CircularProgressIndicator());
    return RefreshIndicator(
      color: primaryColor,
      onRefresh: _fetchWishlist,
      child: GridView.builder(
        padding: const EdgeInsets.only(
          left: 16,
          right: 16,
          top: 16,
          bottom: 100,
        ),
        itemCount: wishlistItems.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
          childAspectRatio: 0.7,
        ),
        itemBuilder: (context, index) {
          final item = wishlistItems[index];
          bool isSelected = _selectedIndex == index;
          String imageUrl = item['image_url'] ?? '';
          if (imageUrl.isNotEmpty && !imageUrl.startsWith('http'))
            imageUrl = "${ApiConfig.baseUrl}/$imageUrl";
          return GestureDetector(
            onTap: () =>
                setState(() => _selectedIndex = isSelected ? null : index),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: isSelected ? primaryColor : Colors.grey.shade200,
                  width: isSelected ? 3 : 1,
                ),
                boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4)],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: ClipRRect(
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(10),
                      ),
                      child: Image.network(
                        imageUrl,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item['item_name'] ?? 'Barang',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                        ),
                        Text(
                          "Rp ${item['price']}",
                          style: TextStyle(
                            fontSize: 11,
                            color: primaryColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatColumn(String label, String count) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          count,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        Text(label, style: const TextStyle(fontSize: 14, color: Colors.grey)),
      ],
    );
  }
}

class _SliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar _tabBar;
  _SliverAppBarDelegate(this._tabBar);
  @override
  double get minExtent => _tabBar.preferredSize.height;
  @override
  double get maxExtent => _tabBar.preferredSize.height;
  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) => Container(color: Colors.white, child: _tabBar);
  @override
  bool shouldRebuild(_SliverAppBarDelegate oldDelegate) => false;
}
