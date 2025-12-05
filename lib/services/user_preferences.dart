import 'package:shared_preferences/shared_preferences.dart';

class UserPreferences {
  static const _keyName = 'user_name';
  static const _keyInterests = 'user_interests';
  static const _keyAvatarPath = 'user_avatar_path'; // 🆕 Thêm key này

  // Lưu tất cả thông tin
  static Future<void> saveUserInfo(String name, String interests, String avatarPath) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyName, name);
    await prefs.setString(_keyInterests, interests);
    await prefs.setString(_keyAvatarPath, avatarPath); // 🆕 Lưu đường dẫn ảnh
  }

  static Future<String> getName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyName) ?? 'Nguyễn Văn A';
  }

  static Future<String> getInterests() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyInterests) ?? '';
  }

  // 🆕 Lấy đường dẫn ảnh
  static Future<String?> getAvatarPath() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyAvatarPath);
  }
}