import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:aplikasi/services/api_config.dart';

class EditProfilePage extends StatefulWidget {
  const EditProfilePage({super.key});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final Color primaryColor = const Color(0xFFA79277);
  // Pastikan IP ini sesuai dengan laptop Anda

  final TextEditingController nameController = TextEditingController();
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController bioController = TextEditingController();
  // Controller Email DIHAPUS karena tidak dipakai lagi

  File? _selectedImage;
  String? _currentPhotoUrl;
  final ImagePicker _picker = ImagePicker();

  bool _isLoading = true;
  int? _userId;

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  Future<void> _fetchUserData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _userId = prefs.getInt('user_id');

      if (_userId == null) {
        setState(() => _isLoading = false);
        return;
      }

      final response = await http.get(
        Uri.parse("${ApiConfig.baseUrl}/api/user/$_userId/profile"),
        headers: ApiConfig.headers, // <--- TAMBAHKAN INI
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (mounted) {
          setState(() {
            nameController.text = data['name'] ?? "";
            usernameController.text = data['username'] ?? "";
            bioController.text = data['bio'] ?? "";

            String? url = data['photo_url'];
            if (url != null && url.isNotEmpty) {
              _currentPhotoUrl = url.startsWith("http")
                  ? url
                  : "${ApiConfig.baseUrl}/$url";
            }

            _isLoading = false;
          });
        }
      }
    } catch (e) {
      print("Error ambil data: $e");
      setState(() => _isLoading = false);
    }
  }

  Future<void> _pickImage() async {
    final XFile? pickedFile = await _picker.pickImage(
      source: ImageSource.gallery,
    );
    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
      });
    }
  }

  Future<void> _saveProfile() async {
    if (_userId == null) return;

    // Validasi sederhana di frontend sebelum kirim
    if (usernameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Username tidak boleh kosong"),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      var uri = Uri.parse("${ApiConfig.baseUrl}/api/user/update");
      var request = http.MultipartRequest('POST', uri);

      request.headers.addAll(ApiConfig.headers); // <--- TAMBAHKAN INI
      request.fields['user_id'] = _userId.toString();
      request.fields['username'] = usernameController.text;
      request.fields['name'] = nameController.text; // <--- KIRIM NAMA BARU
      request.fields['bio'] = bioController.text;

      if (_selectedImage != null) {
        request.files.add(
          await http.MultipartFile.fromPath(
            'profile_image',
            _selectedImage!.path,
          ),
        );
      }

      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);
      var data = jsonDecode(response.body);

      setState(() => _isLoading = false);

      if (response.statusCode == 200 && data['success'] == true) {
        // Update SharedPreferences agar tampilan di Home/Profil langsung berubah
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('username', usernameController.text);
        await prefs.setString(
          'name',
          nameController.text,
        ); // Simpan nama baru ke memori HP

        if (data['new_bio'] != null)
          await prefs.setString('bio', data['new_bio']);
        if (data['new_photo_url'] != null)
          await prefs.setString('photo_url', data['new_photo_url']);

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Profil berhasil diperbarui!")),
        );
        Navigator.pop(context, true);
      }
      // === VALIDASI USERNAME DUPLIKAT (RESPON 409 DARI BACKEND) ===
      else if (response.statusCode == 409) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(data['message'] ?? "Username sudah digunakan"),
            backgroundColor: Colors.red,
          ),
        );
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Gagal: ${data['message']}")));
      }
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error: $e")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'Edit Profil',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFFA79277)),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Column(
                children: [
                  const SizedBox(height: 20),

                  /// ================= FOTO PROFIL =================
                  Center(
                    child: Stack(
                      alignment: Alignment.bottomRight,
                      children: [
                        CircleAvatar(
                          radius: 60,
                          backgroundColor: Colors.grey.shade200,
                          backgroundImage: _getProfileImage(),
                          child: _getProfileImage() == null
                              ? const Icon(
                                  Icons.person,
                                  size: 60,
                                  color: Colors.grey,
                                )
                              : null,
                        ),
                        GestureDetector(
                          onTap: _pickImage,
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: primaryColor,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2),
                            ),
                            child: const Icon(
                              Icons.camera_alt,
                              size: 20,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 30),

                  // Nama: readOnly dihapus, sekarang BISA diedit
                  _buildInput("Nama", nameController, readOnly: false),

                  _buildInput("Username", usernameController),

                  // Email: DIHAPUS TOTAL sesuai permintaan
                  // _buildInput("Email", emailController, readOnly: true),

                  // Bio
                  _buildInput(
                    "Bio",
                    bioController,
                    maxLines: 4,
                    keyboardType: TextInputType.multiline,
                  ),

                  const SizedBox(height: 30),

                  /// ================= SAVE BUTTON =================
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      onPressed: _saveProfile,
                      child: const Text(
                        "Simpan Perubahan",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),
                ],
              ),
            ),
    );
  }

  ImageProvider? _getProfileImage() {
    if (_selectedImage != null) {
      return FileImage(_selectedImage!);
    } else if (_currentPhotoUrl != null) {
      return NetworkImage(_currentPhotoUrl!);
    }
    return null;
  }

  Widget _buildInput(
    String label,
    TextEditingController controller, {
    bool readOnly = false,
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextField(
        controller: controller,
        readOnly: readOnly,
        maxLines: maxLines,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          labelText: label,
          alignLabelWithHint: maxLines > 1,
          filled: true,
          fillColor: readOnly ? Colors.grey.shade100 : Colors.white,
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: primaryColor),
          ),
        ),
      ),
    );
  }
}
