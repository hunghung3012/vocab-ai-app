import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:vocab_ai/screens/authentication/login_screen.dart';
import 'package:vocab_ai/screens/authentication/service/auth_service.dart';
import 'package:vocab_ai/screens/settings/account/account_screen.dart';
import 'package:vocab_ai/screens/settings/appearance_settings/appearance_settings_screen.dart';
import 'package:vocab_ai/screens/settings/help_support/help_support_screen.dart';
import 'package:vocab_ai/screens/settings/notifications_settings/notifications_settings_screen.dart';

import '../../providers/notification_provider.dart';
import '../../providers/theme_provider.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  AuthService get auth => AuthService();

  void _showSnack(
      BuildContext context,
      String msg, {
        Color color = Colors.black,
      }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
            Row(
            children: [
            IconButton(
            onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back_ios),
          style: IconButton.styleFrom(
            backgroundColor: Colors.grey.withOpacity(0.1),
            padding: const EdgeInsets.all(8),
          ),
        ),
        const SizedBox(width: 12),
        const Expanded(
          child: Text(
            'Settings',
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        ],
      ),
        // ✅ VÀ SỬA subtitle này thêm padding
        const Padding(
          padding: EdgeInsets.only(left: 56),
          child: Text(
            'Manage your account and preferences',
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
        ),
                const SizedBox(height: 4),
                const Text(
                  'Manage your account and preferences',
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
                const SizedBox(height: 24),

                _buildSettingsList(context, user),

                const SizedBox(height: 24),

                _buildLogoutButton(context),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSettingsList(BuildContext context, User? user) {
    final notificationProvider = Provider.of<NotificationProvider>(context);
    final themeProvider = Provider.of<ThemeProvider>(context);

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 5,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildSettingsItem(
            context,
            icon: Icons.person,
            title: 'Account',
            // 🔥 Sửa subtitle thành FutureBuilder để hiển thị tên thật
            subtitle: 'Profile & Interests', // Hoặc bạn có thể dùng FutureBuilder để load tên
            isFirst: true,
            onTap: () {
              // 🔥 Navigate tới AccountScreen
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const AccountScreen(),
                ),
              ).then((_) {
                // Có thể thêm logic reload nếu cần cập nhật tên ở màn hình này ngay lập tức
              });
            },
          ),
          _buildSettingsItem(
            context,
            icon: Icons.notifications_none,
            title: 'Notifications',
            subtitle: notificationProvider.isEnabled
                ? 'Enabled (every 20s)'
                : 'Disabled',
            trailing: notificationProvider.isEnabled
                ? Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 8,
                vertical: 4,
              ),
              decoration: BoxDecoration(
                color: Colors.green,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                'ON',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            )
                : null,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const NotificationsSettingsScreen(),
                ),
              );
            },
          ),
          _buildSettingsItem(
            context,
            icon: Icons.language,
            title: 'Language',
            subtitle: 'English',
            onTap: () {},
          ),
          _buildSettingsItem(
            context,
            icon: Icons.light_mode_outlined,
            title: 'Appearance',
            subtitle: themeProvider.isLightMode
                ? 'Light mode'
                : themeProvider.isDarkMode
                ? 'Dark mode'
                : 'System default',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const AppearanceSettingsScreen(),
                ),
              );
            },
          ),
          _buildSettingsItem(
            context,
            icon: Icons.help_outline,
            title: 'Help & Support',
            subtitle: 'Get help and contact us',
            isLast: true,
            onTap: () {
              // ✅ THAY ĐỔI: Navigate đến Help screen
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const HelpSupportScreen(),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsItem(
      BuildContext context, {
        required IconData icon,
        required String title,
        required String subtitle,
        required VoidCallback onTap,
        Widget? trailing,
        bool isFirst = false,
        bool isLast = false,
      }) {
    return Column(
      children: [
        if (!isFirst)
          const Divider(height: 1, color: Color(0xFFEEEEEE), indent: 72),
        ListTile(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16.0,
            vertical: 4.0,
          ),
          leading: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: Colors.black87),
          ),
          title: Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
          subtitle: Text(subtitle, style: const TextStyle(color: Colors.grey)),
          trailing: trailing ??
              const Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: Colors.grey,
              ),
          onTap: onTap,
          shape: isFirst
              ? const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(15)),
          )
              : isLast
              ? const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(
              bottom: Radius.circular(15),
            ),
          )
              : null,
        ),
      ],
    );
  }

  Widget _buildLogoutButton(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 5,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16.0,
          vertical: 4.0,
        ),
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: Colors.red.shade50,
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(Icons.logout, color: Colors.red),
        ),
        title: const Text(
          'Log Out',
          style: TextStyle(fontWeight: FontWeight.w500, color: Colors.red),
        ),
        trailing: const Icon(
          Icons.arrow_forward_ios,
          size: 16,
          color: Colors.grey,
        ),
        onTap: () async {
          _showSnack(context, "Logging out...", color: Colors.orange);

          final isLogout = await auth.logout();

          if (isLogout && context.mounted) {
            _showSnack(context, "Logged out", color: Colors.green);

            await Future.delayed(const Duration(milliseconds: 600));

            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (_) => const LoginScreen()),
                  (route) => false,
            );
          } else {
            _showSnack(context, "Logout failed", color: Colors.red);
          }
        },
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      ),
    );
  }
}