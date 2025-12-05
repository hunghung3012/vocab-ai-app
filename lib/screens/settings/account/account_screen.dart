import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:vocab_ai/services/user_preferences.dart';

// 🔥 IMPORT Widget ImageSourceSheet của bạn ở đây
// Nếu file đó nằm ở thư mục chat, hãy sửa đường dẫn cho đúng nhé.
// Ví dụ: import 'package:vocab_ai/screens/chat_ai/widgets/image_source_sheet.dart';
import 'package:vocab_ai/screens/chat_ai/widgets/image_source_sheet.dart';

class AccountScreen extends StatefulWidget {
  const AccountScreen({super.key});

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  final _nameController = TextEditingController();
  final _interestsController = TextEditingController();

  File? _avatarFile;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final name = await UserPreferences.getName();
    final interests = await UserPreferences.getInterests();
    final avatarPath = await UserPreferences.getAvatarPath();

    setState(() {
      _nameController.text = name;
      _interestsController.text = interests;
      if (avatarPath != null && avatarPath.isNotEmpty) {
        _avatarFile = File(avatarPath);
      }
      _isLoading = false;
    });
  }

  // 🆕 Hàm xử lý chọn ảnh (nhận vào nguồn: Camera hoặc Gallery)
  Future<void> _pickAvatar(ImageSource source) async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(
      source: source,
      imageQuality: 80, // Nén ảnh nhẹ cho mượt app
      maxWidth: 800,    // Giới hạn kích thước để không quá nặng
    );

    if (image != null) {
      setState(() {
        _avatarFile = File(image.path);
      });
    }
  }

  // 🆕 Hàm hiển thị BottomSheet chọn nguồn ảnh (Dùng lại Widget của bạn)
  void _showImagePickerOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => ImageSourceSheet( //
        onCameraTap: () => _pickAvatar(ImageSource.camera),
        onGalleryTap: () => _pickAvatar(ImageSource.gallery),
      ),
    );
  }

  Future<void> _saveUserData() async {
    await UserPreferences.saveUserInfo(
      _nameController.text,
      _interestsController.text,
      _avatarFile?.path ?? '',
    );
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Profile updated successfully!'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );
      FocusScope.of(context).unfocus();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'My Profile',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Avatar Section
            Center(
              child: GestureDetector(
                onTap: _showImagePickerOptions, // 🔥 Bấm vào gọi hàm hiện Sheet
                child: Stack(
                  children: [
                    Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.purple.shade50,
                        border: Border.all(color: Colors.white, width: 4),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.purple.withOpacity(0.2),
                            blurRadius: 15,
                            offset: const Offset(0, 8),
                          ),
                        ],
                        image: _avatarFile != null
                            ? DecorationImage(
                          image: FileImage(_avatarFile!),
                          fit: BoxFit.cover,
                        )
                            : null,
                      ),
                      child: _avatarFile == null
                          ? Center(
                        child: Text(
                          _nameController.text.isNotEmpty
                              ? _nameController.text[0].toUpperCase()
                              : 'A',
                          style: TextStyle(
                            fontSize: 48,
                            fontWeight: FontWeight.bold,
                            color: Colors.purple.shade300,
                          ),
                        ),
                      )
                          : null,
                    ),

                    // Icon Camera nhỏ ở góc
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.purple,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 3),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 5,
                            )
                          ],
                        ),
                        child: const Icon(Icons.camera_alt,
                            color: Colors.white, size: 20),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Center(
              child: Text(
                'Tap to change photo',
                style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[500],
                    fontWeight: FontWeight.w500
                ),
              ),
            ),
            const SizedBox(height: 32),

            // Name Input
            _buildLabel('Full Name'),
            const SizedBox(height: 8),
            _buildTextField(
              controller: _nameController,
              hint: 'Enter your name',
              icon: Icons.person_outline,
              onChanged: (val) => setState(() {}),
            ),

            const SizedBox(height: 24),

            // Interests Input
            Row(
              children: [
                _buildLabel('Your Interests & Hobbies'),
                const SizedBox(width: 8),
                Tooltip(
                  message: 'AI uses this for better examples.',
                  child: Icon(Icons.info_outline, size: 16, color: Colors.grey[400]),
                )
              ],
            ),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: TextField(
                controller: _interestsController,
                maxLines: 5,
                decoration: InputDecoration(
                  hintText: 'E.g., I love Chelsea FC, playing guitar...',
                  hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.all(16),
                  fillColor: Colors.white,
                  filled: true,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '💡 Tip: This helps AI create vocabulary examples relevant to YOU!',
              style: TextStyle(fontSize: 12, color: Colors.purple.shade400, fontStyle: FontStyle.italic),
            ),

            const SizedBox(height: 40),

            // Save Button
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _saveUserData,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.purple,
                  foregroundColor: Colors.white,
                  elevation: 5,
                  shadowColor: Colors.purple.withOpacity(0.4),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: const Text(
                  'Save Changes',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  // ... (Giữ nguyên các hàm _buildLabel, _buildTextField ở dưới)
  Widget _buildLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: Colors.black87,
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    Function(String)? onChanged,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        decoration: InputDecoration(
          hintText: hint,
          prefixIcon: Icon(icon, color: Colors.purple.shade300),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          fillColor: Colors.white,
          filled: true,
        ),
      ),
    );
  }
}